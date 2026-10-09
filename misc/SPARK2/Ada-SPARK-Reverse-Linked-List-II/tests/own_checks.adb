--  Own tests for Reverse_Linked_List_II.Solve (see tests/SOURCES.txt).
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Reverse_Linked_List_II; use Reverse_Linked_List_II;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   type Int_Array is array (Positive range <>) of Integer;

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
   Seed : Long_Long_Integer := AA_Seed (20261008);
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;

   function Build (A : Int_Array) return List is
      L : List := Empty;
   begin
      for V of A loop
         Append (L, V);
      end loop;
      return L;
   end Build;

   procedure Compare (L : List; Want : Int_Array; Label : String) is
   begin
      Checked := Checked + 1;
      if L.Length /= Want'Length then
         Failures := Failures + 1; Put_Line ("  FAIL " & Label & ": length"); return;
      end if;
      for P in Want'Range loop
         if Get (L, P) /= Want (P) then
            Failures := Failures + 1;
            Put_Line ("  FAIL " & Label & ": position" & Integer'Image (P)); return;
         end if;
      end loop;
   end Compare;

   --  inputs: distinct values (so a misplaced element is always seen), and random values with repeats
   function Input (N : Natural; Distinct : Boolean) return Int_Array is
      A : Int_Array (1 .. N);
   begin
      for I in A'Range loop
         A (I) := (if Distinct then 10 * I + 1 else Next (-3, 3));
      end loop;
      return A;
   end Input;
   --  own reference (standard Reverse Linked List II): reverse positions First .. Last
   --  (1-based, inclusive), leave the rest
   procedure Check (A : Int_Array; First, Last : Position) is
      L : List := Build (A);
      W : Int_Array (A'Range) := A;
   begin
      for I in First .. Last loop
         W (I) := A (First + Last - I);
      end loop;
      Solve (L, First, Last);
      Compare (L, W, "length" & Integer'Image (A'Length) & " range" & Integer'Image (First) & Integer'Image (Last));
   end Check;
begin
   --  Empty is the same value as a default-initialized List (the public record's defaults),
   --  so the two ways of making an empty list compare equal with the public "="
   declare
      D : List;
   begin
      Checked := Checked + 1;
      if Empty /= D then
         Failures := Failures + 1; Put_Line ("  FAIL Empty = default-initialized List");
      end if;
   end;
   --  by hand: 1 2 3 4 5 with 2 .. 4 -> 1 4 3 2 5; 1 .. 5 -> 5 4 3 2 1
   declare L : List := Build ([1, 2, 3, 4, 5]); begin Solve (L, 2, 4); Compare (L, [1, 4, 3, 2, 5], "hand 2..4"); end;
   declare L : List := Build ([1, 2, 3, 4, 5]); begin Solve (L, 1, 5); Compare (L, [5, 4, 3, 2, 1], "hand 1..5"); end;
   for N in 1 .. Capacity loop
      for F in 1 .. N loop
         for T in F .. N loop
            Check (Input (N, True), F, T);
            Check (Input (N, False), F, T);
         end loop;
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
