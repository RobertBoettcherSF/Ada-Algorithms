--  Own tests for Remove_Duplicates_From_Sorted_List (see tests/SOURCES.txt).
--  Solve must leave one copy of each value of a sorted list, in order.
pragma Ada_2022;
with Ada.Text_IO;
with Remove_Duplicates_From_Sorted_List; use Remove_Duplicates_From_Sorted_List;

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

   procedure Check_One (N : Count; Lo, Hi : Integer; Label : String) is
      X : IArr (1 .. N);
      L : List := Empty;
      E : IArr (1 .. Capacity) := [others => 0];
      M : Natural := 0;
      Ok : Boolean;
   begin
      for I in X'Range loop
         X (I) := Next (Lo, Hi);
      end loop;
      Ins_Sort (X);
      for V of X loop
         Append (L, V);
         if M = 0 or else E (M) /= V then
            M := M + 1;
            E (M) := V;
         end if;
      end loop;
      Solve (L);
      Ok := L.Length = M;
      for I in 1 .. M loop
         Ok := Ok and then Get (L, I) = E (I);
      end loop;
      Report (Ok, Label);
   end Check_One;
begin
   for N in Count loop
      for K in 1 .. 150 loop
         Check_One (N, 0, 3, "many ties N=" & N'Image);
         Check_One (N, -100, 100, "random N=" & N'Image);
      end loop;
   end loop;
   Check_One (Capacity, 0, 0, "all equal");
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own unique reference)");
end Own_Checks;
