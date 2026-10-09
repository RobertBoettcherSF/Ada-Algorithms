pragma Ada_2022;
with LZ77;
use LZ77;
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
   pragma Assert (Literal_Length ("abracadabra") = 11);
   pragma Assert (Literal_Length ("") = 0);
   --  Same data at shifted origins (and ending at Positive'Last) = origin 1.
   pragma Assert (Literal_Length (At_Origin ("abracadabra", 6)) = 11);
   pragma Assert (Literal_Length (At_Top ("abracadabra")) = 11);
   pragma Assert (Literal_Length (At_Origin ("", 30)) = 0);
end Tests;
