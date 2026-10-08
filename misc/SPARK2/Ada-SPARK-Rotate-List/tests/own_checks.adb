--  Own tests for Rotate_List.Solve (see tests/SOURCES.txt).
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Rotate_List; use Rotate_List;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   type Int_Array is array (Positive range <>) of Integer;

   Seed : Long_Long_Integer := 20261008;
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
   --  own reference (standard Rotate List): rotate right by K places; K may exceed the length
   procedure Check (A : Int_Array; K : Rotate_List.Count) is
      L : List := Build (A);
      W : Int_Array (A'Range);
   begin
      for I in A'Range loop
         W (((I - 1 + K) mod A'Length) + 1) := A (I);
      end loop;
      Solve (L, K);
      Compare (L, W, "length" & Integer'Image (A'Length) & " k" & Integer'Image (K));
   end Check;
begin
   --  by hand: 1 2 3 4 5 rotated right by 2 -> 4 5 1 2 3; by 7 (= 2 mod 5) the same
   declare L : List := Build ([1, 2, 3, 4, 5]); begin Solve (L, 2); Compare (L, [4, 5, 1, 2, 3], "hand k=2"); end;
   declare L : List := Build ([1, 2, 3, 4, 5]); begin Solve (L, 7); Compare (L, [4, 5, 1, 2, 3], "hand k=7"); end;
   declare L : List := Empty; begin Solve (L, 3); Checked := Checked + 1; if L.Length /= 0 then Failures := Failures + 1; end if; end;
   for N in 1 .. Capacity loop
      for K in Rotate_List.Count loop
         Check (Input (N, True), K);
         Check (Input (N, False), K);
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
