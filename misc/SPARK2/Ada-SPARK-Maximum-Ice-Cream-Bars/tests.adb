with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Maximum_Ice_Cream_Bars; use Maximum_Ice_Cream_Bars;
procedure Tests is
   Checked : Natural := 0;
begin
   Assert (Bars_Bought (3, 10) = 3);
   Assert (Bars_Bought (6, 10) = 1);
   Assert (Bars_Bought (1, 32_000) = 32);   --  only 32 bars in stock
   Assert (Bars_Bought (10, 0) = 0);
   --  own property: buy bars one at a time while one is left and the money suffices
   for P in Price loop
      for B in 0 .. 3_200 loop
         declare
            Left : Natural := B;
            Count : Natural := 0;
         begin
            while Count < 32 and then Left >= P loop
               Left := Left - P; Count := Count + 1;
            end loop;
            Assert (Bars_Bought (P, B) = Count);
            Checked := Checked + 1;
         end;
      end loop;
   end loop;
   Put_Line ("PASS Maximum_Ice_Cream_Bars (" & Natural'Image (Checked) & " cases)");
end Tests;
