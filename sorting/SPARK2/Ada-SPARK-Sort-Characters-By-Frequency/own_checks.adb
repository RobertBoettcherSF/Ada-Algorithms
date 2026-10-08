--  Own tests for Sort_Characters_By_Frequency (see tests/SOURCES.txt).
--  README: character-frequency sort; result is a permutation of Input whose
--  character frequencies (in the input) are non-increasing from left to right.
pragma Ada_2022;
with Ada.Text_IO;
with Sort_Characters_By_Frequency; use Sort_Characters_By_Frequency;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   Seed : Long_Long_Integer := 20_261_008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   --  Own reference: straight insertion sort.
   type IArr is array (Positive range <>) of Integer;
   procedure Ins_Sort (A : in out IArr) is
      T : Integer;
      J : Positive;
   begin
      for I in A'First + 1 .. A'Last loop
         T := A (I);
         J := I;
         while J > A'First and then A (J - 1) > T loop
            A (J) := A (J - 1);
            J := J - 1;
         end loop;
         A (J) := T;
      end loop;
   end Ins_Sort;
   pragma Warnings (Off, Ins_Sort);

   procedure Check_One (A : Char_Array; Label : String) is
      type Counts is array (Character) of Natural;
      R : constant Char_Array := Sort_By_Frequency (A);
      C_In, C_Out : Counts := [others => 0];
      Ok : Boolean := True;
   begin
      for I in Index loop
         C_In (A (I)) := C_In (A (I)) + 1;
         C_Out (R (I)) := C_Out (R (I)) + 1;
      end loop;
      for I in Index'First .. Index'Last - 1 loop
         Ok := Ok and then C_In (R (I)) >= C_In (R (I + 1));
      end loop;
      Report (Ok and then C_In = C_Out, Label);
   end Check_One;
   A : Char_Array;
begin
   for K in 1 .. 4_000 loop
      for I in Index loop
         A (I) := Character'Val (Character'Pos ('a') + Next (0, (if K mod 2 = 0 then 2 else 7)));
      end loop;
      Check_One (A, "random" & K'Image);
   end loop;
   Check_One ([others => 'z'], "all equal");
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (frequency order, permutation)");
end Own_Checks;
