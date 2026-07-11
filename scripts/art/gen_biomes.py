# -*- coding: utf-8 -*-
# Generate detailed TOP-DOWN pixel-art biome backgrounds (no sky) for the zoo enclosure.
import random, math
from PIL import Image

LW, LH, SCALE = 128, 104, 3          # logical size, scaled up for chunky pixels
OUT = "/Users/nico/Documents/Dev/Personal/harbour-zoo/qml/images/biomes"
import os; os.makedirs(OUT, exist_ok=True)

def buf(w, h, c): return [[c for _ in range(w)] for _ in range(h)]
def put(b, x, y, c):
    if 0 <= x < LW and 0 <= y < LH: b[y][x] = c
def lerp(a, c, t): return tuple(int(a[i] + (c[i]-a[i])*t) for i in range(3))
def jitter(c, r, rnd):
    r = abs(r); d = rnd.randint(-r, r); return (max(0,min(255,c[0]+d)), max(0,min(255,c[1]+d)), max(0,min(255,c[2]+d)))

def base_noise(b, shades, rnd, band=None):
    for y in range(LH):
        for x in range(LW):
            c = rnd.choice(shades)
            if band: c = lerp(c, band, (y/LH))
            b[y][x] = jitter(c, 6, rnd)

def rect(b, x, y, w, h, c):
    for j in range(h):
        for i in range(w): put(b, x+i, y+j, c)

# ---- sprite stamps (logical pixels) ----
def s_flower(b, x, y, rnd):
    petal = rnd.choice([(240,240,245),(245,220,120),(235,150,190),(200,160,230)])
    ctr = (250,200,80)
    for dx,dy in [(0,-1),(0,1),(-1,0),(1,0)]: put(b,x+dx,y+dy,petal)
    put(b,x,y,ctr)
def s_tuft(b, x, y, rnd, col):
    for dx in (-1,0,1):
        put(b,x+dx,y,col); put(b,x+dx,y-1,jitter(col,-10,rnd))
    put(b,x,y-2,col)
def s_bush(b, x, y, rnd, col):
    for dx in range(-2,3):
        for dy in range(-1,2):
            if abs(dx)+abs(dy)<=2: put(b,x+dx,y+dy, jitter(col,8,rnd))
    put(b,x-1,y-1,lerp(col,(255,255,255),0.25))
def s_rock(b, x, y, rnd):
    g = rnd.randint(90,130); col=(g,g,g+5)
    for dx in range(-2,3):
        for dy in range(-1,2):
            if abs(dx)<=2-abs(dy): put(b,x+dx,y+dy, jitter(col,8,rnd))
    put(b,x-1,y-1,(g+35,g+35,g+40))
def s_cactus(b, x, y, rnd):
    col=(70,120,70)
    for dy in range(-2,3): put(b,x,y+dy,col)
    put(b,x-1,y,col); put(b,x+1,y-1,col); put(b,x-2,y,jitter(col,-8,rnd)); put(b,x+2,y-1,col)
    put(b,x,y-3,lerp(col,(255,255,255),0.2))
def s_pine(b, x, y, rnd):
    dark=(40,80,55); mid=(60,110,70)
    for r,cy in [(3,0),(2,-2),(1,-4)]:
        for dx in range(-r,r+1): put(b,x+dx,y+cy, jitter(mid,8,rnd))
    put(b,x,y+1,(90,70,50)); put(b,x,y,dark)
def s_petal(b, x, y, rnd):
    put(b,x,y, rnd.choice([(245,190,215),(240,170,205),(250,210,225)]))
def s_neon(b, x, y, rnd):
    col = rnd.choice([(70,240,255),(255,80,220),(255,220,80),(120,255,140)])
    rect(b,x,y,2,3,col)
    for dx in range(-1,3):
        for dy in range(-1,4):
            if (dx in (-1,2) or dy in (-1,3)) and 0<=x+dx<LW and 0<=y+dy<LH:
                b[y+dy][x+dx]=lerp(b[y+dy][x+dx], col, 0.35)
def s_lantern(b, x, y, rnd):
    col=(230,70,60)
    rect(b,x,y,2,2,col)
    for dx in range(-1,3):
        for dy in range(-1,3):
            if 0<=x+dx<LW and 0<=y+dy<LH: b[y+dy][x+dx]=lerp(b[y+dy][x+dx],col,0.3)
    put(b,x,y,(255,180,120))

def scatter(b, n, fn, rnd, m=6):
    for _ in range(n):
        fn(b, rnd.randint(m,LW-m), rnd.randint(m,LH-m), rnd)

# ---- biomes ----
def grass(b, rnd):
    base_noise(b, [(78,150,70),(88,160,78),(70,140,64),(96,170,86)], rnd)
    # dirt patch
    for _ in range(2):
        cx,cy=rnd.randint(20,LW-20),rnd.randint(20,LH-20)
        for dx in range(-8,9):
            for dy in range(-6,7):
                if dx*dx/64+dy*dy/36<=1 and rnd.random()<0.9: put(b,cx+dx,cy+dy, jitter((150,120,80),10,rnd))
    scatter(b, 60, lambda b,x,y,r: s_tuft(b,x,y,r,(60,120,55)), rnd)
    scatter(b, 26, s_flower, rnd)

def desert(b, rnd):
    base_noise(b, [(214,180,120),(224,190,132),(206,172,112)], rnd, band=(196,160,100))
    for _ in range(5):  # dune shading bands
        y=rnd.randint(6,LH-6)
        for x in range(LW):
            yy=y+int(3*math.sin(x*0.09))
            put(b,x,yy, jitter((190,155,96),6,rnd)); put(b,x,yy+1, jitter((232,198,140),6,rnd))
    scatter(b, 40, lambda b,x,y,r: put(b,x,y,jitter((150,110,70),8,r)), rnd)  # pebbles

def farwest(b, rnd):
    base_noise(b, [(170,130,86),(182,142,96),(158,120,78)], rnd)
    # boardwalk planks strip
    py=rnd.randint(LH//2-8,LH//2+8)
    for j in range(10):
        col=jitter((120,84,50),8,rnd)
        for x in range(LW): put(b,x,py+j,col)
        for x in range(0,LW,14): put(b,x,py+j,(70,48,30))

    scatter(b, 30, lambda b,x,y,r: put(b,x,y,jitter((140,100,60),8,r)), rnd)
def cyberpunk(b, rnd):
    base_noise(b, [(20,16,32),(26,18,40),(16,12,26)], rnd)
    for x in range(0,LW,10):  # neon grid
        for y in range(LH): b[y][x]=lerp(b[y][x],(60,220,255),0.35)
    for y in range(0,LH,10):
        for x in range(LW): b[y][x]=lerp(b[y][x],(255,60,210),0.30)
    scatter(b, 14, s_neon, rnd)
    for _ in range(5):  # puddles
        cx,cy=rnd.randint(10,LW-10),rnd.randint(10,LH-10)
        for dx in range(-5,6):
            for dy in range(-3,4):
                if dx*dx/25+dy*dy/9<=1: b[cy+dy][cx+dx]=lerp(b[cy+dy][cx+dx],(30,40,70),0.7)
        for dx in range(-4,5): put(b,cx+dx,cy,(90,255,230))
def snow(b, rnd):
    base_noise(b, [(232,238,248),(244,248,255),(224,232,246)], rnd)
    for _ in range(6):  # ice patches
        cx,cy=rnd.randint(10,LW-10),rnd.randint(10,LH-10)
        for dx in range(-6,7):
            for dy in range(-4,5):
                if dx*dx/36+dy*dy/16<=1: b[cy+dy][cx+dx]=lerp(b[cy+dy][cx+dx],(200,222,240),0.6)

    scatter(b, 30, lambda b,x,y,r: (put(b,x,y,(210,220,235)), put(b,x+1,y+1,(210,220,235))), rnd)  # prints
def night(b, rnd):
    base_noise(b, [(30,40,44),(26,34,40),(34,46,50)], rnd)

    for _ in range(30):  # fireflies
        x,y=rnd.randint(4,LW-4),rnd.randint(4,LH-4); c=(240,240,150)
        put(b,x,y,c)
        for dx,dy in [(1,0),(-1,0),(0,1),(0,-1)]: b[y+dy][x+dx]=lerp(b[y+dy][x+dx],c,0.4)
    scatter(b, 8, lambda b,x,y,r:(rect(b,x,y,2,1,(200,60,60)),put(b,x,y-1,(240,240,240))), rnd)  # mushrooms
def tokyo(b, rnd):
    base_noise(b, [(70,72,78),(78,80,86),(64,66,72)], rnd)  # asphalt
    # road markings (dashed center line)
    for y in range(0,LH,8): rect(b, LW//2, y, 2, 4, (230,210,90))
    # crosswalk stripes near top
    for i in range(6): rect(b, 10+i*16, 6, 10, 6, (235,235,240))
    # sidewalk tile strip on left
    for y in range(0,LH,6):
        for x in range(0,14,6): rect(b, x, y, 5, 5, (150,150,160))
    scatter(b, 6, s_neon, rnd, m=8)

    scatter(b, 40, s_petal, rnd)  # sakura
    # manhole
    cx,cy=rnd.randint(30,LW-20),rnd.randint(LH//2,LH-14)
    for dx in range(-5,6):
        for dy in range(-5,6):
            if dx*dx+dy*dy<=25: b[cy+dy][cx+dx]=jitter((50,52,58),6,rnd)

BIOMES = {"grass":grass,"desert":desert,"farwest":farwest,"cyberpunk":cyberpunk,
          "snow":snow,"night":night,"tokyo":tokyo}

sheet = Image.new("RGB",(LW*SCALE*2+30, LH*SCALE*4+50),(30,30,34))
from PIL import ImageDraw, ImageFont
draw=ImageDraw.Draw(sheet)
try: font=ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf",18)
except: font=ImageFont.load_default()
order=["grass","desert","farwest","cyberpunk","snow","night","tokyo"]
for k,name in enumerate(order):
    rnd=random.Random(hash(name)&0xffff)
    b=buf(LW,LH,(0,0,0)); BIOMES[name](b,rnd)
    img=Image.new("RGB",(LW,LH))
    for y in range(LH):
        for x in range(LW): img.putpixel((x,y), b[y][x])
    img.save(f"{OUT}/{name}.png")
    big=img.resize((LW*SCALE,LH*SCALE),Image.NEAREST)
    col=k%2; row=k//2
    ox=10+col*(LW*SCALE+10); oy=10+row*(LH*SCALE+10)
    sheet.paste(big,(ox,oy)); draw.text((ox+6,oy+6),name,fill=(255,255,255),font=font)
prev="/private/tmp/claude-501/-Users-nico-Documents-Dev-Personal-harbour-zoo/59fa26d1-a4d0-4c4f-96a1-d32f20da553f/scratchpad/biomes_preview.png"
sheet.save(prev)
print("wrote 7 biome PNGs to", OUT, "and preview", prev)
