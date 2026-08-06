# PROJECT — Portage natif Linux de Metroid: Zero Mission

## Scope

Ce projet part du fork [`metroidret/mzm`](https://github.com/metroidret/mzm) — une décompilation "matching" de Metroid: Zero Mission (GBA) à 99,89% (2718/2721 fonctions) — pour produire un **binaire natif Linux** qui exécute la vraie logique de jeu décompilée, sans passer par un émulateur GBA.

Objectif final : pouvoir modifier le code du jeu (paramètres, ajout de pouvoirs, etc.) et lancer le résultat comme une application native, avec un cycle "modifie → build → lance" direct, sans étape ROM/émulation.

## Pourquoi ce projet

- Curiosité personnelle : accéder au vrai code source d'un jeu Metroid et pouvoir "s'amuser avec", pas juste patcher des octets (ROM hacking classique).
- Premier terrain de test d'un nouveau framework de collaboration avec Claude Code (voir `CLAUDE.md`) — si la structure `docs/ai/` + `tasks/` fonctionne bien ici, elle deviendra le standard réutilisé sur d'autres projets.

## Précédent qui prouve la faisabilité

[SAT-R/sa2](https://github.com/SAT-R/sa2) a fait exactement ce chemin pour Sonic Advance 1 & 2 : décompilation matching GBA → portage natif PC via SDL2. C'est le modèle suivi ici (voir `ARCHITECTURE.md`).

## In scope

- Portage natif **Linux x86_64** en priorité (pas Windows/Mac pour l'instant).
- Réutilisation maximale du code de logique de jeu déjà décompilé et matché (`src/`, `include/`) — le travail porte sur la couche plateforme (BIOS, PPU, APU, input), pas sur la réécriture de la logique de jeu.
- Vérification objective/automatisée à chaque jalon (principe posé dans `CLAUDE.md`).
- Utilisation exclusive de ROM/assets possédés légalement par Elrik (déjà présents dans le homelab, voir Nexus).

## Out of scope (pour l'instant)

- Portage Windows/Mac.
- Level design / création de contenu (couvert par d'autres outils — MAGE — hors de ce projet).
- Contribution upstream à `metroidret/mzm` (peut arriver ponctuellement si un bug de matching est trouvé en cours de route, mais n'est pas l'objectif).
- Polish audio/visuel au-delà de la fidélité à l'original.

## Definition of done (par jalon)

Voir `tasks/ROADMAP.md` pour le détail des 6 jalons. Aucun jalon n'est considéré acquis sans vérification automatisée reproductible (pas de validation "à l'œil/à l'oreille/au pad") — règle détaillée dans `CLAUDE.md`.

## Liens

- Repo upstream : https://github.com/metroidret/mzm
- Fork : https://github.com/Vindemia/mzm-native
- Contexte complet de la décision et des jalons : Nexus `wiki/perso/retro-ingenierie-jeux-video.md`
