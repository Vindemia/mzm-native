# TODO — tâches immédiates

Détail exécutable du jalon en cours défini dans `ROADMAP.md`. Vidé/réécrit au fur et à mesure qu'un jalon est acquis et qu'on passe au suivant.

## Jalon en cours : 1 — Ça compile pour un compilateur hôte

- [ ] Choisir compilateur hôte (gcc ou clang) et le documenter dans `docs/ai/STACK.md`.
- [ ] Mettre en place une cible de build séparée (ne pas toucher au `Makefile` GBA existant).
- [ ] Tenter de compiler `src/`/`include/` avec le compilateur hôte, sans se soucier du résultat exécutable.
- [ ] Cataloguer chaque erreur de compilation (registre GBA, appel BIOS, ASM inline...) et stuber par une fonction/macro vide pour avancer.
- [ ] Une fois la compilation propre (exit code 0), consigner l'inventaire complet des éléments stubés — ça devient la base du jalon 2 et de `ARCHITECTURE.md`.
- [ ] Vérification : script qui lance la compilation et vérifie le code de sortie (pas de lecture manuelle des logs).

## Bloqué par

Rien pour l'instant — premier jalon, aucune dépendance.
