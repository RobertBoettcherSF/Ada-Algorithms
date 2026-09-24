pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Find_The_Town_Judge; use Find_The_Town_Judge;
procedure Tests is
   T : Trust_Matrix := (others => (others => False));
begin
   for P in Person loop
      if P /= 3 then
         T (P, 3) := True;
      end if;
   end loop;
   Assert (Find_Judge (T) = 3);
   T (3, 1) := True;
   Assert (Find_Judge (T) = 0);
end Tests;
