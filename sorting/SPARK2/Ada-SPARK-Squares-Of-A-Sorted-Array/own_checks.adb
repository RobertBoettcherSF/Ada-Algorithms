--  Own tests for Squares_Of_A_Sorted_Array.Squares (see tests/SOURCES.txt).
--  For a sorted input, Result must be the squares of the input in non-decreasing order
--  (own reference: square every element, then insertion sort). Unsorted input is rejected.
pragma Ada_2022;
--  the rejection checks rely on the input subtype's predicate; check it even in builds
--  without -gnata (the check is made here, at the call)
pragma Assertion_Policy (Dynamic_Predicate => Check);
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions;
with Squares_Of_A_Sorted_Array; use Squares_Of_A_Sorted_Array;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   Seed : Long_Long_Integer := 20_261_008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   procedure Check_One (A : Int_Array; Label : String) is
      R   : constant Square_Array := Squares (A);
      Exp : Square_Array;
      T   : Square_Value;
      J   : Index;
      Ok  : Boolean := True;
   begin
      for I in Index loop
         Exp (I) := A (I) * A (I);
      end loop;
      for I in 2 .. Length loop   --  own insertion sort
         T := Exp (I);
         J := I;
         while J > 1 and then Exp (J - 1) > T loop
            Exp (J) := Exp (J - 1);
            J := J - 1;
         end loop;
         Exp (J) := T;
      end loop;
      for I in Index loop
         Ok := Ok and then R (I) = Exp (I);
      end loop;
      Report (Ok, Label);
   end Check_One;
   procedure Check_Rejected (A : Int_Array; Label : String) is
      R : Square_Array;
   begin
      R := Squares (A);
      Report (False, Label & " (accepted, first square" & R (1)'Image & ")");
   exception
      when Ada.Assertions.Assertion_Error =>
         Report (True, Label);
   end Check_Rejected;

   A : Int_Array;
   T : Value;
   J : Index;
begin
   Check_One ([for I in Index => Value'First + 2 * (I - 1)], "ascending incl. extremes");
   Check_One ([others => Value'Last], "all Last");
   Check_One ([others => Value'First], "all First");
   Check_One ([others => 0], "zeros");
   Check_One ([for I in Index => (if I <= 16 then I - 17 else I - 16)], "symmetric");
   for K in 1 .. 3_000 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'Last);
      end loop;
      for I in 2 .. Length loop   --  sort the random input (own insertion sort)
         T := A (I);
         J := I;
         while J > 1 and then A (J - 1) > T loop
            A (J) := A (J - 1);
            J := J - 1;
         end loop;
         A (J) := T;
      end loop;
      Check_One (A, "random" & K'Image);
   end loop;
   Check_Rejected ([for I in Index => Value'Last - I], "descending");
   for K in 1 .. 500 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'Last);
      end loop;
      if (for some I in 2 .. Length => A (I - 1) > A (I)) then
         Check_Rejected (A, "unsorted random" & K'Image);
      end if;
   end loop;
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " inputs (own square + insertion-sort reference; unsorted input rejected)");
end Own_Checks;
