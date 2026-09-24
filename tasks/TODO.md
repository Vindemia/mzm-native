# TODO — tâches immédiates

Détail exécutable du jalon en cours défini dans `ROADMAP.md`. Vidé/réécrit au fur et à mesure qu'un jalon est acquis et qu'on passe au suivant. Le détail du jalon 1 (acquis le 2026-08-06) est dans l'historique git, commit `60751c97`.

## Jalon en cours : 2 — Ça tourne sans crash

**But** : un exécutable natif qui initialise le jeu et fait tourner sa boucle principale en continu à ~59,7275 Hz, même si rien ne s'affiche.

### Definition of done

`tools/native/verify.sh` étendu à **cinq** étapes, toutes vertes :

1. `make REGION=eu check` — sha1 de `mzm_eu.gba` inchangé *(acquis, ne jamais casser)*.
2. Compilation native des 654 `.c` → exit 0 *(acquis)*.
3. **Édition de liens** → un binaire est produit.
4. **Progression** : le binaire tourne N=600 frames (10 s), sort en 0, et un compteur de frames instrumenté atteint bien 600, sous timeout strict.
5. **Déterminisme** : deux exécutions identiques produisent le même hash d'état mémoire par frame.

Pourquoi les étapes 4 et 5 sont formulées comme ça, plutôt que « ça ne segfault pas » comme le prévoyait `ROADMAP.md` :

- « Ne pas crasher » est satisfait par un **processus qui boucle à l'infini**. Sans compteur de frames ni timeout, un jeu bloqué à attendre un flag d'interruption jamais levé passerait le test. Le compteur prouve la progression, pas seulement la survie.
- Le déterminisme n'est pas du luxe : c'est le **prérequis du jalon 4**, dont toute la vérification repose sur un diff mémoire frame à frame contre mGBA. Si le port dépend de mémoire non initialisée ou de l'ASLR, ce diff sera bruité et inexploitable. Le détecter maintenant coûte deux exécutions ; le détecter au jalon 4 coûte une chasse au fantôme.

En complément, non bloquant pour la DoD mais à faire tourner : une cible de build **ASan + UBSan**. Elle attrape immédiatement la classe de bugs de troncature LP64 identifiée au jalon 1, qui est précisément silencieuse autrement.

### J2-T0 — Purger la dette LP64 (avant toute exécution)

- [x] `SramWriteChecked` (`include/sram/sram.h:9`) retourne `u8*` mais est appelée sans déclaration en contexte booléen (`src/save_file.c:890,901`) → en LP64 le retour implicite `int` tronque l'adresse et peut **inverser la condition**. Corriger par l'`#include` manquant, pas par un cast.
- [x] Repasser sur les 309 fonctions implicitement déclarées (`docs/ai/native-blockers.md`) : re-contrôler qu'aucune autre ne retourne un pointeur maintenant qu'on va exécuter le code. → `tools/native/check-implicit-ptr.sh` (étape 3 de `verify.sh`) : seul `SramWriteChecked` retournait un pointeur ; `CallGetNoteFrequency` (asm, sans prototype) déclarée. Rouge→vert, logs dans `docs/ai/logs/j2-t0-*`.
- [ ] **Résiduel à trancher** : 36 fonctions implicites retournent `u8`/`u16` (liste dans `native-blockers.md`). En SysV x86_64 l'ABI ne garantit pas les bits hauts d'un retour < 32 bits ; l'appelant implicite lit tout `eax` → comparaison potentiellement fausse. Hors du seuil fixé pour J2-T0 (« entier ≤ int »), non corrigé.

Fait en premier délibérément : ce bug ne produit aucun message et se manifesterait comme un comportement erratique au milieu du jalon 2, quand dix autres choses seront neuves et suspectes.

### J2-T1 — Le test avant le code

- [ ] Étendre `tools/native/verify.sh` aux étapes 3, 4, 5. Rouge au départ, comme au jalon 1.
- [ ] Décider comment le binaire expose son compteur de frames et son hash d'état (variable d'environnement, argument `--frames N`, sortie sur stdout). Rester minimal — c'est de l'instrumentation de test, pas une fonctionnalité.

### J2-T2 — Passe de mesure : les symboles non résolus

Le pendant, à l'édition de liens, de la passe de mesure du jalon 1 — et le vrai gros morceau du jalon.

- [ ] Tenter le link, collecter **tous** les symboles indéfinis, les catégoriser par origine.
- [ ] Origines attendues : le moteur audio M4A (entièrement en ASM ARM — `asm/audio_internal.s`, `asm/soundcode.s`, 644 `.s` dans `sound/`), les appels BIOS (`asm/syscalls.s`), le point d'entrée et les interruptions (`asm/crt0.s`, `asm/romheader.s`, `asm/intr_main.s`).
- [ ] Livrable : inventaire chiffré dans `docs/ai/native-blockers.md`, actionnable fichier par fichier.

### J2-T3 — Mapping mémoire

- [ ] Rediriger `EWRAM_BASE`/`IWRAM_BASE`/`VRAM_BASE`/`OAM_BASE`/`PALRAM_BASE`/`REG_BASE` (`include/gba/memory.h`) vers de la mémoire réelle, sous `#ifdef NATIVE`.
- [ ] **Contrainte identifiée au jalon 1** : ces macros servent d'**expressions constantes** dans des initialiseurs statiques (`CAST_TO_ARRAY` de `include/structs/minimap.h`). Un `malloc` est donc exclu. Piste à confirmer : des tableaux statiques (`static u8 gNativeEwram[EWRAM_SIZE]`), dont l'adresse reste une constante d'adresse valide en initialiseur statique.

### J2-T4 — BIOS : implémenter, pas stuber

- [ ] `Div`, `Sqrt`, `CpuSet`, `CpuFastSet`, `LZ77UnComp*`, `BitUnPack`, `RLUnComp`, `HuffUnComp` — à **réellement implémenter** en C portable.

Écart assumé avec `ROADMAP.md`, qui prévoyait des stubs : un `Div` qui retourne 0 ne fait pas « tourner sans crash », il produit des divisions absurdes, des boucles infinies ou des indices hors bornes. Ces routines sont du calcul pur et de la copie mémoire, quelques dizaines de lignes chacune, sans dépendance matérielle. Les stuber coûterait plus cher en débogage que les écrire.

### J2-T5 — Point d'entrée et boucle de frame

- [ ] `main()` natif remplaçant `crt0.s` : initialiser la mémoire, appeler l'init du jeu, entrer dans la boucle.
- [ ] Remplacer l'attente VBlank par un appel natif au gestionnaire enregistré (`src/callbacks.c`), cadencé à 59,7275 Hz.
- [ ] Stub des autres interruptions — assez pour ne pas bloquer la boucle, pas plus.

### J2-T6 — Symboles audio

- [ ] Stubs vides pour tous les symboles du moteur M4A, chacun marqué `TODO(jalon 5)`. On ne réimplémente **rien** du son ici : on rend seulement le link possible.

### J2-T7 — Itération jusqu'au vert

- [ ] Boucle jusqu'aux 5 étapes vertes.
- [ ] Passe ASan/UBSan propre.

## Décisions déjà tranchées (aucune question ouverte)

- **`-nostdinc`** (D008) : `src/` le garde, exactement comme la cible GBA. Les fichiers de `platform/` compilent avec les en-têtes système. Deux jeux de flags dans `Makefile.native`. Réserve : garder mince la surface de `platform/` exposée aux en-têtes du decomp, pour limiter les redéfinitions `NULL`/`TRUE`.
- **Répertoire de la couche plateforme** (D009) : `platform/`, à la racine. **Pas sous `src/`** — vérifié empiriquement, le `Makefile` GBA capterait `src/platform/*.c` via `$(wildcard src/*/*.c)` et les compilerait dans la ROM.

## Bloqué par

Rien.
