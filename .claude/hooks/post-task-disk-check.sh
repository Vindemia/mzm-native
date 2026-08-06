#!/usr/bin/env bash
# PostToolUse / matcher "Task" — se declenche quand un sous-agent rend la main.
#
# But : injecter l'etat REEL du depot dans le contexte de l'orchestrateur, pour
# qu'il verifie ce qui est ecrit sur disque plutot que ce que le rapport affirme
# (regle "Chaque sous-agent tient sa part de la documentation" dans CLAUDE.md).
#
# Non bloquant par choix : il ne peut pas savoir quelle partie de la doc CE
# sous-agent devait tenir, et certains agents (relecteurs) ont interdiction
# d'ecrire. Un hook bloquant les punirait d'avoir obei. Ici on rappelle, on
# n'empeche rien.
#
# Sortie : JSON PostToolUse avec additionalContext. Toujours exit 0 — un hook
# qui casse la session pour un probleme d'affichage serait pire que pas de hook.

set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

status=$(git status --short 2>/dev/null | head -40)
diffstat=$(git diff --stat HEAD 2>/dev/null | tail -20)

if [ -z "$status" ]; then
    status="(arbre propre — ce sous-agent n'a rien ecrit sur disque)"
fi

jq -nc \
    --arg s "$status" \
    --arg d "${diffstat:-(aucun changement suivi)}" \
    '{
        hookSpecificOutput: {
            hookEventName: "PostToolUse",
            additionalContext: (
                "Etat reel du depot apres ce sous-agent — verifier le disque, pas le rapport.\n\n"
                + "git status --short :\n" + $s
                + "\n\ngit diff --stat HEAD :\n" + $d
            )
        }
    }'
