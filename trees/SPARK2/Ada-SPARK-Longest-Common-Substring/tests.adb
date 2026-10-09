pragma Ada_2022;
with Longest_Common_Substring;
with Own_Checks;
use Longest_Common_Substring;
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
   A : constant Char_Array := "abca";
   B : constant Char_Array := "bc";
begin
   pragma Assert (Length (A, B) = 2);
   pragma Assert (Length ("ab", "xy") = 0);
   --  Same data at shifted origins (and ending at Positive'Last) = origin 1.
   pragma Assert (Length (At_Origin (A, 3), At_Origin (B, 50)) = 2);
   pragma Assert (Length (At_Top (A), B) = 2);
   pragma Assert (Length (A, At_Top (B)) = 2);
   pragma Assert (Length (At_Origin ("ab", 9), At_Origin ("xy", 2)) = 0);
   Own_Checks;
end Tests;
