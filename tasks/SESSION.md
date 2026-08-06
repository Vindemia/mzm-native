# SESSION — état de la session de travail en cours

Ce fichier suit le travail **en cours**, pas terminé. Mis à jour au fur et à mesure de la session (pas seulement à la fin) pour pouvoir reprendre ce fichier à tout moment — reprise de session ou passage de relais — et savoir exactement où on en est. Vidé/réinitialisé au début d'une nouvelle session de travail.

## Session close — 2026-08-06

**Jalon 1 acquis et commité.** Branche `jalon-1-compilation-native`, trois commits (`10657d70`, `60751c97`, `4657f2f2`). **Pas encore mergée dans `main`** — `git checkout main && git merge jalon-1-compilation-native` (fast-forward).

Jalon 2 planifié dans `TODO.md`, aucune ligne de code écrite.

## À reprendre à la prochaine session

1. Merger la branche dans `main` (ou décider de continuer dessus).
2. Décider si le hook `PostToolUse`/`Task` est activé — le script est prêt et testé (`.claude/hooks/post-task-disk-check.sh`), **non installé** : il manque l'entrée dans `.claude/settings.json` (snippet dans l'historique de conversation, ou à reconstruire depuis l'en-tête du script). Elrik a dit oui sur le principe.
3. Attaquer J2-T0 (dette LP64) puis J2-T1 (étendre `verify.sh`) — dans cet ordre, le test avant le code.

## Décisions ouvertes pour le jalon 2

- `-nostdinc` vs libc pour la couche plateforme (voir `TODO.md`).
- Nom du répertoire de la couche plateforme — reporté du jalon 1 faute de matière.

## Pour plus tard (jalon 3)

**mGBA n'est pas empaqueté dans Fedora 44** (seul `libretro-mgba` existe, inutilisable comme oracle scriptable). Toute l'architecture de vérification des jalons 3+ en dépend. Options : Flatpak `io.mgba.mGBA` 0.10.5 (`flatpak install --user`, sans sudo, mais bac à sable à contourner pour les dumps) ou compilation depuis les sources.

## Sudo anticipés

- Jalon 3 : `sudo dnf install -y sdl2-compat-devel` (seul le runtime SDL2 est installé, pas les en-têtes).
