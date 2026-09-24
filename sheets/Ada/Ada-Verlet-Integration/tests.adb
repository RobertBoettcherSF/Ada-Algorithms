-- tests.adb
-- Test suite verifying Verification & Validation (V&V) properties.
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Verlet_Integration; use Verlet_Integration;

procedure Tests is
   V1, V2, Result : Vector_3D;
   Pos, Prev_Pos, Vel, Accel, Accel_Next : Vector_3D;
   DT : constant Float_Type := 1.0;
begin
   Put_Line ("Starting Verlet Integration Test Suite...");
   Put_Line ("-----------------------------------------");

   -- TEST 1 - Vector Math: Addition
   Put_Line ("TEST 1 - Vector Math: Addition");
   V1 := (1.0, 2.0, 3.0); V2 := (4.0, 5.0, 6.0); Result := V1 + V2;
   Put_Line ("  1.1 Assert X-axis addition is correct");
   Assert (Result.X = 5.0, "Addition X failed");
   Put_Line ("  1.2 Assert Y-axis addition is correct");
   Assert (Result.Y = 7.0, "Addition Y failed");
   Put_Line ("  1.3 Assert Z-axis addition is correct");
   Assert (Result.Z = 9.0, "Addition Z failed");
   Put_Line ("    PASS");

   -- TEST 2 - Vector Math: Subtraction
   Put_Line ("TEST 2 - Vector Math: Subtraction");
   Result := V2 - V1;
   Put_Line ("  2.1 Assert vector subtraction logic");
   Assert (Result.X = 3.0 and Result.Y = 3.0 and Result.Z = 3.0, "Subtraction failed");
   Put_Line ("    PASS");

   -- TEST 3 - Vector Math: Scalar Multiplication
   Put_Line ("TEST 3 - Vector Math: Scalar Multiplication");
   Result := V1 * 2.0;
   Put_Line ("  3.1 Assert scalar mapping across components");
   Assert (Result.X = 2.0 and Result.Y = 4.0 and Result.Z = 6.0, "Scalar mult failed");
   Put_Line ("    PASS");

   -- TEST 4 - Vector Math: Scalar Division
   Put_Line ("TEST 4 - Vector Math: Scalar Division");
   Result := V1 / 2.0;
   Put_Line ("  4.1 Assert scalar division maps correctly");
   Assert (Result.X = 0.5 and Result.Y = 1.0 and Result.Z = 1.5, "Scalar div failed");
   Put_Line ("  4.2 Assert division by zero raises constraint error");
   begin
      declare
         Div_Zero : Vector_3D := V1 / 0.0;
      begin
         Assert (False, "Expected Constraint_Error not raised");
      end;
   exception
      when Constraint_Error => Put_Line ("    PASS");
   end;

   -- TEST 5 - Tolerance & Equality
   Put_Line ("TEST 5 - Are_Close Helper function");
   Put_Line ("  5.1 Assert very close vectors resolve to true");
   Assert (Are_Close((1.0, 1.0, 1.0), (1.000001, 1.0, 1.0)), "Are_Close failed on tiny epsilon");
   Put_Line ("  5.2 Assert divergent vectors resolve to false");
   Assert (not Are_Close((1.0, 1.0, 1.0), (1.1, 1.0, 1.0)), "Are_Close false positive");
   Put_Line ("    PASS");

   -- TEST 6 - Basic Verlet Step: Constant Acceleration
   Put_Line ("TEST 6 - Basic Verlet Step (Constant Accel)");
   Pos := (0.0, 0.0, 0.0); Prev_Pos := (0.0, 0.0, 0.0); Accel := (2.0, 0.0, 0.0);
   Update_Basic_Verlet(Pos, Prev_Pos, Accel, DT);
   Put_Line ("  6.1 Assert new position matches kinematics (x = 2)");
   Assert (Pos.X = 2.0, "Basic Verlet Pos X incorrect");
   Put_Line ("  6.2 Assert previous position was properly cached (x = 0)");
   Assert (Prev_Pos.X = 0.0, "Basic Verlet Prev_Pos cache incorrect");
   Put_Line ("    PASS");

   -- TEST 7 - Basic Verlet Step: Second Step Inertia
   Put_Line ("TEST 7 - Basic Verlet Step (Inertia check)");
   Update_Basic_Verlet(Pos, Prev_Pos, Accel, DT);
   Put_Line ("  7.1 Assert position continues accelerating (x = 6)");
   -- x(t) = 2*(2) - (0) + 2*(1^2) = 4 + 2 = 6
   Assert (Pos.X = 6.0, "Basic Verlet Second Step incorrect");
   Put_Line ("    PASS");

   -- TEST 8 - Basic Verlet Step: Invalid DT (Exception)
   Put_Line ("TEST 8 - Basic Verlet: Negative Delta Time");
   Put_Line ("  8.1 Assert Negative DT raises Invalid_Delta_Time");
   begin
      Update_Basic_Verlet(Pos, Prev_Pos, Accel, -1.0);
      Assert (False, "Expected Invalid_Delta_Time");
   exception
      when Invalid_Delta_Time => Put_Line ("    PASS");
   end;

   -- TEST 9 - Velocity Verlet Step: Zero Acceleration
   Put_Line ("TEST 9 - Velocity Verlet (Zero Acceleration, const vel)");
   Pos := (0.0, 0.0, 0.0); Vel := (5.0, 0.0, 0.0); Accel := (0.0, 0.0, 0.0);
   Update_Velocity_Verlet(Pos, Vel, Accel, Accel, DT);
   Put_Line ("  9.1 Assert position updates based on velocity solely");
   Assert (Pos.X = 5.0, "Vel_Verlet Pos X failed");
   Put_Line ("  9.2 Assert velocity remains constant");
   Assert (Vel.X = 5.0, "Vel_Verlet Vel X failed");
   Put_Line ("    PASS");

   -- TEST 10 - Velocity Verlet Step: Constant Acceleration
   Put_Line ("TEST 10 - Velocity Verlet (Constant Acceleration)");
   Pos := (0.0, 0.0, 0.0); Vel := (0.0, 0.0, 0.0); Accel := (10.0, 0.0, 0.0);
   Update_Velocity_Verlet(Pos, Vel, Accel, Accel, DT);
   Put_Line ("  10.1 Assert Position matches 0.5*a*t^2 (x = 5)");
   Assert (Pos.X = 5.0, "Vel_Verlet const accel Pos failed");
   Put_Line ("  10.2 Assert Velocity matches a*t (v = 10)");
   Assert (Vel.X = 10.0, "Vel_Verlet const accel Vel failed");
   Put_Line ("    PASS");

   -- TEST 11 - Velocity Verlet Step: Invalid DT
   Put_Line ("TEST 11 - Velocity Verlet: Zero Delta Time");
   Put_Line ("  11.1 Assert DT=0.0 raises Invalid_Delta_Time");
   begin
      Update_Velocity_Verlet(Pos, Vel, Accel, Accel, 0.0);
      Assert (False, "Expected Invalid_Delta_Time");
   exception
      when Invalid_Delta_Time => Put_Line ("    PASS");
   end;

   -- TEST 12 - Leapfrog Integration: Constant Velocity
   Put_Line ("TEST 12 - Leapfrog Integration (Constant Velocity)");
   Pos := (0.0, 0.0, 0.0); Vel := (2.0, 0.0, 0.0); Accel := (0.0, 0.0, 0.0);
   Update_Leapfrog(Pos, Vel, Accel, DT);
   Put_Line ("  12.1 Assert position shifts by v*dt");
   Assert (Pos.X = 2.0, "Leapfrog pos failed");
   Put_Line ("  12.2 Assert half-step velocity remains unchanged");
   Assert (Vel.X = 2.0, "Leapfrog vel failed");
   Put_Line ("    PASS");

   -- TEST 13 - Leapfrog Integration: Constant Acceleration
   Put_Line ("TEST 13 - Leapfrog Integration (Constant Acceleration)");
   Pos := (0.0, 0.0, 0.0); Vel := (0.0, 0.0, 0.0); Accel := (9.8, 0.0, 0.0);
   Update_Leapfrog(Pos, Vel, Accel, DT);
   Put_Line ("  13.1 Assert half-step velocity increases by a*dt");
   Assert (Are_Close(Vel, (9.8, 0.0, 0.0)), "Leapfrog accel vel failed");
   Put_Line ("  13.2 Assert pos updates with half-step vel");
   Assert (Are_Close(Pos, (9.8, 0.0, 0.0)), "Leapfrog accel pos failed");
   Put_Line ("    PASS");

   -- TEST 14 - Leapfrog: Negative Time Edge case
   Put_Line ("TEST 14 - Leapfrog Integration (Negative DT)");
   Put_Line ("  14.1 Assert negative time step is rejected");
   begin
      Update_Leapfrog(Pos, Vel, Accel, -2.5);
      Assert (False, "Expected Invalid_Delta_Time");
   exception
      when Invalid_Delta_Time => Put_Line ("    PASS");
   end;

   Put_Line ("-----------------------------------------");
   Put_Line ("ALL TESTS COMPLETED SUCCESSFULLY");
end Tests;
