with Ada.Assertions; use Ada.Assertions;
with Contiguous_Array; use Contiguous_Array;

procedure Tests is
   A : Bits := [others => 0];
begin
   Assert (One_Count (A) = 0);
   A (4) := 1;
   A (17) := 1;
   Assert (One_Count (A) = 2);
end Tests;
