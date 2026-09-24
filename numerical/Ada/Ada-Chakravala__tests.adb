--  Standalone test suite for Chakravala (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Chakravala; use Chakravala;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwc constant-condition warnings).
   function L (X : Long_Integer) return Long_Integer is (X);

   procedure Expect_Invalid (Label : String; N : Long_Integer) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Pell_Pair := Solve_Pell (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument: " & Label);
   end Expect_Invalid;

   procedure Check_Pell
     (N, Exp_X, Exp_Y : Long_Integer; Label : String)
   is
      P : constant Pell_Pair := Solve_Pell (N);
   begin
      Check (P.X = Exp_X and then P.Y = Exp_Y, Label & " pair");
      Check (Verify_Pell (N, P), Label & " verify");
      Check (P.Y > 0, Label & " Y>0");
   end Check_Pell;

begin
   Ada.Text_IO.Put_Line ("Chakravala tests");
   Ada.Text_IO.Put_Line ("================");

   ------------------------------------------------------------------
   Section ("1. Abs_LI / Floor_Sqrt / Is_Perfect_Square");
   ------------------------------------------------------------------
   Check (Abs_LI (L (0)) = 0, "Abs_LI(0)");
   Check (Abs_LI (L (5)) = 5, "Abs_LI(5)");
   Check (Abs_LI (L (-5)) = 5, "Abs_LI(-5)");

   Check (Floor_Sqrt (L (0)) = 0, "Floor_Sqrt(0)");
   Check (Floor_Sqrt (L (1)) = 1, "Floor_Sqrt(1)");
   Check (Floor_Sqrt (L (2)) = 1, "Floor_Sqrt(2)");
   Check (Floor_Sqrt (L (3)) = 1, "Floor_Sqrt(3)");
   Check (Floor_Sqrt (L (4)) = 2, "Floor_Sqrt(4)");
   Check (Floor_Sqrt (L (15)) = 3, "Floor_Sqrt(15)");
   Check (Floor_Sqrt (L (16)) = 4, "Floor_Sqrt(16)");
   Check (Floor_Sqrt (L (61)) = 7, "Floor_Sqrt(61)");
   Check (Floor_Sqrt (L (100)) = 10, "Floor_Sqrt(100)");

   Check (Is_Perfect_Square (L (0)), "square 0");
   Check (Is_Perfect_Square (L (1)), "square 1");
   Check (Is_Perfect_Square (L (4)), "square 4");
   Check (Is_Perfect_Square (L (9)), "square 9");
   Check (Is_Perfect_Square (L (100)), "square 100");
   Check (not Is_Perfect_Square (L (2)), "not square 2");
   Check (not Is_Perfect_Square (L (3)), "not square 3");
   Check (not Is_Perfect_Square (L (61)), "not square 61");
   Check (not Is_Perfect_Square (L (-1)), "not square -1");
   Check (not Is_Perfect_Square (L (15)), "not square 15");

   ------------------------------------------------------------------
   Section ("2. Invalid_Argument (square / range)");
   ------------------------------------------------------------------
   Expect_Invalid ("N=0", L (0));
   Expect_Invalid ("N=-3", L (-3));
   Expect_Invalid ("N=1 square", L (1));
   Expect_Invalid ("N=4 square", L (4));
   Expect_Invalid ("N=9 square", L (9));
   Expect_Invalid ("N=16 square", L (16));
   Expect_Invalid ("N=100 square", L (100));
   Expect_Invalid ("N>Max_N", Max_N + 1);
   Expect_Invalid ("N=Max_N if square?", 
     (if Is_Perfect_Square (Max_N) then Max_N else 196));  -- 14²

   ------------------------------------------------------------------
   Section ("3. Compose / Verify_Triple (Brahmagupta)");
   ------------------------------------------------------------------
   declare
      T : Auxiliary_Triple;
   begin
      --  (3,2,1) for N=2 composed with itself → next Pell solution
      T := Compose (L (2), L (3), L (2), L (1), L (3), L (2), L (1));
      Check (T.A = 17 and then T.B = 12 and then T.K = 1,
             "Compose (3,2,1)*(3,2,1) N=2 → (17,12,1)");
      Check (Verify_Triple (L (2), T), "Verify_Triple composed N=2");

      --  Wikipedia n=61 start (8,1,3) with (m,1,m²−61), m=7
      T := Compose (L (61), L (8), L (1), L (3), L (7), L (1),
                    L (49 - 61));
      Check (Verify_Triple (L (61), T), "Compose (8,1,3)*(7,1,-12)");
      --  Raw composition before scaling: k = 3*(-12) = -36
      Check (T.K = -36, "raw k=-36");
   end;

   ------------------------------------------------------------------
   Section ("4. Initial_Triple / Choose_M / one step");
   ------------------------------------------------------------------
   declare
      T  : Auxiliary_Triple;
      M  : Long_Integer;
      T2 : Auxiliary_Triple;
   begin
      T := Initial_Triple (L (61));
      Check (T.A = 8 and then T.B = 1 and then T.K = 3,
             "Initial_Triple(61)=(8,1,3)");
      Check (Verify_Triple (L (61), T), "Verify initial 61");

      T := Initial_Triple (L (2));
      Check (T.A = 1 and then T.B = 1 and then T.K = -1,
             "Initial_Triple(2)=(1,1,-1)");
      Check (Verify_Triple (L (2), T), "Verify initial 2");

      T := Initial_Triple (L (3));
      Check (T.A = 2 and then T.B = 1 and then T.K = 1,
             "Initial_Triple(3)=(2,1,1) already solution");

      T := Initial_Triple (L (61));
      M := Choose_M (L (61), T.A, T.B, T.K);
      Check (M = 7, "Choose_M for (8,1,3) N=61 → 7");
      T2 := Chakravala_Step_From (L (61), T, M);
      Check (T2.A = 39 and then T2.B = 5 and then T2.K = -4,
             "Step → (39,5,-4)");
      Check (Verify_Triple (L (61), T2), "Verify step 61");

      T := Initial_Triple (L (67));
      --  Wikipedia: start (8,1,-3); m=7 → ...
      Check (T.A = 8 and then T.B = 1 and then T.K = -3,
             "Initial_Triple(67)=(8,1,-3)");
      M := Choose_M (L (67), T.A, T.B, T.K);
      Check (M = 7, "Choose_M for (8,1,-3) N=67 → 7");
   end;

   ------------------------------------------------------------------
   Section ("5. Classic small Pell solutions");
   ------------------------------------------------------------------
   Check_Pell (L (2),  3, 2, "N=2");
   Check_Pell (L (3),  2, 1, "N=3");
   Check_Pell (L (5),  9, 4, "N=5");
   Check_Pell (L (6),  5, 2, "N=6");
   Check_Pell (L (7),  8, 3, "N=7");
   Check_Pell (L (10), 19, 6, "N=10");
   Check_Pell (L (11), 10, 3, "N=11");
   Check_Pell (L (12), 7, 2, "N=12");
   Check_Pell (L (13), 649, 180, "N=13");
   Check_Pell (L (14), 15, 4, "N=14");
   Check_Pell (L (15), 4, 1, "N=15");
   Check_Pell (L (17), 33, 8, "N=17");
   Check_Pell (L (19), 170, 39, "N=19");
   Check_Pell (L (21), 55, 12, "N=21");

   ------------------------------------------------------------------
   Section ("6. Medium / famous demos (fit Long_Integer)");
   ------------------------------------------------------------------
   Check_Pell (L (29), 9801, 1820, "N=29");
   Check_Pell (L (31), 1520, 273, "N=31");
   Check_Pell (L (37), 73, 12, "N=37");
   Check_Pell (L (41), 2049, 320, "N=41");
   Check_Pell (L (46), 24335, 3588, "N=46");
   Check_Pell (L (53), 66249, 9100, "N=53");
   Check_Pell (L (61), 1_766_319_049, 226_153_980, "N=61 Bhāskara");
   Check_Pell (L (67), 48842, 5967, "N=67");
   Check_Pell (L (71), 3480, 413, "N=71");
   Check_Pell (L (97), 62_809_633, 6_377_352, "N=97");

   ------------------------------------------------------------------
   Section ("7. Verify_Pell false negatives / positives");
   ------------------------------------------------------------------
   declare
      Good : constant Pell_Pair := (X => 3, Y => 2);
      Bad  : constant Pell_Pair := (X => 3, Y => 1);
   begin
      Check (Verify_Pell (L (2), Good), "Verify_Pell true");
      Check (not Verify_Pell (L (2), Bad), "Verify_Pell false");
      Check (not Verify_Pell (L (3), Good), "Verify_Pell wrong N");
   end;

   ------------------------------------------------------------------
   Section ("8. Solve_Pell_With_Chain educational");
   ------------------------------------------------------------------
   declare
      R : constant Solve_With_Chain_Result :=
        Solve_Pell_With_Chain (L (61));
   begin
      Check (R.Solution.X = 1_766_319_049, "chain N=61 X");
      Check (R.Solution.Y = 226_153_980, "chain N=61 Y");
      Check (R.Length >= 2, "chain N=61 length>=2");
      Check (R.Chain (1).Triple.A = 8
             and then R.Chain (1).Triple.B = 1
             and then R.Chain (1).Triple.K = 3,
             "chain N=61 first=(8,1,3)");
      Check (R.Chain (1).M = 0, "chain N=61 first M=0");
      Check (R.Chain (2).M = 7, "chain N=61 second M=7");
      Check (R.Chain (2).Triple.A = 39
             and then R.Chain (2).Triple.K = -4,
             "chain N=61 second=(39,5,-4)");
      --  Every recorded triple (except maybe self-comp sentinel path)
      --  should satisfy a² − N b² = k.
      declare
         All_Ok : Boolean := True;
      begin
         for I in 1 .. R.Length loop
            if not Verify_Triple (L (61), R.Chain (I).Triple) then
               All_Ok := False;
            end if;
         end loop;
         Check (All_Ok, "chain N=61 all triples verify");
      end;
      Check (Verify_Pell (L (61), R.Solution), "chain N=61 solution");
   end;

   declare
      R : constant Solve_With_Chain_Result :=
        Solve_Pell_With_Chain (L (2));
   begin
      Check (R.Solution.X = 3 and then R.Solution.Y = 2,
             "chain N=2 solution");
      Check (R.Length >= 1, "chain N=2 nonempty");
      Check (R.Chain (1).Triple.K = -1, "chain N=2 starts k=-1");
   end;

   declare
      R : constant Solve_With_Chain_Result :=
        Solve_Pell_With_Chain (L (13));
   begin
      Check (R.Solution.X = 649 and then R.Solution.Y = 180,
             "chain N=13 solution");
      Check (Verify_Pell (L (13), R.Solution), "chain N=13 verify");
   end;

   ------------------------------------------------------------------
   Section ("9. Batch nonsquare N in 2..40 verify identity");
   ------------------------------------------------------------------
   declare
      All_Ok : Boolean := True;
      P      : Pell_Pair;
      N      : Long_Integer;
   begin
      for I in 2 .. 40 loop
         N := Long_Integer (I);
         if not Is_Perfect_Square (N) then
            P := Solve_Pell (N);
            if not Verify_Pell (N, P) or else P.Y <= 0 then
               All_Ok := False;
               Ada.Text_IO.Put_Line
                 ("    bad N=" & N'Image
                  & " X=" & P.X'Image & " Y=" & P.Y'Image);
            end if;
         end if;
      end loop;
      Check (All_Ok, "all nonsquare N=2..40 satisfy Pell");
   end;

   ------------------------------------------------------------------
   Section ("10. Compose overload on triples");
   ------------------------------------------------------------------
   declare
      T1 : constant Auxiliary_Triple := (A => 3, B => 2, K => 1);
      T2 : constant Auxiliary_Triple := (A => 3, B => 2, K => 1);
      T  : Auxiliary_Triple;
   begin
      T := Compose (L (2), T1, T2);
      Check (T.A = 17 and then T.B = 12 and then T.K = 1,
             "Compose triples overload");
      Check (Verify_Triple (L (2), T), "Compose triples verify");
   end;

   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result: " & Pass_Count'Image & " PASS,"
      & Fail_Count'Image & " FAIL");
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
