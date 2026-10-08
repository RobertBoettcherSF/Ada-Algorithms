pragma Ada_2022;
with House_Robber_II;
with Own_Checks;
procedure Tests is
   A : constant House_Robber_II.Values := [2, 7, 9, 3, 1, 8];
   B : constant House_Robber_II.Values := [2, 1, 1, 2, 4, 9];
begin
   pragma Assert (House_Robber_II.Maximum (A) = 18);
   pragma Assert (House_Robber_II.Maximum (B) = 12);
   Own_Checks;
end Tests;
