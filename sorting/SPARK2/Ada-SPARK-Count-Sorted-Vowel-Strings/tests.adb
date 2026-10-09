pragma Ada_2022;
with Ada.Text_IO;
with Count_Sorted_Vowel_Strings; use Count_Sorted_Vowel_Strings;
with Own_Checks;

procedure Tests is
   procedure Expect (N : Length; From : Vowel; Want : Natural) is
      Got : constant Natural := Number_Of_Strings (N, From);
   begin
      if Got /= Want then
         raise Program_Error with "Number_Of_Strings" & N'Image & " " & From'Image & ": got" & Got'Image
           & ", expected" & Want'Image;
      end if;
   end Expect;

   --  The old table: C (n + 4, 4) for n <= 16.
   Old : constant array (0 .. 16) of Natural :=
     [1, 5, 15, 35, 70, 126, 210, 330, 495, 715, 1_001, 1_365, 1_820, 2_380, 3_060, 3_876, 4_845];
begin
   for N in Old'Range loop
      Expect (N, A, Old (N));
   end loop;

   --  C (104, 4) = 104 * 103 * 102 * 101 / 24 = 4_598_126.
   Expect (100, A, 4_598_126);
   --  The limit: C (477, 4) = 2_130_031_575 fits Natural (n = 473);
   --  C (478, 4) = 2_148_006_525 would not (n = 474).
   Expect (473, A, 2_130_031_575);

   --  Only the letters from From on: over i, o, u the sorted strings of
   --  length 2 are ii io iu oo ou uu (6); over u alone there is one
   --  string of each length; over o, u there are n + 1.
   Expect (2, I, 6);
   Expect (3, U, 1);
   Expect (0, U, 1);
   Expect (5, O, 6);
   Expect (473, U, 1);
   Expect (473, O, 474);
   --  Over e, i, o, u: C (n + 3, 3); n = 2 gives 10 (ee ei eo eu ii io iu oo ou uu).
   Expect (2, E, 10);

   Own_Checks;
   Ada.Text_IO.Put_Line ("count sorted vowel strings tests passed");
end Tests;
