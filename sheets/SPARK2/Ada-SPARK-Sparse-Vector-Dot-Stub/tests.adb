pragma SPARK_Mode (On);
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Sparse_Vector_Dot_Stub; use Sparse_Vector_Dot_Stub;

procedure Tests is
   A : constant Vector := (1, 0, -2, 3, 0, 0, 4, 0);
   B : constant Vector := (2, 9, 5, -1, 0, 0, 3, 7);
   Z : constant Vector := (others => 0);
begin
   Assert (Dot (A, B) = 1);
   Assert (Dot (A, Z) = 0);
   Assert (Dot (Z, B) = 0);
   Put_Line ("Sparse Vector Dot: PASS");
end Tests;
