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

## D004 — 2026-08-06 — Structure du projet : fork nommé `mzm-native`, scaffolding `docs/ai/` + `tasks/`

**Décision** : fork GitHub créé sous `Vindemia/mzm-native` (au lieu de garder le nom `mzm`), cloné dans `~/Repos/mzm-native`. Adoption d'une structure de documentation expérimentale (`docs/ai/{STACK,ARCHITECTURE,PROJECT,DECISIONS,LEARNINGS}.md`, `tasks/{TODO,ROADMAP,SESSION}.md`, `CLAUDE.md` racine) — premier test d'un nouveau framework personnel de collaboration avec Claude Code.

**Raison** : Elrik veut tester cette structure sur un projet réel avant de l'adopter comme standard sur d'autres repos, et potentiellement en faire un skill Claude Code (noté dans Nexus `wiki/projets/idees-ia-a-explorer.md`).
