pragma Ada_2022;
--  Own tests for Heapsort (see tests/SOURCES.txt).
--  Sort against an own insertion-sort reference on random arrays with arbitrary index bounds, Heapify
--  against the max-heap property, and the documented Sift_Down precondition (A'First <= Root <= Heap_Last
--  <= A'Last): a call outside it must be rejected (Assertion_Error), not run off the array.
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions;
with Heapsort; use Heapsort;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   Seed : Long_Long_Integer := 20261008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   function Heap_Ok (A : Element_Array) return Boolean is
     (for all I in A'Range => (for all C in 1 .. 2 =>
        2 * (I - A'First) + C + A'First > A'Last or else A (2 * (I - A'First) + C + A'First) <= A (I)));
begin
   for Run in 1 .. 3000 loop
      declare
         N : constant Natural := Next (0, 40);
         F0 : constant Natural := Next (0, 5);
         A, R : Element_Array (F0 .. F0 + N - 1);
         T : Integer; J : Integer;
      begin
         for I in A'Range loop A (I) := Next (-50, 50); end loop;
         R := A;
         for P in R'First + 1 .. R'Last loop
            T := R (P); J := P - 1;
            while J >= R'First and then R (J) > T loop R (J + 1) := R (J); J := J - 1; end loop;
            R (J + 1) := T;
         end loop;
         declare H : Element_Array := A; begin
            Heapify (H);
            Report (Heap_Ok (H), "Heapify: not a max-heap, run" & Run'Image);
         end;
         Sort (A);
         Report (A = R and then Is_Sorted (A), "Sort differs from own insertion sort, run" & Run'Image);
      end;
   end loop;
   declare
      A : Element_Array (1 .. 7) := [7, 6, 5, 4, 3, 2, 1];
   begin
      Sift_Down (A, 1, 20);   --  Heap_Last beyond A'Last: outside the documented precondition
      Report (False, "Sift_Down accepted Heap_Last > A'Last");
   exception
      when Ada.Assertions.Assertion_Error => Report (True, "");
      when Constraint_Error => Report (False, "Sift_Down ran off the array (Constraint_Error) instead of rejecting the call");
   end;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
