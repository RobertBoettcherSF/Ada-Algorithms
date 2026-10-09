pragma Ada_2022;
with Zobrist_Hashing;
with Own_Checks;
use Zobrist_Hashing;
procedure Tests is

   --  First-relative test helpers: copy S to storage starting at O, or to
   --  storage ending at Positive'Last.
   function At_Origin (S : Char_Array; O : Positive) return Char_Array is
      R : Char_Array (O .. O + (S'Length - 1));
   begin
      for K in 0 .. S'Length - 1 loop
         R (O + K) := S (S'First + K);
      end loop;
      return R;
   end At_Origin;
   function At_Top (S : Char_Array) return Char_Array is
     (At_Origin (S, Positive'Last - (S'Length - 1)));
begin
   pragma Assert (Hash ("abc") /= Hash ("acb"));
   pragma Assert (Hash ("") = 0);
   --  Same data at shifted origins (and ending at Positive'Last) = origin 1.
   pragma Assert (Hash (At_Origin ("abc", 5)) = Hash ("abc"));
   pragma Assert (Hash (At_Top ("abcdefghijklmnop")) = Hash ("abcdefghijklmnop"));
   pragma Assert (Hash (At_Origin ("abc", 5)) /= Hash (At_Origin ("acb", 5)));
   pragma Assert (Hash (At_Origin ("", 9)) = 0);
   Own_Checks;
end Tests;
