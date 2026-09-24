pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Merge_Two_Sorted_Lists; use Merge_Two_Sorted_Lists;

procedure Tests is
   A : List := Empty; B : List := Empty; R : List;
begin
   Append (A, 1); Append (A, 4); Append (A, 7); Append (B, 2); Append (B, 3); Append (B, 8);
   R := Merge (A, B);
   if Length (R) /= 6 or else Element (R, 1) /= 1 or else Element (R, 4) /= 4 or else Element (R, 6) /= 8 then raise Program_Error; end if;
   Put_Line ("Merge two sorted lists: PASS");
end Tests;
