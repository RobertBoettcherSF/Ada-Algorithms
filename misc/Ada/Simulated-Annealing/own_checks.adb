--  Next_Natural. One stream from seed 0 (stored as 1), 4000 draws of
--  1 .. 10. Expected 400 each, df = 9. Threshold 21.666 (p = 0.01).
--  Span 11: seed 1831847268 is the last state of index 1, 1812995625
--  the first state of index 2, 729043980 the maximum accepted state
--  (index 11). A one-value range returns that value and does not draw.

pragma Ada_2022;

with Ada.Text_IO;
with Simulated_Annealing;

procedure Own_Checks (Fail_Count : out Natural) is
   use Simulated_Annealing;
   package Txt renames Ada.Text_IO;

   Checks : Natural := 0;
   Fails  : Natural := 0;

   procedure Note (OK : Boolean; Label : String) is
   begin
      Checks := Checks + 1;
      if not OK then
         Fails := Fails + 1;
         Txt.Put_Line ("  FAIL -- " & Label);
      end if;
   end Note;

   State, Fresh : RNG_State;
   Count : array (1 .. 10) of Natural := [others => 0];
   Stat : Real := 0.0;
begin
   Fail_Count := 0;
   Txt.Put_Line ("own checks: seed 0, 4000 draws, 1 .. 10, threshold 21.666;"
     & " span 11 seeds 1831847268, 1812995625, 729043980");
   Seed_RNG (State, 0);
   for I in 1 .. 4000 loop
      declare
         Idx : constant Natural := Next_Natural (State, 1, 10);
      begin
         Count (Idx) := Count (Idx) + 1;
      end;
   end loop;
   for P in Count'Range loop
      declare
         Diff : constant Real := Real (Count (P)) - 400.0;
      begin
         Stat := Stat + Diff * Diff / 400.0;
      end;
   end loop;
   Note (Stat < 21.666, "Next_Natural seed 0, span 10");

   Seed_RNG (State, 1831847268);
   Note (Next_Natural (State, 1, 11) = 1,
     "bin edge: last state of the first index");
   Seed_RNG (State, 1812995625);
   Note (Next_Natural (State, 1, 11) = 2,
     "bin edge: first state of the next index");
   Seed_RNG (State, 729043980);
   Note (Next_Natural (State, 1, 11) = 11,
     "maximum accepted state is the last index");

   Seed_RNG (State, 0);
   Note (Next_Natural (State, 7, 7) = 7, "a one-value range is that value");
   Seed_RNG (Fresh, 0);
   Note (Next_Natural (State, 1, 11) = Next_Natural (Fresh, 1, 11),
     "a one-value range does not draw");

   Txt.Put_Line ("own checks:" & Natural'Image (Checks)
     & "  failed:" & Natural'Image (Fails));
   Fail_Count := Fails;
end Own_Checks;
