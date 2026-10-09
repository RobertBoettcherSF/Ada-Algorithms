--  Own tests for Fisher_Yates_Shuffle.Shuffle (written for this
--  repository; see tests/SOURCES.txt). Assumption: Shuffle loses or
--  duplicates items, or two valid choice vectors give the same
--  permutation (then uniform choices would not give a uniform shuffle),
--  or an invalid choice vector is accepted. Reference: no second shuffle;
--  the checks are properties. (1) All 720 valid choice vectors applied to
--  [1 .. 6] give 720 permutations of 1 .. 6, all different (checked by
--  encoding each permutation as a number and marking it). (2) Random
--  item arrays with many repeats keep their occurrence counts for every
--  value under random valid choices. (3) Every vector with one choice
--  above its position is rejected by the Swap_Array predicate.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions;
with Ada.Environment_Variables;
with Fisher_Yates_Shuffle; use Fisher_Yates_Shuffle;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;
   --  Fixed default seed, printed at start; AA_SEED overrides it.
   subtype Seed_Range is Long_Long_Integer range 1 .. 2_147_483_646;
   Default_Seed : constant Seed_Range := 20_261_008;
   function Initial_Seed return Seed_Range is
     (if Ada.Environment_Variables.Exists ("AA_SEED")
      then Seed_Range'Value (Ada.Environment_Variables.Value ("AA_SEED"))
      else Default_Seed);
   Seed : Long_Long_Integer := Initial_Seed;
   function Next (Lo, Hi : Long_Long_Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Lo + Seed mod (Hi - Lo + 1));
   end Next;

   procedure Fail (Msg : String) is
   begin
      Failures := Failures + 1;
      if Failures <= 5 then
         Put_Line ("FAIL " & Msg);
      end if;
   end Fail;

   --  Choice vector number Code (0 .. 719): Choices (I) = 1 + digit I of
   --  Code in the mixed radix 1, 2, .., 6.
   function Vector (Code : Natural) return Swap_Array is
      C : array (Index) of Index;
      R : Natural := Code;
   begin
      for I in Index loop
         C (I) := R mod I + 1;
         R := R / I;
      end loop;
      return Swap_Array (C);
   end Vector;

   Seen : array (0 .. 6 ** 6 - 1) of Boolean := [others => False];
begin
   Put_Line ("own checks seed:" & Seed'Image & " (default"
             & Default_Seed'Image & "; set AA_SEED to override)");
   --  (1) Bijection from the 720 valid vectors onto the permutations.
   for Code in 0 .. 719 loop
      declare
         D   : Item_Array := [1, 2, 3, 4, 5, 6];
         Key : Natural := 0;
         Hit : array (1 .. 6) of Boolean := [others => False];
      begin
         Shuffle (D, Vector (Code));
         Cases := Cases + 1;
         for I in Index loop
            if D (I) not in 1 .. 6 or else Hit (D (I)) then
               Fail ("vector" & Code'Image & ": not a permutation");
               exit;
            end if;
            Hit (D (I)) := True;
            Key := Key * 6 + (D (I) - 1);
         end loop;
         if Seen (Key) then
            Fail ("vector" & Code'Image & ": permutation already produced");
         end if;
         Seen (Key) := True;
      end;
   end loop;
   --  (2) Occurrence counts under 5,000 random arrays and valid choices.
   for K in 1 .. 5_000 loop
      declare
         Width : constant Integer := Next (0, 100);
         D, D0 : Item_Array;
         C     : Swap_Array := [1, 2, 3, 4, 5, 6];
      begin
         for I in Index loop
            D (I) := Next (Long_Long_Integer (-Width), Long_Long_Integer (Width));
         end loop;
         C := Vector (Next (0, 719));
         D0 := D;
         Shuffle (D, C);
         Cases := Cases + 1;
         for V in -100 .. 100 loop
            declare
               A, B : Natural := 0;
            begin
               for I in Index loop
                  A := A + (if D0 (I) = V then 1 else 0);
                  B := B + (if D (I) = V then 1 else 0);
               end loop;
               if A /= B then
                  Fail ("random" & K'Image & ": count of" & V'Image & " changed");
               end if;
            end;
         end loop;
      end;
   end loop;
   --  (3) Invalid vectors: position I chooses I + 1 .. 6.
   for I in 1 .. 5 loop
      for Bad in I + 1 .. 6 loop
         declare
            Raw : array (Index) of Index := [1, 2, 3, 4, 5, 6];
            Rejected : Boolean := False;
         begin
            Raw (I) := Bad;
            begin
               declare
                  C : constant Swap_Array := Swap_Array (Raw);
               begin
                  Rejected := C (I) /= Bad;   --  False: accepted as given
               end;
            exception
               when Ada.Assertions.Assertion_Error =>
                  Rejected := True;
            end;
            Cases := Cases + 1;
            if not Rejected then
               Fail ("choice" & Bad'Image & " at position" & I'Image & " accepted");
            end if;
         end;
      end loop;
   end loop;

   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image
             & " cases (720 vectors -> 720 distinct permutations; counts kept; invalid choices rejected)");
end Own_Checks;
