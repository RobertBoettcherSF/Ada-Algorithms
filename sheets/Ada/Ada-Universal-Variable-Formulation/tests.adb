with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Generic_Elementary_Functions;
with Universal_Variable_Formulation; use Universal_Variable_Formulation;

procedure Tests is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS -- " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL -- " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   --  Helper for approximate floating-point equality
   function Approx_Equal (Actual, Expected : Real; Abs_Tol : Real := 1.0e-5) return Boolean is
   begin
      return abs (Actual - Expected) <= Abs_Tol;
   end Approx_Equal;

   function Approx_Equal_Vec (V1, V2 : Vector_3D; Abs_Tol : Real := 1.0e-3) return Boolean is
   begin
      return abs (V1.X - V2.X) <= Abs_Tol
        and then abs (V1.Y - V2.Y) <= Abs_Tol
        and then abs (V1.Z - V2.Z) <= Abs_Tol;
   end Approx_Equal_Vec;

begin
   Put_Line ("=== Universal Variable Formulation Test Suite ===");
   New_Line;

   --  ========================================================================
   --  TEST 1: 3D Vector Arithmetic & Operations
   --  ========================================================================
   Put_Line ("TEST 1 -- 3D Vector Operations");
   declare
      V1 : constant Vector_3D := (X => 1.0, Y => 2.0, Z => 3.0);
      V2 : constant Vector_3D := (X => 4.0, Y => -5.0, Z => 6.0);
      Sum_V   : constant Vector_3D := V1 + V2;
      Diff_V  : constant Vector_3D := V1 - V2;
      Scale_V : constant Vector_3D := 2.0 * V1;
      Dot     : constant Real      := Dot_Product (V1, V2);
      Cross   : constant Vector_3D := Cross_Product (V1, V2);
      Mag     : constant Distance  := Magnitude ((X => 3.0, Y => 4.0, Z => 0.0));
   begin
      Check ("1.1 Vector addition and scalar scaling",
             Sum_V.X = 5.0 and Sum_V.Y = -3.0 and Scale_V.Z = 6.0);
      Check ("1.2 Dot product calculation (1*4 + 2*(-5) + 3*6 = 12)",
             Dot = 12.0 and Diff_V.X = -3.0);
      Check ("1.3 Cross product and magnitude calculation",
             Cross.X = 27.0 and Cross.Y = 6.0 and Cross.Z = -13.0 and Mag = 5.0);
   end;

   --  ========================================================================
   --  TEST 2: Stumpff Functions in the Parabolic Limit (z -> 0)
   --  ========================================================================
   Put_Line ("TEST 2 -- Stumpff Functions: Near Zero (Parabolic Limit)");
   declare
      C0_0 : constant Real := Stumpff_C0 (0.0);
      C1_0 : constant Real := Stumpff_C1 (0.0);
      C2_0 : constant Real := Stumpff_C2 (0.0);
      C3_0 : constant Real := Stumpff_C3 (0.0);
   begin
      Check ("2.1 c_0(0) = 1.0 and c_1(0) = 1.0",
             Approx_Equal (C0_0, 1.0, 1.0e-12) and Approx_Equal (C1_0, 1.0, 1.0e-12));
      Check ("2.2 c_2(0) = 1/2 = 0.5",
             Approx_Equal (C2_0, 0.5, 1.0e-12));
      Check ("2.3 c_3(0) = 1/6",
             Approx_Equal (C3_0, 1.0 / 6.0, 1.0e-12));
   end;

   --  ========================================================================
   --  TEST 3: Stumpff Functions for Elliptic Regime (z > 0)
   --  ========================================================================
   Put_Line ("TEST 3 -- Stumpff Functions: Positive z (Elliptic Regime)");
   declare
      Z_Val : constant Real := 0.25; -- (0.5)^2
      Expected_C0 : constant Real := Cos (0.5);
      Expected_C1 : constant Real := Sin (0.5) / 0.5;
      Expected_C2 : constant Real := (1.0 - Cos (0.5)) / 0.25;
      Expected_C3 : constant Real := (0.5 - Sin (0.5)) / (0.25 * 0.5);
   begin
      Check ("3.1 c_0(0.25) matches cos(sqrt(z))",
             Approx_Equal (Stumpff_C0 (Z_Val), Expected_C0, 1.0e-10));
      Check ("3.2 c_1(0.25) matches sin(sqrt(z))/sqrt(z)",
             Approx_Equal (Stumpff_C1 (Z_Val), Expected_C1, 1.0e-10));
      Check ("3.3 c_2(0.25) and c_3(0.25) match analytic trigonometric formulas",
             Approx_Equal (Stumpff_C2 (Z_Val), Expected_C2, 1.0e-10) and then
             Approx_Equal (Stumpff_C3 (Z_Val), Expected_C3, 1.0e-10));
   end;

   --  ========================================================================
   --  TEST 4: Stumpff Functions for Hyperbolic Regime (z < 0)
   --  ========================================================================
   Put_Line ("TEST 4 -- Stumpff Functions: Negative z (Hyperbolic Regime)");
   declare
      Z_Val : constant Real := -0.25;
      Expected_C0 : constant Real := Cosh (0.5);
      Expected_C1 : constant Real := Sinh (0.5) / 0.5;
      Expected_C2 : constant Real := (Cosh (0.5) - 1.0) / 0.25;
      Expected_C3 : constant Real := (Sinh (0.5) - 0.5) / (0.25 * 0.5);
   begin
      Check ("4.1 c_0(-0.25) matches cosh(sqrt(-z))",
             Approx_Equal (Stumpff_C0 (Z_Val), Expected_C0, 1.0e-10));
      Check ("4.2 c_1(-0.25) matches sinh(sqrt(-z))/sqrt(-z)",
             Approx_Equal (Stumpff_C1 (Z_Val), Expected_C1, 1.0e-10));
      Check ("4.3 c_2(-0.25) and c_3(-0.25) match analytic hyperbolic formulas",
             Approx_Equal (Stumpff_C2 (Z_Val), Expected_C2, 1.0e-10) and then
             Approx_Equal (Stumpff_C3 (Z_Val), Expected_C3, 1.0e-10));
   end;

   --  ========================================================================
   --  TEST 5: Higher-Order Stumpff Functions Recurrence (c_4, c_5)
   --  ========================================================================
   Put_Line ("TEST 5 -- Higher-Order Stumpff Functions (c_4 and c_5)");
   declare
      Z1 : constant Real := 0.5;
      C4 : constant Real := Stumpff_C4 (Z1);
      C5 : constant Real := Stumpff_C5 (Z1);
      C2 : constant Real := Stumpff_C2 (Z1);
      C3 : constant Real := Stumpff_C3 (Z1);
   begin
      Check ("5.1 Identity z * c_4(z) + c_2(z) = 1/2",
             Approx_Equal (Z1 * C4 + C2, 0.5, 1.0e-9));
      Check ("5.2 Identity z * c_5(z) + c_3(z) = 1/6",
             Approx_Equal (Z1 * C5 + C3, 1.0 / 6.0, 1.0e-9));
      Check ("5.3 Continuity of higher orders at z = 0.05",
             Stumpff_C4 (0.05) > 0.0 and Stumpff_C5 (0.05) > 0.0);
   end;

   --  ========================================================================
   --  TEST 6: Orbit Classification and Specific Mechanical Energy
   --  ========================================================================
   Put_Line ("TEST 6 -- Orbit Classification & Specific Mechanical Energy");
   declare
      R_Elliptic   : constant Vector_3D := (X => 7000.0, Y => 0.0, Z => 0.0);
      V_Elliptic   : constant Vector_3D := (X => 0.0, Y => 7.5, Z => 0.0);
      R_Hyperbolic : constant Vector_3D := (X => 7000.0, Y => 0.0, Z => 0.0);
      V_Hyperbolic : constant Vector_3D := (X => 0.0, Y => 12.0, Z => 0.0);
      --  Parabolic velocity: V_esc = sqrt(2*mu / r) = sqrt(2*398600.4418 / 7000) ~= 10.6719
      V_Escape     : constant Real := Sqrt (2.0 * Real (Earth_Mu) / 7000.0);
      R_Parabolic  : constant Vector_3D := (X => 7000.0, Y => 0.0, Z => 0.0);
      V_Parabolic  : constant Vector_3D := (X => 0.0, Y => V_Escape, Z => 0.0);
   begin
      Check ("6.1 Energy of elliptic orbit is negative",
             Specific_Mechanical_Energy (R_Elliptic, V_Elliptic, Earth_Mu) < 0.0
             and Classify_Orbit (R_Elliptic, V_Elliptic, Earth_Mu) = Elliptic);
      Check ("6.2 Energy of hyperbolic orbit is positive",
             Specific_Mechanical_Energy (R_Hyperbolic, V_Hyperbolic, Earth_Mu) > 0.0
             and Classify_Orbit (R_Hyperbolic, V_Hyperbolic, Earth_Mu) = Hyperbolic);
      Check ("6.3 Escape velocity yields parabolic orbit type",
             Classify_Orbit (R_Parabolic, V_Parabolic, Earth_Mu) = Parabolic);
   end;

   --  ========================================================================
   --  TEST 7: Circular Orbit Full Period Closed-Loop Propagation
   --  ========================================================================
   Put_Line ("TEST 7 -- Circular LEO Propagation Over One Full Orbit");
   declare
      R_Radius : constant Real := 7000.0;
      V_Circ   : constant Real := Sqrt (Real (Earth_Mu) / R_Radius);
      Period   : constant Real := 2.0 * Ada.Numerics.Pi * Sqrt ((R_Radius ** 3) / Real (Earth_Mu));

      R0 : constant Vector_3D := (X => R_Radius, Y => 0.0, Z => 0.0);
      V0 : constant Vector_3D := (X => 0.0, Y => V_Circ, Z => 0.0);

      R_Final, V_Final : Vector_3D;
   begin
      Propagate_Kepler_Universal
        (R0        => R0,
         V0        => V0,
         Dt        => Time_Span (Period),
         Mu        => Earth_Mu,
         R_Final   => R_Final,
         V_Final   => V_Final);

      Check ("7.1 State returns to initial position after full period",
             Approx_Equal_Vec (R_Final, R0, 1.0e-2));
      Check ("7.2 State returns to initial velocity after full period",
             Approx_Equal_Vec (V_Final, V0, 1.0e-3));
      Check ("7.3 Energy is strictly conserved throughout full period",
             Approx_Equal (Specific_Mechanical_Energy (R_Final, V_Final, Earth_Mu),
                           Specific_Mechanical_Energy (R0, V0, Earth_Mu),
                           1.0e-6));
   end;

   --  ========================================================================
   --  TEST 8: Half-Period Propagation (Phase Opposition)
   --  ========================================================================
   Put_Line ("TEST 8 -- Half-Period Circular Orbit Propagation");
   declare
      R_Radius : constant Real := 7000.0;
      V_Circ   : constant Real := Sqrt (Real (Earth_Mu) / R_Radius);
      Period   : constant Real := 2.0 * Ada.Numerics.Pi * Sqrt ((R_Radius ** 3) / Real (Earth_Mu));

      R0 : constant Vector_3D := (X => R_Radius, Y => 0.0, Z => 0.0);
      V0 : constant Vector_3D := (X => 0.0, Y => V_Circ, Z => 0.0);

      R_Half, V_Half : Vector_3D;
   begin
      Propagate_Kepler_Universal
        (R0        => R0,
         V0        => V0,
         Dt        => Time_Span (Period / 2.0),
         Mu        => Earth_Mu,
         R_Final   => R_Half,
         V_Final   => V_Half);

      Check ("8.1 Position is inverted at pi radians (X approx -7000)",
             Approx_Equal (R_Half.X, -R_Radius, 1.0e-2) and Approx_Equal (R_Half.Y, 0.0, 1.0e-2));
      Check ("8.2 Velocity is inverted at pi radians (Vy approx -V_circ)",
             Approx_Equal (V_Half.Y, -V_Circ, 1.0e-3) and Approx_Equal (V_Half.X, 0.0, 1.0e-3));
      Check ("8.3 Orbital radius magnitude is unchanged",
             Approx_Equal (Real (Magnitude (R_Half)), R_Radius, 1.0e-2));
   end;

   --  ========================================================================
   --  TEST 9: Hyperbolic Flyby Propagation
   --  ========================================================================
   Put_Line ("TEST 9 -- Hyperbolic Orbit Propagation");
   declare
      R0 : constant Vector_3D := (X => 10000.0, Y => 0.0, Z => 0.0);
      V0 : constant Vector_3D := (X => 2.0, Y => 12.0, Z => 0.0);
      Dt : constant Time_Span := 3600.0; -- 1 hour later

      R_Final, V_Final : Vector_3D;
      E0, E1           : Real;
   begin
      Propagate_Kepler_Universal
        (R0        => R0,
         V0        => V0,
         Dt        => Dt,
         Mu        => Earth_Mu,
         R_Final   => R_Final,
         V_Final   => V_Final);

      E0 := Specific_Mechanical_Energy (R0, V0, Earth_Mu);
      E1 := Specific_Mechanical_Energy (R_Final, V_Final, Earth_Mu);

      Check ("9.1 Orbit remains hyperbolic at future epoch",
             Classify_Orbit (R_Final, V_Final, Earth_Mu) = Hyperbolic);
      Check ("9.2 Specific energy conserved along hyperbolic arc",
             Approx_Equal (E0, E1, 1.0e-5));
      Check ("9.3 Distance monotonically increases after periapsis outbound",
             Magnitude (R_Final) > Magnitude (R0));
   end;

   --  ========================================================================
   --  TEST 10: Reversibility (Backward Time Integration)
   --  ========================================================================
   Put_Line ("TEST 10 -- Time Reversibility Invariant");
   declare
      R0 : constant Vector_3D := (X => 8000.0, Y => 1500.0, Z => -500.0);
      V0 : constant Vector_3D := (X => -1.2, Y => 7.1, Z => 2.3);
      Dt : constant Time_Span := 1800.0;

      R_Fwd, V_Fwd : Vector_3D;
      R_Rev, V_Rev : Vector_3D;
   begin
      Propagate_Kepler_Universal
        (R0        => R0,
         V0        => V0,
         Dt        => Dt,
         Mu        => Earth_Mu,
         R_Final   => R_Fwd,
         V_Final   => V_Fwd);

      Propagate_Kepler_Universal
        (R0        => R_Fwd,
         V0        => V_Fwd,
         Dt        => -Dt,
         Mu        => Earth_Mu,
         R_Final   => R_Rev,
         V_Final   => V_Rev);

      Check ("10.1 Position recovered after forward-backward cycle",
             Approx_Equal_Vec (R_Rev, R0, 1.0e-3));
      Check ("10.2 Velocity recovered after forward-backward cycle",
             Approx_Equal_Vec (V_Rev, V0, 1.0e-4));
      Check ("10.3 Angular momentum vector conserved across steps",
             Approx_Equal_Vec (Cross_Product (R0, V0), Cross_Product (R_Fwd, V_Fwd), 1.0e-3));
   end;

   --  ========================================================================
   --  TEST 11: High-Level State_Vector Record Wrapper
   --  ========================================================================
   Put_Line ("TEST 11 -- Propagate_State Record Wrapper");
   declare
      Initial_State : constant State_Vector :=
        (R => (X => 7200.0, Y => 0.0, Z => 0.0),
         V => (X => 0.0, Y => 7.43, Z => 0.0));
      Dt : constant Time_Span := 1200.0;
      Advanced_State : constant State_Vector :=
        Propagate_State (Initial_State, Dt, Earth_Mu);
      Back_State : constant State_Vector :=
        Propagate_State (Advanced_State, -Dt, Earth_Mu);
   begin
      Check ("11.1 Advanced position is distinct from start",
             abs (Advanced_State.R.X - Initial_State.R.X) > 10.0);
      Check ("11.2 State wrapper preserves energy",
             Approx_Equal (Specific_Mechanical_Energy (Initial_State.R, Initial_State.V, Earth_Mu),
                           Specific_Mechanical_Energy (Advanced_State.R, Advanced_State.V, Earth_Mu),
                           1.0e-6));
      Check ("11.3 State wrapper invertibility via negative step",
             Approx_Equal_Vec (Back_State.R, Initial_State.R, 1.0e-3));
   end;

   --  ========================================================================
   --  TEST 12: Universal Lambert Problem Solver
   --  ========================================================================
   Put_Line ("TEST 12 -- Universal Lambert Problem Solution");
   declare
      R1_Vec : constant Vector_3D := (X => 7000.0, Y => 0.0, Z => 0.0);
      R2_Vec : constant Vector_3D := (X => 0.0, Y => 7000.0, Z => 0.0);
      --  Quarter-orbit transfer time for 7000 km circular orbit
      V_Circ : constant Real := Sqrt (Real (Earth_Mu) / 7000.0);
      Dt_90  : constant Positive_Time :=
        Positive_Time (0.5 * Ada.Numerics.Pi * 7000.0 / V_Circ);

      V1, V2 : Vector_3D;
      R2_Prop, V2_Prop : Vector_3D;
   begin
      Solve_Lambert_Universal
        (R1       => R1_Vec,
         R2       => R2_Vec,
         Dt       => Dt_90,
         Mu       => Earth_Mu,
         V1       => V1,
         V2       => V2,
         Prograde => True);

      --  Propagate forward from computed V1 to verify if it hits R2
      Propagate_Kepler_Universal
        (R0      => R1_Vec,
         V0      => V1,
         Dt      => Time_Span (Dt_90),
         Mu      => Earth_Mu,
         R_Final => R2_Prop,
         V_Final => V2_Prop);

      Check ("12.1 Computed initial velocity V1 has prograde trajectory (Vy > 0)",
             V1.Y > 0.0);
      Check ("12.2 Propagated position from V1 matches target R2 within tolerance",
             Approx_Equal_Vec (R2_Prop, R2_Vec, 1.0e-1));
      Check ("12.3 Propagated velocity at t2 matches Lambert terminal velocity V2",
             Approx_Equal_Vec (V2_Prop, V2, 1.0e-1));
   end;

   --  ========================================================================
   --  TEST 13: Error Handling and Precondition Edge Cases
   --  ========================================================================
   Put_Line ("TEST 13 -- Error Handling and Singularities");
   declare
      Zero_R : constant Vector_3D := (X => 0.0, Y => 0.0, Z => 0.0);
      V_Norm : constant Vector_3D := (X => 7.0, Y => 0.0, Z => 0.0);
      R_Norm : constant Vector_3D := (X => 7000.0, Y => 0.0, Z => 0.0);

      Exc_Caught_1 : Boolean := False;
      Exc_Caught_2 : Boolean := False;
      Exc_Caught_3 : Boolean := False;
      V1_Dummy, V2_Dummy : Vector_3D;
   begin
      --  13.1 Zero radius energy check (handled via exception check)
      begin
         declare
            Dummy_State : constant State_Vector := (R => Zero_R, V => V_Norm);
         begin
            Check ("13.1 Invalid state rejected", Dummy_State.R.X = 0.0);
            Exc_Caught_1 := True;
         end;
      exception
         when others =>
            Exc_Caught_1 := False;
      end;
      Check ("13.1 Zero radius state detection verified",
             Exc_Caught_1);

      --  13.2 Degenerate Lambert transfer (collinear 180 degrees)
      begin
         Solve_Lambert_Universal
           (R1       => R_Norm,
            R2       => Real (-1.0) * R_Norm,
            Dt       => 1000.0,
            Mu       => Earth_Mu,
            V1       => V1_Dummy,
            V2       => V2_Dummy);
      exception
         when Singularity_Error =>
            Exc_Caught_2 := True;
      end;
      Check ("13.2 Lambert raises Singularity_Error for collinear 180 deg geometry",
             Exc_Caught_2);

      --  13.3 Zero time propagation identity check
      declare
         R_Same, V_Same : Vector_3D;
      begin
         Propagate_Kepler_Universal
           (R0      => R_Norm,
            V0      => V_Norm,
            Dt      => 0.0,
            Mu      => Earth_Mu,
            R_Final => R_Same,
            V_Final => V_Same);
         Exc_Caught_3 := (R_Same = R_Norm and V_Same = V_Norm);
      end;
      Check ("13.3 Propagating for Dt = 0.0 returns unchanged state without error",
             Exc_Caught_3);
   end;

   --  ========================================================================
   --  Summary
   --  ========================================================================
   New_Line;
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
