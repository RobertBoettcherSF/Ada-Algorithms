with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions; use Ada.Numerics.Long_Elementary_Functions;
with Orbital_Mechanics; use Orbital_Mechanics;

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

   --  Relative error threshold checker
   function Approx_Eq (Val, Expected : Long_Float; Rel_Tol : Long_Float := 1.0e-4) return Boolean is
   begin
      if Expected = 0.0 then
         return abs (Val) < Rel_Tol;
      else
         return abs (Val - Expected) / abs (Expected) <= Rel_Tol;
      end if;
   end Approx_Eq;

   R_Earth : constant Positive_Distance := 6_378_137.0; -- Earth mean equatorial radius
   LEO_Alt : constant Positive_Distance := 400_000.0;   -- 400 km LEO altitude
   LEO_Rad : constant Positive_Distance := R_Earth + LEO_Alt; -- 6,778,137 m
   GEO_Rad : constant Positive_Distance := 42_164_000.0;     -- GEO radius

begin
   Put_Line ("============================================================");
   Put_Line ("           ORBITAL MECHANICS TEST SUITE                     ");
   Put_Line ("============================================================");

   -------------------------------------------------------------------
   --  TEST 1: Circular Orbital Velocity (LEO and GEO)
   -------------------------------------------------------------------
   Put_Line ("TEST 1 -- Circular Orbital Velocity");
   declare
      V_LEO : constant Speed := Circular_Velocity (Mu_Earth, LEO_Rad);
      V_GEO : constant Speed := Circular_Velocity (Mu_Earth, GEO_Rad);
   begin
      Check ("1.1 LEO circular velocity near 7672 m/s",
             Approx_Eq (Long_Float (V_LEO), 7672.6, 1.0e-3));
      Check ("1.2 GEO circular velocity near 3075 m/s",
             Approx_Eq (Long_Float (V_GEO), 3074.6, 1.0e-3));
      Check ("1.3 LEO velocity is strictly higher than GEO velocity",
             V_LEO > V_GEO);
   end;

   -------------------------------------------------------------------
   --  TEST 2: Escape Velocity Properties
   -------------------------------------------------------------------
   Put_Line ("TEST 2 -- Escape Velocity");
   declare
      V_Esc_Surface : constant Speed := Escape_Velocity (Mu_Earth, R_Earth);
      V_Circ_Surf   : constant Speed := Circular_Velocity (Mu_Earth, R_Earth);
      Ratio         : constant Long_Float := Long_Float (V_Esc_Surface) / Long_Float (V_Circ_Surf);
   begin
      Check ("2.1 Earth surface escape speed is approx 11186 m/s",
             Approx_Eq (Long_Float (V_Esc_Surface), 11186.0, 1.0e-3));
      Check ("2.2 Exact sqrt(2) ratio with circular speed",
             Approx_Eq (Ratio, 1.41421356, 1.0e-5));
      Check ("2.3 Escape velocity decreases with higher altitude",
             Escape_Velocity (Mu_Earth, GEO_Rad) < V_Esc_Surface);
   end;

   -------------------------------------------------------------------
   --  TEST 3: Vis-Viva Equation Across Conic Sections
   -------------------------------------------------------------------
   Put_Line ("TEST 3 -- General Vis-Viva Equation");
   declare
      V_Elliptic  : constant Speed := Vis_Viva_Velocity (Mu_Earth, LEO_Rad, 1.0 / Long_Float (GEO_Rad));
      V_Parabolic : constant Speed := Vis_Viva_Velocity (Mu_Earth, LEO_Rad, 0.0);
      V_Circ      : constant Speed := Circular_Velocity (Mu_Earth, LEO_Rad);
   begin
      Check ("3.1 Vis-Viva circular match when 1/a = 1/r",
             Approx_Eq (Long_Float (Vis_Viva_Velocity (Mu_Earth, LEO_Rad, 1.0 / Long_Float (LEO_Rad))),
                        Long_Float (V_Circ), 1.0e-6));
      Check ("3.2 Parabolic velocity matches escape velocity",
             Approx_Eq (Long_Float (V_Parabolic), Long_Float (Escape_Velocity (Mu_Earth, LEO_Rad)), 1.0e-6));
      Check ("3.3 Hierarchy: v_circ < v_elliptic_apogee_transfer < v_esc",
             V_Circ < V_Elliptic and then V_Elliptic < V_Parabolic);
   end;

   -------------------------------------------------------------------
   --  TEST 4: Kepler's Third Law and Period Calculations
   -------------------------------------------------------------------
   Put_Line ("TEST 4 -- Kepler's Third Law (Harmonic Law)");
   declare
      T_LEO : constant Positive_Time := Orbital_Period (Mu_Earth, LEO_Rad);
      T_GEO : constant Positive_Time := Orbital_Period (Mu_Earth, GEO_Rad);
      N_LEO : constant Long_Float    := Mean_Motion (Mu_Earth, LEO_Rad);
   begin
      Check ("4.1 LEO period is roughly 92.5 minutes (5555 s)",
             Approx_Eq (Long_Float (T_LEO), 5555.0, 1.0e-2));
      Check ("4.2 GEO period equals one sidereal day (approx 86164 s)",
             Approx_Eq (Long_Float (T_GEO), 86164.0, 2.0e-3));
      Check ("4.3 Mean motion relation n = 2*pi / T",
             Approx_Eq (N_LEO * Long_Float (T_LEO), 2.0 * Ada.Numerics.Pi, 1.0e-6));
   end;

   -------------------------------------------------------------------
   --  TEST 5: Semi-Major Axis Inversion from Period
   -------------------------------------------------------------------
   Put_Line ("TEST 5 -- Inversion: Semi-Major Axis from Period");
   declare
      Target_T : constant Positive_Time := 86164.0905; -- Earth sidereal day
      Calc_A   : constant Positive_Distance := Semi_Major_Axis_From_Period (Mu_Earth, Target_T);
      Roundtrip_T : constant Positive_Time := Orbital_Period (Mu_Earth, Calc_A);
   begin
      Check ("5.1 Calculated GEO semi-major axis is 42,164 km",
             Approx_Eq (Long_Float (Calc_A), 4.2164e7, 1.0e-3));
      Check ("5.2 Period-to-Axis-to-Period round-trip consistency",
             Approx_Eq (Long_Float (Roundtrip_T), Long_Float (Target_T), 1.0e-6));
      Check ("5.3 Monotonicity: longer period gives strictly larger semi-major axis",
             Semi_Major_Axis_From_Period (Mu_Earth, Target_T * 2.0) > Calc_A);
   end;

   -------------------------------------------------------------------
   --  TEST 6: Specific Orbital Energy
   -------------------------------------------------------------------
   Put_Line ("TEST 6 -- Specific Mechanical Energy");
   declare
      V_Circ : constant Speed := Circular_Velocity (Mu_Earth, LEO_Rad);
      E_Circ : constant Long_Float := Specific_Orbital_Energy (V_Circ, LEO_Rad, Mu_Earth);
      E_Theory : constant Long_Float := -Long_Float (Mu_Earth) / (2.0 * Long_Float (LEO_Rad));
      V_Esc  : constant Speed := Escape_Velocity (Mu_Earth, LEO_Rad);
      E_Esc  : constant Long_Float := Specific_Orbital_Energy (V_Esc, LEO_Rad, Mu_Earth);
   begin
      Check ("6.1 Bound circular orbit energy matches -mu / (2*a)",
             Approx_Eq (E_Circ, E_Theory, 1.0e-5));
      Check ("6.2 Parabolic escape energy is zero",
             abs (E_Esc) < 1.0e-1);
      Check ("6.3 Hyperbolic orbit has positive energy",
             Specific_Orbital_Energy (Speed (Long_Float (V_Esc) + 500.0), LEO_Rad, Mu_Earth) > 0.0);
   end;

   -------------------------------------------------------------------
   --  TEST 7: Apsidal Distances and Semi-Latus Rectum
   -------------------------------------------------------------------
   Put_Line ("TEST 7 -- Apsidal Geometry");
   declare
      A   : constant Positive_Distance := 10_000_000.0;
      Ecc : constant Elliptic_Eccentricity := 0.2;
      Rp  : constant Distance := Periapsis_Distance (A, Ecc);
      Ra  : constant Positive_Distance := Apoapsis_Distance (A, Ecc);
      P   : constant Positive_Distance := Semi_Latus_Rectum (A, Ecc);
   begin
      Check ("7.1 Periapsis rp = a*(1-e) is 8,000,000 m",
             Approx_Eq (Long_Float (Rp), 8_000_000.0, 1.0e-6));
      Check ("7.2 Apoapsis ra = a*(1+e) is 12,000,000 m",
             Approx_Eq (Long_Float (Ra), 12_000_000.0, 1.0e-6));
      Check ("7.3 Average of rp and ra equals semi-major axis",
             Approx_Eq ((Long_Float (Rp) + Long_Float (Ra)) / 2.0, Long_Float (A), 1.0e-6));
      Check ("7.4 Semi-latus rectum p = a*(1 - e^2) = 9,600,000 m",
             Approx_Eq (Long_Float (P), 9_600_000.0, 1.0e-6));
   end;

   -------------------------------------------------------------------
   --  TEST 8: Kepler's Equation Solver (Elliptic)
   -------------------------------------------------------------------
   Put_Line ("TEST 8 -- Kepler Solver (Elliptic Orbit)");
   declare
      Ecc : constant Elliptic_Eccentricity := 0.1;
      M_Known : constant Radians := 0.75;
      E_Calc  : constant Radians := Solve_Kepler_Elliptic (M_Known, Ecc);
      M_Back  : constant Long_Float :=
        Long_Float (E_Calc) - Long_Float (Ecc) * Sin (Long_Float (E_Calc));
   begin
      Check ("8.1 Solver satisfies Kepler equation M = E - e*sin(E)",
             Approx_Eq (M_Back, Long_Float (M_Known), 1.0e-9));
      Check ("8.2 Zero mean anomaly produces zero eccentric anomaly",
             Approx_Eq (Long_Float (Solve_Kepler_Elliptic (0.0, Ecc)), 0.0, 1.0e-9));
      Check ("8.3 Pi anomaly symmetry: M = pi yields E = pi",
             Approx_Eq (Long_Float (Solve_Kepler_Elliptic (Radians (Ada.Numerics.Pi), Ecc)),
                        Ada.Numerics.Pi, 1.0e-8));
   end;

   -------------------------------------------------------------------
   --  TEST 9: Hyperbolic Kepler Equation Solver and Excess Velocity
   -------------------------------------------------------------------
   Put_Line ("TEST 9 -- Kepler Solver (Hyperbolic Orbit)");
   declare
      Ecc_Hyp : constant Hyperbolic_Eccentricity := 1.5;
      M_Hyp   : constant Radians := 1.2;
      H_Calc  : constant Radians := Solve_Kepler_Hyperbolic (M_Hyp, Ecc_Hyp);
      M_Back  : constant Long_Float :=
        Long_Float (Ecc_Hyp) * Sinh (Long_Float (H_Calc)) - Long_Float (H_Calc);
      V_Inf   : constant Speed := Hyperbolic_Excess_Velocity (Mu_Earth, -2.0e7);
   begin
      Check ("9.1 Hyperbolic Kepler residual e*sinh(H) - H - M = 0",
             Approx_Eq (M_Back, Long_Float (M_Hyp), 1.0e-8));
      Check ("9.2 Hyperbolic excess speed sqrt(-mu/a) evaluates correctly",
             Approx_Eq (Long_Float (V_Inf), 4464.3, 1.0e-3));
      Check ("9.3 H has same sign as M (positive for positive input)",
             Long_Float (H_Calc) > 0.0);
   end;

   -------------------------------------------------------------------
   --  TEST 10: True Anomaly Transformation and Radius Function
   -------------------------------------------------------------------
   Put_Line ("TEST 10 -- True Anomaly and Radial Position");
   declare
      Ecc : constant Elliptic_Eccentricity := 0.25;
      A   : constant Positive_Distance := 10_000_000.0;
      P   : constant Positive_Distance := Semi_Latus_Rectum (A, Ecc);
      Nu0 : constant Radians := True_Anomaly_From_Eccentric (0.0, Ecc);
      R0  : constant Positive_Distance := Radius_At_True_Anomaly (P, Ecc, Nu0);
      NuPi: constant Radians := True_Anomaly_From_Eccentric (Radians (Ada.Numerics.Pi), Ecc);
      RPi : constant Positive_Distance := Radius_At_True_Anomaly (P, Ecc, NuPi);
   begin
      Check ("10.1 E = 0 corresponds to true anomaly nu = 0",
             Approx_Eq (Long_Float (Nu0), 0.0, 1.0e-6));
      Check ("10.2 Radius at nu = 0 is periapsis distance",
             Approx_Eq (Long_Float (R0), Long_Float (Periapsis_Distance (A, Ecc)), 1.0e-6));
      Check ("10.3 Radius at nu = pi is apoapsis distance",
             Approx_Eq (Long_Float (RPi), Long_Float (Apoapsis_Distance (A, Ecc)), 1.0e-6));
   end;

   -------------------------------------------------------------------
   --  TEST 11: Hohmann Transfer (LEO to GEO)
   -------------------------------------------------------------------
   Put_Line ("TEST 11 -- Hohmann Transfer (LEO to GEO)");
   declare
      Tx : constant Hohmann_Transfer_Result := Hohmann_Transfer (Mu_Earth, LEO_Rad, GEO_Rad);
   begin
      Check ("11.1 First burn Delta V_1 near 2397 m/s",
             Approx_Eq (Long_Float (Tx.Delta_V_1), 2397.5, 1.0e-2));
      Check ("11.2 Second burn Delta V_2 near 1456 m/s",
             Approx_Eq (Long_Float (Tx.Delta_V_2), 1456.5, 1.0e-2));
      Check ("11.3 Total Delta V near 3854 m/s",
             Approx_Eq (Long_Float (Tx.Total_Delta_V), 3854.0, 1.0e-2));
      Check ("11.4 Time of flight is approx 5.27 hours (18990 s)",
             Approx_Eq (Long_Float (Tx.Time_Of_Flight), 18990.0, 1.0e-2));
   end;

   -------------------------------------------------------------------
   --  TEST 12: Conservation of Specific Angular Momentum
   -------------------------------------------------------------------
   Put_Line ("TEST 12 -- Specific Angular Momentum Invariant");
   declare
      A    : constant Positive_Distance := 15_000_000.0;
      Ecc  : constant Elliptic_Eccentricity := 0.3;
      P    : constant Positive_Distance := Semi_Latus_Rectum (A, Ecc);
      H    : constant Long_Float := Specific_Relative_Angular_Momentum (P, Mu_Earth);
      Rp   : constant Positive_Distance := Positive_Distance (Periapsis_Distance (A, Ecc));
      Ra   : constant Positive_Distance := Apoapsis_Distance (A, Ecc);
      Vp   : constant Speed := Vis_Viva_Velocity (Mu_Earth, Rp, 1.0 / Long_Float (A));
      Va   : constant Speed := Vis_Viva_Velocity (Mu_Earth, Ra, 1.0 / Long_Float (A));
      H_p  : constant Long_Float := Long_Float (Rp) * Long_Float (Vp);
      H_a  : constant Long_Float := Long_Float (Ra) * Long_Float (Va);
   begin
      Check ("12.1 Angular momentum h = sqrt(p*mu) matches r_p * v_p",
             Approx_Eq (H, H_p, 1.0e-4));
      Check ("12.2 Periapsis and Apoapsis angular momentum are identical (conservation)",
             Approx_Eq (H_p, H_a, 1.0e-5));
      Check ("12.3 Speed at periapsis is strictly higher than at apoapsis",
             Vp > Va);
   end;

   -------------------------------------------------------------------
   --  TEST 13: Edge Cases and Robustness
   -------------------------------------------------------------------
   Put_Line ("TEST 13 -- Edge Cases and Robustness");
   begin
      --  13.1 Testing invalid radius/energy resulting in negative term
      begin
         declare
            Dummy : Speed := Vis_Viva_Velocity (Mu_Earth, 1.0e9, 1.0 / 100.0);
            pragma Unreferenced (Dummy);
         begin
            Check ("13.1 Invalid energy didn't raise exception", False);
         end;
      exception
         when Singularity_Error =>
            Check ("13.1 Singularity_Error correctly raised on negative kinetic energy", True);
         when others =>
            Check ("13.1 Unexpected exception raised", False);
      end;

      --  13.2 Circular orbit limit: e = 0.0 -> rp = ra = a
      declare
         A_Circ : constant Positive_Distance := 7_000_000.0;
         E_Circ : constant Elliptic_Eccentricity := 0.0;
         Rp     : constant Distance := Periapsis_Distance (A_Circ, E_Circ);
         Ra     : constant Positive_Distance := Apoapsis_Distance (A_Circ, E_Circ);
      begin
         Check ("13.2 Eccentricity = 0 yields rp == ra == a",
                Long_Float (Rp) = Long_Float (A_Circ) and then Long_Float (Ra) = Long_Float (A_Circ));
      end;

      --  13.3 Parabolic limit: e = 1.0 -> rp = a * 0 = 0
      declare
         A_Parab : constant Positive_Distance := 7_000_000.0;
         E_Parab : constant Eccentricity := 1.0;
      begin
         Check ("13.3 Eccentricity = 1.0 yields periapsis rp = 0 for collision path",
                Long_Float (Periapsis_Distance (A_Parab, E_Parab)) = 0.0);
      end;
   end;

   -------------------------------------------------------------------
   --  SUMMARY
   -------------------------------------------------------------------
   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");

end Tests;
