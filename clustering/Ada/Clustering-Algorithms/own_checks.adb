--  Draw_Index from the integer LCG, not from a scaled float.
--  Chi-square: one stream, seed 0, 4000 draws of 1 .. 20. Expected 200
--  each, df = 19. Threshold 36.191 (p = 0.01). That seed set stays put.
--  Span 24: seed 114925855 is the last state of index 1, seed 1784785080
--  is the first state of index 2, seed 1532920309 is the maximum
--  accepted state and must be index 24.

pragma Ada_2022;

with Ada.Text_IO;
with Clustering_Algorithms;

procedure Own_Checks (Fail_Count : out Natural) is
   use Clustering_Algorithms;
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

   State : RNG_State;
   Count : array (1 .. 20) of Natural := [others => 0];
   Stat  : Real := 0.0;
begin
   Fail_Count := 0;
   Txt.Put_Line ("own checks: seed stream 0, 4000 draws, span 1 .. 20,"
     & " threshold 36.191; span 24 seeds 114925855, 1784785080, 1532920309");
   Seed_RNG (State, 0);
   for I in 1 .. 4000 loop
      declare
         Idx : constant Point_Index := Draw_Index (State, 1, 20);
      begin
         Count (Integer (Idx)) := Count (Integer (Idx)) + 1;
      end;
   end loop;
   for P in Count'Range loop
      declare
         Diff : constant Real := Real (Count (P)) - 200.0;
      begin
         Stat := Stat + Diff * Diff / 200.0;
      end;
   end loop;
   Note (Stat < 36.191, "Draw_Index seed stream 0, span 20");

   Seed_RNG (State, 114925855);
   Note (Draw_Index (State, 1, 24) = 1,
     "bin edge: last state of the first index");
   Seed_RNG (State, 1784785080);
   Note (Draw_Index (State, 1, 24) = 2,
     "bin edge: first state of the next index");
   Seed_RNG (State, 1532920309);
   Note (Draw_Index (State, 1, 24) = 24,
     "maximum accepted state is the last index");

   Txt.Put_Line ("own checks:" & Natural'Image (Checks)
     & "  failed:" & Natural'Image (Fails));
   Fail_Count := Fails;
end Own_Checks;
