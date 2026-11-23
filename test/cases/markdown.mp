\startMPcode
input pomermaid ;
pm_colour(0, 0.9255, 0.9255, 1);
pm_colour(1, 0.5765, 0.4392, 0.8588);
pm_colour(2, 0.2, 0.2, 0.2);
pm_begin(2, 10, 432, 9, 4, 9, 0);
pm_node(0, 0, 0, 0, 21.375, 0, -1, "{\bf Bold} and {\it italic} and {\bi both}");
pm_style(0, 0, 1, 2, 0.625, 0);
pm_node(1, 0, 2, 0, 21.375, 0, -1, "snake{\char95}case{\char95}name and {\it em} *not*");
pm_style(1, 0, 1, 2, 0.625, 0);
pm_node(2, 0, 4, 0, 21.375, 0, -1, "a {\bf long bold phrase} that\\wraps over lines");
pm_style(2, 0, 1, 2, 0.625, 0);
pm_node(3, 0, 6, 0, 21.375, 0, -1, "{\bf strong} {\it em} **unclosed {\it mixed}\\end");
pm_style(3, 0, 1, 2, 0.625, 0);
pm_node(4, 0, 8, 0, 21.375, 0, -1, "{\it a }{\bi b}{\it  c} and {\bi x}{\it  y}");
pm_style(4, 0, 1, 2, 0.625, 0);
pm_node(5, 1, 1, 0, 21.375, 0, 0, "");
pm_node(6, 2, 3, 0, 21.375, 0, 1, "");
pm_node(7, 1, 5, 0, 21.375, 0, 2, "");
pm_node(8, 1, 7, 0, 21.375, 0, 3, "");
pm_edge(0, 0, 1, -1, -1, 0, -1, 1, 0, 1, 2, 2, 1.25, 0, "")(5);
pm_edge(1, 1, 2, -1, -1, 0, 6, 1, 0, 1, 2, 2, 1.25, 0, "edge {\bf label}")(6);
pm_edge(2, 2, 3, -1, -1, 0, -1, 1, 0, 1, 2, 2, 1.25, 0, "")(7);
pm_edge(3, 3, 4, -1, -1, 0, -1, 1, 0, 1, 2, 2, 1.25, 0, "")(8);
pm_end;
\stopMPcode
