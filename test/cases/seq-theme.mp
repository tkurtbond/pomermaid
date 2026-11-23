\startMPcode
input pomermaid-seq ;
pms_begin(432, 2, 2, 0, 1);
pms_colour(0, 1, 0, 0);
pms_colour(1, 0.5765, 0.4392, 0.8588);
pms_colour(2, 0, 0, 0);
pms_colour(3, 0.2, 0.2, 0.2);
pms_colour(4, 0, 1, 0);
pms_colour(5, 0.6667, 0.6667, 0.2);
pms_colour(6, 0.9569, 0.9569, 0.9569);
pms_colour(7, 0.4, 0.4, 0.4);
pms_colour(8, 1, 1, 1);
pms_colour(9, 0.502, 0.502, 0.502);
pms_theme(0, 1, 2, 1, 3, 3, 0, 1, 2, 2, 4, 5, 2, 6, 7, 3, 8, 3, 9);
pms_actor(0, 0, -1, -1, -1, "A");
pms_actor(1, 0, -1, -1, -1, "B");
pms_msg(0, 0, 1, 0, 1, 0, 0, 0, 0, "", "hi");
pms_note(1, 0, 1, 2, "n");
pms_end;
\stopMPcode
