--  Own tests for Median_Of_Two_Sorted_Arrays_Lite (see tests/SOURCES.txt).
--  Median of the 2 * Length values: between the two middle ones (exactly their
--  mean when it is an integer).
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Median_Of_Two_Sorted_Arrays_Lite; use Median_Of_Two_Sorted_Arrays_Lite;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20_261_008);
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

   procedure Check_One (Hi : Value; Label : String) is
      A, B : Input_Array;
      XA, XB : IArr (1 .. Length);
      E : IArr (1 .. 2 * Length);
      M : Integer;
   begin
      for I in 1 .. Length loop
         XA (I) := Next (0, Hi);
         XB (I) := Next (0, Hi);
      end loop;
      Ins_Sort (XA);
      Ins_Sort (XB);
      for I in 1 .. Length loop
         A (I) := XA (I);
         B (I) := XB (I);
      end loop;
      E := XA & XB;
      Ins_Sort (E);
      M := Median (A, B).Median;
      if (E (Length) + E (Length + 1)) mod 2 = 0 then
         Report (M = (E (Length) + E (Length + 1)) / 2, Label);
      else
         Report (M in E (Length) .. E (Length + 1), Label);
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
