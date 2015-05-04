print "********************************************";
print "*                                          *";
print "*             TOSSIM Script                *";
print "*                                          *";
print "********************************************";

N_MOTES = 10
DBG_CHANNELS = "default timer radio_send radio_receive"
TOPO_FILE = "linkgain.out"
NOISE_FILE = "meyer-heavy.txt"

import sys;
import time;

from TOSSIM import *;
from tinyos.tossim.TossimApp import *;
from random import *;

t = Tossim([]);
r = t.radio();

t.randomSeed(1);


print "Initializing mac....";
mac = t.mac();
print "Initializing radio channels....";
radio=t.radio();
print "    using topology file:",TOPO_FILE;
print "    using noise file:",NOISE_FILE;
print "Initializing simulator....";
t.init();


simulation_outfile = "simulation.txt";
print "Saving sensors simulation output to:", simulation_outfile;
out = open(simulation_outfile, "w");

#out = sys.stdout;

#Add debug channel
for channel in DBG_CHANNELS.split():
    print "Activate debug message on channel ", channel
    t.addChannel(channel, out)

#add gain links
f = open(TOPO_FILE, "r")
lines = f.readlines()

for line in lines:
    s = line.split()
    if (len(s) > 0):
        if s[0] == "gain":
            r.add(int(s[1]), int(s[2]), float(s[3]))
        elif s[0] == "noise":
            r.setNoise(int(s[1]), float(s[2]), float(s[3]))


#add noise trace
print "Reading noise model data file:", NOISE_FILE;
print "Loading:",
noise = open(NOISE_FILE, "r")
lines = noise.readlines()
for line in lines:
    str = line.strip()
    if (str != ""):
        val = int(float(str))
        for i in range(0, N_MOTES):
            t.getNode(i).addNoiseTraceReading(val)
print "Done!";



for i in range (0, N_MOTES):
    time=i * t.ticksPerSecond()
    m=t.getNode(i)
    m.bootAtTime(time)
    print "Booting ", i, " at ~ ", time/t.ticksPerSecond(), "sec"



for i in range(0, N_MOTES):
    print ">>>Creating noise model for node:",i;
    t.getNode(i).createNoiseModel()

print "Start simulation with TOSSIM! \n\n\n";

for i in range(0,100000):
	t.runNextEvent()
	
print "\n\n\nSimulation finished!";

