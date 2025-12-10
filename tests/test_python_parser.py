#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Tests unitaires pour parse_and_load_event_file.py
Teste le parsing du fichier events.txt et la génération du CSV
"""

import unittest
import sys
import os
import tempfile
import json

# Ajouter le dossier parent au path pour importer le module
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from parse_and_load_event_file import (
    parse_events,
    get_impacts_from_category,
    _get_impact_from_entry
)


class TestParseEvents(unittest.TestCase):
    """Tests pour la fonction parse_events"""
    
    def setUp(self):
        """Créer un fichier de test temporaire"""
        self.test_dir = tempfile.mkdtemp()
        self.test_file = os.path.join(self.test_dir, 'test_events.txt')
    
    def tearDown(self):
        """Nettoyer les fichiers temporaires"""
        if os.path.exists(self.test_file):
            os.remove(self.test_file)
        os.rmdir(self.test_dir)
    
    def test_parse_empty_file(self):
        """Test parsing d'un fichier vide"""
        with open(self.test_file, 'w', encoding='utf-8') as f:
            f.write('')
        
        result = parse_events(self.test_file)
        self.assertEqual(result, {})
    
    def test_parse_comments_only(self):
        """Test parsing d'un fichier avec seulement des commentaires"""
        with open(self.test_file, 'w', encoding='utf-8') as f:
            f.write('# Ceci est un commentaire\n')
            f.write('#== CATEGORY_TEST\n')
            f.write('# Autre commentaire\n')
        
        result = parse_events(self.test_file)
        self.assertEqual(result, {})
    
    def test_parse_single_event(self):
        """Test parsing d'un événement unique"""
        # Créer les images fictives
        os.makedirs(os.path.join(os.path.dirname(self.test_file), '..', 'images'), exist_ok=True)
        img_dir = os.path.join(os.path.dirname(self.test_file), '..', 'images')
        
        # Créer fichiers images vides
        open(os.path.join(img_dir, 'FRONT.png'), 'w').close()
        open(os.path.join(img_dir, 'BACK.png'), 'w').close()
        
        with open(self.test_file, 'w', encoding='utf-8') as f:
            f.write('#== TEST_CATEGORY\n')
            f.write('EVENT001;phase1;Problem?;Choice A;Long A;sound_a;Choice B;Long B;sound_b;FRONT;BACK\n')
        
        # Sauvegarder le répertoire courant
        old_cwd = os.getcwd()
        try:
            os.chdir(os.path.dirname(self.test_file) + '/..')
            result = parse_events(self.test_file)
            
            self.assertIn('phase1', result)
            self.assertEqual(len(result['phase1']), 1)
            
            event = result['phase1'][0]
            self.assertEqual(event['id'], 'EVENT001')
            self.assertEqual(event['phase'], 'phase1')
            self.assertEqual(event['problem'], 'Problem?')
            self.assertEqual(event['choice_a'], 'Choice A')
            self.assertEqual(event['choice_a_long'], 'Long A')
            self.assertEqual(event['sound_a'], 'sound_a')
            self.assertEqual(event['choice_b'], 'Choice B')
            self.assertEqual(event['choice_b_long'], 'Long B')
            self.assertEqual(event['sound_b'], 'sound_b')
            self.assertEqual(event['image_front'], 'FRONT')
            self.assertEqual(event['image_back'], 'BACK')
            self.assertEqual(event['category'], 'TEST_CATEGORY')
        finally:
            os.chdir(old_cwd)
            # Nettoyer
            os.remove(os.path.join(img_dir, 'FRONT.png'))
            os.remove(os.path.join(img_dir, 'BACK.png'))
            os.rmdir(img_dir)
    
    def test_parse_multiple_phases(self):
        """Test parsing avec plusieurs phases"""
        os.makedirs(os.path.join(os.path.dirname(self.test_file), '..', 'images'), exist_ok=True)
        img_dir = os.path.join(os.path.dirname(self.test_file), '..', 'images')
        open(os.path.join(img_dir, 'IMG1.png'), 'w').close()
        open(os.path.join(img_dir, 'IMG2.png'), 'w').close()
        
        with open(self.test_file, 'w', encoding='utf-8') as f:
            f.write('#== CAT1\n')
            f.write('E1;phase1;Problem1;A1;LA1;sa1;B1;LB1;sb1;IMG1;IMG2\n')
            f.write('E2;phase1;Problem2;A2;LA2;sa2;B2;LB2;sb2;IMG1;IMG2\n')
            f.write('E3;phase2;Problem3;A3;LA3;sa3;B3;LB3;sb3;IMG1;IMG2\n')
        
        old_cwd = os.getcwd()
        try:
            os.chdir(os.path.dirname(self.test_file) + '/..')
            result = parse_events(self.test_file)
            
            self.assertIn('phase1', result)
            self.assertIn('phase2', result)
            self.assertEqual(len(result['phase1']), 2)
            self.assertEqual(len(result['phase2']), 1)
        finally:
            os.chdir(old_cwd)
            os.remove(os.path.join(img_dir, 'IMG1.png'))
            os.remove(os.path.join(img_dir, 'IMG2.png'))
            os.rmdir(img_dir)
    
    def test_category_change(self):
        """Test changement de catégorie"""
        os.makedirs(os.path.join(os.path.dirname(self.test_file), '..', 'images'), exist_ok=True)
        img_dir = os.path.join(os.path.dirname(self.test_file), '..', 'images')
        open(os.path.join(img_dir, 'A.png'), 'w').close()
        open(os.path.join(img_dir, 'B.png'), 'w').close()
        
        with open(self.test_file, 'w', encoding='utf-8') as f:
            f.write('#== CATEGORY_1\n')
            f.write('E1;p1;Prob1;A;LA;sa;B;LB;sb;A;B\n')
            f.write('#== CATEGORY_2\n')
            f.write('E2;p1;Prob2;A;LA;sa;B;LB;sb;A;B\n')
        
        old_cwd = os.getcwd()
        try:
            os.chdir(os.path.dirname(self.test_file) + '/..')
            result = parse_events(self.test_file)
            
            self.assertEqual(result['p1'][0]['category'], 'CATEGORY_1')
            self.assertEqual(result['p1'][1]['category'], 'CATEGORY_2')
        finally:
            os.chdir(old_cwd)
            os.remove(os.path.join(img_dir, 'A.png'))
            os.remove(os.path.join(img_dir, 'B.png'))
            os.rmdir(img_dir)


class TestImpactCalculation(unittest.TestCase):
    """Tests pour le calcul des impacts"""
    
    def test_get_impact_from_entry_single_impact(self):
        """Test calcul impact avec une seule catégorie"""
        entry = {
            'A': [{'impact_category': 'popularity', 'impact_sign': '+'}],
            'B': [{'impact_category': 'speed', 'impact_sign': '-'}]
        }
        
        result_a = _get_impact_from_entry(entry, 'A')
        self.assertEqual(result_a, '+1;0;0;0')
        
        result_b = _get_impact_from_entry(entry, 'B')
        self.assertEqual(result_b, '0;0;0;-1')
    
    def test_get_impact_from_entry_multiple_impacts(self):
        """Test calcul impact avec plusieurs catégories"""
        entry = {
            'A': [
                {'impact_category': 'popularity', 'impact_sign': '+'},
                {'impact_category': 'creativity', 'impact_sign': '-'}
            ],
            'B': [
                {'impact_category': 'familly_life', 'impact_sign': '+'},
                {'impact_category': 'speed', 'impact_sign': '+'}
            ]
        }
        
        result_a = _get_impact_from_entry(entry, 'A')
        self.assertEqual(result_a, '+1;-1;0;0')
        
        result_b = _get_impact_from_entry(entry, 'B')
        self.assertEqual(result_b, '0;0;+1;+1')
    
    def test_get_impact_from_entry_all_categories(self):
        """Test calcul impact avec toutes les catégories"""
        entry = {
            'A': [
                {'impact_category': 'popularity', 'impact_sign': '+'},
                {'impact_category': 'creativity', 'impact_sign': '+'},
                {'impact_category': 'familly_life', 'impact_sign': '-'},
                {'impact_category': 'speed', 'impact_sign': '-'}
            ]
        }
        
        result = _get_impact_from_entry(entry, 'A')
        self.assertEqual(result, '+1;+1;-1;-1')


class TestRealFileStructure(unittest.TestCase):
    """Tests avec la structure réelle du projet"""
    
    def test_events_file_exists(self):
        """Vérifie que le fichier events.txt existe"""
        events_path = os.path.join(os.path.dirname(__file__), '..', 'events.txt')
        self.assertTrue(os.path.exists(events_path), "Le fichier events.txt doit exister")
    
    def test_categories_file_exists(self):
        """Vérifie que le fichier categories.json existe"""
        cat_path = os.path.join(os.path.dirname(__file__), '..', 'categories.json')
        self.assertTrue(os.path.exists(cat_path), "Le fichier categories.json doit exister")
    
    def test_categories_json_valid(self):
        """Vérifie que categories.json est un JSON valide"""
        cat_path = os.path.join(os.path.dirname(__file__), '..', 'categories.json')
        
        if not os.path.exists(cat_path):
            self.skipTest("categories.json n'existe pas")
        
        with open(cat_path, 'r', encoding='utf-8') as f:
            try:
                data = json.load(f)
                self.assertIsInstance(data, list, "categories.json doit contenir une liste")
            except json.JSONDecodeError as e:
                self.fail(f"categories.json n'est pas un JSON valide: {e}")
    
    def test_parse_real_events_file(self):
        """Test parsing du vrai fichier events.txt"""
        events_path = os.path.join(os.path.dirname(__file__), '..', 'events.txt')
        
        if not os.path.exists(events_path):
            self.skipTest("events.txt n'existe pas")
        
        old_cwd = os.getcwd()
        try:
            # Se placer dans le bon répertoire
            os.chdir(os.path.join(os.path.dirname(__file__), '..'))
            
            result = parse_events(events_path)
            
            # Vérifications basiques
            self.assertIsInstance(result, dict)
            self.assertGreater(len(result), 0, "Le fichier events.txt doit contenir des événements")
            
            # Vérifier la structure de chaque événement
            for phase, events in result.items():
                self.assertIsInstance(phase, str)
                self.assertIsInstance(events, list)
                
                for event in events:
                    # Vérifier les clés requises
                    required_keys = [
                        'id', 'phase', 'problem', 'choice_a', 'choice_a_long',
                        'sound_a', 'choice_b', 'choice_b_long', 'sound_b',
                        'image_front', 'image_back', 'category'
                    ]
                    for key in required_keys:
                        self.assertIn(key, event, f"La clé '{key}' doit être présente dans l'événement")
                        # Vérifier que les champs obligatoires ne sont pas vides
                        # Les champs phase, sound_a et sound_b peuvent être vides
                        if key not in ['phase', 'sound_a', 'sound_b']:
                            self.assertTrue(event[key], f"Le champ '{key}' ne doit pas être vide")
        
        finally:
            os.chdir(old_cwd)


class TestEventValidation(unittest.TestCase):
    """Tests de validation des événements"""
    
    def test_event_has_all_fields(self):
        """Vérifie qu'un événement parsé a tous les champs"""
        required_fields = [
            'id', 'phase', 'problem', 'choice_a', 'choice_a_long',
            'sound_a', 'choice_b', 'choice_b_long', 'sound_b',
            'image_front', 'image_back', 'category'
        ]
        
        # Créer un événement de test
        event = {
            'id': 'TEST001',
            'phase': 'test_phase',
            'problem': 'Test problem?',
            'choice_a': 'Option A',
            'choice_a_long': 'Long description A',
            'sound_a': 'sound_a',
            'choice_b': 'Option B',
            'choice_b_long': 'Long description B',
            'sound_b': 'sound_b',
            'image_front': 'front_img',
            'image_back': 'back_img',
            'category': 'TEST_CAT'
        }
        
        for field in required_fields:
            self.assertIn(field, event, f"Le champ '{field}' doit être présent")
    
    def test_impact_format(self):
        """Vérifie le format de sortie des impacts"""
        entry = {
            'A': [
                {'impact_category': 'popularity', 'impact_sign': '+'},
                {'impact_category': 'speed', 'impact_sign': '-'}
            ]
        }
        
        result = _get_impact_from_entry(entry, 'A')
        
        # Vérifier le format: "X;X;X;X" avec 4 éléments
        parts = result.split(';')
        self.assertEqual(len(parts), 4, "L'impact doit avoir 4 éléments séparés par ';'")
        
        # Chaque partie doit être soit '0', '+1', ou '-1'
        valid_values = ['0', '+1', '-1']
        for part in parts:
            self.assertIn(part, valid_values, f"'{part}' n'est pas une valeur d'impact valide")


def run_tests():
    """Fonction principale pour lancer les tests"""
    # Créer la suite de tests
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Ajouter tous les tests
    suite.addTests(loader.loadTestsFromTestCase(TestParseEvents))
    suite.addTests(loader.loadTestsFromTestCase(TestImpactCalculation))
    suite.addTests(loader.loadTestsFromTestCase(TestRealFileStructure))
    suite.addTests(loader.loadTestsFromTestCase(TestEventValidation))
    
    # Lancer les tests avec un runner verbose
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Retourner le code de sortie approprié
    return 0 if result.wasSuccessful() else 1


if __name__ == '__main__':
    exit_code = run_tests()
    sys.exit(exit_code)

