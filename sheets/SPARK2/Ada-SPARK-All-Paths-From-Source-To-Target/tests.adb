pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with All_Paths_From_Source_To_Target; use All_Paths_From_Source_To_Target;
procedure Tests is
   G : Graph := (others => (others => False));
begin
   for N in Node range 1 .. Capacity - 1 loop
      G (N, N + 1) := True;
   end loop;
   Assert (Has_Path (G));
   G (1, 2) := False;
   Assert (not Has_Path (G));
end Tests;
