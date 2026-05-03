# Spécification des tests de gameplay

## Principes généraux

### Deck contrôlé
Chaque scénario utilise un deck fixe injecté au lieu du chargement aléatoire normal.
Un helper `_inject_test_deck(problems_by_phase, phases)` sera ajouté à `main.gd` (ou via
un script de test qui surcharge les données après `_ready`) pour court-circuiter
`_load_problems()` et `_limit_problems_counts()`.

Une carte de test minimale ressemble à :
```
{
  "problem_id": "TEST_001",
  "phase_id_dep": "CHOOSE_CHRONIQUE_GAME",
  "problem_description": "Test card",
  "choice_a": "Oui", "choice_b": "Non",
  "outcome_a": "", "outcome_b": "",
  "sound_a": "", "sound_b": "",
  "character_img_id": "PLOUF", "background_img_id": "FADED",
  "creativity_a": 0, "creativity_b": 0,
  "familly_life_a": 0, "familly_life_b": 0,
  "popularity_a": 0, "popularity_b": 0,
  "speed_a": 0, "speed_b": 0,
  "impact_multiplier": 1
}
```

### Save file contrôlé
Un flag `DEBUG_SAVE_OVERRIDE: Dictionary = {}` sera ajouté à `main.gd`.
Si non vide, il remplace la lecture du fichier `user://save_data.json` dans `_load_game_data()`.
Les tests l'alimentent avant de lancer la scène :
```gdscript
main.DEBUG_SAVE_OVERRIDE = { "has_reached_phase_5": false }
```

---

## Catégorie 1 — Tutoriel

### T-01 `tuto_premier_lancement`
**Objectif** : vérifier que le tuto s'affiche pour un nouveau joueur.

**Setup** :
- `DEBUG_SAVE_OVERRIDE = { "has_reached_phase_5": false }`
- Pas de fichier save sur le disque (ou override suffit)

**Actions** : laisser `_ready()` se terminer, ne pas interagir.

**Assertions** :
- `$help_1.visible == true`
- `$help_2.visible == false`
- `$help_3.visible == false`
- `card_deck.is_interaction_enabled() == false`

---

### T-02 `tuto_joueur_experimente`
**Objectif** : vérifier que le tuto est skippé pour un joueur ayant atteint la phase 5.

**Setup** :
- `DEBUG_SAVE_OVERRIDE = { "has_reached_phase_5": true }`

**Actions** : laisser `_ready()` se terminer.

**Assertions** :
- `$help_1.visible == false`
- `$help_2.visible == false`
- `$help_3.visible == false`
- `card_deck.is_interaction_enabled() == true`

---

## Catégorie 2 — Les 8 morts

Toutes les morts partagent le même pattern :

**Setup commun** :
- `DEBUG_SAVE_OVERRIDE = { "has_reached_phase_5": true }` (pas de tuto)
- `DEBUG_DISABLE_INTRO = true`
- Deck injecté : 1 seule phase (`CHOOSE_CHRONIQUE_GAME`), 1 carte avec l'impact ciblé

**Actions communes** : swiper le choix qui amène la stat hors limites.

**Assertion commune** : `g_game_over == true` + vérifier le bon message/image affiché.

---

### M-01 `mort_creativity_trop_basse`
**Deck** : 1 carte avec `creativity_a = -20`, stats de départ à 20 → total 0 → game over.

**Assertions** :
- `g_game_over == true`
- Message contient "Page Blanche"
- Image : `CREATIVITY_TOO_LOW`

---

### M-02 `mort_creativity_trop_haute`
**Deck** : 1 carte avec `creativity_a = 21`, stats de départ à 20 → total 41 > MAX_STAT.

**Assertions** :
- `g_game_over == true`
- Message contient "Plouf en feu"
- Image : `CREATIVITY_TOO_HIGH`

---

### M-03 `mort_familly_life_trop_basse`
**Deck** : 1 carte avec `familly_life_a = -20`.

**Assertions** :
- `g_game_over == true`
- Message contient "Papa, c'est qui lui"
- Image : `FAMILLY_LIFE_TOO_LOW`

---

### M-04 `mort_familly_life_trop_haute`
**Deck** : 1 carte avec `familly_life_a = 21`.

**Assertions** :
- `g_game_over == true`
- Message contient "PloufFamille VLog"
- Image : `FAMILLY_LIFE_TOO_HIGH`

---

### M-05 `mort_popularity_trop_basse`
**Deck** : 1 carte avec `popularity_a = -20`.

**Assertions** :
- `g_game_over == true`
- Message contient "grand silence"
- Image : `POPULARITY_TOO_LOW`

---

### M-06 `mort_popularity_trop_haute`
**Deck** : 1 carte avec `popularity_a = 21`.

**Assertions** :
- `g_game_over == true`
- Message contient "Influenceur"
- Image : `POPULARITY_TOO_HIGH`

---

### M-07 `mort_speed_trop_basse`
**Deck** : 1 carte avec `speed_a = -20`.

**Assertions** :
- `g_game_over == true`
- Message contient "fusionne avec sa chaise"
- Image : `SPEED_TOO_LOW`

---

### M-08 `mort_speed_trop_haute`
**Deck** : 1 carte avec `speed_a = 21`.

**Assertions** :
- `g_game_over == true`
- Message contient "Productivité terminale"
- Image : `SPEED_TOO_HIGH`

---

## Catégorie 3 — Victoire

### V-01 `victoire_complete`
**Objectif** : traverser les 10 phases sans mourir et atteindre l'écran de fin.

**Setup** :
- `DEBUG_SAVE_OVERRIDE = { "has_reached_phase_5": true }`
- `DEBUG_DISABLE_INTRO = true`
- Deck injecté : 1 carte neutre (tous impacts à 0, `impact_multiplier = 1`) par phase,
  pour les 10 phases (`CHOOSE_CHRONIQUE_GAME` → `STREAM_POST_CHRONIQUE`)

**Actions** : swiper choix A sur chaque carte (10 fois) + swiper les cartes de transition
de phase.

**Assertions** :
- `g_game_over == true` (le flag est mis à true aussi en fin de victoire)
- Message contient "Fin de la semaine de Monsieur Plouf"
- `current_phase_index == phases.size()`

---

## Catégorie 4 — Progression

### P-01 `phase_5_sauvegardee`
**Objectif** : vérifier que le flag `has_reached_phase_5` est bien écrit dans le save
quand le joueur finit la phase 5.

**Setup** :
- `DEBUG_SAVE_OVERRIDE = { "has_reached_phase_5": false }`
- `DEBUG_DISABLE_INTRO = true`
- Deck injecté : 1 carte neutre par phase pour les phases 0 à 5 inclus

**Actions** : swiper toutes les cartes jusqu'à la fin de la phase 5 (index 5).

**Assertions** :
- `save_data["has_reached_phase_5"] == true`
- Le fichier `user://save_data.json` contient `"has_reached_phase_5": true`

---

### P-02 `huge_impact_card`
**Objectif** : vérifier qu'une carte marquée `impact_multiplier = 10` applique bien
10× l'impact sur les stats.

**Setup** :
- `DEBUG_SAVE_OVERRIDE = { "has_reached_phase_5": true }`
- `DEBUG_DISABLE_INTRO = true`
- Deck injecté : 1 carte avec `creativity_a = 1`, `impact_multiplier = 10`
  (toutes autres stats à 0)

**Actions** : noter `stats["creativity"]` avant → swiper A → noter après.

**Assertions** :
- `stats["creativity"] == 20 + (1 * 10)` → soit `30`

---

## Catégorie 5 — Effets warning

### W-01 `warning_threshold_bas`
**Objectif** : vérifier que l'état warning est activé quand une stat passe sous 20%
(soit sous 8/40 = valeur 8).

**Setup** :
- `DEBUG_SAVE_OVERRIDE = { "has_reached_phase_5": true }`
- `DEBUG_DISABLE_INTRO = true`
- Stats initiales à 20. Deck : 1 carte avec `creativity_a = -13`
  (20 - 13 = 7, soit 17.5% < seuil 20%)

**Actions** : swiper A.

**Assertions** :
- `impact_is_activated_creativity == true`
- `stats["creativity"] == 7`

---

### W-02 `warning_threshold_haut`
**Objectif** : vérifier que l'état warning est activé quand une stat dépasse 80%
(soit au-dessus de 32/40).

**Setup** :
- Identique W-01, deck : 1 carte avec `creativity_a = 13`
  (20 + 13 = 33, soit 82.5% > seuil 80%)

**Actions** : swiper A.

**Assertions** :
- `impact_is_activated_creativity == true`
- `stats["creativity"] == 33`

---

## Résumé

| ID   | Nom                          | Catégorie   |
|------|------------------------------|-------------|
| T-01 | tuto_premier_lancement       | Tutoriel    |
| T-02 | tuto_joueur_experimente      | Tutoriel    |
| M-01 | mort_creativity_trop_basse   | Mort        |
| M-02 | mort_creativity_trop_haute   | Mort        |
| M-03 | mort_familly_life_trop_basse | Mort        |
| M-04 | mort_familly_life_trop_haute | Mort        |
| M-05 | mort_popularity_trop_basse   | Mort        |
| M-06 | mort_popularity_trop_haute   | Mort        |
| M-07 | mort_speed_trop_basse        | Mort        |
| M-08 | mort_speed_trop_haute        | Mort        |
| V-01 | victoire_complete            | Victoire    |
| P-01 | phase_5_sauvegardee          | Progression |
| P-02 | huge_impact_card             | Progression |
| W-01 | warning_threshold_bas        | Warning     |
| W-02 | warning_threshold_haut       | Warning     |

**Total : 15 scénarios**
