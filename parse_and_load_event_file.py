import sys
import csv
import json
import os
import codecs


def parse_events(file_path):
    # Dictionnaire final qui contiendra les événements organisés par section
    events_by_phase = {}
    event_category = None
    
    # Let's parse it!
    with open(file_path, mode='r', encoding='utf-8') as file:
        # cannot use csv.reader as it auto skip # and we need it
        lines = file.readlines()
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
            row = line.split(';')
            # Ignorer les lignes vides ou les commentaires
            if len(row) == 0:
                continue
            # print(f'ROW {row}')
            if row[0].startswith("#"):
                if row[0].startswith("#=="):
                    # new section
                    event_category = row[0][3:].strip()  # Enlever #== et les espaces
                    print(f'New category: {event_category}')
                continue
            
            # print(f'NB ELEMENTS: {len(row)}')
            # Vérifier que chaque ligne contient le nombre correct de colonnes (8)
            if len(row) != 9:
                print(f"Erreur dans la ligne : {row} => trop d'éléments")
                sys.exit(2)
                continue
            
            # Parse des valeurs
            event_id = row[0]
            phase = row[1] if row[1] else ''
            problem = row[2]
            choice_a = row[3]
            choice_a_long = row[4]
            choice_b = row[5]
            choice_b_long = row[6]
            image_front = row[7]
            image_back = row[8]
            
            # Si une phase n'est pas définie, c'est une erreur, ou au moins un cas qu'on veut ignorer
            if not event_id or not problem or not choice_a or not choice_a_long or not choice_b or not choice_b_long or not image_front or not image_back:
                print(f"Erreur : l'événement {row} a des informations manquantes.")
                sys.exit(2)
                continue
            
            # Check images too
            if not os.path.exists('images/' + image_front + '.png') or not os.path.exists('images/' + image_back + '.png'):
                print(f'Error: image for {event_id} is missing')
                sys.exit(2)
            
            # Créer l'entrée de l'événement sous forme de dictionnaire
            event = {
                "id":            event_id,
                "phase":         phase,
                "problem":       problem,
                "choice_a":      choice_a,
                "choice_a_long": choice_a_long,
                "choice_b":      choice_b,
                "choice_b_long": choice_b_long,
                "image_front":   image_front,
                "image_back":    image_back,
                "category":      event_category
            }
            
            if phase not in events_by_phase:
                events_by_phase[phase] = []
            events_by_phase[phase].append(event)
    
    return events_by_phase


categories_data = json.load(open('categories.json'))
all_categories = [d['id'] for d in categories_data]


def _get_impact_from_entry(entry, choice):
    # example:'A': [{'impact_category': 'speed', 'impact_sign': '-'}, {'impact_category': 'popularity', 'impact_sign': '+'}],
    # order: popularity_a;creativity_a;familly_life_a;speed_a;
    a_popularity = '0'
    a_creativity = '0'
    a_familly_life = '0'
    a_speed = '0'
    for d in entry[choice]:
        which = d['impact_category']
        if which == 'popularity':
            a_popularity = d['impact_sign'] + '1'
        elif which == 'creativity':
            a_creativity = d['impact_sign'] + '1'
        elif which == 'familly_life':
            a_familly_life = d['impact_sign'] + '1'
        elif which == 'speed':
            a_speed = d['impact_sign'] + '1'
        else:
            print(f'Erreur : {which} is not a valid category')
            sys.exit(2)
    a_str = f'{a_popularity};{a_creativity};{a_familly_life};{a_speed}'
    return a_str


def get_impacts_from_category(category_name):
    entry = None
    for entry in categories_data:
        if entry['id'] == category_name:
            break
    #print(f'Category: {entry}')
    a_str = _get_impact_from_entry(entry, 'A')
    b_str = _get_impact_from_entry(entry, 'B')
    
    # print(f'A: {a_str}')
    # print(f'B: {b_str}')
    
    return a_str, b_str


file_path = "events.txt"
events = parse_events(file_path)

categories = set()
all_event_ids = set()

# Afficher les événements organisés par section
total = 0
for phase, events_list in events.items():
    print(f"\n\nPhase : {phase} => {len(events_list)}")
    for event in events_list:
        print(event)
        categories.add(event["category"])
        if event['id'] in all_event_ids:
            print(f'ERROR: event {event["id"]} is already existing!')
            sys.exit(2)
        all_event_ids.add(event['id'])
    total += len(events_list)

print(f'Total events: {total}')
categories = list(categories)
categories.sort()
cat_s = '\n'.join(categories)
print(f'Categories: {cat_s}')
if set(categories) != set(all_categories):
    print(f'Error: some categories are not valid {set(all_categories) - set(categories)}   {set(categories) - set(all_categories)}')
    sys.exit(2)

data = 'problem_id;phase_id_dep;title;problem_description;choice_a;outcome_a;popularity_a;creativity_a;familly_life_a;speed_a;choice_b;outcome_b;popularity_b;creativity_b;familly_life_b;speed_b;character_img_id;background_img_id\n'

new_lines = []
for phase, events_list in events.items():
    for event in events_list:
        category = event["category"]
        impact_a, impact_b = get_impacts_from_category(category)
        
        line = f'{event["id"]};{event["phase"]};;{event["problem"]};{event["choice_a"]};{event["choice_a_long"]};{impact_a};{event["choice_b"]};{event["choice_b_long"]};{impact_b};{event["image_front"]};{event["image_back"]}'
        print(f'{line}')
        new_lines.append(line)

with codecs.open('plouf_game_cards.csv', mode='w', encoding='utf8') as f:
    buf = data + '\n'.join(new_lines)
    f.write(buf)

print('\n\n ALL IS OK')
