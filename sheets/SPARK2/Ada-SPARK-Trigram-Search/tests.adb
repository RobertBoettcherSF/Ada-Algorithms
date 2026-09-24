pragma Ada_2022;
with Trigram_Search;
use Trigram_Search;
procedure Tests is
begin
   pragma Assert (Contains ("abracadabra", 'r', 'a', 'c'));
   pragma Assert (not Contains ("abracadabra", 'x', 'y', 'z'));
   pragma Assert (not Contains ("ab", 'a', 'b', 'c'));
end Tests;
