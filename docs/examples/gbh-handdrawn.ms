.\" -*- coding: utf-8 -*-
.\" The two mermaid diagrams of galactic_bounty_hunters_one_shot.md,
.\" drawn by hand in pic.  groff -k -ms -p -Tpdf diagrams.ms > diagrams.pdf
.\" Colours: mermaid's default theme, and the classDefs of diagram 2.
.defcolor nodefill  rgb #ececff
.defcolor nodeline  rgb #9370db
.defcolor sgfill    rgb #ffffde
.defcolor sgline    rgb #aaaa33
.defcolor upper     rgb #ff99ff
.defcolor main      rgb #bbbbff
.defcolor ground    rgb #ffbbff
.defcolor dark      rgb #333333
.TL
Museum of the Void: the diagrams in pic
.SH 1
Scenario Overview
.LP
.ps 8
.vs 10
.PS
boxwid = 1.95; boxht = 0.42; linethick = 1
define node { box shaded "nodefill" outlined "nodeline" $1 }
A:  node("\m[dark]Act I: The Drop & The Lockdown\m[]") wid 2.3 at (0, 0)
B:  node("\m[dark]Act II: Explore & Rescue\m[]") wid 2.3 at (0, -0.8)
B1: node("\m[dark]Upper Level: Hall of Gems -\m[]" "\m[dark]Find Banishment Key\m[]") at (-2.1, -1.75)
B2: node("\m[dark]Main Level: Stanley Field Hall -\m[]" "\m[dark]Protect Survivors\m[]") at (0, -1.75)
B3: node("\m[dark]Ground Level: Simpson Theatre -\m[]" "\m[dark]Rescue Kids\m[]") at (2.1, -1.75)
C:  node("\m[dark]Act III: Confrontation & Banishment\m[]") wid 2.3 at (0, -2.7)
D:  node("\m[dark]Mastaba Tomb of Unis-Ankh:\m[]" "\m[dark]Seal Void Sovereign & Arrest Drake\m[]") wid 2.5 at (0, -3.5)
arrow from A.s to B.n
arrow from B.s to B1.n
arrow from B.s to B2.n
arrow from B.s to B3.n
arrow from B1.s to C.n
arrow from B2.s to C.n
arrow from B3.s to C.n
arrow from C.s to D.n
.PE
.bp
.SH 1
Moving Through the Museum
.LP
.ps 8
.vs 10
.PS
boxwid = 1.9; boxht = 0.5
define sub { box shaded "sgfill" outlined "sgline" dashed 0.05 \
  wid $2 ht 0.95 with .nw at (-1.1, $1 + 0.55); \
  $3 at last box.n - (0, 0.12) }
define room { box shaded $2 outlined "dark" thickness 1.5 $1 }
sub(0, 6.6, "\fBUPPER LEVEL\fP")
sub(-1.4, 6.6, "\fBMAIN LEVEL\fP")
sub(-2.8, 4.4, "\fBGROUND LEVEL\fP")
Gems:   room("Gems" "(Room 10 - Banishment Key)", "upper") at (0, 0)
Sue:    room("SUE the T. rex" "(Room 3 - Hazard)", "upper") at (2.2, 0)
Plants: room("Plants of the World" "(Room 7 - Labyrinth Shortcut)", "upper") at (4.4, 0)
SFH:    room("Stanley Field Hall" "(Máximo / Survivors)", "main") at (0, -1.4)
Egypt:  room("Egypt" "(Room 8 - The Rift)", "main") at (2.2, -1.4)
Amer:   room("Ancient Americas" "(Room 2 - Totem Traps)", "main") at (4.4, -1.4)
Th:     room("Simpson Theatre" "(Room I - Trapped Kids)", "ground") at (0, -2.8)
Und:    room("Underground" "(Room 2 - Kaiju Bugs)", "ground") at (2.2, -2.8)
arrow <-> from Gems.e to Sue.w
arrow <-> from SFH.e to Egypt.w
arrow <-> from Th.e to Und.w
arrow <-> from Gems.s to SFH.n
arrow <-> from SFH.s to Th.n
arrow <-> from Plants.s to Amer.n
.PE
