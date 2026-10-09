pragma Ada_2022;
with Damerau_Levenshtein_Distance;
use Damerau_Levenshtein_Distance;
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
   A : constant Char_Array := "CA";
   B : constant Char_Array := "AC";
   C : constant Char_Array := "book";
   D : constant Char_Array := "back";
begin
   pragma Assert (Distance (A, B) = 1);
   pragma Assert (Distance (C, D) = 2);
   --  Same data at shifted origins (and ending at Positive'Last) = origin 1.
   pragma Assert (Distance (At_Origin (A, 5), At_Origin (B, 9)) = 1);
   pragma Assert (Distance (At_Origin (C, 100), D) = 2);
   pragma Assert (Distance (C, At_Top (D)) = 2);
   pragma Assert (Distance (At_Top ("abcd"), At_Origin ("bacd", 3)) = 1);
   pragma Assert (Distance (At_Origin ("", 9), At_Origin ("ab", 7)) = 2);
end Tests;
