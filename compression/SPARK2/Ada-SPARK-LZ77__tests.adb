pragma Ada_2022;
with LZ77;
use LZ77;
procedure Tests is
begin
   pragma Assert (Literal_Length ("abracadabra") = 11);
   pragma Assert (Literal_Length ("") = 0);
end Tests;
