# -*- coding: utf-8 -*-
import json, os, html
ROOT = "/Users/nico/Documents/Dev/Personal/harbour-zoo"
SCRATCH = os.path.dirname(__file__)
LANGS = ["fr", "de", "it", "es", "fi"]
qml = json.load(open(os.path.join(SCRATCH, "qml_strings.json"), encoding="utf-8"))

zc_src = [
 "Introduce yourself to a cloud. Keep it professional.",
 "Compliment an inanimate object out loud. Mean it.",
 "Photograph three triangular things. They know what they did.",
 "Name a pigeon. Do NOT tell it its name. It must never know.",
 "Walk somewhere you've never walked. Ten whole metres counts.",
 "Do your best impression of a door. Nobody's watching. Probably.",
 "Find a face in something that isn't a face. Say hi. Be normal about it.",
 "Hum a dramatic theme for a boring task. Commit like your life depends on it.",
 "Reorganise something by colour for absolutely no reason.",
 "Thank a tool that helped you today. Out loud. Yes, really.",
 "Invent a word for how you feel right now. Use it once, aggressively.",
 "Stand like a superhero for one full breath. Feel the power. Leave.",
 "A group of blobs is called a 'mild concern'.",
 "No blob has ever finished a to-do list. They find it aspirational.",
 "The average blob blinks four times before deciding you're fine.",
 "Every blob believes it is slightly larger than it actually is.",
 "Blobs hop to think. They think rarely.",
 "A blob's favourite colour is 'the grey one'.",
 "Statistically, you are someone's favourite. The blobs took a vote.",
 "Blobs do not dream. They simply buffer.",
 "It is considered rude to count a blob's pixels aloud.",
 "Blobs are 90% vibes and 10% structural concern.",
 "The oldest known blob is three weeks old and unbearably smug.",
 "Crumbs aren't currency anywhere reputable. Here, they're everything.",
 "Blobs experience Tuesdays more intensely than other creatures.",
 "The word 'blep' predates language. Probably.",
 "You've done precisely nothing today. Magnificent restraint.",
 "A blank slate. The blobs are pretending not to notice.",
 "Nothing yet. Bold. We admire the commitment to leisure.",
 "A start. The blobs are cautiously optimistic.",
 "Some progress. Steady on, hero.",
 "Not bad. The zoo noticed and will deny it later.",
 "Look at you. Insufferable, honestly.",
 "Fully productive. The blobs are a little intimidated.",
 "All done. Please leave some ambition for tomorrow.",
 "Volunteer", "Junior Keeper", "Keeper", "Head Keeper", "Curator", "Director", "Legendary Director",
 "A Suspicious Rock", "A Resilient Fern", "A Passive-Aggressive Sign", "A Moody Lamp",
 "A Modest Pond", "An Unnecessary Archway", "A Statue of Nobody", "A Single Sad Balloon",
 "An Off-Duty Gnome", "A Creaky Swing", "A Totem of Mild Power", "A Fountain, Allegedly",
 "Night (default)", "Meadow", "Desert", "Far West", "Neon City", "Quiet Snow", "Tokyo Street",
 "Hatchling", "Menagerie", "Consistent-ish", "Regular", "Creature of Habit", "Quest Cleared",
 "Interior Decorator", "Impossible Colour", "Small Hours", "Regular Attender", "Devotee",
 "Fortnight", "Full House", "Quest Master", "Landscaper", "Ritualist", "Focused", "Well-Tended",
 "Hatch your first blob.", "Five residents.", "A 3-day streak.", "A 7-day streak.",
 "Ten habit check-ins.", "Finish five quests.", "Own three objects.", "Hatch a mythic blob.",
 "A challenge before 5am.", "25 useful things done.", "100 useful things done.", "A 14-day streak.",
 "Ten residents.", "Finish ten quests.", "Own three biomes.", "Thirty habit check-ins.",
 "Five focus sessions.", "A 7-day streak with 20 habits. You are being looked after.",
 "Every creature here is a day you showed up.",
 "The zoo fills as you do the small things. Funny, that.",
 "A collection of ordinary days, quietly kept.",
 "Turns out this is what looking after yourself looks like.",
 "A whole zoo, built from Tuesdays. You did that. On purpose, even.",
 # Ceremonies
 "A fond farewell",
 "One of your blobs has set off for new adventures. It will be fine. Probably.",
 "Well kept",
 "%1 habit check-ins. The blobs are quietly proud, and a little competitive.",
 "Happy birthday",
 "The whole zoo made you something. It's a blob. It's always a blob.",
 "The zoo is closed for celebrations. The blobs are wearing tiny hats.",
]

# Flat translation dict: source -> [fr, de, it, es, fi]
T = json.load(open(os.path.join(SCRATCH, "translations.json"), encoding="utf-8"))

contexts = dict(qml)
contexts["ZooController"] = zc_src

def esc(s): return html.escape(s, quote=False)
missing = []
for li, lang in enumerate(LANGS):
    out = ['<?xml version="1.0" encoding="utf-8"?>', '<!DOCTYPE TS>', f'<TS version="2.1" language="{lang}">']
    for ctx, srcs in contexts.items():
        out.append(f'<context>\n    <name>{ctx}</name>')
        for src in srcs:
            tr = T.get(src)
            if tr is None:
                if src not in missing: missing.append(src)
                trans = src
            else:
                trans = tr[li]
            out.append(f'    <message>\n        <source>{esc(src)}</source>\n        <translation>{esc(trans)}</translation>\n    </message>')
        out.append('</context>')
    out.append('</TS>\n')
    open(os.path.join(ROOT, f"translations/harbour-zoo-{lang}.ts"), "w", encoding="utf-8").write("\n".join(out))

if missing:
    print("MISSING", len(missing))
    for m in missing: print("  |"+m)
else:
    print("OK, all translated.")
