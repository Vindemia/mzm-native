# STACK

## Cible existante — build GBA (héritée du decomp upstream, ne pas casser)

| Élément | Détail |
|---|---|
| Langage | C |
| Compilateur | `agbcc` (GCC patché pour matcher le compilateur d'époque) — **fork `jiangzhengwenjz/agbcc`, pas `pret/agbcc`** (voir piège ci-dessous), installé dans `tools/agbcc/` (gitignoré), détecté automatiquement par le `Makefile` |
| Toolchain | `arm-none-eabi-binutils-cs` 2.45 (Fedora 44) |
| Architecture cible | ARM7TDMI (ARMv4T), jeu d'instructions Thumb |
| Build | `make` (voir `Makefile` racine) |
| Région | `eu` — seule ROM possédée, sha1 conforme à `mzm_eu.sha1` (D005) |
| Sortie | `mzm_{region}.gba`, doit rester byte-identique au ROM original (contrat du decomp matching) |

**Piège agbcc** : `pret/agbcc` est le dépôt qu'on trouve en premier, et il compile sans erreur — mais il ne connaît pas le flag `-f2003-patch` utilisé par le `CFLAGS` du `Makefile`. Le symptôme arrive tard, à la compilation du jeu : `agbcc: Invalid option '-f2003-patch'`. Le bon fork est `jiangzhengwenjz/agbcc` (indiqué dans le `README.md` du repo, section Dependencies).

**Prérequis de build, tous gitignorés** : `mzm_eu_baserom.gba` à la racine, puis `python3 tools/extractor.py -r eu` qui génère `data/` et `include/extracted/` — 450 des 654 `.c` de `src/` en dépendent, rien ne compile sans.

Cette cible reste fonctionnelle en permanence — c'est le filet de sécurité qui prouve que la logique de jeu n'a pas été cassée pendant les modifications côté port natif.

## Cible à construire — portage natif Linux

| Élément | Détail | Statut |
|---|---|---|
| Langage | C (même base que le decomp) | — |
| Compilateur hôte | `gcc` (clang absent de la machine, aucune raison de l'ajouter) | tranché |
| Build système natif | `Makefile.native` séparé à la racine — le repo est déjà en make, pas de CMake | tranché |
| Pipeline natif | identique à la cible GBA : `preproc.py` → `cpp` → `gcc -c`, avec `-DREGION_EU -DNATIVE -nostdinc -Iinclude/`. Objets dans `build/native/`. ASM ARM (`asm/`, `sound/`) exclu. | tranché |
| Couche plateforme (vidéo/audio/input) | SDL2 — précédent direct : `SAT-R/sa2` (Sonic Advance 2), `sm64-port` | à confirmer, pas d'alternative sérieuse identifiée |
| Rendu | à décider : blit logiciel du framebuffer composé vs upload texture GL. Pas encore tranché. | ouvert — loggen la décision dans `DECISIONS.md` quand choisi |
| Build système natif | probablement CMake ou Makefile séparé, à décider au jalon 1/2 | ouvert |

## Outillage de vérification (indépendant des deux builds ci-dessus)

| Outil | Rôle |
|---|---|
| **mGBA** (≥ 0.10) | Émulateur de référence ("oracle") — vérité terrain pour comparer le port |
| API scripting Lua de mGBA | Lecture mémoire par frame (`emu.memory.wram:read8(...)`), callbacks `frame`, dump d'écran, dump audio |
| Séquences d'input scriptées (style TAS) | Éliminent la variabilité humaine — même script rejoué sur mGBA et sur le port natif |
| Symboles/map file du build `mzm` | Donne les adresses mémoire des variables de jeu (position, vitesse, état) sans reverse à l'aveugle |

## Non-décisions actuelles (à trancher plus tard, pas maintenant)

- Nom exact du dossier contenant le code de la couche plateforme native (proposition à faire au jalon 1, une fois qu'on voit concrètement ce qu'il faut isoler).
- Système de build natif définitif.
- Stratégie de rendu (logiciel vs GL).

Toute décision prise sur ces points doit être loggée dans `DECISIONS.md`, pas seulement codée silencieusement.
