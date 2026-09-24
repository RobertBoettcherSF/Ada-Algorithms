--  Standalone test suite for Miser (main program).

pragma Ada_2022;

with Ada.Numerics;
with Ada.Text_IO; use Ada.Text_IO;
with Miser;       use Miser;

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
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   Pi : constant Real := Ada.Numerics.Pi;

   --  Bounds helpers
   function Unit_1D return Bounds is
      B : Bounds (1);
   begin
      B.Lo := [1 => 0.0];
      B.Hi := [1 => 1.0];
      return B;
   end Unit_1D;

   function Unit_Square return Bounds is
      B : Bounds (2);
   begin
      B.Lo := [0.0, 0.0];
      B.Hi := [1.0, 1.0];
      return B;
   end Unit_Square;

   function Unit_Cube return Bounds is
      B : Bounds (3);
   begin
      B.Lo := [0.0, 0.0, 0.0];
      B.Hi := [1.0, 1.0, 1.0];
      return B;
   end Unit_Cube;

   function Box_2D (X0, X1, Y0, Y1 : Real) return Bounds is
      B : Bounds (2);
   begin
      B.Lo := [X0, Y0];
      B.Hi := [X1, Y1];
      return B;
   end Box_2D;

   Cfg_Small : constant Config :=
     (N_Points   => 800,
      Dither     => 0.1,
      Min_Points => 15,
      Max_Depth  => 8,
      Seed       => 7);

   Cfg_Pi : constant Config :=
     (N_Points   => 20_000,
      Dither     => 0.1,
      Min_Points => 15,
      Max_Depth  => 10,
      Seed       => 123);

   Cfg_Const : constant Config :=
     (N_Points   => 5_000,
      Dither     => 0.1,
      Min_Points => 15,
      Max_Depth  => 8,
      Seed       => 99);

   Cfg_Poly : constant Config :=
     (N_Points   => 8_000,
      Dither     => 0.1,
      Min_Points => 15,
      Max_Depth  => 10,
      Seed       => 42);

   R, R2 : Result;

begin
   Put_Line ("Miser test suite (recursive stratified Monte Carlo)");
   Put_Line ("====================================================");

   ---------------------------------------------------------------------
   Section ("1. Bounds_Valid / Volume");
   ---------------------------------------------------------------------
   Check (Bounds_Valid (Unit_1D), "Bounds_Valid unit 1D");
   Check (Bounds_Valid (Unit_Square), "Bounds_Valid unit square");
   Check (Bounds_Valid (Unit_Cube), "Bounds_Valid unit cube");
   declare
      Bad : Bounds (1);
   begin
      Bad.Lo := [1 => 1.0];
      Bad.Hi := [1 => 1.0];
      Check (not Bounds_Valid (Bad), "Bounds_Valid rejects Lo=Hi");
      Bad.Hi := [1 => 0.5];
      Check (not Bounds_Valid (Bad), "Bounds_Valid rejects Lo>Hi");
   end;
   Check (Approx (Volume (Unit_1D), 1.0, 1.0E-14), "Volume unit 1D = 1");
   Check (Approx (Volume (Unit_Square), 1.0, 1.0E-14), "Volume unit square = 1");
   Check (Approx (Volume (Unit_Cube), 1.0, 1.0E-14), "Volume unit cube = 1");
   Check (Approx (Volume (Box_2D (0.0, 2.0, 0.0, 3.0)), 6.0, 1.0E-14),
          "Volume 2x3 rectangle = 6");
   declare
      B4 : Bounds (4);
   begin
      B4.Lo := [0.0, 0.0, 0.0, 0.0];
      B4.Hi := [2.0, 2.0, 2.0, 2.0];
      Check (Bounds_Valid (B4), "Bounds_Valid 4D");
      Check (Approx (Volume (B4), 16.0, 1.0E-12), "Volume 4D hypercube side 2");
   end;

   ---------------------------------------------------------------------
   Section ("2. Sample integrands");
   ---------------------------------------------------------------------
   declare
      P1 : constant Point := [1 => 0.5];
      P2 : constant Point := [0.3, 0.4];
      P3 : constant Point := [0.0, 0.0];
      P4 : constant Point := [1.0, 0.0];
   begin
      Check (Constant_One (P1) = 1.0, "Constant_One");
      Check (Constant_Three (P2) = 3.0, "Constant_Three");
      Check (Quarter_Circle (P3) = 1.0, "Quarter_Circle origin inside");
      Check (Quarter_Circle (P2) = 1.0, "Quarter_Circle (0.3,0.4) inside");
      Check (Quarter_Circle (P4) = 1.0, "Quarter_Circle (1,0) on boundary");
      Check (Quarter_Circle ([0.9, 0.9]) = 0.0, "Quarter_Circle outside");
      Check (Approx (Poly_X_Squared (P1), 0.25, 1.0E-14), "Poly_X_Squared(0.5)");
      Check (Approx (Poly_Linear_1D (P1), 1.0, 1.0E-14), "Poly_Linear_1D(0.5)");
      Check (Approx (Product_XY (P2), 0.12, 1.0E-14), "Product_XY(0.3,0.4)");
      Check (Separable_Peak (P1) > 0.9, "Separable_Peak near center high");
      Check (Separable_Peak ([1 => 0.0]) < Separable_Peak (P1),
             "Separable_Peak lower at edge");
   end;

   ---------------------------------------------------------------------
   Section ("3. Plain_Monte_Carlo constant");
   ---------------------------------------------------------------------
   R := Plain_Monte_Carlo (Constant_One'Access, Unit_Square, Cfg_Const);
   Check (Approx (R.Estimate, 1.0, 0.05), "Plain MC ∫1 on unit square ≈ 1");
   Check (R.Variance_Estimate >= 0.0, "Plain MC variance non-negative");
   Check (R.Std_Error >= 0.0, "Plain MC Std_Error non-negative");
   Check (Approx (R.Std_Error ** 2, R.Variance_Estimate, 1.0E-9)
            or else Approx (R.Std_Error, 0.0, 1.0E-12),
          "Plain MC Std_Error² ≈ Variance_Estimate");

   R := Plain_Monte_Carlo (Constant_Three'Access, Unit_1D, Cfg_Const);
   Check (Approx (R.Estimate, 3.0, 0.05), "Plain MC ∫3 on [0,1] ≈ 3");
   Check (R.Variance_Estimate < 1.0E-20
            or else R.Std_Error < 1.0E-8,
          "Plain MC constant has near-zero variance");

   R := Plain_Monte_Carlo
     (Constant_One'Access, Box_2D (0.0, 2.0, 0.0, 3.0), Cfg_Const);
   Check (Approx (R.Estimate, 6.0, 0.1), "Plain MC ∫1 on 2×3 ≈ 6");

   ---------------------------------------------------------------------
   Section ("4. Integrate_Miser constant (exact-ish)");
   ---------------------------------------------------------------------
   R := Integrate_Miser (Constant_One'Access, Unit_Square, Cfg_Const);
   Check (Approx (R.Estimate, 1.0, 0.02), "MISER ∫1 unit square ≈ 1");
   Check (R.Variance_Estimate >= 0.0, "MISER variance non-negative");
   Check (R.Std_Error >= 0.0, "MISER Std_Error non-negative");

   R := Integrate_Miser (Constant_Three'Access, Unit_1D, Cfg_Const);
   Check (Approx (R.Estimate, 3.0, 0.02), "MISER ∫3 on [0,1] ≈ 3");

   R := Integrate_Miser (Constant_One'Access, Unit_Cube, Cfg_Const);
   Check (Approx (R.Estimate, 1.0, 0.05), "MISER ∫1 unit cube ≈ 1");

   R := Integrate_Miser
     (Constant_One'Access, Box_2D (-1.0, 1.0, -1.0, 1.0), Cfg_Const);
   Check (Approx (R.Estimate, 4.0, 0.05), "MISER ∫1 on [-1,1]² ≈ 4");

   ---------------------------------------------------------------------
   Section ("5. Quarter circle → π/4");
   ---------------------------------------------------------------------
   R := Integrate_Miser (Quarter_Circle'Access, Unit_Square, Cfg_Pi);
   Check (Approx (R.Estimate, Pi / 4.0, 0.03),
          "MISER quarter circle ≈ π/4 (tol 0.03)");
   Check (Approx (R.Estimate * 4.0, Pi, 0.12),
          "MISER 4×estimate ≈ π (tol 0.12)");
   Check (R.Std_Error < 0.05, "MISER π/4 Std_Error modest");

   R2 := Plain_Monte_Carlo (Quarter_Circle'Access, Unit_Square, Cfg_Pi);
   Check (Approx (R2.Estimate, Pi / 4.0, 0.05),
          "Plain MC quarter circle ≈ π/4 (looser)");
   Check (Approx (R2.Estimate * 4.0, Pi, 0.2),
          "Plain MC 4×estimate ≈ π");

   ---------------------------------------------------------------------
   Section ("6. 1D polynomials with known integrals");
   ---------------------------------------------------------------------
   R := Integrate_Miser (Poly_X_Squared'Access, Unit_1D, Cfg_Poly);
   Check (Approx (R.Estimate, 1.0 / 3.0, 0.02),
          "MISER ∫₀¹ x² dx ≈ 1/3");

   R := Integrate_Miser (Poly_Linear_1D'Access, Unit_1D, Cfg_Poly);
   Check (Approx (R.Estimate, 1.0, 0.02),
          "MISER ∫₀¹ 2x dx ≈ 1");

   R := Plain_Monte_Carlo (Poly_X_Squared'Access, Unit_1D, Cfg_Poly);
   Check (Approx (R.Estimate, 1.0 / 3.0, 0.05),
          "Plain MC ∫₀¹ x² dx ≈ 1/3");

   R := Integrate_Miser (Product_XY'Access, Unit_Square, Cfg_Poly);
   Check (Approx (R.Estimate, 0.25, 0.03),
          "MISER ∫ xy on unit square ≈ 1/4");

   ---------------------------------------------------------------------
   Section ("7. Reproducibility (same seed)");
   ---------------------------------------------------------------------
   R  := Integrate_Miser (Quarter_Circle'Access, Unit_Square, Cfg_Small);
   R2 := Integrate_Miser (Quarter_Circle'Access, Unit_Square, Cfg_Small);
   Check (R.Estimate = R2.Estimate, "MISER same seed → same estimate");
   Check (R.Variance_Estimate = R2.Variance_Estimate,
          "MISER same seed → same variance");

   R  := Plain_Monte_Carlo (Poly_X_Squared'Access, Unit_1D, Cfg_Small);
   R2 := Plain_Monte_Carlo (Poly_X_Squared'Access, Unit_1D, Cfg_Small);
   Check (R.Estimate = R2.Estimate, "Plain MC same seed → same estimate");

   declare
      Cfg_A : constant Config := Cfg_Small;
      Cfg_B : Config := Cfg_Small;
   begin
      Cfg_B.Seed := Cfg_A.Seed + 1;
      R  := Integrate_Miser (Quarter_Circle'Access, Unit_Square, Cfg_A);
      R2 := Integrate_Miser (Quarter_Circle'Access, Unit_Square, Cfg_B);
      Check (R.Estimate /= R2.Estimate
               or else R.Variance_Estimate /= R2.Variance_Estimate,
             "Different seeds typically differ");
   end;

   ---------------------------------------------------------------------
   Section ("8. Config edge cases / depth / dither");
   ---------------------------------------------------------------------
   declare
      Cfg_Leaf : constant Config :=
        (N_Points   => 40,
         Dither     => 0.1,
         Min_Points => 50,
         Max_Depth  => 12,
         Seed       => 1);
   begin
      --  Min_Points > N_Points forces leaf plain MC path.
      R := Integrate_Miser (Constant_One'Access, Unit_1D, Cfg_Leaf);
      Check (Approx (R.Estimate, 1.0, 0.15), "MISER leaf path (Min_Points>N)");
   end;

   declare
      Cfg_Shallow : constant Config :=
        (N_Points   => 2_000,
         Dither     => 0.1,
         Min_Points => 15,
         Max_Depth  => 0,
         Seed       => 3);
   begin
      R := Integrate_Miser (Constant_One'Access, Unit_Square, Cfg_Shallow);
      Check (Approx (R.Estimate, 1.0, 0.05), "MISER Max_Depth=0 → plain MC");
   end;

   declare
      Cfg_D0 : Config := Cfg_Small;
   begin
      Cfg_D0.Dither := 0.0;
      R := Integrate_Miser (Constant_One'Access, Unit_1D, Cfg_D0);
      Check (Approx (R.Estimate, 1.0, 0.1), "MISER Dither=0 clamped");
   end;

   declare
      Cfg_Hi : Config := Cfg_Small;
   begin
      Cfg_Hi.Dither := 1.0;
      R := Integrate_Miser (Constant_One'Access, Unit_1D, Cfg_Hi);
      Check (Approx (R.Estimate, 1.0, 0.1), "MISER Dither=1 clamped");
   end;

   ---------------------------------------------------------------------
   Section ("9. Separable peak / higher-D smoke");
   ---------------------------------------------------------------------
   R := Integrate_Miser (Separable_Peak'Access, Unit_1D, Cfg_Poly);
   Check (R.Estimate > 0.4 and then R.Estimate < 0.7,
          "MISER separable peak integral in plausible range");

   declare
      B4 : Bounds (4);
      Cfg4 : constant Config :=
        (N_Points   => 4_000,
         Dither     => 0.1,
         Min_Points => 15,
         Max_Depth  => 6,
         Seed       => 11);
   begin
      B4.Lo := [0.0, 0.0, 0.0, 0.0];
      B4.Hi := [1.0, 1.0, 1.0, 1.0];
      R := Integrate_Miser (Constant_One'Access, B4, Cfg4);
      Check (Approx (R.Estimate, 1.0, 0.08), "MISER ∫1 on unit 4-cube ≈ 1");
      R := Plain_Monte_Carlo (Constant_One'Access, B4, Cfg4);
      Check (Approx (R.Estimate, 1.0, 0.08), "Plain MC ∫1 on unit 4-cube ≈ 1");
   end;

   ---------------------------------------------------------------------
   Section ("10. Result field consistency");
   ---------------------------------------------------------------------
   R := Integrate_Miser (Poly_X_Squared'Access, Unit_1D, Cfg_Poly);
   Check (R.Std_Error >= 0.0, "Std_Error >= 0");
   Check (R.Variance_Estimate >= 0.0, "Variance_Estimate >= 0");
   if R.Variance_Estimate > 0.0 then
      Check (Approx (R.Std_Error * R.Std_Error, R.Variance_Estimate, 1.0E-8),
             "Std_Error**2 matches Variance_Estimate");
   else
      Check (R.Std_Error = 0.0, "Zero variance → zero Std_Error");
   end if;

   R := Plain_Monte_Carlo (Product_XY'Access, Unit_Square, Cfg_Poly);
   Check (R.Estimate > 0.0, "Product_XY plain estimate positive");
   Check (R.Std_Error < 0.5, "Product_XY plain Std_Error bounded");

   --  Default config smoke
   R := Integrate_Miser (Constant_One'Access, Unit_1D);
   Check (Approx (R.Estimate, 1.0, 0.05), "Default Config MISER ∫1");

   R := Plain_Monte_Carlo (Constant_One'Access, Unit_1D);
   Check (Approx (R.Estimate, 1.0, 0.05), "Default Config Plain MC ∫1");

   ---------------------------------------------------------------------
   Section ("11. Invalid bounds raise");
   ---------------------------------------------------------------------
   declare
      Bad : Bounds (1);
      Raised : Boolean := False;
   begin
      Bad.Lo := [1 => 2.0];
      Bad.Hi := [1 => 1.0];
      begin
         R := Integrate_Miser (Constant_One'Access, Bad, Cfg_Small);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Integrate_Miser raises on invalid bounds");
   end;

   declare
      Bad : Bounds (2);
      Raised : Boolean := False;
   begin
      Bad.Lo := [0.0, 0.0];
      Bad.Hi := [1.0, 0.0];
      begin
         R := Plain_Monte_Carlo (Constant_One'Access, Bad, Cfg_Small);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Plain_Monte_Carlo raises on invalid bounds");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Real := Volume (Bounds'(D => 1,
              Lo => [1 => 1.0], Hi => [1 => 1.0]));
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Volume raises on zero-width interval");
   end;

   ---------------------------------------------------------------------
   Section ("12. Extra demos / comparisons");
   ---------------------------------------------------------------------
   R  := Integrate_Miser (Quarter_Circle'Access, Unit_Square, Cfg_Pi);
   R2 := Plain_Monte_Carlo (Quarter_Circle'Access, Unit_Square, Cfg_Pi);
   Check (abs (R.Estimate - Pi / 4.0) < 0.05, "MISER π/4 absolute error < 0.05");
   Check (abs (R2.Estimate - Pi / 4.0) < 0.08, "Plain π/4 absolute error < 0.08");
   Check (R.Estimate > 0.7 and then R.Estimate < 0.85,
          "π/4 estimate in (0.7, 0.85)");

   R := Integrate_Miser (Poly_Linear_1D'Access, Unit_1D,
     (N_Points => 3_000, Dither => 0.15, Min_Points => 20,
      Max_Depth => 6, Seed => 55));
   Check (Approx (R.Estimate, 1.0, 0.03), "MISER 2x custom config ≈ 1");

   R := Plain_Monte_Carlo (Constant_Three'Access, Unit_Cube,
     (N_Points => 2_000, Dither => 0.1, Min_Points => 15,
      Max_Depth => 4, Seed => 2));
   Check (Approx (R.Estimate, 3.0, 0.08), "Plain MC ∫3 unit cube ≈ 3");

   R := Integrate_Miser (Constant_Three'Access, Unit_Cube,
     (N_Points => 3_000, Dither => 0.1, Min_Points => 15,
      Max_Depth => 5, Seed => 2));
   Check (Approx (R.Estimate, 3.0, 0.05), "MISER ∫3 unit cube ≈ 3");

   --  Midpoint identity: ∫₀² x² = 8/3
   declare
      B : Bounds (1);
   begin
      B.Lo := [1 => 0.0];
      B.Hi := [1 => 2.0];
      R := Integrate_Miser (Poly_X_Squared'Access, B,
        (N_Points => 10_000, Dither => 0.1, Min_Points => 15,
         Max_Depth => 10, Seed => 17));
      Check (Approx (R.Estimate, 8.0 / 3.0, 0.05),
             "MISER ∫₀² x² dx ≈ 8/3");
   end;

   --  Extra API / volume consistency checks
   declare
      V1 : constant Real := Volume (Unit_1D);
      V2 : constant Real := Volume (Unit_Square);
      V3 : constant Real := Volume (Unit_Cube);
      Box : constant Bounds := Box_2D (0.0, 4.0, 1.0, 3.0);
   begin
      Check (Approx (V1 * V2, V3, 1.0E-14), "Volumes: 1D*2D = 3D unit");
      Check (Approx (Volume (Box), 8.0, 1.0E-14), "Volume [0,4]x[1,3] = 8");
      Check (Unit_Square.D <= Max_Dimension, "2D within Max_Dimension");
      Check (Unit_Cube.D <= Max_Dimension, "3D within Max_Dimension");
      R := Integrate_Miser (Constant_One'Access, Box,
        (N_Points => 2_500, Dither => 0.1, Min_Points => 15,
         Max_Depth => 6, Seed => 8));
      Check (Approx (R.Estimate, 8.0, 0.15), "MISER ∫1 on area-8 box ≈ 8");
      R2 := Plain_Monte_Carlo (Constant_One'Access, Box,
        (N_Points => 2_500, Dither => 0.1, Min_Points => 15,
         Max_Depth => 6, Seed => 8));
      Check (Approx (R2.Estimate, 8.0, 0.2), "Plain ∫1 on area-8 box ≈ 8");
      Check (abs (R.Estimate - R2.Estimate) < 0.5,
             "MISER vs Plain close on constant box");
      Check (Cfg_Pi.Seed /= Cfg_Const.Seed, "demo configs use distinct seeds");
   end;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("====================================================");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;
end Tests;
