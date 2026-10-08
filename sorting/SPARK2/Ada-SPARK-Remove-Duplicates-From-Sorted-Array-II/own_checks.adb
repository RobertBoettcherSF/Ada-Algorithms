--  Own tests for Remove_Duplicates_From_Sorted_Array_II (see tests/SOURCES.txt).
--  README: compaction retaining at most two copies of each value of a sorted prefix.
pragma Ada_2022;
with Ada.Text_IO;
with Remove_Duplicates_From_Sorted_Array_II; use Remove_Duplicates_From_Sorted_Array_II;

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

   procedure Check_One (N : Length_Type; Hi : Value; Label : String) is
      X : IArr (1 .. N);
      D : Values := [others => 0];
      L : Length_Type := N;
      E : IArr (1 .. Index'Last) := [others => 0];
      M : Natural := 0;
      Ok : Boolean;
   begin
      for I in X'Range loop
         X (I) := Next (Value'First / 100, Hi);
      end loop;
      Ins_Sort (X);
      for I in X'Range loop
         D (I) := X (I);
         --  Own reference: keep X (I) unless the two kept before it equal it.
         if M < 2 or else E (M - 1) /= X (I) then
            M := M + 1;
            E (M) := X (I);
         end if;
      end loop;
      Keep_Two (D, L);
      Ok := L = M;
      for I in 1 .. M loop
         Ok := Ok and then D (I) = E (I);
      end loop;
      Report (Ok, Label);
   end Check_One;
begin
   for N in Length_Type loop
      for K in 1 .. 100 loop
         Check_One (N, Value'First / 100 + 3, "many ties N=" & N'Image);
         Check_One (N, Value'Last, "random N=" & N'Image);
      end loop;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own keep-two reference)");
end Own_Checks;
