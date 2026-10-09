pragma Ada_2022;
with Trigram_Search;
use Trigram_Search;
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
   pragma Assert (Contains ("abracadabra", 'r', 'a', 'c'));
   pragma Assert (not Contains ("abracadabra", 'x', 'y', 'z'));
   pragma Assert (not Contains ("ab", 'a', 'b', 'c'));
   --  Same data at shifted origins (and ending at Positive'Last) = origin 1.
   pragma Assert (Contains (At_Origin ("abracadabra", 5), 'r', 'a', 'c'));
   pragma Assert (not Contains (At_Origin ("abracadabra", 5), 'x', 'y', 'z'));
   pragma Assert (Contains (At_Origin ("abcxx", 9), 'a', 'b', 'c'));  --  match at A'First
   pragma Assert (Contains (At_Top ("xxabc"), 'a', 'b', 'c'));  --  match ending at Positive'Last
   pragma Assert (not Contains (At_Origin ("ab", 14), 'a', 'b', 'c'));
end Tests;
