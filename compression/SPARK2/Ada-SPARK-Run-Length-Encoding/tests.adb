pragma Ada_2022;
with Run_Length_Encoding;
procedure Tests is
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
end Tests;
