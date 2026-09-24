pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Maximum_Points_You_Can_Obtain_From_Cards; use Maximum_Points_You_Can_Obtain_From_Cards;
procedure Tests is
   A : constant Card_Array := (1, 2, 3, 4, 5, 6, 7, 8);
   B : constant Card_Array := (8, 7, 7, 8, 7, 7, 8, 7);
begin
   if Max_Points (A, 3) /= 21 then raise Program_Error; end if;
   if Max_Points (B, 4) /= 30 then raise Program_Error; end if;
   if Max_Points (A, 0) /= 0 then raise Program_Error; end if;
   Put_Line ("Maximum points from cards: PASS");
end Tests;
