--  Own property tests for Wiggle_Sort.Wiggle (see tests/SOURCES.txt).
--  Expected behaviour (README): a permutation of the input with
--  R(1) <= R(2) >= R(3) <= R(4) ... for every adjacent pair.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Wiggle_Sort; use Wiggle_Sort;

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

   procedure Check_One (A : Input_Array; Label : String) is
      type Counts is array (Value) of Natural;
      R     : constant Input_Array := Wiggle (A);
      C_In  : Counts := [others => 0];
      C_Out : Counts := [others => 0];
      Ok    : Boolean := True;
   begin
      for I in Index loop
         C_In (A (I)) := C_In (A (I)) + 1;
         C_Out (R (I)) := C_Out (R (I)) + 1;
         if I < Index'Last then
            if I mod 2 = 1 then
               Ok := Ok and then R (I) <= R (I + 1);
            else
               Ok := Ok and then R (I) >= R (I + 1);
            end if;
         end if;
      end loop;
      Report (Ok and then C_In = C_Out, Label);
   end Check_One;

   A : Input_Array;
begin
   Check_One ([others => 0], "all equal");
   Check_One ([for I in Index => Value'First + I], "ascending");
   Check_One ([for I in Index => Value'Last - I], "descending");
   for K in 1 .. 3_000 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'Last);
      end loop;
      Check_One (A, "random" & K'Image);
   end loop;
   for K in 1 .. 1_000 loop
      for I in Index loop
         A (I) := Next (0, 2);
      end loop;
      Check_One (A, "duplicates" & K'Image);
   end loop;
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " inputs (wiggle order, permutation)");
end Own_Checks;
