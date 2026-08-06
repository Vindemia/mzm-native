# ROADMAP — objectif long terme

Portage natif Linux jouable de Metroid: Zero Mission, à partir du decomp `mzm`. 6 jalons, chacun avec un livrable concret et une vérification objective obligatoire (voir `CLAUDE.md` pour le principe, jamais de validation subjective).

## Jalon 1 — Ça compile pour un compilateur hôte

**But** : faire accepter le code de `src/`/`include/` par un compilateur natif (gcc/clang x86_64) au lieu d'`agbcc`/`arm-none-eabi`.

**Comment** : créer une cible de build séparée (ne pas toucher au `Makefile` existant qui doit continuer à produire la ROM GBA). Stuber temporairement tout ce qui casse (registres GBA, appels BIOS, ASM inline) derrière des fonctions/macros vides, sans essayer de les implémenter correctement à ce stade.

**Livrable** : la compilation aboutit sans erreur.

**Vérification** : code de sortie du compilateur = 0. Bonus : la liste des symboles stubés devient l'inventaire de travail pour la suite (à reporter dans `docs/ai/STACK.md` ou `ARCHITECTURE.md`).

**✅ ACQUIS le 2026-08-06** (commits `10657d70`, `60751c97`). 654/654 fichiers compilent pour gcc x86_64. La vérification a été renforcée en cours de route : `tools/native/verify.sh` exige aussi le sha1 de la ROM inchangé (D006), sans quoi on modifierait `src/` à l'aveugle. Inventaire et dette : `docs/ai/native-blockers.md`.

## Jalon 2 — Ça tourne sans crash

**But** : un exécutable natif qui initialise le jeu et fait tourner sa boucle principale en continu (VBlank simulé à ~59,7275 Hz), même si rien ne s'affiche.

**Comment** : mapper IWRAM/EWRAM/VRAM sur de la mémoire allouée normalement (au lieu d'adresses fixes ARM), stub minimal des interruptions pour qu'elles ne bloquent pas la boucle.

**Livrable** : le process tourne en continu sans segfault.

**Vérification** : harnais automatisé — la boucle tourne N frames (ex. 600 = 10s), code de sortie et absence de crash vérifiés par script, pas par lecture manuelle de logs.

**Renforcement décidé au moment de planifier ce jalon** (détail et justification dans `TODO.md`) : « ne pas crasher » est satisfait par un processus qui boucle à l'infini. La vérification exige donc en plus un **compteur de frames instrumenté** atteignant N sous timeout (preuve de progression, pas de simple survie), et un **contrôle de déterminisme** — deux exécutions produisant le même hash d'état mémoire. Ce dernier est le prérequis du jalon 4, dont le diff mémoire serait inexploitable si le port dépendait de mémoire non initialisée ou de l'ASLR.

## Jalon 3 — Une image reconnaissable à l'écran ⭐ premier objectif concret

**But** : afficher une seule frame fixe issue du vrai code du jeu (typiquement l'écran-titre), via une réimplémentation minimale du PPU (juste assez pour ce cas).

**Comment** : lire les vraies données VRAM/OAM/palette écrites par le code du jeu, composer l'image, blit via SDL2.

**Livrable** : une fenêtre SDL2 affichant l'écran-titre.

**Vérification** : capture d'écran du port, capture d'écran de mGBA au même point, diff pixel automatisé (pas une comparaison à l'œil).

## Jalon 4 — Une salle jouable, sans son

**But** : Samus contrôlable (marche, saut) dans un décor qui scrolle, avec collisions correctes — une salle simple pour commencer (ex. la première salle du jeu).

**Comment** : brancher l'input SDL2 sur les registres lus par le jeu, étendre le PPU au scrolling/tilemaps dynamiques + sprites animés.

**Livrable** : une salle réellement jouable au clavier/pad.

**Vérification** : séquence d'inputs scriptée (style TAS) rejouée sur mGBA et sur le port ; dump mémoire (position, vitesse, état) à chaque frame des deux côtés ; diff numérique automatisé — match exact attendu, toute divergence pointe la frame exacte où chercher le bug.

## Jalon 5 — Le son

**But** : musique et bruitages fonctionnels.

**Comment** : rebrancher la sortie du moteur son (Sappy/M4A, déjà décompilé) vers SDL2 audio au lieu des canaux matériels DMA/PWM.

**Vérification**, deux niveaux :
- **Séquenceur** (déterministe) : dump des événements note-on/off + instrument + timing émis par le moteur, des deux côtés, diff exact.
- **Mixage/sortie** (moins garanti bit-exact) : dump des échantillons PCM des deux côtés, comparaison numérique (RMS/corrélation), pas à l'oreille.

## Jalon 6 — Couverture complète

**But** : toutes les salles, objets, boss, cutscenes, sauvegarde.

**Comment** : extension progressive, salle par salle / mécanique par mécanique.

**Vérification** : chaque salle/feature ajoutée devient un nouveau cas de test de référence (capture mémoire/pixel scriptée) — suite de non-régression qui grossit avec le projet, rejouée automatiquement à chaque changement.

## Piste écartée pour l'instant

[gba-recomp](https://github.com/JRickey/gba-recomp) — recompilateur générique direct-depuis-ROM, très précoce, à surveiller mais pas exploitable aujourd'hui (voir `docs/ai/DECISIONS.md` D001).
