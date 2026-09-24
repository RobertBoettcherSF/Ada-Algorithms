with Ada.Assertions; use Ada.Assertions;
with Sort_Array_By_Parity; use Sort_Array_By_Parity;
procedure Tests is
   A : Int_Array := [others => 0];
   R : Int_Array;
begin
   A (1 .. 6) := [3, 1, 2, 4, 5, 6];
   R := By_Parity (A);
   declare
      Seen_Odd : Boolean := False;
   begin
      for I in Index loop
         if R (I) mod 2 /= 0 then
            Seen_Odd := True;
         else
            Assert (not Seen_Odd);
         end if;
      end loop;
   end;
end Tests;
