pragma Ada_2022;
with FNV_Hash;
use FNV_Hash;
procedure Tests is
   H1 : constant Hash_Value := Hash ("hello");
   H2 : constant Hash_Value := Hash ("world");
   Hello5 : constant Char_Array (5 .. 9) := ['h', 'e', 'l', 'l', 'o'];
   Hello_Top : constant Char_Array (Positive'Last - 4 .. Positive'Last) :=
     ['h', 'e', 'l', 'l', 'o'];
   Empty_At_9 : constant Char_Array (9 .. 8) := [others => ' '];
begin
   pragma Assert (H1 /= H2);
   pragma Assert (Hash ("") = 2_166_136_261);
   --  First-relative: the same characters at any origin give the same value
   --  (origins 1, 5, 200 and storage ending at Positive'Last).
   pragma Assert (Hash (Hello5) = H1);
   pragma Assert (Hash (Hello_Top) = H1);
   pragma Assert (Hash (Empty_At_9) = 2_166_136_261);
end Tests;
