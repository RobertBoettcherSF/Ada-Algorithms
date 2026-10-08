--  Own tests for Median_Of_Two_Sorted_Arrays_Lite (see tests/SOURCES.txt).
--  Median of the eight values: between the 4th and 5th smallest (exactly their
--  mean when it is an integer).
pragma Ada_2022;
with Ada.Text_IO;
with Median_Of_Two_Sorted_Arrays_Lite; use Median_Of_Two_Sorted_Arrays_Lite;

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

   procedure Check_One (Hi : Value; Label : String) is
      A, B : Input_Array;
      XA, XB : IArr (1 .. 4);
      E : IArr (1 .. 8);
      M : Integer;
   begin
      for I in 1 .. 4 loop
         XA (I) := Next (0, Hi);
         XB (I) := Next (0, Hi);
      end loop;
      Ins_Sort (XA);
      Ins_Sort (XB);
      for I in 1 .. 4 loop
         A (I) := XA (I);
         B (I) := XB (I);
      end loop;
      E := XA & XB;
      Ins_Sort (E);
      M := Median (A, B);
      if (E (4) + E (5)) mod 2 = 0 then
         Report (M = (E (4) + E (5)) / 2, Label);
      else
         Report (M in E (4) .. E (5), Label);
      end if;
   end Check_One;
begin
   for K in 1 .. 3_000 loop
      Check_One (Value'Last, "random" & K'Image);
      Check_One (3, "ties" & K'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own sorted-merge median reference)");
end Own_Checks;
