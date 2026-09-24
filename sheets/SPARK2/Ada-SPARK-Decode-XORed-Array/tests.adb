pragma Ada_2022;
with Decode_XORed_Array;
procedure Tests is
   use Decode_XORed_Array;
   Result : constant Original_Array := Decode (5, [2, 7, 3]);
begin
   pragma Assert (Result = [5, 7, 0, 3]);
end Tests;
