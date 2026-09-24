with Ada.Assertions; use Ada.Assertions;
with Replace_Elements_With_Greatest_On_Right; use Replace_Elements_With_Greatest_On_Right;
procedure Tests is
   A : Int_Array := [others => 0];
   R : Int_Array;
begin
   A (1 .. 5) := [17, 18, 5, 4, 6];
   R := Replace (A);
   Assert (R (1) = 18 and then R (2) = 6 and then R (5) = 0);
end Tests;
