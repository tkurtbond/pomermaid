\startMPcode
input pomermaid ;
pm_begin(2, 10, 432, 3, 1, 3);
pm_colour(0, 0.9255, 0.9255, 1);
pm_colour(1, 0.5765, 0.4392, 0.8588);
pm_colour(2, 0.2, 0.2, 0.2);
pm_colour(3, 0.0392, 0.0784, 0.1176);
pm_node(0, 0, 0, 0, 15.375, 0, -1, "A");
pm_style(0, 0, 1, 2, 0.625, 0);
pm_node(1, 0, 2, 0, 15.375, 0, -1, "B");
pm_style(1, 0, 1, 2, 0.625, 0);
pm_node(2, 1, 1, 0, 15.375, 0, 0, "");
pm_edge(0, 0, 1, 0, -1, 1, 0, 1, 3, 2, 2, 0, "")(2);
pm_end;
\stopMPcode
