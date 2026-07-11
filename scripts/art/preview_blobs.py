# -*- coding: utf-8 -*-
# Render a contact sheet of candidate pixel-art blob STYLES (grayscale), each with seed variants.
import random, math
from PIL import Image, ImageDraw, ImageFont

def gray(v):
    v = max(0, min(255, int(v)))
    return (v, v, v, 255)
TRANS = (0, 0, 0, 0)
EYE = (238, 238, 238, 255)
PUP = (20, 20, 22, 255)

def ellipse_mask(N, rx, ry, cx=0.5, cy=0.5, bump=None, rnd=None):
    on = [[False]*N for _ in range(N)]
    for y in range(N):
        for x in range(N):
            nx = (x+0.5)/N - cx
            ny = (y+0.5)/N - cy
            r = (nx*nx)/(rx*rx) + (ny*ny)/(ry*ry)
            if bump:
                r += bump*math.sin((x*1.7)+(y*0.9)) * 0.03
            on[y][x] = r <= 1.0
    return on

def is_edge(on, x, y, N):
    for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
        nx,ny=x+dx,y+dy
        if nx<0 or ny<0 or nx>=N or ny>=N or not on[ny][nx]:
            return True
    return False

def eyes_2x2(grid, N, ex, ey, pupdx=0, pupdy=0, sep=None, white=EYE, pup=PUP):
    cols = [ex, N-2-ex] if sep is None else sep
    for c in cols:
        for a in range(2):
            for b in range(2):
                if 0<=ey+b<N and 0<=c+a<N: grid[ey+b][c+a]=white
        px,py=c+pupdx, ey+pupdy
        if pup is not None and 0<=py<N and 0<=px<N: grid[py][px]=pup

def render_grid(on, N, top=150, bot=90, outline=None, spots=0, rnd=None):
    grid=[[TRANS]*N for _ in range(N)]
    for y in range(N):
        for x in range(N):
            if not on[y][x]: continue
            if outline is not None and is_edge(on,x,y,N):
                grid[y][x]=gray(outline); continue
            t=y/(N-1)
            v=top+(bot-top)*t
            if spots and rnd and rnd.random()<spots: v-=25
            grid[y][x]=gray(v)
    return grid

# ---- styles: each returns (grid, N) ----
def st_ovoid(seed):
    r=random.Random(seed); N=12
    on=ellipse_mask(N, r.uniform(.34,.40), r.uniform(.40,.46))
    g=render_grid(on,N,top=r.uniform(145,165),bot=r.uniform(85,100),outline=25,spots=.06,rnd=r)
    eyes_2x2(g,N, r.randint(3,4), r.randint(4,5))
    return g,N

def st_chonk(seed):
    r=random.Random(seed); N=14
    on=ellipse_mask(N,.44,.44)
    g=render_grid(on,N,top=170,bot=120,outline=18)
    # big 3x3 eyes
    ey=r.randint(5,6)
    for c in (r.randint(3,4), N-4-r.randint(0,1)):
        for a in range(3):
            for b in range(3):
                if 0<=ey+b<N and 0<=c+a<N: g[ey+b][c+a]=EYE
        g[ey+1][c+1]=PUP
    return g,N

def st_slime(seed):
    r=random.Random(seed); N=13
    on=ellipse_mask(N, .40, .34, cy=.42)
    # flatten bottom
    for x in range(N):
        for y in range(int(N*0.82),N): on[y][x]=on[y][x] and True
    g=render_grid(on,N,top=175,bot=110,outline=None)
    # gloss highlight
    if on[3][4]: g[3][4]=gray(230)
    if on[3][5]: g[3][5]=gray(215)
    eyes_2x2(g,N,4,r.randint(5,6))
    return g,N

def st_ghost(seed):
    r=random.Random(seed); N=13
    on=ellipse_mask(N,.36,.46,cy=.40)
    # scalloped bottom
    for x in range(N):
        if x%3==0:
            for y in range(N-2,N): on[y][x]=False
    g=render_grid(on,N,top=140,bot=100,outline=20)
    eyes_2x2(g,N,4,r.randint(4,5),white=EYE)
    return g,N

def st_bean(seed):
    r=random.Random(seed); N=13
    on=ellipse_mask(N,.42,.30,cy=.5,bump=1.0,rnd=r)
    g=render_grid(on,N,top=150,bot=95,outline=22)
    # sleepy line eyes
    ey=r.randint(5,6)
    for c in (4,8):
        for a in range(2):
            if 0<=c+a<N: g[ey][c+a]=EYE
    return g,N

def st_mono(seed):
    r=random.Random(seed); N=12
    on=ellipse_mask(N, r.uniform(.34,.40), r.uniform(.40,.46))
    g=[[TRANS]*N for _ in range(N)]
    for y in range(N):
        for x in range(N):
            if on[y][x]: g[y][x]=gray(40)
    eyes_2x2(g,N,r.randint(3,4),r.randint(4,5),white=gray(235),pup=None)
    return g,N

def st_amoeba(seed):
    r=random.Random(seed); N=14
    on=ellipse_mask(N,.40,.42,bump=1.6,rnd=r)
    g=render_grid(on,N,top=150,bot=100,outline=24,spots=.08,rnd=r)
    # three eyes
    ey=r.randint(4,5)
    for c in (3,6,9):
        if 0<=c<N and 0<=ey<N:
            g[ey][c]=EYE
            if ey+1<N: g[ey+1][c]=PUP if r.random()>.3 else EYE
    return g,N

def st_smiley(seed):
    r=random.Random(seed); N=13
    on=ellipse_mask(N,.40,.42)
    g=render_grid(on,N,top=155,bot=100,outline=22)
    eyes_2x2(g,N,4,4)
    # little smile
    my=8
    for c in (5,6,7):
        if on[my][c]: g[my][c]=PUP
    return g,N

def st_hires(seed):
    r=random.Random(seed); N=16
    on=ellipse_mask(N, r.uniform(.36,.42), r.uniform(.42,.48))
    g=[[TRANS]*N for _ in range(N)]
    for y in range(N):
        for x in range(N):
            if not on[y][x]: continue
            if is_edge(on,x,y,N): g[y][x]=gray(30); continue
            t=y/(N-1); v=160+(-70)*t
            # soft dither highlight
            if x<N*.4 and y<N*.4 and (x+y)%2==0: v+=20
            g[y][x]=gray(v)
    # cute small eyes 2x2
    eyes_2x2(g,N,5,r.randint(6,7))
    return g,N

def st_cyclops(seed):
    r=random.Random(seed); N=12
    on=ellipse_mask(N,.36,.44)
    g=render_grid(on,N,top=150,bot=95,outline=22)
    # one big eye 4x4
    ex,ey=4,4
    for a in range(4):
        for b in range(3):
            if 0<=ey+b<N and 0<=ex+a<N: g[ey+b][ex+a]=EYE
    g[ey+1][ex+1+r.randint(0,1)]=PUP
    g[ey+1][ex+2]=PUP
    return g,N

STYLES=[("Ovoid (current)",st_ovoid),("Chonk",st_chonk),("Slime",st_slime),
        ("Ghost",st_ghost),("Bean",st_bean),("Mono 1-bit",st_mono),
        ("Amoeba",st_amoeba),("Smiley",st_smiley),("Hi-res 16",st_hires),
        ("Cyclops",st_cyclops)]

BOX=120; VARIANTS=4; PAD=16; LABELW=150
COLS=VARIANTS; ROWS=len(STYLES)
W=LABELW+COLS*(BOX+PAD)+PAD
H=PAD+ROWS*(BOX+PAD)
BG=(216,216,216,255)
sheet=Image.new("RGBA",(W,H),BG)
draw=ImageDraw.Draw(sheet)
try: font=ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf",20)
except: font=ImageFont.load_default()

def blit(grid,N,ox,oy):
    scale=BOX//N
    off=(BOX-scale*N)//2
    im=Image.new("RGBA",(N,N),TRANS)
    for y in range(N):
        for x in range(N):
            im.putpixel((x,y),grid[y][x])
    im=im.resize((scale*N,scale*N),Image.NEAREST)
    sheet.alpha_composite(im,(ox+off,oy+off))

for ri,(name,fn) in enumerate(STYLES):
    oy=PAD+ri*(BOX+PAD)
    draw.text((PAD,oy+BOX//2-10),name,fill=(30,30,30,255),font=font)
    for ci in range(VARIANTS):
        ox=LABELW+ci*(BOX+PAD)
        # swatch bg (subtle) to frame
        draw.rectangle([ox,oy,ox+BOX,oy+BOX],fill=(232,232,232,255))
        g,N=fn(seed=1000+ri*97+ci*13)
        blit(g,N,ox,oy)

out="/private/tmp/claude-501/-Users-nico-Documents-Dev-Personal-harbour-zoo/59fa26d1-a4d0-4c4f-96a1-d32f20da553f/scratchpad/blobs.png"
sheet.convert("RGB").save(out)
print("saved", out, sheet.size)

# ---- mixed zoo preview (weighted) on a dark enclosure background ----
MIX=[("mono",st_mono,3),("chonk",st_chonk,3),("ovoid",st_ovoid,2),("bean",st_bean,2),
     ("hires",st_hires,2),("slime",st_slime,1),("cyclops",st_cyclops,1),("smiley",st_smiley,1),("ghost",st_ghost,1)]
bag=[]
for name,fn,w in MIX: bag+=[(name,fn)]*w
def pick(rr): return bag[rr.randrange(len(bag))]

COLS2=6; ROWS2=5; CELL=110; GAP=6
W2=GAP+COLS2*(CELL+GAP); H2=GAP+ROWS2*(CELL+GAP)
mix=Image.new("RGBA",(W2,H2),(43,47,63,255))  # night-ish enclosure
for i in range(COLS2*ROWS2):
    rr=random.Random(7000+i*17)
    name,fn=pick(rr)
    g,N=fn(seed=rr.randint(1,10**9))
    ox=GAP+(i%COLS2)*(CELL+GAP); oy=GAP+(i//COLS2)*(CELL+GAP)
    scale=CELL//N; off=(CELL-scale*N)//2
    im=Image.new("RGBA",(N,N),TRANS)
    for y in range(N):
        for x in range(N):
            im.putpixel((x,y),g[y][x])
    im=im.resize((scale*N,scale*N),Image.NEAREST)
    mix.alpha_composite(im,(ox+off,oy+off))
out2="/private/tmp/claude-501/-Users-nico-Documents-Dev-Personal-harbour-zoo/59fa26d1-a4d0-4c4f-96a1-d32f20da553f/scratchpad/blobs_mix.png"
mix.convert("RGB").save(out2)
print("saved", out2, mix.size)
