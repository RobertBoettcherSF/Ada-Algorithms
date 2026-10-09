pragma Ada_2022;
with Run_Length_Encoding;
with Own_Checks;
procedure Tests is

   --  First-relative test helpers: copy S to storage starting at O, or to
   --  storage ending at Positive'Last.
   function At_Origin (S : Run_Length_Encoding.Char_Array; O : Positive) return Run_Length_Encoding.Char_Array is
      R : Run_Length_Encoding.Char_Array (O .. O + (S'Length - 1));
   begin
      for K in 0 .. S'Length - 1 loop
         R (O + K) := S (S'First + K);
      end loop;
      return R;
   end At_Origin;
   function At_Top (S : Run_Length_Encoding.Char_Array) return Run_Length_Encoding.Char_Array is
     (At_Origin (S, Positive'Last - (S'Length - 1)));
   use Run_Length_Encoding;
   A : constant Char_Array := "aaabbc";
   B : constant Char_Array := "zzzz";
   C : constant Char_Array := "abcd";
   E : constant Char_Array (1 .. 0) := [others => 'x'];
   M : constant Char_Array (1 .. Max_Length) :=
     [for I in 1 .. Max_Length => (if I mod 2 = 0 then 'a' else 'b')];
begin
   pragma Assert (Number_Of_Runs (A) = 3);
   pragma Assert (Number_Of_Runs (B) = 1);
   pragma Assert (Number_Of_Runs (C) = 4);
   pragma Assert (Number_Of_Runs (E) = 0);              --  empty: no runs
   pragma Assert (Number_Of_Runs (M) = Max_Length);     --  alternating: one run per char
   pragma Assert (Number_Of_Runs (M (1 .. 1)) = 1);
   --  Same data at shifted origins (and ending at Positive'Last) = origin 1.
   pragma Assert (Number_Of_Runs (At_Origin (A, 9)) = 3);
   pragma Assert (Number_Of_Runs (At_Top (C)) = 4);
   pragma Assert (Number_Of_Runs (At_Top (M)) = Max_Length);
   pragma Assert (Number_Of_Runs (At_Origin (E, 20)) = 0);
   --  Single cell at Positive'Last: the loop bound must not compute
   --  Input'First + 1 (overflow found by GNATprove after the rewrite).
   pragma Assert (Number_Of_Runs (At_Top ("q")) = 1);
   pragma Assert (Number_Of_Runs (At_Top ("qq")) = 1);
   pragma Assert (Number_Of_Runs (At_Top ("qr")) = 2);
   Own_Checks;
end Tests;
