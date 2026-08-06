# STACK

## Cible existante — build GBA (héritée du decomp upstream, ne pas casser)

| Élément | Détail |
|---|---|
| Langage | C |
| Compilateur | `agbcc` (GCC patché pour matcher le compilateur d'époque) |
| Toolchain | `binutils-arm-none-eabi` |
| Architecture cible | ARM7TDMI (ARMv4T), jeu d'instructions Thumb |
| Build | `make` (voir `Makefile` racine) |
| Sortie | `mzm_{region}.gba`, doit rester byte-identique au ROM original (contrat du decomp matching) |

Cette cible reste fonctionnelle en permanence — c'est le filet de sécurité qui prouve que la logique de jeu n'a pas été cassée pendant les modifications côté port natif.

## Cible à construire — portage natif Linux

| Élément | Détail | Statut |
|---|---|---|
| Langage | C (même base que le decomp) | — |
| Compilateur hôte | gcc ou clang (x86_64 Linux) | à choisir au jalon 1 |
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
