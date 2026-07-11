# -*- coding: utf-8 -*-
# Extract qsTr() source strings per QML file (context = file base name). Also lists which sources
# are missing from translations.json so they can be filled. Run from repo root.
import re, os, glob, json

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
HERE = os.path.dirname(__file__)

def literals(argblob):
    return "".join(re.findall(r'"((?:[^"\\]|\\.)*)"', argblob))

def extract_qml(path):
    s = open(path, encoding="utf-8").read()
    out = []
    for m in re.finditer(r'qsTr\(\s*((?:"(?:[^"\\]|\\.)*"\s*\+?\s*)+)', s):
        out.append(literals(m.group(1)))
    seen = set(); res = []
    for x in out:
        if x not in seen: seen.add(x); res.append(x)
    return res

ctx = {}
for f in sorted(glob.glob(os.path.join(ROOT, "qml", "**", "*.qml"), recursive=True)):
    base = os.path.splitext(os.path.basename(f))[0]
    strs = extract_qml(f)
    if strs: ctx.setdefault(base, [])
    for s in strs:
        if s not in ctx[base]: ctx[base].append(s)
json.dump(ctx, open(os.path.join(HERE, "qml_strings.json"), "w"), ensure_ascii=False, indent=1)

# All sources = qml + the C++ ZooController list defined in gen_ts.py
import importlib.util
spec = importlib.util.spec_from_file_location("gts", os.path.join(HERE, "gen_ts.py"))
# gen_ts imports translations.json at import; guard by only reading its zc_src via regex instead.
zc = []
gts = open(os.path.join(HERE, "gen_ts.py"), encoding="utf-8").read()
mm = re.search(r'zc_src\s*=\s*\[(.*?)\n\]', gts, re.S)
if mm:
    zc = re.findall(r'"((?:[^"\\]|\\.)*)"', mm.group(1))

allsrc = []
for k, v in ctx.items(): allsrc += v
allsrc += zc
allsrc = list(dict.fromkeys(allsrc))

T = json.load(open(os.path.join(HERE, "translations.json"), encoding="utf-8"))
missing = [s for s in allsrc if s not in T]
print("QML contexts:", len(ctx), "| total unique sources:", len(allsrc), "| already translated:", len(T))
print("MISSING", len(missing))
for s in missing:
    print("  |" + s)
