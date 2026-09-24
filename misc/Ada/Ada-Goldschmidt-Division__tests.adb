--  Standalone test suite for Goldschmidt_Division (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Text_IO;
with Goldschmidt_Division; use Goldschmidt_Division;

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

   function Approx
     (A, B : Long_Float; Tol : Long_Float := 1.0E-9) return Boolean
   is
   begin
      return abs (A - B) <= Tol
        or else abs (A - B) <= Tol * (1.0 + abs (B));
   end Approx;

   Pi : constant Long_Float := Ada.Numerics.Pi;

begin
   Ada.Text_IO.Put_Line ("Goldschmidt_Division test suite");
   Ada.Text_IO.Put_Line ("===============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Abs_Error / Rel_Error helpers");
   ---------------------------------------------------------------------
   declare
      E : Long_Float;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects far");
      Check (Near (0.0, 0.0), "Near zeros");
      E := Abs_Error (3.0, 1.0);
      Check (Approx (E, 2.0), "Abs_Error 3-1");
      Check (Approx (Abs_Error (1.0, 1.0), 0.0), "Abs_Error zero");
      Check (Approx (Abs_Error (-1.0, 1.0), 2.0), "Abs_Error signed");
      Check (Approx (Rel_Error (1.001, 1.0), 0.001, 1.0E-12),
             "Rel_Error 0.1%");
      Check (Approx (Rel_Error (2.0, 0.0), 2.0), "Rel_Error Exact=0");
      Check (Approx (Rel_Error (-2.0, -1.0), 1.0), "Rel_Error negatives");
   end;

   ---------------------------------------------------------------------
   Section ("2. Exact_Quotient oracle");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Check (Approx (Exact_Quotient (10.0, 2.0), 5.0), "Exact 10/2");
      Check (Approx (Exact_Quotient (1.0, 3.0), 1.0 / 3.0, 1.0E-15),
             "Exact 1/3");
      Check (Approx (Exact_Quotient (-9.0, 3.0), -3.0), "Exact -9/3");
      Check (Approx (Exact_Quotient (9.0, -3.0), -3.0), "Exact 9/(-3)");
      Check (Approx (Exact_Quotient (-9.0, -3.0), 3.0), "Exact (-9)/(-3)");
      Check (Approx (Exact_Quotient (0.0, 5.0), 0.0), "Exact 0/5");

      Raised := False;
      begin
         declare
            Unused : Long_Float := Exact_Quotient (1.0, 0.0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Exact_Quotient(*,0) raises");
   end;

   ---------------------------------------------------------------------
   Section ("3. Classic Divide_Goldschmidt quotients");
   ---------------------------------------------------------------------
   declare
      Q  : Long_Float;
      Dr : Division_Result;
   begin
      Q := Divide_Goldschmidt (10.0, 2.0);
      Check (Approx (Q, 5.0, 1.0E-12), "10/2 = 5");

      Q := Divide_Goldschmidt (1.0, 3.0);
      Check (Approx (Q, 1.0 / 3.0, 1.0E-12), "1/3");

      Q := Divide_Goldschmidt (15.0, 3.0);
      Check (Approx (Q, 5.0, 1.0E-12), "15/3 = 5");

      Q := Divide_Goldschmidt (22.0, 7.0);
      Check (Approx (Q, Exact_Quotient (22.0, 7.0), 1.0E-12), "22/7");

      Q := Divide_Goldschmidt (1.0, 1.0);
      Check (Approx (Q, 1.0, 1.0E-12), "1/1 = 1");

      Q := Divide_Goldschmidt (0.5, 0.25);
      Check (Approx (Q, 2.0, 1.0E-12), "0.5/0.25 = 2");

      Dr := Divide_Goldschmidt_Detail (100.0, 7.0);
      Check (Dr.Status = Converged, "100/7 converged");
      Check (Approx (Dr.Quotient, Exact_Quotient (100.0, 7.0), 1.0E-11),
             "100/7 vs oracle");
   end;

   ---------------------------------------------------------------------
   Section ("4. D → 1 convergence (Final_Denom)");
   ---------------------------------------------------------------------
   declare
      Dr     : Division_Result;
      Ok_All : Boolean := True;
      Args   : constant array (Positive range <>) of Long_Float :=
        [2.0, 0.5, 3.0, 4.0, 10.0, 0.75, 0.9, 1.0,
         Pi, Pi / 2.0, Ada.Numerics.e, 1.414_213_562_37,
         0.123_456_789, 1.0E-3, 1.0E3, 7.0, 42.0, 16.0];
   begin
      for D of Args loop
         Dr := Divide_Goldschmidt_Detail (1.0, D);
         if Dr.Status /= Converged
           or else not Approx (Dr.Final_Denom, 1.0, 1.0E-11)
           or else not Approx (Dr.Quotient, Exact_Quotient (1.0, D), 1.0E-11)
         then
            Ok_All := False;
         end if;
      end loop;
      Check (Ok_All, "18 divisors: Final_Denom≈1 and Q vs Exact");

      Dr := Divide_Goldschmidt_Detail (7.0, 2.0);
      Check (Approx (Dr.Final_Denom, 1.0, 1.0E-12), "7/2: D_k ≈ 1");
      Check (Dr.Iterations <= 40, "7/2: modest iteration count");
      Check (Dr.Status = Converged, "7/2: status Converged");
   end;

   ---------------------------------------------------------------------
   Section ("5. Negatives (all sign combinations)");
   ---------------------------------------------------------------------
   declare
      Q  : Long_Float;
      Dr : Division_Result;
   begin
      Q := Divide_Goldschmidt (-10.0, 2.0);
      Check (Approx (Q, -5.0, 1.0E-12), "-10/2 = -5");

      Q := Divide_Goldschmidt (10.0, -2.0);
      Check (Approx (Q, -5.0, 1.0E-12), "10/(-2) = -5");

      Q := Divide_Goldschmidt (-10.0, -2.0);
      Check (Approx (Q, 5.0, 1.0E-12), "(-10)/(-2) = 5");

      Q := Divide_Goldschmidt (-Pi, 3.0);
      Check (Approx (Q, Exact_Quotient (-Pi, 3.0), 1.0E-11), "-π/3");

      Q := Divide_Goldschmidt (Pi, -3.0);
      Check (Approx (Q, Exact_Quotient (Pi, -3.0), 1.0E-11), "π/(-3)");

      Q := Divide_Goldschmidt (-Pi, -3.0);
      Check (Approx (Q, Exact_Quotient (-Pi, -3.0), 1.0E-11), "(-π)/(-3)");

      Dr := Divide_Goldschmidt_Detail (-15.0, 3.0);
      Check (Dr.Status = Converged
               and then Approx (Dr.Quotient, -5.0, 1.0E-12),
             "Detail -15/3");
      Check (Approx (Dr.Final_Denom, 1.0, 1.0E-12),
             "Detail -15/3 Final_Denom≈1");

      Dr := Divide_Goldschmidt_Detail (15.0, -3.0);
      Check (Approx (Dr.Quotient, -5.0, 1.0E-12), "Detail 15/(-3)");

      Dr := Divide_Goldschmidt_Detail (-15.0, -3.0);
      Check (Approx (Dr.Quotient, 5.0, 1.0E-12), "Detail (-15)/(-3)");
   end;

   ---------------------------------------------------------------------
   Section ("6. D = 0 rejected");
   ---------------------------------------------------------------------
   declare
      Dr     : Division_Result;
      Raised : Boolean;
   begin
      Dr := Divide_Goldschmidt_Detail (5.0, 0.0);
      Check (Dr.Status = Bad_Domain, "Detail(*,0) Bad_Domain");
      Check (Dr.Iterations = 0, "zero: Iterations=0");
      Check (Dr.Quotient = 0.0, "zero: Quotient=0");
      Check (Dr.Final_Denom = 0.0, "zero: Final_Denom=0");

      Dr := Divide_Goldschmidt_Detail (0.0, 0.0);
      Check (Dr.Status = Bad_Domain, "Detail(0,0) Bad_Domain");

      Raised := False;
      begin
         declare
            Unused : Long_Float := Divide_Goldschmidt (5.0, 0.0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Divide_Goldschmidt(*,0) raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Unused : Long_Float := Divide_Goldschmidt (-1.0, 0.0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Divide_Goldschmidt(-1,0) raises");
   end;

   ---------------------------------------------------------------------
   Section ("7. Divide_Goldschmidt vs Exact_Quotient (batch)");
   ---------------------------------------------------------------------
   declare
      type Pair is record
         N, D : Long_Float;
      end record;
      Cases  : constant array (Positive range <>) of Pair :=
        [(10.0, 2.0), (1.0, 3.0), (100.0, 7.0), (22.0, 7.0),
         (Pi, 2.0), (1.0, Pi), (Ada.Numerics.e, Pi),
         (0.5, 0.25), (123.456, 7.89), (1.0E6, 3.0),
         (-10.0, 2.0), (10.0, -2.0), (-10.0, -2.0),
         (-Pi, 3.0), (Pi, -3.0), (0.0, 5.0), (5.0, 5.0),
         (8.0, 0.5), (0.001, 0.003), (1.0E-6, 2.0),
         (2.5, 0.125), (99.0, 11.0), (-42.0, 7.0)];
      Dr     : Division_Result;
      Q, Ex  : Long_Float;
      Ok_All : Boolean := True;
   begin
      for C of Cases loop
         Dr := Divide_Goldschmidt_Detail (C.N, C.D);
         Ex := Exact_Quotient (C.N, C.D);
         Q  := Divide_Goldschmidt (C.N, C.D);
         if Dr.Status /= Converged
           or else not Approx (Dr.Quotient, Ex, 1.0E-10)
           or else not Approx (Dr.Final_Denom, 1.0, 1.0E-10)
           or else not Approx (Q, Ex, 1.0E-10)
         then
            Ok_All := False;
         end if;
      end loop;
      Check (Ok_All, "23 Float pairs: Detail+Divide vs Exact, D→1");
      Check (Approx (Divide_Goldschmidt (10.0, 2.0), 5.0, 1.0E-12),
             "spot 10/2");
      Check (Approx (Divide_Goldschmidt (1.0, 3.0), 1.0 / 3.0, 1.0E-12),
             "spot 1/3");
      Check (Approx (Divide_Goldschmidt (-10.0, 2.0), -5.0, 1.0E-12),
             "spot -10/2");
      Check (Approx (Divide_Goldschmidt (10.0, -2.0), -5.0, 1.0E-12),
             "spot 10/(-2)");
      Check (Approx (Divide_Goldschmidt (-10.0, -2.0), 5.0, 1.0E-12),
             "spot (-10)/(-2)");
   end;

   ---------------------------------------------------------------------
   Section ("8. Several magnitudes");
   ---------------------------------------------------------------------
   declare
      Dr : Division_Result;
      Ex : Long_Float;
   begin
      Dr := Divide_Goldschmidt_Detail (1.0E12, 1.0E6);
      Ex := Exact_Quotient (1.0E12, 1.0E6);
      Check (Dr.Status = Converged and then Approx (Dr.Quotient, Ex, 1.0E-8),
             "1e12/1e6");

      Dr := Divide_Goldschmidt_Detail (1.0E-8, 1.0E-4);
      Ex := Exact_Quotient (1.0E-8, 1.0E-4);
      Check (Dr.Status = Converged and then Approx (Dr.Quotient, Ex, 1.0E-10),
             "1e-8/1e-4");

      Dr := Divide_Goldschmidt_Detail (1.0E9, 3.0);
      Check (Dr.Status = Converged
               and then Approx (Dr.Quotient,
                                Exact_Quotient (1.0E9, 3.0), 1.0E-6),
             "1e9/3");

      Dr := Divide_Goldschmidt_Detail (3.0, 1.0E9);
      Check (Dr.Status = Converged
               and then Approx (Dr.Quotient,
                                Exact_Quotient (3.0, 1.0E9), 1.0E-15),
             "3/1e9");

      Dr := Divide_Goldschmidt_Detail (1.0E-6, 1.0E6);
      Check (Dr.Status = Converged
               and then Approx (Dr.Quotient,
                                Exact_Quotient (1.0E-6, 1.0E6), 1.0E-18),
             "1e-6/1e6");

      Dr := Divide_Goldschmidt_Detail (7.0, 0.001);
      Check (Dr.Status = Converged
               and then Approx (Dr.Quotient, 7000.0, 1.0E-8),
             "7/0.001 = 7000");
   end;

   ---------------------------------------------------------------------
   Section ("9. Iteration counts (quadratic D→1)");
   ---------------------------------------------------------------------
   declare
      Dr : Division_Result;
   begin
      Dr := Divide_Goldschmidt_Detail (2.0, 2.0);
      Check (Dr.Status = Converged, "2/2 converged");
      Check (Dr.Iterations <= 20, "2/2 iters ≤ 20");
      Check (Approx (Dr.Quotient, 1.0, 1.0E-12), "2/2 = 1");

      Dr := Divide_Goldschmidt_Detail (1.0, 1.0E6);
      Check (Dr.Status = Converged, "1/1e6 converged");
      Check (Dr.Iterations <= 30, "1/1e6 modest iters");

      Dr := Divide_Goldschmidt_Detail (1.0, 0.001);
      Check (Dr.Status = Converged and then Dr.Iterations <= 30,
             "1/0.001 modest iters");

      Dr := Divide_Goldschmidt_Detail (7.0, 3.0, Tol => 1.0E-14);
      Check (Dr.Status = Converged and then Dr.Iterations <= 40,
             "tight tol still ≤ 40 iters");
      Check (Approx (Dr.Final_Denom, 1.0, 1.0E-13), "tight: D_k≈1");
      Check (Approx (Dr.Quotient, Exact_Quotient (7.0, 3.0), 1.0E-13),
             "tight: Q vs Exact");
   end;

   ---------------------------------------------------------------------
   Section ("10. Manual F=2−D residual shrink");
   ---------------------------------------------------------------------
   declare
      --  After normalize into (1/2,1], one Goldschmidt step squares error.
      D, N, F, E0, E1, E2 : Long_Float;
      Dr : Division_Result;
   begin
      D  := 0.7;
      N  := 1.0;
      E0 := abs (D - 1.0);
      F  := 2.0 - D;
      N  := N * F;
      D  := D * F;
      E1 := abs (D - 1.0);
      F  := 2.0 - D;
      N  := N * F;
      D  := D * F;
      E2 := abs (D - 1.0);

      Check (E0 > 0.0 and then E0 < 0.5, "seed |D−1| < 0.5 on (1/2,1]");
      Check (E1 < E0, "residual shrinks after step 1");
      Check (E2 < E1, "residual shrinks after step 2");
      --  With ε = 1 − D, F = 2 − D = 1 + ε, new D = D(1+ε) = (1−ε)(1+ε) = 1−ε²
      --  so |1 − D_new| = ε² when D ∈ (0,1].
      Check (E1 <= E0 * E0 + 1.0E-15, "one step: |ε1| ≤ |ε0|²");
      Check (E2 <= E1 * E1 + 1.0E-18, "two steps: |ε2| ≤ |ε1|²");

      Dr := Divide_Goldschmidt_Detail (1.0, 0.7);
      Check (Dr.Status = Converged, "1/0.7 converged");
      Check (Approx (Dr.Final_Denom, 1.0, 1.0E-12), "1/0.7 D_k≈1");
      Check (Approx (Dr.Quotient, Exact_Quotient (1.0, 0.7), 1.0E-12),
             "1/0.7 vs Exact");
      Check (Dr.Iterations <= 10, "1/0.7 few iters (digit doubling)");
   end;

   ---------------------------------------------------------------------
   Section ("11. Scattered Float divisions batch");
   ---------------------------------------------------------------------
   declare
      Ok_All : Boolean := True;
      Dr     : Division_Result;
      N, D   : Long_Float;
      Ex     : Long_Float;
   begin
      for K in 1 .. 40 loop
         N := Long_Float (K) * 1.7 - 20.0;
         D := Long_Float (K) * 0.31 - 5.0;
         if D = 0.0 then
            D := 0.5;
         end if;
         Dr := Divide_Goldschmidt_Detail (N, D);
         Ex := Exact_Quotient (N, D);
         if Dr.Status /= Converged
           or else not Approx (Dr.Quotient, Ex, 1.0E-9)
           or else not Approx (Dr.Final_Denom, 1.0, 1.0E-9)
         then
            Ok_All := False;
         end if;
      end loop;
      Check (Ok_All, "40 scattered Float divisions vs oracle");
   end;

   ---------------------------------------------------------------------
   Section ("12. Divide_Goldschmidt_Detail fields");
   ---------------------------------------------------------------------
   declare
      Dr : Division_Result;
   begin
      Dr := Divide_Goldschmidt_Detail (15.0, 3.0);
      Check (Dr.Status = Converged, "15/3 detail status");
      Check (Approx (Dr.Quotient, 5.0, 1.0E-12), "15/3 = 5");
      Check (Approx (Dr.Final_Denom, 1.0, 1.0E-12), "15/3 Final_Denom");
      Check (Dr.Iterations <= 30, "15/3 iters ≤ 30");

      Dr := Divide_Goldschmidt_Detail (-15.0, 3.0);
      Check (Approx (Dr.Quotient, -5.0, 1.0E-12), "-15/3 = -5");
      Dr := Divide_Goldschmidt_Detail (15.0, -3.0);
      Check (Approx (Dr.Quotient, -5.0, 1.0E-12), "15/(-3) = -5");
      Dr := Divide_Goldschmidt_Detail (-15.0, -3.0);
      Check (Approx (Dr.Quotient, 5.0, 1.0E-12), "(-15)/(-3) = 5");

      Dr := Divide_Goldschmidt_Detail (0.0, 5.0);
      Check (Dr.Status = Converged and then Approx (Dr.Quotient, 0.0),
             "0/5 = 0");
   end;

   ---------------------------------------------------------------------
   Section ("13. Power-of-two divisors (normalize edge)");
   ---------------------------------------------------------------------
   declare
      Dr : Division_Result;
   begin
      Dr := Divide_Goldschmidt_Detail (8.0, 4.0);
      Check (Dr.Status = Converged and then Approx (Dr.Quotient, 2.0),
             "8/4 = 2");
      Check (Approx (Dr.Final_Denom, 1.0, 1.0E-12), "8/4 D_k≈1");

      Dr := Divide_Goldschmidt_Detail (1.0, 8.0);
      Check (Approx (Dr.Quotient, 0.125, 1.0E-12), "1/8 = 0.125");

      Dr := Divide_Goldschmidt_Detail (16.0, 0.5);
      Check (Approx (Dr.Quotient, 32.0, 1.0E-12), "16/0.5 = 32");

      Dr := Divide_Goldschmidt_Detail (3.0, 1.0);
      Check (Dr.Status = Converged and then Approx (Dr.Quotient, 3.0),
             "3/1 = 3 (already unit denom after normalize)");
   end;

   ---------------------------------------------------------------------
   Section ("14. Rel_Error vs oracle on varied set");
   ---------------------------------------------------------------------
   declare
      Ok_All : Boolean := True;
      Q, Ex  : Long_Float;
      type Pair is record
         N, D : Long_Float;
      end record;
      Cases : constant array (Positive range <>) of Pair :=
        [(Pi, Ada.Numerics.e), (Ada.Numerics.e, Pi),
         (1.234_567_89, 9.876_543_21), (100.0, Pi),
         (-50.0, 8.0), (50.0, -8.0), (-50.0, -8.0),
         (0.01, 0.07), (1.0E4, 1.0E2), (9.0, 11.0)];
   begin
      for C of Cases loop
         Q  := Divide_Goldschmidt (C.N, C.D);
         Ex := Exact_Quotient (C.N, C.D);
         if Rel_Error (Q, Ex) > 1.0E-10 then
            Ok_All := False;
         end if;
      end loop;
      Check (Ok_All, "10 pairs Rel_Error < 1e-10");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("===============================");
   Ada.Text_IO.Put_Line
     ("Passed:" & Natural'Image (Pass_Count)
      & "  Failed:" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
