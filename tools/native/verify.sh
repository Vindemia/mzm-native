#!/usr/bin/env bash
# Definition of done du jalon 1 (voir tasks/TODO.md).
#
# Enchaine TROIS verifications independantes, sort non-zero si l'une echoue :
#   1. `make REGION=eu tidy check` -> le sha1 de la ROM GBA reste conforme
#      (preuve qu'on n'a pas casse la decomp en touchant a src/). `tidy`
#      obligatoire : le Makefile GBA ne suit pas les dependances aux .h, et
#      un agbcc en echec laisse un .s partiel plus recent que le .c -> un
#      `check` incremental peut etre vert a tort (constate en J2-T0, D010).
#   2. Compilation native (Makefile.native, -B) de tous les .c de src/ -> exit 0.
#   3. tools/native/check-implicit-ptr.sh -> aucune fonction appelee sans
#      declaration ne retourne autre chose que void / entier <= int (J2-T0).
#
# Rouge au depart, c'est attendu : ne pas affaiblir ce script pour le
# faire passer, corriger la cause (src/ ou le squelette de build natif).

set -u

cd "$(dirname "${BASH_SOURCE[0]}")/../.."  # racine du repo

STEP1_OK=0
STEP2_OK=0
STEP3_OK=0

echo "== [1/3] make REGION=eu tidy check (decomp GBA, rebuild complet, sha1) =="
if make REGION=eu tidy && make -j"$(nproc)" REGION=eu check; then
    STEP1_OK=1
    echo "== [1/3] OK =="
else
    echo "== [1/3] ECHEC : le sha1 de mzm_eu.gba ne correspond plus (ou le build GBA a echoue) =="
fi

echo
echo "== [2/3] compilation native de src/ (Makefile.native) =="
# -B : Makefile.native ne suit pas non plus les dependances aux .h (D010).
if make -B -j"$(nproc)" -f Makefile.native all; then
    STEP2_OK=1
    echo "== [2/3] OK =="
else
    echo "== [2/3] ECHEC : au moins un .c de src/ ne compile pas pour le compilateur hote =="
fi

echo
echo "== [3/3] fonctions implicites a retour non-int (dette LP64) =="
if tools/native/check-implicit-ptr.sh; then
    STEP3_OK=1
    echo "== [3/3] OK =="
else
    echo "== [3/3] ECHEC : une fonction a retour pointeur/non-int est appelee sans declaration =="
fi

echo
if [ "$STEP1_OK" -eq 1 ] && [ "$STEP2_OK" -eq 1 ] && [ "$STEP3_OK" -eq 1 ]; then
    echo "verify.sh : PASS"
    exit 0
else
    echo "verify.sh : FAIL -- etape 1: $([ $STEP1_OK -eq 1 ] && echo ok || echo ECHEC), etape 2: $([ $STEP2_OK -eq 1 ] && echo ok || echo ECHEC), etape 3: $([ $STEP3_OK -eq 1 ] && echo ok || echo ECHEC)"
    exit 1
fi
