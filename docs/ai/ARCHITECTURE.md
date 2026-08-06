# ARCHITECTURE

## Principe central : deux cibles de build, une seule logique de jeu

`src/`/`include/` (logique de jeu décompilée, matchée) alimente deux cibles de build : la cible GBA existante (agbcc + ARM → `mzm_us.gba`, ne pas casser) et la cible native à construire (gcc/clang + SDL2 → binaire Linux). Le code de `src/`/`include/` doit rester **identique pour les deux cibles** autant que possible — seule la "couche plateforme" (tout ce qui touche au matériel GBA) diffère.

## La frontière plateforme (ce qui doit être remplacé pour la cible native)

- **Registres matériel** (`REG_DISPCNT`, `REG_BG0CNT`, etc.) — accès mémoire directs à des adresses fixes sur GBA (0x04000000+), à intercepter/rediriger côté natif.
- **Appels BIOS** (SWI — `Div`, `Sqrt`, `CpuSet`, décompression LZ77/Huffman, attente VBlank) — routines fournies par le matériel GBA, à réimplémenter en C portable.
- **PPU (affichage)** — composition des tiles/sprites/backgrounds/priorités depuis VRAM/OAM/palette. C'est le plus gros morceau : il faut lire les mêmes structures de données que le vrai jeu écrit, et les traduire en pixels affichables via SDL2.
- **APU (son)** — le moteur son du jeu (Sappy/M4A, probablement déjà décompilé comme le reste) pilote des canaux matériels DMA/PWM. Côté natif, on garde le séquenceur tel quel et on redirige juste sa sortie vers SDL2 audio.
- **Input** — lecture d'un registre matériel côté GBA, à remplacer par le polling SDL2 au même point du cycle de frame (le timing de lecture compte, voir `docs/ai/LEARNINGS.md` si ça devient un point de friction récurrent).

Tout le reste (physique, collisions, IA, état du jeu, inventaire...) ne devrait avoir **aucune raison de changer** entre les deux cibles.

## Feuille de route (résumé — détail dans `tasks/ROADMAP.md`)

1. Ça compile pour un compilateur hôte (inventaire de ce qui casse).
2. Ça tourne sans crash (boucle de jeu native, écran noir).
3. Une image reconnaissable à l'écran (premier jalon montrable).
4. Une salle jouable, sans son.
5. Le son.
6. Couverture complète, salle par salle.

## Architecture de vérification

Chaque jalon se prouve par comparaison automatisée contre mGBA (l'oracle), jamais par observation subjective : même script d'input figé (TAS-style) rejoué sur mGBA (dump mémoire/pixels/audio via scripting Lua) et sur le port natif (même instrumentation ajoutée au code), puis diff automatique des deux séries de valeurs. Détail de la méthode et principe directeur (aucun jalon acquis sans check automatisé) : voir `CLAUDE.md`.

## Ce document évolue

Toute décision d'architecture significative (ex. choix du découpage exact des fichiers de la couche plateforme, stratégie de rendu) doit être **d'abord loggée dans `DECISIONS.md`**, puis reflétée ici si elle change la structure décrite ci-dessus.
