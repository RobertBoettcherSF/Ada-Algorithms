--  Standalone test suite for Newton_Raphson_Division (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Text_IO;
with Newton_Raphson_Division; use Newton_Raphson_Division;

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
   Ada.Text_IO.Put_Line ("Newton_Raphson_Division test suite");
   Ada.Text_IO.Put_Line ("==================================");

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
   Section ("2. Exact oracles");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      IR     : Integer_Division_Result;
   begin
      Check (Approx (Exact_Quotient (10.0, 2.0), 5.0), "Exact 10/2");
      Check (Approx (Exact_Quotient (1.0, 3.0), 1.0 / 3.0, 1.0E-15),
             "Exact 1/3");
      Check (Approx (Exact_Quotient (-9.0, 3.0), -3.0), "Exact -9/3");
      Check (Approx (Exact_Reciprocal (2.0), 0.5), "Exact 1/2");
      Check (Approx (Exact_Reciprocal (-4.0), -0.25), "Exact 1/(-4)");

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

      Raised := False;
      begin
         declare
            Unused : Long_Float := Exact_Reciprocal (0.0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Exact_Reciprocal(0) raises");

      IR := Exact_Integer_Divide (17, 5);
      Check (IR.Quotient = 3 and then IR.Remainder = 2, "Exact int 17/5");
      IR := Exact_Integer_Divide (-17, 5);
      Check (IR.Quotient = -3 and then IR.Remainder = -2,
             "Exact int -17/5 (toward zero)");
      IR := Exact_Integer_Divide (17, -5);
      Check (IR.Quotient = -3 and then IR.Remainder = 2,
             "Exact int 17/(-5)");

      Raised := False;
      begin
         declare
            Unused : Integer_Division_Result := Exact_Integer_Divide (1, 0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Exact_Integer_Divide(*,0) raises");
   end;

   ---------------------------------------------------------------------
   Section ("3. Reciprocal_Newton classics");
   ---------------------------------------------------------------------
   declare
      R : Reciprocal_Result;
   begin
      R := Reciprocal_Newton (2.0);
      Check (R.Status = Converged, "1/2 converged");
      Check (Approx (R.Value, 0.5, 1.0E-12), "1/2 = 0.5");
      Check (Approx (2.0 * R.Value, 1.0, 1.0E-12), "D*X=1 for D=2");

      R := Reciprocal_Newton (0.5);
      Check (R.Status = Converged and then Approx (R.Value, 2.0, 1.0E-12),
             "1/0.5 = 2");

      R := Reciprocal_Newton (1.0);
      Check (R.Status = Converged and then Approx (R.Value, 1.0, 1.0E-12),
             "1/1 = 1");

      R := Reciprocal_Newton (4.0);
      Check (R.Status = Converged and then Approx (R.Value, 0.25, 1.0E-12),
             "1/4 = 0.25");

      R := Reciprocal_Newton (10.0);
      Check (R.Status = Converged and then Approx (R.Value, 0.1, 1.0E-12),
             "1/10 = 0.1");

      R := Reciprocal_Newton (3.0);
      Check (R.Status = Converged
               and then Approx (R.Value, Exact_Reciprocal (3.0), 1.0E-12),
             "1/3 vs Exact_Reciprocal");
   end;

   ---------------------------------------------------------------------
   Section ("4. Reciprocal convergence D·X ≈ 1");
   ---------------------------------------------------------------------
   declare
      R      : Reciprocal_Result;
      Ok_All : Boolean := True;
      Args   : constant array (Positive range <>) of Long_Float :=
        [Pi, Pi / 2.0, 3.0 * Pi, Ada.Numerics.e,
         1.414_213_562_37, 2.718_281_828_46, 0.123_456_789,
         1.0E-3, 1.0E3, 7.0, 42.0, 0.25, 16.0];
   begin
      for D of Args loop
         R := Reciprocal_Newton (D);
         if R.Status /= Converged
           or else not Approx (D * R.Value, 1.0, 1.0E-11)
           or else not Approx (R.Value, Exact_Reciprocal (D), 1.0E-12)
         then
            Ok_All := False;
         end if;
      end loop;
      Check (Ok_All, "13 args: converged, D*X≈1, vs Exact_Reciprocal");
   end;

   ---------------------------------------------------------------------
   Section ("5. Reciprocal negatives");
   ---------------------------------------------------------------------
   declare
      R  : Reciprocal_Result;
      Ex : Long_Float;
   begin
      R := Reciprocal_Newton (-2.0);
      Check (R.Status = Converged and then Approx (R.Value, -0.5, 1.0E-12),
             "1/(-2) = -0.5");
      Check (Approx ((-2.0) * R.Value, 1.0, 1.0E-12), "(-2)*X=1");

      R := Reciprocal_Newton (-0.5);
      Check (R.Status = Converged and then Approx (R.Value, -2.0, 1.0E-12),
             "1/(-0.5) = -2");

      R := Reciprocal_Newton (-Pi);
      Ex := Exact_Reciprocal (-Pi);
      Check (R.Status = Converged and then Approx (R.Value, Ex, 1.0E-12),
             "1/(-π) vs oracle");

      R := Reciprocal_Newton (-100.0);
      Check (R.Status = Converged and then Approx (R.Value, -0.01, 1.0E-12),
             "1/(-100) = -0.01");
   end;

   ---------------------------------------------------------------------
   Section ("6. D = 0 rejected");
   ---------------------------------------------------------------------
   declare
      R      : Reciprocal_Result;
      Dr     : Division_Result;
      Raised : Boolean;
   begin
      R := Reciprocal_Newton (0.0);
      Check (R.Status = Bad_Domain, "Reciprocal_Newton(0) Bad_Domain");
      Check (R.Iterations = 0, "zero: Iterations=0");
      Check (R.Value = 0.0, "zero: Value=0");

      Dr := Divide_NR_Detail (5.0, 0.0);
      Check (Dr.Status = Bad_Domain, "Divide_NR_Detail(*,0) Bad_Domain");

      Raised := False;
      begin
         declare
            Unused : Long_Float := Divide_NR (5.0, 0.0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Divide_NR(*,0) raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Unused : Integer_Division_Result :=
              Divide_Integer_Toward_Zero (5, 0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Divide_Integer_Toward_Zero(*,0) raises");

      Raised := False;
      begin
         declare
            Unused : Integer_Division_Result :=
              Divide_Integer_Floor (5, 0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Divide_Integer_Floor(*,0) raises");
   end;

   ---------------------------------------------------------------------
   Section ("7. Divide_NR vs Exact_Quotient (Float)");
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
         (-Pi, 3.0), (Pi, -3.0), (0.0, 5.0), (5.0, 5.0)];
      Dr     : Division_Result;
      Q, Ex  : Long_Float;
      Ok_All : Boolean := True;
   begin
      for C of Cases loop
         Dr := Divide_NR_Detail (C.N, C.D);
         Ex := Exact_Quotient (C.N, C.D);
         Q  := Divide_NR (C.N, C.D);
         if Dr.Status /= Converged
           or else not Approx (Dr.Quotient, Ex, 1.0E-10)
           or else not Approx (C.D * Dr.Reciprocal, 1.0, 1.0E-11)
           or else not Approx (Q, Ex, 1.0E-10)
         then
            Ok_All := False;
         end if;
      end loop;
      Check (Ok_All, "17 Float pairs: Detail+Divide_NR vs Exact");
      --  Spot checks
      Check (Approx (Divide_NR (10.0, 2.0), 5.0, 1.0E-12), "10/2 = 5");
      Check (Approx (Divide_NR (1.0, 3.0), 1.0 / 3.0, 1.0E-12), "1/3");
      Check (Approx (Divide_NR (-10.0, 2.0), -5.0, 1.0E-12), "-10/2");
      Check (Approx (Divide_NR (10.0, -2.0), -5.0, 1.0E-12), "10/(-2)");
      Check (Approx (Divide_NR (-10.0, -2.0), 5.0, 1.0E-12), "(-10)/(-2)");
   end;

   ---------------------------------------------------------------------
   Section ("8. Iteration counts (quadratic / digit doubling)");
   ---------------------------------------------------------------------
   declare
      R : Reciprocal_Result;
   begin
      R := Reciprocal_Newton (2.0);
      Check (R.Status = Converged and then R.Iterations >= 1, "iters ≥ 1");
      Check (R.Iterations <= 20, "iters ≤ 20 for D=2");

      R := Reciprocal_Newton (1.0E6);
      Check (R.Status = Converged, "large D=1e6 converged");
      Check (Approx (R.Value, 1.0E-6, 1.0E-15), "1/1e6");
      Check (R.Iterations <= 25, "iters modest for 1e6");

      R := Reciprocal_Newton (0.001);
      Check (R.Status = Converged and then R.Iterations <= 25,
             "small D=0.001 modest iters");

      --  Tight tol still finishes quickly (quadratic digit doubling).
      R := Reciprocal_Newton (7.0, Tol => 1.0E-14);
      Check (R.Status = Converged and then R.Iterations <= 30,
             "tight tol still ≤ 30 iters");
      Check (Approx (7.0 * R.Value, 1.0, 1.0E-13), "tight: D*X≈1");
   end;

   ---------------------------------------------------------------------
   Section ("9. Integer toward-zero wrapper vs oracle");
   ---------------------------------------------------------------------
   declare
      type IPair is record
         N, D : Integer;
      end record;
      Cases  : constant array (Positive range <>) of IPair :=
        [(17, 5), (100, 7), (22, 7), (1, 1), (0, 5), (5, 5),
         (10, 3), (99, 10), (8, 2), (7, 2), (1, 2), (1000, 13),
         (-17, 5), (17, -5), (-17, -5), (-10, 3), (10, -3),
         (-22, 7), (22, -7), (-100, 7), (0, -3), (-1, 2),
         (1, -2), (-8, 3), (8, -3)];
      Got, Exp : Integer_Division_Result;
      Ok_All   : Boolean := True;
   begin
      for C of Cases loop
         Got := Divide_Integer_Toward_Zero (C.N, C.D);
         Exp := Exact_Integer_Divide (C.N, C.D);
         if Got.Quotient /= Exp.Quotient
           or else Got.Remainder /= Exp.Remainder
           or else C.N /= Got.Quotient * C.D + Got.Remainder
           or else (Got.Remainder /= 0
                      and then abs (Got.Remainder) >= abs (C.D))
         then
            Ok_All := False;
         end if;
      end loop;
      Check (Ok_All, "25 int pairs TZ vs oracle + identity");
      Got := Divide_Integer_Toward_Zero (17, 5);
      Check (Got.Quotient = 3 and then Got.Remainder = 2, "TZ 17/5 -> 3 R2");
      Got := Divide_Integer_Toward_Zero (-17, 5);
      Check (Got.Quotient = -3 and then Got.Remainder = -2,
             "TZ -17/5 -> -3 R-2");
      Got := Divide_Integer_Toward_Zero (17, -5);
      Check (Got.Quotient = -3 and then Got.Remainder = 2,
             "TZ 17/(-5) -> -3 R2");
   end;

   ---------------------------------------------------------------------
   Section ("10. Integer floor wrapper + identity");
   ---------------------------------------------------------------------
   declare
      type IPair is record
         N, D : Integer;
      end record;
      Cases  : constant array (Positive range <>) of IPair :=
        [(17, 5), (100, 7), (22, 7), (1, 1), (0, 5),
         (10, 3), (99, 10), (7, 2), (1, 2),
         (-17, 5), (-10, 3), (-22, 7), (-1, 2), (-8, 3),
         (17, -5), (10, -3), (22, -7), (1, -2), (8, -3),
         (-17, -5), (-10, -3)];
      Got    : Integer_Division_Result;
      Qf     : Long_Float;
      Ok_All : Boolean := True;
      Rem_Ok : Boolean;
   begin
      for C of Cases loop
         Got := Divide_Integer_Floor (C.N, C.D);
         Qf  := Long_Float (C.N) / Long_Float (C.D);
         if C.D > 0 then
            Rem_Ok := Got.Remainder >= 0 and then Got.Remainder < C.D;
         else
            Rem_Ok := Got.Remainder <= 0 and then Got.Remainder > C.D;
         end if;
         if C.N /= Got.Quotient * C.D + Got.Remainder
           or else not Rem_Ok
           or else not Approx (Long_Float (Got.Quotient),
                               Long_Float'Floor (Qf), 1.0E-9)
         then
            Ok_All := False;
         end if;
      end loop;
      Check (Ok_All, "21 int pairs Floor identity + range + floor(Q)");
      Got := Divide_Integer_Floor (17, 5);
      Check (Got.Quotient = 3 and then Got.Remainder = 2, "Floor 17/5");
      Got := Divide_Integer_Floor (-17, 5);
      Check (Got.Quotient = -4 and then Got.Remainder = 3,
             "Floor -17/5 -> -4 R3");
      Got := Divide_Integer_Floor (17, -5);
      Check (Got.Quotient = -4 and then Got.Remainder = -3,
             "Floor 17/(-5) -> -4 R-3");
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
         Dr := Divide_NR_Detail (N, D);
         Ex := Exact_Quotient (N, D);
         if Dr.Status /= Converged
           or else not Approx (Dr.Quotient, Ex, 1.0E-9)
         then
            Ok_All := False;
         end if;
      end loop;
      Check (Ok_All, "40 scattered Float divisions vs oracle");
   end;

   ---------------------------------------------------------------------
   Section ("12. Scattered Integer toward-zero batch");
   ---------------------------------------------------------------------
   declare
      Ok_All : Boolean := True;
      Got, Exp : Integer_Division_Result;
      N, D     : Integer;
   begin
      for A in -20 .. 20 loop
         for B in -10 .. 10 loop
            if B /= 0 then
               N := A;
               D := B;
               Got := Divide_Integer_Toward_Zero (N, D);
               Exp := Exact_Integer_Divide (N, D);
               if Got.Quotient /= Exp.Quotient
                 or else Got.Remainder /= Exp.Remainder
                 or else N /= Got.Quotient * D + Got.Remainder
               then
                  Ok_All := False;
               end if;
            end if;
         end loop;
      end loop;
      Check (Ok_All, "Integer TZ grid [-20..20]×[-10..10]\\{0}");
   end;

   ---------------------------------------------------------------------
   Section ("13. Digit-doubling / residual shrink");
   ---------------------------------------------------------------------
   declare
      --  One manual Newton step from the linear seed should square error.
      --  Non-constants so -gnatwa does not fold the predicates.
      D, X0, X1, X2, E0, E1, E2 : Long_Float;
      R : Reciprocal_Result;
   begin
      D  := 0.7;  -- already in [0.5,1)
      X0 := (48.0 - 32.0 * D) / 17.0;
      E0 := abs (1.0 - D * X0);
      X1 := X0 * (2.0 - D * X0);
      E1 := abs (1.0 - D * X1);
      X2 := X1 * (2.0 - D * X1);
      E2 := abs (1.0 - D * X2);
      Check (E0 > 0.0 and then E0 < 0.1, "seed |ε0| < 0.1 on [1/2,1]");
      Check (E1 <= E0 * E0 + 1.0E-15, "one step: |ε1| ≤ |ε0|²");
      Check (E2 <= E1 * E1 + 1.0E-18, "two steps: |ε2| ≤ |ε1|²");
      Check (E1 < E0, "residual shrinks after step 1");
      Check (E2 < E1, "residual shrinks after step 2");
      R := Reciprocal_Newton (D);
      Check (R.Status = Converged, "D=0.7 converged");
      Check (Approx (D * R.Value, 1.0, 1.0E-12), "D=0.7 product ≈ 1");
      Check (R.Iterations <= 10, "D=0.7 few iters (digit doubling)");
   end;

   ---------------------------------------------------------------------
   Section ("14. Divide_NR_Detail fields");
   ---------------------------------------------------------------------
   declare
      Dr : Division_Result;
   begin
      Dr := Divide_NR_Detail (15.0, 3.0);
      Check (Dr.Status = Converged, "15/3 detail status");
      Check (Approx (Dr.Quotient, 5.0, 1.0E-12), "15/3 = 5");
      Check (Approx (Dr.Reciprocal, 1.0 / 3.0, 1.0E-12), "recip 1/3");
      Check (Dr.Iterations >= 1 and then Dr.Iterations <= 30,
             "15/3 iters in range");

      Dr := Divide_NR_Detail (-15.0, 3.0);
      Check (Approx (Dr.Quotient, -5.0, 1.0E-12), "-15/3 = -5");
      Dr := Divide_NR_Detail (15.0, -3.0);
      Check (Approx (Dr.Quotient, -5.0, 1.0E-12), "15/(-3) = -5");
      Dr := Divide_NR_Detail (-15.0, -3.0);
      Check (Approx (Dr.Quotient, 5.0, 1.0E-12), "(-15)/(-3) = 5");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("==================================");
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
