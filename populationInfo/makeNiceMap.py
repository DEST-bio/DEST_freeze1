import sys
from collections import defaultdict as d
import random

dist=5
Ycol=["white","lightblue","black","brown","grey","cyan","red","green","magenta","yellow","darkgreen","orange","darkblue"]
Sp={"spring":0,"fall":0.6,"frost":-0.6,"NA":-1.2}
Nh=d(list)
Y=[]

for l in open(sys.argv[1],"r"):
    if l.startswith("latitude"):
        continue
    latitude,longitude,Season,Year=l.rstrip().split()
    if Year=="NA":
        Year=0
    Nh[latitude+"_"+longitude].append((int(Year),Season))
    Y.append(int(Year))

Yc=dict(zip(sorted(list(set(Y))),Ycol))

print "latitude\tlongitude\tYear\tSeason\tX\tY\tspacing_x\tspacing_y\tcolors"

for k,v in sorted(Nh.items()):
    Lat,Lon=map(float,k.split("_"))
    Years=list(set(zip(*v)[0]))
    Yh=dict(zip(sorted(Years),range(len(Years))))
    #print k,Yh,v
    if Lon<-40 and Lat > 20:
        amlat=24
        amlon=-100
    elif Lon>-40 and Lat > 20:
        amlat=42
        amlon=15
    elif Lat<20 and Lon<-20:
        amlat=15
        amlon=-65
    else:
        amlat=0
        amlon=0
    if float(Lat)<amlat:
        Latoff=-((amlat-float(Lat))**2)/20
    else:
        Latoff=((float(Lat)-amlat))**2/20
    if float(Lon)<amlon:
        Lonoff=-((amlon-float(Lon))**2)/30
    else:
        Lonoff=((float(Lon)-amlon)**2)/30
    for Year,Season in v:
        spacingX=Lonoff+(Yh[Year]*2)
        spacingY=Latoff+(Sp[Season]*3)
        print "\t".join(map(str,[Lat,Lon,Year,Season,Lonoff,Latoff,spacingX,spacingY,"black"]))
        #print "\t".join(map(str,[Lat,Lon,Year,Season,Lonoff,Latoff,spacingX,spacingY,Yc[Year]]))
