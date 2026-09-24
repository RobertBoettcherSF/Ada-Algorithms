pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Keys_And_Rooms; use Keys_And_Rooms;
procedure Tests is
   K : Key_Matrix := (others => (others => False));
begin
   for R in Room range 1 .. Capacity - 1 loop
      K (R, R + 1) := True;
   end loop;
   Assert (Can_Visit_All (K));
   K (1, 2) := False;
   Assert (not Can_Visit_All (K));
end Tests;
