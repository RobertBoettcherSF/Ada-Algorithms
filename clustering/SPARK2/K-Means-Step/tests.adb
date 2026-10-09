pragma Ada_2022;
with Ada.Text_IO;
with K_Means_Step; use K_Means_Step;
with Own_Checks;
procedure Tests is
   C1 : Point := 0;
   C2 : Point := 100;
   N1 : Count := 0;
   N2 : Count := 0;
begin
   Step (2, C1, C2, N1, N2);
   pragma Assert (C1 = 2 and N1 = 1);
   Step (10, C1, C2, N1, N2);
   pragma Assert (C1 = 6 and N1 = 2);
   Step (98, C1, C2, N1, N2);
   pragma Assert (C2 = 98 and N2 = 1);

   --  Hand-worked (V&V sweep, agent A3).
   --  10 is 4 from 6 and 88 from 98: cluster 1, (6 * 2 + 10) / 3 = 7.
   Step (10, C1, C2, N1, N2);
   pragma Assert (C1 = 7 and N1 = 3 and C2 = 98 and N2 = 1);
   --  60 is 53 from 7 and 38 from 98: cluster 2, (98 + 60) / 2 = 79.
   Step (60, C1, C2, N1, N2);
   pragma Assert (C1 = 7 and N1 = 3 and C2 = 79 and N2 = 2);
   --  43 is 36 from both 7 and 79: a tie goes to cluster 1,
   --  (7 * 3 + 43) / 4 = 16.
   Step (43, C1, C2, N1, N2);
   pragma Assert (C1 = 16 and N1 = 4 and C2 = 79 and N2 = 2);
   pragma Assert (Nearest (50, 40, 60) = 1);
   pragma Assert (Nearest (51, 40, 60) = 2);
   pragma Assert (Nearest (30, 40, 20) = 1);
   pragma Assert (Nearest (31, 40, 20) = 1);
   pragma Assert (Nearest (29, 40, 20) = 2);

   Own_Checks;
   Ada.Text_IO.Put_Line ("k-means step: PASS");
end Tests;
