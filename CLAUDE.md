# CLAUDE.md

## Projet

Fork de [`metroidret/mzm`](https://github.com/metroidret/mzm) (decomp matching GBA de Metroid: Zero Mission, 99,89%). But : portage natif Linux jouable, en gardant la logique de jeu décompilée intacte et en ne remplaçant que la couche plateforme. Détail complet : `docs/ai/PROJECT.md`.

Ce repo sert aussi de premier test d'un framework personnel de collaboration avec Claude Code (`docs/ai/` + `tasks/`). S'il fait ses preuves ici, il sera réutilisé sur d'autres projets et probablement formalisé en skill.

## Index — à lire avant de travailler

| Fichier | Contenu | Quand le mettre à jour |
|---|---|---|
| `docs/ai/PROJECT.md` | Scope du projet : in/out of scope, definition of done | Rarement — seulement si le périmètre change |
| `docs/ai/STACK.md` | Stack technique (build GBA existant + build natif à construire + outillage de vérification) | Dès qu'un choix technique est tranché (compilateur, lib, etc.) |
| `docs/ai/ARCHITECTURE.md` | Découpage logique/plateforme, frontière à remplacer pour le natif, architecture de vérification | Quand une décision d'architecture change la structure décrite |
| `docs/ai/DECISIONS.md` | Journal des décisions (fonctionnement, micro-architecture) — daté, jamais effacé | À chaque décision non triviale, avant de coder dessus |
| `docs/ai/LEARNINGS.md` | Blocages **récurrents** liés à la stack/façon de travailler, pas des bugs ponctuels | Quand un même type de blocage se reproduit une 2e fois |
| `tasks/ROADMAP.md` | Objectif long terme, détaillé par jalon | Rarement — si un jalon est redéfini |
| `tasks/TODO.md` | Détail exécutable du jalon en cours (dérivé de ROADMAP) | À chaque tâche cochée/ajoutée, en continu |
| `tasks/SESSION.md` | État de la session de travail en cours (dérivé de TODO) | En continu pendant la session, pas juste à la fin. Réinitialisé au début d'une nouvelle session |

Chaîne de détail : `ROADMAP.md` (long terme) → `TODO.md` (jalon en cours) → `SESSION.md` (ce qui se passe là, maintenant).

**Ces fichiers sont lus par toi (l'IA), pas pour un rendu humain soigné** — rester lean : prose dense, listes, tableaux. Pas de schémas ASCII ni d'illustrations qui coûtent des tokens sans ajouter d'information qu'une phrase ne donnerait pas aussi bien.

## Règle — test déterministe avant tout travail

Avant de commencer à travailler sur un objectif (un jalon, une tâche de `TODO.md`), définir **comment il sera vérifié**, et l'écrire avant d'écrire du code. Le meilleur test est toujours un test déterministe/mathématique (diff mémoire, diff pixel, diff audio, code de sortie), jamais un avis ou une impression ("ça a l'air bon"). Si un objectif n'a pas de vérification déterministe possible, le dire explicitement plutôt que de l'ignorer.

## Règle — cette session est un orchestrateur, jamais un exécutant

Cette session (celle qui lit ce `CLAUDE.md`) ne fait **jamais** d'implémentation elle-même. Fonctionnement :

1. L'orchestrateur découpe le travail et lance un **sous-agent d'implémentation** pour chaque tâche.
2. L'orchestrateur vérifie que le sous-agent a mené l'implémentation jusqu'au bout (pas de travail partiel silencieusement laissé de côté).
3. L'orchestrateur lance un **second sous-agent, distinct**, pour relire le code et vérifier que la vérification déterministe définie en amont a bien été exécutée et passe.
4. L'orchestrateur ne code pas, ne corrige pas de bug lui-même — il redirige vers un sous-agent si quelque chose ne va pas.

## Règle — proposer un hook après une bêtise évitable

Si, en cours de session, Claude fait une erreur qui aurait pu être évitée par un hook (Claude Code hook — validation automatique avant/après une action), le noter. **En fin de session**, proposer ce hook à Elrik avec ce qu'il aurait empêché. Ne jamais l'installer soi-même — toujours à évaluer et valider par l'humain d'abord.

## Liens

- Contexte complet de la décision de faire ce projet et des jalons : Nexus `~/nexus/wiki/perso/retro-ingenierie-jeux-video.md`
- Repo upstream : https://github.com/metroidret/mzm
