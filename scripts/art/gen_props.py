# -*- coding: utf-8 -*-
# Top-down pixel-art PROP + DECORATION sprites (transparent, outlined) for the zoo.
import os
from PIL import Image
OUT = "/Users/nico/Documents/Dev/Personal/harbour-zoo/qml/images/props"
os.makedirs(OUT, exist_ok=True)
SCALE = 4
T = (0,0,0,0); OL = (32,28,36,255)

def cv(w,h): return [[T for _ in range(w)] for _ in range(h)]
def px(g,x,y,c):
    if 0<=y<len(g) and 0<=x<len(g[0]): g[y][x]=c
def rect(g,x,y,w,h,c):
    for j in range(h):
        for i in range(w): px(g,x+i,y+j,c)
def disc(g,cx,cy,r,c):
    for y in range(len(g)):
        for x in range(len(g[0])):
            if (x-cx)**2+(y-cy)**2<=r*r: g[y][x]=c
def outline(g):
    h=len(g); w=len(g[0]); add=[]
    for y in range(h):
        for x in range(w):
            if g[y][x][3]==0:
                for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                    nx,ny=x+dx,y+dy
                    if 0<=nx<w and 0<=ny<h and g[ny][nx][3]!=0: add.append((x,y)); break
    for x,y in add: g[y][x]=OL
def save(name,g):
    outline(g)
    h=len(g); w=len(g[0]); im=Image.new("RGBA",(w,h))
    for y in range(h):
        for x in range(w): im.putpixel((x,y),g[y][x])
    im.resize((w*SCALE,h*SCALE),Image.NEAREST).save(f"{OUT}/{name}.png")

def shade(g,cx,cy,r,base,hi):  # simple round shading
    disc(g,cx,cy,r,base)
    disc(g,cx-r//3,cy-r//3,max(1,r//2),hi)
    for y in range(len(g)):
        for x in range(len(g[0])):
            if g[y][x]==base and (x-cx)**2+(y-cy)**2>(r-1)**2:
                g[y][x]=tuple(max(0,v-24) for v in base[:3])+(255,)

# ---- nature props ----
def tree():
    g=cv(24,26); rect(g,11,19,2,5,(96,66,42,255)); rect(g,11,19,1,5,(120,84,52,255))
    shade(g,12,11,9,(58,126,64,255),(96,176,102,255))
    for (x,y) in [(15,9),(9,13),(16,13),(8,9),(13,15)]: px(g,x,y,(46,104,54,255))
    return g
def pine():
    g=cv(22,24); rect(g,10,18,2,5,(96,66,42,255))
    for r,cy,c in [(9,11,(46,100,66,255)),(7,8,(58,120,76,255)),(5,5,(72,144,90,255)),(3,2,(94,168,110,255))]:
        disc(g,11,cy,r,c)
    return g
def rock():
    g=cv(20,15); shade(g,10,8,7,(126,126,134,255),(164,164,172,255)); return g
def bush():
    g=cv(20,15); disc(g,7,9,4,(58,120,66,255)); disc(g,12,8,5,(68,134,76,255)); disc(g,10,10,4,(52,112,60,255)); disc(g,10,7,2,(100,176,108,255)); return g
def cactus():
    g=cv(18,22); body=(70,132,76,255)
    rect(g,8,4,3,16,body)                 # trunk
    rect(g,4,10,3,2,body); rect(g,4,6,2,5,body)   # left arm
    rect(g,11,8,3,2,body); rect(g,12,4,2,5,body)  # right arm
    for y in range(4,20,3): px(g,9,y,(50,108,58,255))
    px(g,9,4,(110,180,116,255))
    return g

# ---- buildings ----
def house():   # far-west wooden cabin, top-down-ish
    g=cv(26,24)
    rect(g,2,6,22,16,(150,104,60,255))            # roof planks
    for x in range(2,24,3): rect(g,x,6,1,16,(112,76,42,255))
    rect(g,2,6,22,2,(176,128,78,255))             # ridge highlight
    rect(g,9,2,8,5,(120,80,46,255)); rect(g,11,3,4,3,(60,44,30,255))  # chimney/sign
    rect(g,10,13,6,4,(200,180,120,255)); rect(g,11,14,1,2,(70,50,34,255))  # a little sign board
    return g
def building():  # tokyo modern rooftop
    g=cv(26,26); rect(g,2,2,22,22,(104,110,128,255))
    rect(g,2,2,22,2,(140,146,164,255)); rect(g,2,22,22,2,(74,80,96,255))
    for rx,ry in [(5,5),(15,5),(5,15),(15,15)]:
        rect(g,rx,ry,6,5,(150,156,170,255)); px(g,rx,ry,(190,196,210,255))
    rect(g,4,12,18,1,(80,86,102,255))
    return g
def lantern():
    g=cv(12,15); rect(g,3,3,6,9,(214,72,64,255)); rect(g,3,3,1,9,(150,44,44,255)); rect(g,8,3,1,9,(150,44,44,255))
    rect(g,3,6,6,2,(245,210,130,255)); rect(g,4,0,4,2,(60,50,50,255)); return g

# ---- decorations (match shop ids) ----
def d_rock(): return rock()
def d_fern():
    g=cv(20,20)
    for ang,ln in [(-4,9),(-2,11),(0,12),(2,11),(4,9)]:
        for t in range(ln):
            x=10+int(ang*t/ln*1.4); y=18-t
            px(g,x,y,(58,126,66,255));
            if t%2==0: px(g,x-1,y,(46,104,54,255)); px(g,x+1,y,(72,146,80,255))
    rect(g,9,17,2,2,(96,66,42,255)); return g
def d_sign():
    g=cv(18,20); rect(g,8,8,2,11,(120,82,48,255))            # post
    rect(g,3,3,12,7,(200,178,120,255)); rect(g,3,3,12,1,(224,204,150,255))  # board
    rect(g,5,5,8,1,(90,64,40,255)); rect(g,5,7,6,1,(90,64,40,255)); return g
def d_lamp():
    g=cv(16,20); rect(g,7,6,2,12,(70,72,80,255))             # pole
    disc(g,8,5,4,(255,224,130,255)); disc(g,8,5,2,(255,246,200,255))  # glow bulb
    rect(g,5,18,6,2,(60,62,70,255)); return g
def d_pond():
    g=cv(22,16); shade(g,11,8,9,(70,120,190,255),(120,170,230,255))
    disc(g,11,8,9,None) if False else None
    for y in range(len(g)):
        for x in range(len(g[0])):
            if g[y][x][:3]==(46,96,166): pass
    rect(g,6,6,3,1,(150,200,240,255)); rect(g,13,10,3,1,(150,200,240,255)); return g
def d_arch():
    g=cv(24,22); c=(160,158,166,255); d=(120,118,128,255)
    rect(g,3,8,4,13,c); rect(g,17,8,4,13,c)                  # pillars
    rect(g,3,3,18,6,c); rect(g,3,3,18,2,(190,188,196,255))   # top
    rect(g,7,9,10,2,d); return g
def d_statue():
    g=cv(18,22); rect(g,4,17,10,4,(150,148,156,255))          # pedestal
    disc(g,9,8,4,(180,178,186,255)); rect(g,7,11,4,6,(170,168,176,255))  # figure
    px(g,8,7,(120,118,128,255)); return g
def d_balloon():
    g=cv(16,22); disc(g,8,7,6,(220,70,70,255)); disc(g,6,5,2,(255,150,150,255))
    for y in range(13,21): px(g,8,y,(120,120,130,255))
    px(g,8,13,(200,60,60,255)); return g
def d_gnome():
    g=cv(16,20);
    for i in range(6): rect(g,8-i,3+i,2*i+1 if False else (2*i+1),1,(210,66,60,255))  # hat
    rect(g,5,3,6,1,(210,66,60,255)); rect(g,4,4,8,2,(210,66,60,255)); rect(g,6,2,4,1,(230,90,84,255))
    rect(g,5,7,6,3,(240,214,180,255))                         # face
    rect(g,4,10,8,7,(70,110,180,255)); rect(g,6,12,4,4,(240,240,240,255))  # beard/body
    return g
def d_swing():
    g=cv(22,22); rect(g,3,4,2,16,(120,82,48,255)); rect(g,17,4,2,16,(120,82,48,255)); rect(g,3,4,16,2,(140,96,56,255))
    for y in range(6,14): px(g,7,y,(90,90,98,255)); px(g,15,y,(90,90,98,255))
    rect(g,6,14,10,2,(160,110,64,255)); return g
def d_totem():
    g=cv(16,24)
    for k,c in enumerate([(210,80,70,255),(70,170,160,255),(240,200,90,255)]):
        rect(g,3,3+k*7,10,6,c); rect(g,5,5+k*7,2,2,(30,30,34,255)); rect(g,9,5+k*7,2,2,(30,30,34,255))
    return g
def d_fountain():
    g=cv(24,20); shade(g,12,11,10,(150,150,158,255),(184,184,192,255))  # basin
    disc(g,12,11,7,(80,140,200,255)); disc(g,12,11,3,(140,190,235,255)) # water
    rect(g,11,3,2,7,(180,180,188,255)); px(g,11,3,(150,200,240,255)); return g

sprites = {
 "tree":tree,"pine":pine,"rock":rock,"bush":bush,"cactus":cactus,"house":house,
 "building":building,"lantern":lantern,
 "deco_rock":d_rock,"deco_fern":d_fern,"deco_sign":d_sign,"deco_lamp":d_lamp,"deco_pond":d_pond,
 "deco_arch":d_arch,"deco_statue":d_statue,"deco_balloon":d_balloon,"deco_gnome":d_gnome,
 "deco_swing":d_swing,"deco_totem":d_totem,"deco_fountain":d_fountain,
}
for n,fn in sprites.items(): save(n, fn())
print("wrote", len(sprites), "sprites")

# preview
names=list(sprites.keys())
imgs=[Image.open(f"{OUT}/{n}.png") for n in names]
cols=6; cw=max(i.width for i in imgs)+16; ch=max(i.height for i in imgs)+30
rows=(len(imgs)+cols-1)//cols
from PIL import ImageDraw, ImageFont
sheet=Image.new("RGBA",(cols*cw, rows*ch),(110,150,110,255)); d=ImageDraw.Draw(sheet)
try: font=ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf",13)
except: font=ImageFont.load_default()
for k,(n,im) in enumerate(zip(names,imgs)):
    ox=(k%cols)*cw+8; oy=(k//cols)*ch+8
    sheet.alpha_composite(im,(ox,oy)); d.text((ox,oy+ch-22),n,fill=(20,20,20,255),font=font)
sheet.convert("RGB").save("/private/tmp/claude-501/-Users-nico-Documents-Dev-Personal-harbour-zoo/59fa26d1-a4d0-4c4f-96a1-d32f20da553f/scratchpad/props_preview.png")
print("preview written")
