import csv
from io import StringIO

# Liste de 50 cartes avec titre, id, impacts sur critères et faits majeurs éventuels

cards = [
    # id, title, creativity, mental_health, family_life, game_time, notes/faits majeurs
    ("DREAMT_NEW_VIDEO_CONCEPT", "Tu rêves d’un concept de chronique révolutionnaire", 4, 1, 0, 0, ""),
    ("FAMILY_DRAWING_SESSION", "Session de dessin avec ta fille", 2, 2, 4, -1, ""),
    ("RECEIVE_KEY_FOR_OBSCURE_GAME", "Tu reçois une clé presse pour un jeu obscur", 2, 0, 0, 3, "choisir le prochain jeu à chroniquer"),
    ("FAILED_AUDIO_RECORDING", "Enregistrement raté, micro mal branché", -1, -3, 0, 0, ""),
    ("START_CHRONIQUE_SCRIPT", "Tu te lances dans l'écriture de la chronique", 1, -1, 0, 0, "Ecrire la chronique"),
    ("DRAW_TILL_3AM", "Tu dessines jusqu'à 3h du matin", 2, -3, -2, 0, "Dessiner la chronique"),
    ("SHORT_GAME_SESSION", "Tu joues vite fait entre deux tâches", 0, 1, 0, 2, "Jouer au jeu à chroniquer"),
    ("WATCH_YOUTUBE_INSTEAD", "Tu passes 1h à regarder des vidéos random", -1, 1, -1, -1, ""),
    ("TAKE_DAUGHTER_TO_PARK", "Tu vas au parc avec ta fille", 0, 2, 4, -2, ""),
    ("RECORD_VOICEOVER", "Tu enregistres la voix de la chronique", 1, -1, 0, 0, ""),
    ("PEUDOLESS_REVEALS_PODCAST_GAME", "Pseudoless t’annonce le jeu du podcast", 0, 0, 0, 1, "Pseudoless t'annonce le jeu du podcast"),
    ("START_PODCAST_SCRIPT", "Tu commences à écrire l’intro du podcast", 2, -1, 0, 0, "Ecrire le résumé du jeu du podcast"),
    ("STREAM_FOR_AN_HOUR", "Tu fais un stream d’une heure", 1, -2, -2, 2, "Streamer 1heure le soir de la chronique"),
    ("BUGGY_GAME_MOMENT", "Le jeu plante au moment critique", -1, -3, 0, -1, ""),
    ("BREAKFAST_WITH_FAMILY", "Petit dej tranquille avec ta famille", 0, 2, 3, 0, ""),
    ("WATCH_DAUGHTER_PLAY", "Tu regardes ta fille jouer à un jeu éducatif", 2, 1, 3, 0, ""),
    ("EDIT_PODCAST_VIDEO", "Tu montes la vidéo du podcast", 1, -2, 0, 0, "monter la vidéo du podcast"),
    ("RESPOND_YOUTUBE_COMMENTS", "Tu réponds aux commentaires YouTube", 1, -1, 0, 0, "Répondre aux commentaires de la vidéo"),
    ("UPLOAD_VIDEO_ON_TIME", "Tu uploades la vidéo à temps", 0, 2, 0, 0, "Uploader la vidéo"),
    ("LATE_NIGHT_EDITING", "Montage tardif jusqu'à pas d'heure", 0, -4, -3, 0, "monter la vidéo"),
    ("START_GAME_FOR_VIDEO", "Tu commences à jouer au jeu pour la chronique", 0, 0, -1, 3, "Jouer au jeu à chroniquer"),
    ("FIND_SPONSOR", "Tu décroches un sponsor pour la vidéo", 1, -1, 0, 0, "Trouver un sponsor pur la vidéo analyse"),
    ("WATCH_REVIEW_PODCAST_GAME", "Tu regardes des reviews pour le jeu du podcast", 1, 0, 0, 2, "Jouer au jeu du podcast"),
    ("BURNOUT_WARNING", "Tu sens venir le burn-out", -3, -5, -2, -1, ""),
    ("TAKE_AN_HOUR_OFF", "Tu t’accordes une heure off avec ta femme", 0, 3, 4, -2, ""),
    ("SKIP_FAMILY_DINNER", "Tu sautes le dîner familial pour travailler", 0, -1, -4, 0, ""),
    ("SLEEP_IN_MORNING", "Tu dors une heure de plus", 0, 2, 0, -1, ""),
    ("REWRITE_SCRIPT", "Tu réécris tout le script, pas content du premier", 2, -2, 0, 0, ""),
    ("DAUGHTER_ILL", "Ta fille est malade", 0, -3, -5, 0, ""),
    ("GET_SICK", "Tu chopes la crève", -2, -4, 0, -2, ""),
    ("WIN_GAME_PRIZE", "Tu gagnes un prix d’humour vidéoludique", 4, 3, 0, 0, ""),
    ("YOUTUBE_ALGO_HITS", "L’algorithme YouTube booste ta dernière vidéo", 1, 3, 0, 0, ""),
    ("YOUTUBE_ALGO_KILLS", "L’algo flingue ta dernière vidéo", -2, -3, 0, 0, ""),
    ("LOSE_SAVE_FILE", "Tu perds ta sauvegarde", -1, -2, 0, -3, ""),
    ("FAN_MAIL", "Tu reçois une lettre touchante d’un fan", 2, 3, 0, 0, ""),
    ("TECHNICAL_GLITCH", "Problème technique sur ton logiciel de montage", -1, -3, 0, 0, ""),
    ("MISSING_AUDIO_FILE", "Fichier audio manquant", -2, -2, 0, 0, ""),
    ("DISCOVER_GREAT_GAME", "Tu découvres un jeu incroyable", 3, 2, 0, 2, ""),
    ("DO_NOTHING_DAY", "Tu ne fais rien de la journée", 0, 1, 1, 0, ""),
    ("PSEUDOLESS_DELAY", "Pseudoless décale l’enregistrement", 0, -1, 0, 0, ""),
    ("MAKE_THUMBNAIL", "Tu fais la miniature de la vidéo", 1, -1, 0, 0, ""),
    ("WATCH_DOCUMENTARY", "Tu regardes un docu inspirant sur les jeux", 2, 2, 0, 0, ""),
    ("RECORD_PODCAST", "Enregistrement du podcast", 1, -2, 0, 0, ""),
    ("HOUSE_CHAOS", "Ta fille repeint les murs", 0, -1, -3, 0, ""),
    ("BREAK_COMPUTER", "Ton PC plante définitivement", -4, -5, -1, -3, ""),
    ("PLAY_PAST_FAVORITE", "Tu rejoues à un ancien jeu culte", 3, 2, 0, 1, ""),
    ("LATE_NIGHT_VANNE", "Une vanne géniale à 1h du mat", 4, -2, -1, 0, ""),
    ("DELETE_PROJECT_ACCIDENTALLY", "Tu supprimes ton projet de montage", -3, -5, 0, 0, "")
]

# Convert to CSV
output = StringIO()
writer = csv.writer(output)
writer.writerow(["id", "title", "creativity", "mental_health", "family_life", "game_time", "note"])

for card in cards:
    writer.writerow(card)

csv_data = output.getvalue()
output.close()
print(csv_data)
