#!/usr/bin/env bash
# Definition of done du jalon 1 (voir tasks/TODO.md).
#
# Enchaine DEUX verifications independantes, sort non-zero si l'une echoue :
#   1. `make REGION=eu check`      -> le sha1 de la ROM GBA reste conforme
#      (preuve qu'on n'a pas casse la decomp en touchant a src/).
#   2. Compilation native (Makefile.native) de tous les .c de src/ -> exit 0.
#
# Rouge au depart, c'est attendu : ne pas affaiblir ce script pour le
# faire passer, corriger la cause (src/ ou le squelette de build natif).

set -u

cd "$(dirname "${BASH_SOURCE[0]}")/../.."  # racine du repo

STEP1_OK=0
STEP2_OK=0

echo "== [1/2] make REGION=eu check (decomp GBA, sha1) =="
if make REGION=eu check; then
    STEP1_OK=1
    echo "== [1/2] OK =="
else
    echo "== [1/2] ECHEC : le sha1 de mzm_eu.gba ne correspond plus (ou le build GBA a echoue) =="
fi

echo
echo "== [2/2] compilation native de src/ (Makefile.native) =="
if make -f Makefile.native all; then
    STEP2_OK=1
    echo "== [2/2] OK =="
else
    echo "== [2/2] ECHEC : au moins un .c de src/ ne compile pas pour le compilateur hote =="
fi

echo
if [ "$STEP1_OK" -eq 1 ] && [ "$STEP2_OK" -eq 1 ]; then
    echo "verify.sh : PASS (jalon 1 acquis)"
    exit 0
else
    echo "verify.sh : FAIL -- etape 1: $([ $STEP1_OK -eq 1 ] && echo ok || echo ECHEC), etape 2: $([ $STEP2_OK -eq 1 ] && echo ok || echo ECHEC)"
    exit 1
fi
