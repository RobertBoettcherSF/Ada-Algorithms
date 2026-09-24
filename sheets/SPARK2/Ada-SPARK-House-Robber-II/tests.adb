with House_Robber_II;
procedure Tests is
   A : constant House_Robber_II.Values := (2, 7, 9, 3, 1, 8);
   B : constant House_Robber_II.Values := (2, 1, 1, 2, 4, 9);
begin
   pragma Assert (House_Robber_II.Maximum (A) = 18);
   pragma Assert (House_Robber_II.Maximum (B) = 12);
end Tests;
