--  Own tests for Merge_Sorted_Array (see tests/SOURCES.txt).
--  Merge_Sum (Left, Right, Length): sum of the first Length values of the merge of
--  the sorted arrays Left and Right.
pragma Ada_2022;
with Ada.Text_IO;
with Merge_Sorted_Array; use Merge_Sorted_Array;

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

   procedure Check_One (Lo, Hi : Value; N : Length_Type; Label : String) is
      L, R : Values;
      XL, XR : IArr (1 .. Index'Last);
      E : IArr (1 .. 2 * Index'Last);
      Sum : Integer := 0;
   begin
      for I in Index loop
         XL (I) := Next (Lo, Hi);
         XR (I) := Next (Lo, Hi);
      end loop;
      Ins_Sort (XL);
      Ins_Sort (XR);
      for I in Index loop
         L (I) := XL (I);
         R (I) := XR (I);
      end loop;
      E := XL & XR;
      Ins_Sort (E);
      for I in 1 .. N loop
         Sum := Sum + E (I);
      end loop;
      Report (Merge_Sum (L, R, N) = Sum, Label);
   end Check_One;
begin
   for N in Length_Type loop
      for K in 1 .. 100 loop
         Check_One (Value'First, Value'Last, N, "random N=" & N'Image);
         Check_One (-2, 2, N, "ties N=" & N'Image);
      end loop;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own merge-prefix-sum reference)");
end Own_Checks;
