pragma Ada_2022;
with Interfaces;
with Bitwise_Ors_Of_Subarrays_Lite;
procedure Tests is
   use type Interfaces.Unsigned_32;
begin
   pragma Assert (Bitwise_Ors_Of_Subarrays_Lite.Or_Of_Two (1, 2) = 3);
   pragma Assert (Bitwise_Ors_Of_Subarrays_Lite.Or_Of_Three (1, 2, 4) = 7);
end Tests;
