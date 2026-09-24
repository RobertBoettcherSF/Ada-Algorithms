with K_Means_Step; use K_Means_Step;
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
end Tests;
