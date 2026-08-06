# DECISIONS

Journal des décisions prises en cours de route (fonctionnement, micro-architecture). Chaque entrée : date, décision, alternatives considérées, raison. On n'efface jamais une entrée passée — si une décision est renversée, on ajoute une nouvelle entrée qui référence l'ancienne.

## D001 — 2026-08-06 — Portage manuel sur `mzm` plutôt qu'un recompilateur générique

**Décision** : construire le portage natif à la main, sur la base du decomp `metroidret/mzm` (modèle Sonic Advance 2 / `SAT-R/sa2`).

**Alternatives considérées** :
- `gba-recomp` (recompilateur générique direct-depuis-ROM, équivalent N64Recomp) — écarté : très précoce (~170k/4,1M fonctions mappées, un seul jeu de référence, aucun Metroid testé), pas utilisable aujourd'hui.
- Attendre Metaforce (réimplémentation native de Metroid Prime) — écarté pour ce projet : autre jeu, statut alpha sans build public.

**Raison** : `mzm` est à 99,89% de matching, le plus gros du travail de compréhension du code est déjà fait. Le précédent Sonic Advance 2 prouve que le chemin "decomp matching → port SDL2" fonctionne réellement sur un jeu GBA.

## D002 — 2026-08-06 — Vérification objective obligatoire à chaque jalon

**Décision** : aucun jalon n'est considéré acquis sans une vérification automatisée/reproductible en script (diff mémoire, diff pixel, diff audio) — jamais une validation "ça a l'air/sonne bon" ou "je l'ai joué, ça semble pareil".

**Raison** : la logique de jeu décompilée est déjà prouvée identique bit-à-bit. Ce qui peut diverger dans un port, c'est l'environnement construit autour (timing de boucle, arrondi virgule fixe, instant de lecture de l'input) — des bugs d'intégration subtils, plus faciles à détecter par un diff numérique qu'à l'œil/l'oreille. Détail de la méthode (scripting mGBA + diff mémoire/pixel/audio) dans `CLAUDE.md` et `ARCHITECTURE.md`.

## D003 — 2026-08-06 — Ordre des jalons et choix du premier jalon "montrable"

**Décision** : 6 jalons (compile → tourne sans crash → image reconnaissable → salle jouable → son → couverture complète), avec le **jalon 3** (image reconnaissable à l'écran) comme premier objectif visible à viser concrètement — les jalons 1 et 2 sont indispensables mais invisibles de l'extérieur.

**Détail** : voir `tasks/ROADMAP.md`.

## D005 — 2026-08-06 — Région de travail : EU (pas US)

**Décision** : le projet travaille sur `REGION=eu`. Le baserom est la copie EU possédée par Elrik (`/mnt/retro/roms/gba/Metroid - Zero Mission (Europe) (En,Fr,De,Es,It).gba`), copiée en `mzm_eu_baserom.gba` à la racine (non commitée — `.gitignore` couvre `*.gba`).

**Alternatives considérées** : US — c'est la région la plus travaillée upstream, mais elle n'est pas dans la collection d'Elrik. En acheter/récupérer une autre copie n'apporte rien ici.

**Raison** : le sha1 de la ROM EU disponible (`0fd107445a42e6f3a3e5ce8c865f412583179903`) correspond exactement à `mzm_eu.sha1` du decomp. `REGION=eu` est donc une cible pleinement supportée upstream (`make check` a un oracle valide). Aucune raison de préférer US.

## D006 — 2026-08-06 — Vérification du jalon 1 : sha1 de la ROM **en plus** du build natif

**Décision** : la definition of done du jalon 1 est un script `tools/native/verify.sh` qui vérifie deux choses — (1) `make REGION=eu check`, sha1 de la ROM GBA inchangé, et (2) compilation native exit 0. Le `ROADMAP.md` ne mentionnait que le point (2).

**Raison** : le jalon 1 consiste à modifier `src/`/`include/` (stubs, `#ifdef NATIVE`) pour faire passer un autre compilateur. Sans le sha1, on modifie le decomp à l'aveugle et une régression n'est découverte que plusieurs jalons plus tard, quand elle est devenue coûteuse à localiser. Le sha1 transforme la règle « ne pas toucher à la logique de jeu » d'une intention en une contrainte mécanique. Coût : installer la toolchain GBA (`arm-none-eabi-binutils` + `agbcc`) dès maintenant — validé par Elrik.

## D004 — 2026-08-06 — Structure du projet : fork nommé `mzm-native`, scaffolding `docs/ai/` + `tasks/`

**Décision** : fork GitHub créé sous `Vindemia/mzm-native` (au lieu de garder le nom `mzm`), cloné dans `~/Repos/mzm-native`. Adoption d'une structure de documentation expérimentale (`docs/ai/{STACK,ARCHITECTURE,PROJECT,DECISIONS,LEARNINGS}.md`, `tasks/{TODO,ROADMAP,SESSION}.md`, `CLAUDE.md` racine) — premier test d'un nouveau framework personnel de collaboration avec Claude Code.

**Raison** : Elrik veut tester cette structure sur un projet réel avant de l'adopter comme standard sur d'autres repos, et potentiellement en faire un skill Claude Code (noté dans Nexus `wiki/projets/idees-ia-a-explorer.md`).

## D007 — 2026-08-06 — Cible native en x86_64, pas `-m32`

**Décision** : le build natif cible x86_64 (architecture par défaut de l'hôte), pas `-m32`.

**Mesure (T3)** : sur les 654 `.c` de `src/`, la catégorie de diagnostics directement imputable à la taille de pointeur est `-Wpointer-to-int-cast`/`-Wint-to-pointer-cast` (684 sites, 44 fichiers) + `STATIC_ASSERT(sizeof(struct Sram) <= SRAM_SIZE)` (43 fichiers, dépassement de 8 octets). Ventilé par origine réelle du cast, pas par fichier appelant :

| Origine | Sites | Nature |
|---|---|---|
| Macro `DMA_SET` (`include/gba/dma.h`) — écriture de pointeurs dans des registres DMA matériels | ~629 (92 %) | Plateforme pure — sera réécrite intégralement au jalon 2, quel que soit le choix 32/64 |
| Moteur audio (bit-packing d'adresses ROM dans le driver dérivé M4A) | ~47 (7 %) | Plateforme/driver, jalon 5, déjà hors périmètre |
| Truc BIOS SRAM (relocation de code auto-modifiant, `src/sram/sram.c`) | 8 (1 %) | Plateforme, sera stubé intégralement en T4 |
| `struct EnvironmentalEffect.pOamFrame` (pointeur réel dans `struct Sram`, via `SaveFile`/`SaveDemo`) | 1 champ, cause du dépassement de 8 octets du `STATIC_ASSERT` sur 43 fichiers | Struct de sauvegarde/état de jeu — mais la limite 32 Ko violée est une contrainte du flash SRAM physique du GBA, sans objet une fois la sauvegarde native sur fichier |
| Logique de jeu (IA de sprite, physique, état de niveau, cutscenes) réinterprétant elle-même un pointeur en entier | **0 confirmé** après audit de tous les fichiers | — |

Vérifié : aucun site de troncature de pointeur trouvé dans du code de gameplay au sens strict (`src/sprites_ai/`, physique, état de progression). Tous les sites audités renvoient soit à la macro `DMA_SET`, soit au moteur audio, soit au hack SRAM — trois points de correction centralisés (2 fichiers `include/`, 1 fichier `src/sram/`), pas une modification dispersée dans le decomp.

Passe de comparaison 32 bits (`gcc -m32 -c`, sans `glibc-devel.i686` — viable car `-c` seul ne nécessite ni `crt` ni libc avec `-nostdinc`) : `-Wpointer-to-int-cast` tombe de 680 à 14 sites, et le dépassement `SramStructSize` disparaît (32608 vs 32768, marge positive). Confirme que ces catégories sont bien pilotées par la taille de pointeur — mais ce chiffre n'est pas le critère de décision (voir raison ci-dessous).

Angle mort vérifié : une passe neutralisant la première cause de blocage (`-Wimplicit-function-declaration` downgradée en avertissement, 148 fichiers débloqués en plus) donne exactement le même compte de `-Wpointer-to-int-cast` (680) qu'en passe normale — les erreurs amont ne masquent donc pas de sites supplémentaires de façon significative sur cette mesure.

**Alternatives considérées** :
- `-m32` — écarté. Spécifique x86, ferme la porte à ARM64 (Apple Silicon, Raspberry Pi, mobile) alors que x86_64 reste portable. Nécessiterait en plus `glibc-devel.i686` (absent, non installable sans sudo) puis un SDL2 32 bits complet au jalon 3, sur des distributions qui réduisent leur support i686 (Fedora).
- Correction au cas par cas dans chaque fichier de gameplay touché — écarté car inutile : la mesure montre que le nombre réel de sites en logique de jeu est nul une fois la classification par origine faite, pas par fichier appelant.

**Raison** : le principe fondateur du projet (ne pas modifier la logique de jeu décompilée) aurait dû faire pencher vers `-m32` si les sites de troncature avaient été dispersés dans le gameplay. Ce n'est pas le cas : 99 % des sites mesurés sont concentrés dans une macro plateforme (`DMA_SET`) et deux sous-systèmes déjà prévus pour réécriture complète (audio jalon 5, SRAM T4). Les corriger en 64 bits coûte la même chose qu'en 32 bits — un remplacement de macro/fonction plateforme, zéro fichier `src/*.c` de gameplay modifié. Le seul site touchant une struct de sauvegarde/état de jeu (`EnvironmentalEffect.pOamFrame`) se résout par un `#ifdef NATIVE` sur une assertion devenue sans objet (contrainte de taille du flash SRAM physique), pas par une réécriture de la struct. x86_64 est donc retenu sans compromis sur la contrainte de non-régression du decomp, avec le bénéfice de rester portable ARM64 et de ne dépendre d'aucun paquet 32 bits pour SDL2 au jalon 3.

## D008 — 2026-08-06 — `-nostdinc` conservé sur `src/`, en-têtes système autorisés sur la couche plateforme

**Décision** : le code de jeu décompilé (`src/`) continue de compiler avec `-nostdinc -Iinclude/`, exactement comme la cible GBA. Les fichiers de la couche plateforme, eux, compilent avec les en-têtes système normaux. Deux jeux de flags dans `Makefile.native`.

**Alternatives considérées** :
- Tout garder `-nostdinc`, la couche plateforme redéclarant à la main les fonctions libc dont elle a besoin — écarté : tenable pour `memcpy`, intenable dès SDL2 au jalon 3, qu'on ne va pas redéclarer à la main.
- Abandonner `-nostdinc` partout et corriger les collisions — écarté : c'est l'option risquée. Changer ce que voient les 654 fichiers de `src/` est précisément la façon dont une divergence subtile s'installe, et le sha1 de la ROM ne protège que la cible GBA, pas la sémantique native.

**Raison** : tant que `src/` voit exactement les mêmes en-têtes dans les deux cibles, aucune divergence n'est possible par ce chemin. Le coût est d'une règle supplémentaire dans le Makefile.

**Réserve connue** : à la couture, un fichier plateforme incluant à la fois `<stdio.h>` et `types.h` redéfinira `NULL`/`TRUE`. Garder mince la surface du code plateforme exposée aux en-têtes du decomp.

## D009 — 2026-08-06 — La couche plateforme vit dans `platform/`, à la racine

**Décision** : le code de la couche plateforme va dans un répertoire `platform/` à la racine du dépôt. (Lève la non-décision laissée ouverte dans `STACK.md` et reportée au jalon 1 faute de matière.)

**Alternatives considérées** :
- `src/platform/` — **techniquement impossible**. Vérifié empiriquement : le `Makefile` GBA collecte ses sources via `$(wildcard src/*/*.c)`, qui capte `src/platform/*.c` et les compilerait dans la ROM. Casserait le build GBA.
- `native/` — écarté : décrit la cible, or tout le projet est « natif », le mot ne distingue rien.
- `port/` — écarté : vague, ne dit pas que le dossier contient la couche de remplacement du matériel.

**Raison** : au-delà de la contrainte technique ci-dessus, garder la couche plateforme hors de `src/` préserve l'invariant qui a servi tout le jalon 1 — « tout diff sous `src/` est suspect et doit être justifié ». `platform/` reprend le vocabulaire déjà employé dans `ARCHITECTURE.md`.
