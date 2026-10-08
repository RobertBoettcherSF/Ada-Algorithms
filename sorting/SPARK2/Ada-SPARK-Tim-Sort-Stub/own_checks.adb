--  Own tests for Tim_Sort_Stub (see tests/SOURCES.txt).
--  Sort must return the same bounds, sorted, and a permutation of Input.
pragma Ada_2022;
with Ada.Text_IO;
with Tim_Sort_Stub; use Tim_Sort_Stub;

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

   procedure Check_One (First : Positive; N : Natural; Lo, Hi : Integer; Label : String) is
      A : Value_Array (First .. First + N - 1);
      E : IArr (First .. First + N - 1);
   begin
      for I in A'Range loop
         A (I) := Next (Lo, Hi);
         E (I) := A (I);
      end loop;
      Ins_Sort (E);
      declare
         R : constant Value_Array := Sort (A);
         Ok : Boolean := R'First = A'First and then R'Last = A'Last;
      begin
         if Ok then
            for I in A'Range loop
               Ok := Ok and then R (I) = E (I);
            end loop;
         end if;
         Report (Ok, Label);
      end;
   end Check_One;
begin
   for N in 0 .. 40 loop
      for K in 1 .. 50 loop
         Check_One (1, N, -1_000, 1_000, "random N=" & N'Image);
         Check_One (100, N, 0, 3, "duplicates N=" & N'Image);
      end loop;
   end loop;
   Check_One (1, 64, Integer'First, Integer'Last, "full Integer range");
   Check_One (Positive'Last - 100, 60, -5, 5, "high index bounds");
   Check_One (1, 200, -1_000_000, 1_000_000, "long array");
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (bounds, own insertion-sort reference)");
end Own_Checks;
