with Ada.Assertions; use Ada.Assertions; with Ada.Text_IO; use Ada.Text_IO;
with Top_K_Frequent_Stub; use Top_K_Frequent_Stub;
procedure Tests is A : constant Input_Array := [1, 1, 1, 2, 2, 3, 4, 4]; R : Result_Array; begin
   R := Top_K (A, 3); Assert (R (1) = 1); Assert (R (2) = 2); Assert (R (3) = 4); Put_Line ("PASS Top_K_Frequent_Stub");
end Tests;
