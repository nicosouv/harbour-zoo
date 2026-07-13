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
 "A blob grew up and set off to live its own life. Not because you failed it, because it was ready. The zoo remembers.",
 "Well kept",
 "%1 habit check-ins. The blobs are quietly proud, and a little competitive.",
 "Happy birthday",
 "The whole zoo made you something. It's a blob. It's always a blob.",
 "The zoo is closed for celebrations. The blobs are wearing tiny hats.",
 # The Keeper's Almanac (the narrative fil rouge)
 "The empty zoo",
 "It was empty when you found it, a few bare enclosures, the wind, and a ring of keys nobody had claimed. You picked them up. Nothing here is anything yet. That is the very best time to begin.",
 "The first light",
 "A handful of ordinary days, and already something stirs in the grass. You didn't build a creature; you kept a small promise, and the creature came to keep you company. Keep coming back. It watches the gate.",
 "Company",
 "There's a little crowd now, each one a day you chose yourself over the easier nothing. They don't know they're a calendar. They think they're a family. Let them.",
 "The seat, kept warm",
 "Seven days you turned up. A day will slip one day, it always does, and when it does, the gate stays open and your seat stays warm. This zoo counts arrivals, never absences. Coming back is the only rule there is.",
 "The first goodbye",
 "One of them shouldered a little bundle and walked out the gate for good. It didn't leave because you failed it. It left because it had finally grown enough to. That small ache? That is proof it mattered. The things we tend outgrow us. Let it be the happy ending it is.",
 "What the zoo was for",
 "You thought you were collecting creatures. Look again. Every enclosure is a Tuesday you didn't waste, a promise to yourself quietly kept. The zoo was never the point. It was only ever the proof.",
 "A zoo built from Tuesdays",
 "Here is the whole secret, now that you've earned it: none of this was ever about the blobs. It was about someone who kept showing up for themselves, one small day at a time, until the showing-up became who they are. That someone is you. The zoo only ever remembered it back to you.",
 "Not yet written",
 "The Almanac keeps this page blank, for now. Keep showing up.",
 # Readiness (emotional check-in) and gentle behaviour-science nudges
 "Rough one today. Then today we go tiny: one small thing, and that fully counts.",
 "Low tank. Pick the easiest habit and let that be plenty. Gentle is still forward.",
 "Steady. A fine day to keep the thread going, nothing heroic required.",
 "Good energy. This is a nice day to start something you've been circling.",
 "Flying. Ride it, start the thing, stack a habit. The blobs are excited.",
 "Yesterday slipped by. Today is the one that keeps the thread, one small thing does it.",
 "The gate's still open, no clock running. Pick it back up whenever you like.",
 "A new month, a clean page. A good moment to swap or renegotiate one habit.",
 "New week, fresh page. Want to renegotiate one habit while it's easy?",
]

# Flat translation dict: source -> [fr, de, it, es, fi]
T = json.load(open(os.path.join(SCRATCH, "translations.json"), encoding="utf-8"))

contexts = dict(qml)
# C++ tr() context is the metaobject className, which includes the namespace: zoo::ZooController.
contexts["zoo::ZooController"] = zc_src

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
