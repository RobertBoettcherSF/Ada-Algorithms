--  Own property tests for Squares_Of_A_Sorted_Array.Squares (see
--  tests/SOURCES.txt). Expected behaviour (README: "elementwise square
--  transform"): Result (I) = A (I) * A (I) for every I, computed here
--  independently.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
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
      R  : constant Square_Array := Squares (A);
      Ok : Boolean := True;
   begin
      for I in Index loop
         Ok := Ok and then R (I) = A (I) * A (I);
      end loop;
      Report (Ok, Label);
   end Check_One;

   A : Int_Array;
begin
   Check_One ([for I in Index => Value'First + 2 * (I - 1)], "ascending incl. extremes");
   Check_One ([others => Value'Last], "all Last");
   Check_One ([others => Value'First], "all First");
   Check_One ([others => 0], "zeros");
   for K in 1 .. 3_000 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'Last);
      end loop;
      Check_One (A, "random" & K'Image);
   end loop;
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " inputs (elementwise squares)");
end Own_Checks;
