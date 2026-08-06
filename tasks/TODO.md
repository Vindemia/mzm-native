# TODO — tâches immédiates

Détail exécutable du jalon en cours défini dans `ROADMAP.md`. Vidé/réécrit au fur et à mesure qu'un jalon est acquis et qu'on passe au suivant.

## Jalon en cours : 1 — Ça compile pour un compilateur hôte

**Definition of done** : `tools/native/verify.sh` sort avec le code 0. Ce script vérifie **deux** choses, pas une :
1. `make REGION=eu check` → sha1 de `mzm_eu.gba` inchangé (preuve qu'on n'a pas cassé le decomp).
2. Compilation native des 654 `.c` de `src/` → exit 0.

Rien d'autre ne compte comme "jalon 1 acquis". Pas de link natif à ce stade (objets `.o` uniquement) — l'exécutable est le jalon 2.

**Contrainte structurante** : aucune modification de la logique de jeu. Toute intervention dans `src/`/`include/` est soit un `#ifdef NATIVE` autour d'un accès plateforme, soit rien. Le sha1 de l'étape 1 est ce qui rend cette contrainte vérifiable au lieu d'être une intention.

### P0 — Environnement (prérequis, aucun code) ✅

- [x] ROM EU copiée en `mzm_eu_baserom.gba`, sha1 `0fd107445a42e6f3a3e5ce8c865f412583179903` conforme à `mzm_eu.sha1`.
- [x] `python3 tools/extractor.py -r eu` → `data/` et `include/extracted/` peuplés.
- [x] Toolchain GBA : `arm-none-eabi-binutils-cs` 2.45 + `agbcc` (**fork `jiangzhengwenjz`**, pas `pret` — voir `STACK.md`) dans `tools/agbcc/`.
- [x] `make REGION=eu check` → `mzm_eu.gba: Réussi`, exit 0. **Le filet de sécurité est opérationnel.**

### T1 — Le test avant le code ✅

- [x] `tools/native/verify.sh` écrit avant le squelette de build. Rouge au départ, comme attendu.

### T2 — Squelette de build natif ✅

- [x] `Makefile.native` séparé, `Makefile` GBA intact (diff vide vérifié). `gcc`, `-DREGION_EU -DNATIVE -nostdinc -Iinclude/`, pipeline `preproc.py` → `cpp` → `gcc -c`, objets dans `build/native/`.
- [x] ASM ARM exclu de fait (on ne compile que les `.c` de `src/`).
- [x] `SHELL := /bin/bash` + `.SHELLFLAGS := -o pipefail -c` : sans ça, un échec de `preproc.py` en tête de pipe serait masqué par le code de sortie de `gcc` → faux verts.

### T3 — Passe de mesure (constater, pas corriger) ✅

- [x] 654 fichiers mesurés : 492 compilent, 162 échouent. 1305 erreurs, 714 avertissements, 8 catégories. Log : `build/native/diagnostics.log`.
- [x] **x86_64 retenu** (D007). Les 684 troncatures de pointeur viennent à 92 % de la seule macro `DMA_SET` (`include/gba/dma.h`), 7 % du moteur audio (jalon 5), 1 % du hack SRAM. **0 site confirmé en logique de jeu** → x86_64 ne coûte rien, et `-m32` fermerait la porte à ARM64.
- [x] Inventaire actionnable : `docs/ai/native-blockers.md`.
- [x] Découverte majeure : le blocage n°1 (1170 occ., 148 fichiers) n'est **pas** un problème de plateforme mais de dialecte — GCC ≥14 fait de `implicit-function-declaration` une erreur (C23) alors que le decomp est du C89. `-std=gnu89` le corrige sans toucher aux sources.

### T4 — Couche de compatibilité minimale (stubs, pas d'implémentation) ✅

- [x] `-std=gnu89` dans `Makefile.native` → 148 fichiers débloqués, **zéro source touchée**. C'est le dialecte réel du decomp (agbcc est C89), pas un contournement.
- [x] `DMA_SET` réécrit sous `#ifdef NATIVE` (`include/gba/dma.h`) → ~629 casts pointeur→entier, **zéro fichier de gameplay touché**.
- [x] `STATIC_ASSERT(sizeof(struct Sram) <= SRAM_SIZE)` désactivé sous `#ifdef NATIVE` (`include/structs/save_file.h`) → 43 fichiers. Struct non modifiée.
- [x] Macro `SYSCALL(num)` neutralisée sous `#ifdef NATIVE` (`include/syscalls.h`) → 3 fichiers. **Non anticipé par T3** : elle embarque `asm("svc N")` en dur, mnémonique ARM que l'assembleur x86 refuse.
- [x] 5 sites d'ASM inline stubés, chacun marqué `TODO(jalon 2)`.
- [x] 89 symboles `static` → non-`static` dans 3 fichiers `src/data/` : incohérence de linkage réelle du decomp (`extern` dans le header, `static` dans le `.c`). **Seule modification de source inconditionnelle du jalon.** Vérifié par le relecteur : les lignes sont octet-pour-octet identiques une fois `static ` retiré, et le sha1 ROM tient après rebuild forcé.
- [ ] ~~Registres matériel (`include/gba/memory.h`)~~ — **écart assumé, reporté au jalon 2**. `REG_BASE`/`VRAM_BASE`/etc. sont des `(void*)0x04...` utilisés comme **expressions constantes** dans des initialiseurs (`CAST_TO_ARRAY` de `include/structs/minimap.h`). Les rediriger vers de la mémoire allouée casserait ces initialiseurs, pour zéro bénéfice : la compilation passe déjà sans. Écart validé en relecture.
- [ ] ~~Nommer le répertoire de la couche plateforme~~ — sans objet : le jalon n'a produit aucun fichier de plateforme, seulement des `#ifdef` dans les en-têtes existants. À reprendre au jalon 2, quand il y aura réellement du code à isoler.

### T5 — Itération jusqu'au vert ✅

- [x] **654/654 fichiers compilent** (départ : 492/654). 0 `error:`, 170 avertissements, tous classés jalon 2 ou 5.
- [x] `tools/native/verify.sh` → **exit 0 sur les deux étapes**. Vérifié indépendamment par l'orchestrateur et par un agent relecteur distinct (dont un run après `clean` + rebuild forcé, pour écarter tout cache périmé).

### T6 — Capitaliser ✅

- [x] Inventaire des symboles stubés + **section « Dette LP64 »** dans `docs/ai/native-blockers.md`.
- [x] `STACK.md` mis à jour : gcc, `Makefile.native`, région EU, piège du fork agbcc.
- [x] `DECISIONS.md` : D005 (région EU), D006 (sha1 dans la DoD), D007 (x86_64).

## Dette ouverte pour le jalon 2

- **`SramWriteChecked`** (`include/sram/sram.h:9`) retourne `u8*` mais est appelée sans déclaration en contexte booléen (`src/save_file.c:890,901`). En LP64, retour implicite `int` → **troncature silencieuse** qui peut inverser la condition. Seule des 309 fonctions implicitement déclarées à retourner un pointeur (re-vérifié indépendamment en relecture). À traiter **avant** toute exécution.
- `DMA_SET` natif fait une copie mémoire respectant la taille d'élément, mais ignore `DMA_SRC_FIXED`/`DMA_DEST_FIXED`/`DMA_DEST_DEC`, les timings HBLANK/VBLANK et les interruptions DMA. Documenté sur place.
- `src/sram/sram.c` : relocation de code auto-modifiant pour le timing flash, non stubée (compile déjà). À remplacer par une sauvegarde sur fichier.
- `include/gba/memory.h` : mapping mémoire réel, cœur du jalon 2.
- Moteur audio : ~47 sites de bit-packing d'adresses ROM `0x08xxxxxx`. Jalon 5, réécriture et non élargissement de type.

## Bloqué par

Rien. **Jalon 1 acquis**, prochaine étape : jalon 2 (`ROADMAP.md`).
