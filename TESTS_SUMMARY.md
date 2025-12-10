# ✅ Tests Mis en Place pour le Projet Plouf



### Lancer uniquement les tests Python
```powershell
python tests\test_python_parser.py
```

2. **En ligne de commande :**
```powershell
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit

Sous windows pour Jean:
C:\Users\napar\Downloads\Godot_v4.5.1-windows-64-stable\Godot_v4.5.1-stable_win64.exe --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/ --verbose -gexit
```




## 📝 Prochaines Étapes Recommandées

### Tests prioritaires à ajouter
1. **Tests d'intégration**
   - Système de chargement des cartes CSV
   - Système de sauvegarde/chargement
   - Calcul des impacts sur les stats

2. **Tests de logique métier**
   - Conditions de game over (stat = 0 ou MAX_STAT)
   - Conditions de victoire (arriver à la fin)
   - Gestion des phases
   - Distribution des cartes

3. **Tests de régression**
   - Vérifier que les anciennes sauvegardes fonctionnent
   - Tester la compatibilité des fichiers JSON

### Amélirations futures
- [ ] Ajouter coverage reporting (pytest-cov)
- [ ] Créer des mocks pour les nodes UI
- [ ] Tests de performance
- [ ] Tests de l'UI (si possible avec GUT)

## 🛠️ Maintenance

### Ajouter un nouveau test GDScript
```gdscript
# Dans tests/test_game_helpers.gd
func test_ma_nouvelle_fonctionnalite():
    # IMPORTANT : Utiliser autofree() pour éviter les fuites mémoire
    var main = autofree(MainScript.new())
    var result = main.ma_fonction()
    assert_eq(result, valeur_attendue, "Message si échec")
```

### Ajouter un nouveau test Python
```python
# Dans tests/test_python_parser.py
def test_ma_nouvelle_fonctionnalite(self):
    result = ma_fonction()
    self.assertEqual(result, attendu)
```

## 📚 Documentation

- Guide complet : `tests/README_TESTS.md`
- Documentation GUT : https://github.com/bitwes/Gut/wiki
- Documentation Python unittest : https://docs.python.org/3/library/unittest.html

---

**Date de création** : 2025-01-10
**Tests créés par** : GitHub Copilot (sérieux, c'est relou à écrire les tests, 0 pitié pour lui filer le boulot)
**État** : ✅ Opérationnel

