#!/usr/bin/env bash
# J2-T0 : dette LP64 des fonctions implicitement declarees.
#
# En -std=gnu89, un appel sans declaration prealable suppose un retour
# `int`. En LP64 (x86_64), si la fonction retourne en realite un pointeur
# (ou u64/s64, struct...), la valeur est tronquee/mal lue en silence.
#
# 1. Compile (-fsyntax-only) tous les .c de src/ via le pipeline de
#    Makefile.native avec -Wimplicit-function-declaration, locale C.
# 2. Extrait les noms de fonctions implicitement declarees.
# 3. Retrouve le type de retour de chacune via ctags : prototype dans
#    include/, a defaut definition dans src/.
# 4. Exit != 0 si l'une retourne autre chose que void / entier <= int
#    (ou si son prototype est introuvable : inconnu = non sur).
#
# Usage : tools/native/check-implicit-ptr.sh  (depuis n'importe ou)

set -u -o pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

OUT=build/native-implicit
mkdir -p "$OUT"
LOG=$OUT/build.log

# Meme pipeline que la regle %.o de Makefile.native (preproc -> cpp -> gcc),
# en -fsyntax-only et fichier par fichier pour que chaque diagnostic porte
# le nom du .c (le pipeline lit stdin, gcc n'affiche sinon que "<stdin>").
# ponytail: CPPFLAGS duplique de Makefile.native, a resynchroniser s'il change.
CPPFLAGS="-DREGION_EU -DNATIVE -nostdinc -Iinclude/"
# Un log par fichier puis concatenation : en parallele, une sortie commune
# s'entrelace et coupe des lignes (diagnostic perdu, constate).
rm -rf "$OUT/src"
find src -name '*.c' | sort | LC_ALL=C xargs -P"$(nproc)" -I{} bash -o pipefail -c \
    "mkdir -p \$(dirname $OUT/{}) && python3 tools/preproc.py {} charmap.txt | cpp $CPPFLAGS | gcc -fsyntax-only -x cpp-output -std=gnu89 -Wimplicit-function-declaration - 2>&1 | sed 's|^<stdin>|{}|' > $OUT/{}.log" \
    || { echo "check-implicit-ptr : la compilation native a echoue, voir $OUT/src/**/*.log"; exit 2; }
find "$OUT/src" -name '*.log' | sort | xargs cat > "$LOG"

mapfile -t NAMES < <(grep -oE "implicit declaration of function '[A-Za-z_0-9]+'" "$LOG" \
    | sed -E "s/.*'(.*)'/\1/" | sort -u)

# Types de retour surs : void et entiers de taille <= int (typedefs resolus
# ci-dessous, enums compris).
# ponytail: u8/u16/s8/s16 acceptes comme le demande la spec ; en SysV x86_64
# les bits hauts d'un retour < 32 bits ne sont pas garantis par l'ABI.
# gcc etend en pratique, mais un prototype propre reste la vraie solution.
SAFE_RE='^(void|u8|s8|u16|s16|u32|s32|vu8|vs8|vu16|vs16|vu32|vs32|int|unsigned int|signed int|unsigned|char|signed char|unsigned char|short|unsigned short|signed short|_Bool)$'

TAGS=$(ctags -R -f - --languages=C --langmap=C:.c.h --kinds-C=+p --fields=+t include src 2>/dev/null)

# typeref d'un nom : prototype (p) dans include/ d'abord, puis definition (f).
lookup() {
    local n=$1 kind dir
    for kind in "p	include/" "f	include/" "f	src/"; do
        dir=${kind#*	}; kind=${kind%%	*}
        awk -F'\t' -v n="$n" -v k="$kind" -v d="$dir" \
            '$1==n && index($2,d)==1 && $4==k { for(i=5;i<=NF;i++) if ($i ~ /^typeref:/) { sub(/^typeref:/,"",$i); print $2 "\t" $i; exit } }' \
            <<< "$TAGS" | grep . && return 0
    done
    return 1
}

# Resout un typedef (typeref:typename:X) jusqu'a un type de base.
resolve() {
    local t=$1 next i
    for i in 1 2 3 4 5 6 7 8; do
        case $t in
            enum:*) echo int; return ;;
            struct:*|union:*) echo "$t"; return ;;
        esac
        t=${t#typename:}
        [[ $t == *'*'* ]] && { echo "$t"; return; }
        next=$(awk -F'\t' -v n="$t" '$1==n && $4=="t" { for(i=5;i<=NF;i++) if ($i ~ /^typeref:/) { sub(/^typeref:/,"",$i); print $i; exit } }' <<< "$TAGS")
        # MAKE_ENUM(type, Nom) (include/macros.h) = typedef type Nom; invisible pour ctags
        [ -z "$next" ] && next=$(grep -rhoE "MAKE_ENUM\(\s*[A-Za-z0-9_]+\s*,\s*$t\s*\)" include src | head -1 | sed -E 's/MAKE_ENUM\(\s*([A-Za-z0-9_]+).*/typename:\1/')
        [ -z "$next" ] && { echo "$t"; return; }
        t=$next
    done
    echo "$t"
}

BAD=0
echo "check-implicit-ptr : ${#NAMES[@]} fonctions implicitement declarees ($(grep -c 'implicit declaration of function' "$LOG") sites), log $LOG"
for n in "${NAMES[@]}"; do
    if ! hit=$(lookup "$n"); then
        echo "  ECHEC  $n : prototype introuvable (include/ ni src/)"
        BAD=$((BAD+1)); continue
    fi
    where=${hit%%	*}; raw=${hit#*	}
    base=$(resolve "$raw")
    if [[ ! $base =~ $SAFE_RE ]]; then
        sites=$(grep -E "implicit declaration of function '$n'" "$LOG" | cut -d: -f1,2 | sort -uV | tr '\n' ' ')
        echo "  ECHEC  $n : retourne '${raw#typename:}' -> '$base' ($where) ; appels : $sites"
        BAD=$((BAD+1))
    fi
done

if [ "$BAD" -ne 0 ]; then
    echo "check-implicit-ptr : FAIL ($BAD fonction(s) a retour non-int appelee(s) sans declaration)"
    exit 1
fi
echo "check-implicit-ptr : PASS (aucune fonction implicite ne retourne autre chose que void / entier <= int)"
