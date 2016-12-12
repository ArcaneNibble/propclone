# propclone - Parallax Propeller cog clone

This is a code dump of a clone of the Parallax Propeller cog that I wrote back
in high school (6+ years ago!). It is presented as-is with no cleanup
whatsoever. This was done solely from the public Propeller datasheet and
predates the current official Verilog code release.

If I remember correctly, most of the testing was done in simulation. The design
did not meet timing at 80 MHz on the board I was testing on (Digilent Spartan
3E Starter Kit).

There is no logic implemented for interfacing with the hub. Also, peripherals
such as the timer and video generator are not implemented.
