with House_Robber;
procedure Tests is
   A : constant House_Robber.Values := (2, 7, 9, 3, 1, 8);
   B : constant House_Robber.Values := (2, 1, 1, 2, 4, 9);
begin
   pragma Assert (House_Robber.Maximum (A) = 19);
   pragma Assert (House_Robber.Maximum (B) = 13);
end Tests;
