\startMPcode
input pomermaid ;
pm_begin(0, 10, 432, 3, 1, 3);
pm_colour(0, 0.9255, 0.9255, 1);
pm_colour(1, 0.5765, 0.4392, 0.8588);
pm_colour(2, 0.2, 0.2, 0.2);
pm_colour(3, 1, 1, 1);
pm_colour(4, 1, 0.6, 0.4);
pm_colour(5, 0.7333, 0.7333, 1);
pm_colour(6, 1, 0.4, 0.4);
pm_colour(7, 0.0039, 0.0078, 0.0118);
pm_colour(8, 1, 1, 0.2);
pm_node(0, 0, 0, 0, 12.625, 0, -1, "A");
pm_style(0, 4, 2, 2, 2.5, 0);
pm_node(1, 0, 2, 0, 12.625, 0, -1, "B");
pm_style(1, 5, 6, 7, 2.5, 3.125);
pm_node(2, 1, 1, 0, 12.625, 0, 0, "");
pm_edge(0, 0, 1, 0, -1, 1, 0, 1, 8, 2, 2.5, 0, "")(2);
pm_end;
\stopMPcode
