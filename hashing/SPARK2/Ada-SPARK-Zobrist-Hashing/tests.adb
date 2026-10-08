pragma Ada_2022;
with Zobrist_Hashing;
with Own_Checks;
use Zobrist_Hashing;
procedure Tests is
begin
   pragma Assert (Hash ("abc") /= Hash ("acb"));
   pragma Assert (Hash ("") = 0);
   Own_Checks;
end Tests;
