--  Own tests for Remove_Duplicates_From_Sorted_List_II (see tests/SOURCES.txt).
--  Solve must keep exactly the values that occur once, in their original order.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Remove_Duplicates_From_Sorted_List_II; use Remove_Duplicates_From_Sorted_List_II;

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

   type IArr is array (1 .. Capacity) of Integer;
   --  own reference: walk the input, keep an element when no other position holds the same value
   procedure Check (A : IArr; N : Count; Label : String) is
      L : List := Empty;
      Exp : IArr := [others => 0];
      M : Natural := 0;
      Ok : Boolean;
   begin
      for I in 1 .. N loop
         Append (L, A (I));
      end loop;
      for I in 1 .. N loop
         if (for all J in 1 .. N => J = I or else A (J) /= A (I)) then
            M := M + 1;
            Exp (M) := A (I);
         end if;
      end loop;
      Solve (L);
      Ok := L.Length = M;
      if Ok then
         for P in 1 .. M loop
            Ok := Ok and then Get (L, P) = Exp (P);
         end loop;
      end if;
      Report (Ok, Label);
   end Check;
   A : IArr;
   N : Count;
begin
   Check ([1, 2, 3, 3, 4, 4, 5, others => 0], 7, "1 2 3 3 4 4 5 -> 1 2 5");
   Check ([1, 1, 1, 2, 3, others => 0], 5, "1 1 1 2 3 -> 2 3");
   Check ([others => 7], 16, "16 equal values -> empty");
   Check ([others => 0], 0, "empty list");
   Check ([for I in 1 .. Capacity => I], 16, "all distinct");
   Check ([Integer'First, Integer'First, Integer'Last, others => 0], 3, "extreme values");
   for K in 1 .. 5_000 loop
      N := Next (0, Capacity);
      --  sorted input with many repeats (non-decreasing steps of 0 or 1); every 5th run unsorted
      A (1) := Next (-5, 5);
      for I in 2 .. Capacity loop
         A (I) := (if K mod 5 = 0 then Next (-4, 4) else A (I - 1) + Next (0, 1));
      end loop;
      Check (A, N, "random" & K'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own occurs-once reference)");
end Own_Checks;
