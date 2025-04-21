import csv
import json
import random
import sys


# Load problems from CSV
def load_problems(filename):
    with open(filename, newline='', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile, delimiter=';')
        return list(reader)


def load_phases(filename):
    with open(filename, encoding='utf-8') as f:
        data = json.load(f)
        return data["phases"]


def rotate_list_randomly(lst):
    index = random.randint(0, len(lst) - 1)
    return lst[index:] + lst[:index]


class Phase:
    def __init__(self, phase_id):
        self._phase_id = phase_id
        self._problems = []
    
    
    def get_id(self):
        return self._phase_id
    
    
    def get_problems(self):
        return self._problems
    
    
    def add_problem(self, problem):
        self._problems.append(problem)


# Display a problem and get the player's choice
def play_game(phases):
    # type: (list[Phase]) -> None
    
    stats = {
        "Créativité":     20,
        "Santé mentale":  20,
        "Vie de famille": 20,
        "Temps de jeu":   20,
    }
    
    loop_nb = 1
    
    for phase in phases:
        print(f'\n\n\nPhase: {phase.get_id()}')
        problems = phase.get_problems()
        print(f'Phase has {len(problems)} problems')
        seen_ids = set()
        while len(seen_ids) < len(problems):
            # Pick a new problem not yet seen
            problem = random.choice([p for p in problems if p["problem_id"] not in seen_ids])
            seen_ids.add(problem["problem_id"])
            
            print("\n📌 Problème :", problem["problem_id"], problem["title"])
            print(problem["problem_description"])
            print("Choix A :", problem["choice_a"], "=> : Créativité {}, Santé mentale {}, Vie de famille {}, Temps de jeu {}".format(
                    problem["creativity_a"], problem["mental_health_a"], problem["family_life_a"], problem["game_time_a"]
            ))
            print("Choix B :", problem["choice_b"], "=> : Créativité {}, Santé mentale {}, Vie de famille {}, Temps de jeu {}".format(
                    problem["creativity_b"], problem["mental_health_b"], problem["family_life_b"], problem["game_time_b"]
            ))
            
            choice = input("\nQue choisis-tu ? (A/B) ").strip().upper()
            #choice = random.choice(["A", "B"])
            while choice not in ["A", "B"]:
                choice = input("Choix invalide. Tape A ou B : ").strip().upper()
            
            if choice == "A":
                print("🎬 A =>", problem["outcome_a"])
                stats["Créativité"] += int(problem["creativity_a"])
                stats["Santé mentale"] += int(problem["mental_health_a"])
                stats["Vie de famille"] += int(problem["family_life_a"])
                stats["Temps de jeu"] += int(problem["game_time_a"])
            else:
                print("🎬 B =>", problem["outcome_b"])
                stats["Créativité"] += int(problem["creativity_b"])
                stats["Santé mentale"] += int(problem["mental_health_b"])
                stats["Vie de famille"] += int(problem["family_life_b"])
                stats["Temps de jeu"] += int(problem["game_time_b"])
            
            print(f"📊 Statut actuel : Créativité={stats['Créativité']} Santé mentale={stats['Santé mentale']} Vie de famille={stats['Vie de famille']} Temps de jeu={stats['Temps de jeu']}")
            for key, value in stats.items():
                if value < 0 or value > 40:
                    print(f'\n\nFAIL  ==> {phase.get_id()} {loop_nb} : {key}: {value}')
                    sys.exit(1)
            
            loop_nb += 1
            # input("\nAppuie sur Entrée pour continuer...")
            
        print(f'Félicitation tu as fini {phase.get_id()}!')
    
    print("\n✅ Tous les problèmes ont été traités. Fin de la semaine de Monsieur Plouf !")


if __name__ == "__main__":
    problems = load_problems("plouf_game_50_original_cards.csv")
    phase_ids = load_phases('phases.json')
    
    phase_ids = rotate_list_randomly(phase_ids)
    
    phases = [Phase(phase_id) for phase_id in phase_ids]
    
    for problem in problems:
        pb_phase_id = problem["phase_id_dep"]
        if pb_phase_id and pb_phase_id not in phase_ids:
            print(f'ERROR: OUPS: no such phase_id {pb_phase_id}')
            sys.exit(2)
        
        found = False
        for phase in phases:
            if phase.get_id() == pb_phase_id:
                phase.add_problem(problem)
                found = True
                break
        # Take a random phase
        if not found:
            phase = random.choice(phases)
            phase.add_problem(problem)
    
    for phase in phases:
        print(f'Phase: {phase.get_id()} size= {len(phase.get_problems())}')
    
    play_game(phases)
