--  File: tests.adb
--  Standalone verification suite and usage demonstration for Radiosity algorithms
--  Standard: Ada 2023 (ISO/IEC 8652:2023)

with Ada.Text_IO; use Ada.Text_IO;
with Radiosity;   use Radiosity;

procedure Tests is
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

   --  Tolerance comparison helper
   function Approx_Equal (A, B : Real; Margin : Real := 0.005) return Boolean is
   begin
      return abs (A - B) <= Margin;
   end Approx_Equal;

   --  Helper to construct a 2-patch opposing parallel capacitor-like scene
   --  Patch 1 at (0, 0, 0), facing +Z (Normal = 0, 0, 1)
   --  Patch 2 at (0, 0, D), facing -Z (Normal = 0, 0, -1)
   function Make_Two_Patch_Scene
     (Distance : Real;
      Area     : Positive_Real;
      Albedo1  : Reflectance;
      Albedo2  : Reflectance;
      Emit1    : Flux_Density;
      Emit2    : Flux_Density) return Patch_List
   is
      Scene : Patch_List;
      P1 : constant Patch :=
        (Id       => 1,
         Center   => (0.0, 0.0, 0.0),
         Normal   => (0.0, 0.0, 1.0),
         Area     => Area,
         Albedo   => Albedo1,
         Emission => Emit1);
      P2 : constant Patch :=
        (Id       => 2,
         Center   => (0.0, 0.0, Distance),
         Normal   => (0.0, 0.0, -1.0),
         Area     => Area,
         Albedo   => Albedo2,
         Emission => Emit2);
   begin
      Scene.Append (P1);
      Scene.Append (P2);
      return Scene;
   end Make_Two_Patch_Scene;

   --  Helper to construct a 3-patch enclosure model (Emitter, Wall, Floor)
   function Make_Three_Patch_Scene return Patch_List is
      Scene : Patch_List;
      --  P1: Light source at ceiling (0, 10, 0), pointing down -Y
      P1 : constant Patch :=
        (Id       => 1,
         Center   => (0.0, 10.0, 0.0),
         Normal   => (0.0, -1.0, 0.0),
         Area     => 2.0,
         Albedo   => 0.05,
         Emission => 100.0);
      --  P2: Floor at (0, 0, 0), pointing up +Y
      P2 : constant Patch :=
        (Id       => 2,
         Center   => (0.0, 0.0, 0.0),
         Normal   => (0.0, 1.0, 0.0),
         Area     => 25.0,
         Albedo   => 0.7,
         Emission => 0.0);
      --  P3: Angled reflector wall at (5, 5, 0), normal pointing towards (-1, 0, 0)
      P3 : constant Patch :=
        (Id       => 3,
         Center   => (5.0, 5.0, 0.0),
         Normal   => (-1.0, 0.0, 0.0),
         Area     => 20.0,
         Albedo   => 0.5,
         Emission => 0.0);
   begin
      Scene.Append (P1);
      Scene.Append (P2);
      Scene.Append (P3);
      return Scene;
   end Make_Three_Patch_Scene;

begin
   --  ========================================================================
   --  TEST 1: Vector Algebra and Normalization Mechanics
   --  ========================================================================
   Put_Line ("TEST 1 -- Vector Algebra and Normalization Mechanics");
   declare
      V1     : constant Vector_3D := (3.0, 4.0, 0.0);
      V2     : constant Vector_3D := (1.0, 2.0, 2.0);
      V_Norm : constant Vector_3D := Normalize (V1);
      V_Sum  : constant Vector_3D := V1 + V2;
   begin
      Check ("1.1 Magnitude of (3,4,0) is 5.0", Approx_Equal (Norm (V1), 5.0, 1.0e-6));
      Check ("1.2 Normalized vector has unit length", Approx_Equal (Norm (V_Norm), 1.0, 1.0e-6));
      Check ("1.3 Dot product of orthogonal vectors is zero",
             Approx_Equal (Dot_Product ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0)), 0.0, 1.0e-6));
      Check ("1.4 Vector addition gives component sum",
             V_Sum.X = 4.0 and then V_Sum.Y = 6.0 and then V_Sum.Z = 2.0);
   end;

   --  ========================================================================
   --  TEST 2: Geometry & Differential Form Factor Formulation
   --  ========================================================================
   Put_Line ("TEST 2 -- Differential Form Factor Calculation");
   declare
      Source_C : constant Vector_3D := (0.0, 0.0, 0.0);
      Source_N : constant Vector_3D := (0.0, 0.0, 1.0);
      Target_C : constant Vector_3D := (0.0, 0.0, 2.0);
      Target_N : constant Vector_3D := (0.0, 0.0, -1.0);
      Area_T   : constant Positive_Real := 1.0;
      F_ij     : Form_Factor;
      Back_N   : constant Vector_3D := (0.0, 0.0, 1.0); -- pointing away
      F_back   : Form_Factor;
   begin
      F_ij := Compute_Point_Form_Factor (Source_C, Source_N, Target_C, Target_N, Area_T);
      --  Expected: cos(0)*cos(0) / (pi * 2^2) * 1.0 = 1.0 / (4 * pi) ~ 0.079577
      Check ("2.1 Directly opposing form factor matches theoretical 1/(4*pi)",
             Approx_Equal (F_ij, 0.079577, 0.001));

      F_back := Compute_Point_Form_Factor (Source_C, Source_N, Target_C, Back_N, Area_T);
      Check ("2.2 Back-facing surface yields zero form factor", F_back = 0.0);

      declare
         F_self : constant Form_Factor :=
           Compute_Point_Form_Factor (Source_C, Source_N, Source_C, Source_N, Area_T);
      begin
         Check ("2.3 Coincident points return zero form factor", F_self = 0.0);
      end;
   end;

   --  ========================================================================
   --  TEST 3: Scene Validation Rules
   --  ========================================================================
   Put_Line ("TEST 3 -- Scene Validation and Invariants");
   declare
      Valid_Scene   : constant Patch_List := Make_Two_Patch_Scene (2.0, 1.0, 0.5, 0.5, 10.0, 0.0);
      Invalid_Scene : Patch_List;
      Bad_Patch     : constant Patch :=
        (Id       => 1,
         Center   => (0.0, 0.0, 0.0),
         Normal   => (0.0, 0.0, 0.0), -- non-unit length normal
         Area     => 1.0,
         Albedo   => 0.5,
         Emission => 0.0);
   begin
      Check ("3.1 Well-formed scene is recognized as valid", Is_Valid_Scene (Valid_Scene));
      Invalid_Scene.Append (Bad_Patch);
      Check ("3.2 Scene containing unnormalized normal is rejected", not Is_Valid_Scene (Invalid_Scene));
      declare
         Empty_List : Patch_List;
      begin
         Check ("3.3 Empty scene fails validation", not Is_Valid_Scene (Empty_List));
      end;
   end;

   --  ========================================================================
   --  TEST 4: Form Factor Matrix Assembly
   --  ========================================================================
   Put_Line ("TEST 4 -- Scene Form Factor Matrix Assembly");
   declare
      Scene : constant Patch_List := Make_Two_Patch_Scene (2.0, 1.0, 0.5, 0.5, 10.0, 0.0);
      FF    : constant Form_Factor_Matrix := Compute_Scene_Form_Factors (Scene);
   begin
      Check ("4.1 Diagonal self-view form factor is zero (planar patch)", FF (1, 1) = 0.0 and FF (2, 2) = 0.0);
      Check ("4.2 Symmetric mutual exchange between identical patches",
             Approx_Equal (FF (1, 2), FF (2, 1), 1.0e-5));
      Check ("4.3 Form factor magnitude is physically positive and strictly bounded below 1",
             FF (1, 2) > 0.0 and FF (1, 2) < 1.0);
   end;

   --  ========================================================================
   --  TEST 5: Direct Matrix Inversion Solver (Infinite Bounce Analytical Solution)
   --  ========================================================================
   Put_Line ("TEST 5 -- Direct Matrix Inversion Solver");
   declare
      Scene : constant Patch_List := Make_Two_Patch_Scene (2.0, 1.0, 0.8, 0.8, 100.0, 0.0);
      FF    : constant Form_Factor_Matrix := Compute_Scene_Form_Factors (Scene);
      Rad   : Radiosity_Array (1 .. 2);
   begin
      Solve_Matrix_Direct (Scene, FF, Rad);
      Check ("5.1 Emitter radiosity exceeds initial emission due to back-reflections",
             Rad (1) > 100.0);
      Check ("5.2 Passive receiver develops positive secondary radiosity",
             Rad (2) > 0.0);
      --  B1 = E1 + rho1 * F12 * B2; B2 = rho2 * F21 * B1
      --  Hence B2 = 0.8 * F * B1, confirming mutual balance
      Check ("5.3 Radiosity ratio closely matches albedo * form factor",
             Approx_Equal (Rad (2), 0.8 * FF (2, 1) * Rad (1), 0.01));
   end;

   --  ========================================================================
   --  TEST 6: Jacobi Gathering Iterations
   --  ========================================================================
   Put_Line ("TEST 6 -- Jacobi Gathering Iterative Solver");
   declare
      Scene : constant Patch_List := Make_Two_Patch_Scene (2.0, 1.0, 0.8, 0.8, 100.0, 0.0);
      FF    : constant Form_Factor_Matrix := Compute_Scene_Form_Factors (Scene);
      Rad_Direct : Radiosity_Array (1 .. 2);
      Rad_Jacobi : Radiosity_Array (1 .. 2);
      Steps      : Natural;
   begin
      Solve_Matrix_Direct (Scene, FF, Rad_Direct);
      Solve_Jacobi_Gathering (Scene, FF, 100, 1.0e-5, Rad_Jacobi, Steps);

      Check ("6.1 Jacobi terminates within iteration budget", Steps > 0 and Steps < 100);
      Check ("6.2 Jacobi patch 1 matches direct matrix solution",
             Approx_Equal (Rad_Jacobi (1), Rad_Direct (1), 0.01));
      Check ("6.3 Jacobi patch 2 matches direct matrix solution",
             Approx_Equal (Rad_Jacobi (2), Rad_Direct (2), 0.01));
   end;

   --  ========================================================================
   --  TEST 7: Gauss-Seidel Asynchronous Convergence
   --  ========================================================================
   Put_Line ("TEST 7 -- Gauss-Seidel Accelerated Iterative Solver");
   declare
      Scene : constant Patch_List := Make_Two_Patch_Scene (2.0, 1.0, 0.8, 0.8, 100.0, 0.0);
      FF    : constant Form_Factor_Matrix := Compute_Scene_Form_Factors (Scene);
      Rad_Direct : Radiosity_Array (1 .. 2);
      Rad_GS     : Radiosity_Array (1 .. 2);
      Steps_GS   : Natural;
      Rad_Jacobi : Radiosity_Array (1 .. 2);
      Steps_Jac  : Natural;
   begin
      Solve_Matrix_Direct (Scene, FF, Rad_Direct);
      Solve_Gauss_Seidel (Scene, FF, 100, 1.0e-6, Rad_GS, Steps_GS);
      Solve_Jacobi_Gathering (Scene, FF, 100, 1.0e-6, Rad_Jacobi, Steps_Jac);

      Check ("7.1 Gauss-Seidel converges within limits", Steps_GS > 0 and Steps_GS <= 100);
      Check ("7.2 Gauss-Seidel requires no more iterations than synchronous Jacobi",
             Steps_GS <= Steps_Jac);
      Check ("7.3 Gauss-Seidel radiosity agrees with direct solver",
             Approx_Equal (Rad_GS (1), Rad_Direct (1), 0.01));
   end;

   --  ========================================================================
   --  TEST 8: Progressive Refinement / Shooting Radiosity
   --  ========================================================================
   Put_Line ("TEST 8 -- Progressive Refinement / Shooting Variant");
   declare
      Scene : constant Patch_List := Make_Two_Patch_Scene (2.0, 1.0, 0.8, 0.8, 100.0, 0.0);
      FF    : constant Form_Factor_Matrix := Compute_Scene_Form_Factors (Scene);
      Rad_Direct : Radiosity_Array (1 .. 2);
      Rad_Shoot  : Radiosity_Array (1 .. 2);
      Steps      : Natural;
   begin
      Solve_Matrix_Direct (Scene, FF, Rad_Direct);
      Solve_Progressive_Shooting (Scene, FF, 100, 1.0e-4, Rad_Shoot, Steps);

      Check ("8.1 Progressive shooting executes successfully", Steps > 0);
      Check ("8.2 Shooting solver converges near analytical emitter solution",
             Approx_Equal (Rad_Shoot (1), Rad_Direct (1), 0.05));
      Check ("8.3 Shooting solver converges near analytical receiver solution",
             Approx_Equal (Rad_Shoot (2), Rad_Direct (2), 0.05));
   end;

   --  ========================================================================
   --  TEST 9: Single-Bounce (Direct Illumination) Approximation
   --  ========================================================================
   Put_Line ("TEST 9 -- Single-Bounce Approximation");
   declare
      Scene : constant Patch_List := Make_Two_Patch_Scene (2.0, 1.0, 0.5, 0.5, 100.0, 0.0);
      FF    : constant Form_Factor_Matrix := Compute_Scene_Form_Factors (Scene);
      Rad_1 : constant Radiosity_Array := Compute_Single_Bounce (Scene, FF);
      Rad_Full : Radiosity_Array (1 .. 2);
   begin
      Solve_Matrix_Direct (Scene, FF, Rad_Full);

      Check ("9.1 Emitter single-bounce retains initial self-emission",
             Approx_Equal (Rad_1 (1), 100.0, 1.0e-6));
      Check ("9.2 Passive receiver receives exactly rho * F * E1",
             Approx_Equal (Rad_1 (2), 0.5 * FF (2, 1) * 100.0, 1.0e-5));
      Check ("9.3 Single-bounce is strictly less than full infinite-bounce radiosity",
             Rad_1 (2) < Rad_Full (2) and Rad_1 (1) < Rad_Full (1));
   end;

   --  ========================================================================
   --  TEST 10: Multi-Patch Complex Scene Interaction (3 Patches)
   --  ========================================================================
   Put_Line ("TEST 10 -- Three-Patch Room Enclosure");
   declare
      Scene : constant Patch_List := Make_Three_Patch_Scene;
      FF    : constant Form_Factor_Matrix := Compute_Scene_Form_Factors (Scene);
      Rad_Dir : Radiosity_Array (1 .. 3);
      Rad_GS  : Radiosity_Array (1 .. 3);
      Steps   : Natural;
   begin
      Solve_Matrix_Direct (Scene, FF, Rad_Dir);
      Solve_Gauss_Seidel (Scene, FF, 150, 1.0e-5, Rad_GS, Steps);

      Check ("10.1 Floor receives energy from ceiling luminaire", Rad_Dir (2) > 0.0);
      Check ("10.2 Reflector wall receives energy from scene", Rad_Dir (3) > 0.0);
      Check ("10.3 Direct and iterative solvers agree on multi-patch configuration",
             Approx_Equal (Rad_Dir (2), Rad_GS (2), 0.05)
             and then Approx_Equal (Rad_Dir (3), Rad_GS (3), 0.05));
   end;

   --  ========================================================================
   --  TEST 11: Energy Conservation & Total Power Metrics
   --  ========================================================================
   Put_Line ("TEST 11 -- Energy Conservation and Monotonicity");
   declare
      Scene : constant Patch_List := Make_Two_Patch_Scene (2.0, 2.0, 0.5, 0.5, 50.0, 0.0);
      FF    : constant Form_Factor_Matrix := Compute_Scene_Form_Factors (Scene);
      Emit_P : constant Real := Total_Emitted_Power (Scene);
      Rad    : Radiosity_Array (1 .. 2);
   begin
      Solve_Matrix_Direct (Scene, FF, Rad);
      declare
         Total_P : constant Real := Total_Scene_Power (Scene, Rad);
      begin
         Check ("11.1 Emitted power matches Area * Emission (2.0 * 50 = 100 W)",
                Approx_Equal (Emit_P, 100.0, 1.0e-5));
         Check ("11.2 Total leaving flux density exceeds pure initial emission due to interreflection",
                Total_P > Emit_P);
         Check ("11.3 Individual patch radiosities are strictly positive",
                Rad (1) > 0.0 and then Rad (2) > 0.0);
      end;
   end;

   --  ========================================================================
   --  TEST 12: Absorption Boundary: Zero Reflectance Blackbody
   --  ========================================================================
   Put_Line ("TEST 12 -- Zero Reflectance Blackbody Surfaces");
   declare
      --  When albedos are 0.0, surfaces absorb 100% of incident light.
      --  No interreflection can occur, so B_i must identically equal E_i.
      Scene : constant Patch_List := Make_Two_Patch_Scene (2.0, 1.0, 0.0, 0.0, 80.0, 0.0);
      FF    : constant Form_Factor_Matrix := Compute_Scene_Form_Factors (Scene);
      Rad   : Radiosity_Array (1 .. 2);
   begin
      Solve_Matrix_Direct (Scene, FF, Rad);
      Check ("12.1 Blackbody emitter radiosity equals its self-emission",
             Approx_Equal (Rad (1), 80.0, 1.0e-6));
      Check ("12.2 Blackbody receiver radiosity remains exactly zero",
             Approx_Equal (Rad (2), 0.0, 1.0e-6));
      declare
         Rad_Single : constant Radiosity_Array := Compute_Single_Bounce (Scene, FF);
      begin
         Check ("12.3 Single bounce matches full solution for blackbody surfaces",
                Approx_Equal (Rad_Single (1), Rad (1), 1.0e-6)
                and then Approx_Equal (Rad_Single (2), Rad (2), 1.0e-6));
      end;
   end;

   --  ========================================================================
   --  TEST 13: Error Handling and Degenerate Inputs
   --  ========================================================================
   Put_Line ("TEST 13 -- Error Handling and Preconditions");
   declare
      Caught_Zero_Norm : Boolean := False;
   begin
      --  Normalizing a zero vector must raise Invalid_Patch_Error
      begin
         declare
            Bad_V : constant Vector_3D := Normalize ((0.0, 0.0, 0.0));
         begin
            if Bad_V.X = 0.0 then
               null;
            end if;
         end;
      exception
         when Invalid_Patch_Error =>
            Caught_Zero_Norm := True;
      end;
      Check ("13.1 Normalize (0,0,0) raises Invalid_Patch_Error", Caught_Zero_Norm);

      --  Single patch scene without mutual view
      declare
         Single_Scene : Patch_List;
         P1 : constant Patch :=
           (Id       => 1,
            Center   => (0.0, 0.0, 0.0),
            Normal   => (0.0, 1.0, 0.0),
            Area     => 1.0,
            Albedo   => 0.5,
            Emission => 42.0);
         FF : constant Form_Factor_Matrix (1 .. 1, 1 .. 1) := [others => [others => 0.0]];
         Rad : Radiosity_Array (1 .. 1);
      begin
         Single_Scene.Append (P1);
         Solve_Matrix_Direct (Single_Scene, FF, Rad);
         Check ("13.2 Isolated single planar patch retains exact self-emission",
                Approx_Equal (Rad (1), 42.0, 1.0e-6));
      end;

      --  Patch validity checks
      declare
         P_Bad_Albedo : constant Patch :=
           (Id       => 1,
            Center   => (0.0, 0.0, 0.0),
            Normal   => (0.0, 1.0, 0.0),
            Area     => 1.0,
            Albedo   => 1.0, -- maximum legal albedo
            Emission => 0.0);
      begin
         Check ("13.3 Unit albedo patch is accepted by Is_Valid_Patch",
                Is_Valid_Patch (P_Bad_Albedo));
      end;
   end;

   --  ========================================================================
   --  TEST 14: Progressive Shooting Monotonicity
   --  ========================================================================
   Put_Line ("TEST 14 -- Progressive Shooting Monotonicity");
   declare
      Scene : constant Patch_List := Make_Two_Patch_Scene (2.0, 1.0, 0.7, 0.7, 100.0, 0.0);
      FF    : constant Form_Factor_Matrix := Compute_Scene_Form_Factors (Scene);
      Rad_1 : Radiosity_Array (1 .. 2);
      Rad_5 : Radiosity_Array (1 .. 2);
      Steps_1 : Natural;
      Steps_5 : Natural;
   begin
      Solve_Progressive_Shooting (Scene, FF, 1, 1.0e-9, Rad_1, Steps_1);
      Solve_Progressive_Shooting (Scene, FF, 5, 1.0e-9, Rad_5, Steps_5);

      Check ("14.1 Step limit 1 executes exactly 1 step", Steps_1 = 1);
      Check ("14.2 Receiver radiosity increases monotonically from step 1 to step 5",
             Rad_5 (2) >= Rad_1 (2));
      Check ("14.3 Total scene energy grows monotonically with iterations towards steady state",
             Total_Scene_Power (Scene, Rad_5) >= Total_Scene_Power (Scene, Rad_1));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
