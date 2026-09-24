--  Standalone test suite for Crank_Nicolson (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;
with Crank_Nicolson; use Crank_Nicolson;

procedure Tests is

   package Elem is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Elem;

   Pi : constant Real := Ada.Numerics.Pi;

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

   Raised : Boolean;

   --  Analytic helpers ----------------------------------------------------

   function F_Sin_Pi (X : Real) return Real is
   begin
      return Sin (Pi * X);
   end F_Sin_Pi;

   function F_Zero (X : Real) return Real is
      pragma Unreferenced (X);
   begin
      return 0.0;
   end F_Zero;

   function F_Linear (X : Real) return Real is
   begin
      return X;
   end F_Linear;

   function F_Const_One (X : Real) return Real is
      pragma Unreferenced (X);
   begin
      return 1.0;
   end F_Const_One;

   function F_X2 (X : Real) return Real is
   begin
      return X * X;
   end F_X2;

   function Sample_Sin_Pi is new Sample (F_Sin_Pi);
   function Sample_Zero   is new Sample (F_Zero);
   function Sample_Linear is new Sample (F_Linear);
   function Sample_One    is new Sample (F_Const_One);
   function Sample_X2     is new Sample (F_X2);

   --  Exact heat solution u(x,t) = exp(−π² α t) sin(π x)
   function Exact_Heat
     (X, T, Alpha : Real) return Real
   is
   begin
      return Exp (-Pi * Pi * Alpha * T) * Sin (Pi * X);
   end Exact_Heat;

begin
   Put_Line ("Crank_Nicolson test suite");
   Put_Line ("=========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Abs_Error / Vec_Near / L2 / Max_Error");
   ---------------------------------------------------------------------
   Check (Near (1.0, 1.0), "Near equal");
   Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
   Check (not Near (1.0, 2.0), "Near rejects large delta");
   Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
   Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
   Check (Near (-5.0, -5.0), "Near negatives");
   Check (Abs_Error (1.0, 1.0) = 0.0, "Abs_Error zero");
   Check (Near (Abs_Error (3.0, 1.0), 2.0), "Abs_Error 3-1");
   Check (Near (Abs_Error (-1.0, 1.0), 2.0), "Abs_Error signed");
   declare
      A : constant Grid := [1.0, 2.0, 3.0];
      B : constant Grid := [1.0, 2.0, 3.0];
      C : constant Grid := [1.0, 2.0, 3.1];
   begin
      Check (Vec_Near (A, B), "Vec_Near equal");
      Check (not Vec_Near (A, C), "Vec_Near unequal");
      Check (Vec_Near (A, C, 0.2), "Vec_Near loose Tol");
      Check (Near (Max_Error (A, B), 0.0), "Max_Error zero");
      Check (Near (Max_Error (A, C), 0.1), "Max_Error 0.1");
      Check (Near (L2_Error (A, B, 1.0), 0.0), "L2_Error zero");
      Check (L2_Error (A, C, 1.0) > 0.0, "L2_Error positive");
   end;

   ---------------------------------------------------------------------
   Section ("2. X_At / Sample");
   ---------------------------------------------------------------------
   Check (Near (X_At (0.0, 0.1, 1), 0.0), "X_At first");
   Check (Near (X_At (0.0, 0.1, 2), 0.1), "X_At second");
   Check (Near (X_At (1.0, 0.5, 3), 2.0), "X_At offset");
   declare
      F : constant Grid := Sample_Sin_Pi (5, 0.25, 0.0);
   begin
      Check (F'Length = 5, "Sample length");
      Check (Near (F (1), 0.0, 1.0E-12), "Sample sin(0)");
      Check (Near (F (3), 1.0, 1.0E-12), "Sample sin(pi/2) at x=0.5");
      Check (Near (F (5), 0.0, 1.0E-12), "Sample sin(pi) at x=1");
   end;
   declare
      F : constant Grid := Sample_X2 (4, 1.0, 0.0);
   begin
      Check (Near (F (1), 0.0), "Sample x^2 at 0");
      Check (Near (F (2), 1.0), "Sample x^2 at 1");
      Check (Near (F (4), 9.0), "Sample x^2 at 3");
   end;
   Raised := False;
   begin
      declare
         Dummy : constant Real := X_At (0.0, -1.0, 1);
         pragma Unreferenced (Dummy);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "X_At rejects H<=0");

   ---------------------------------------------------------------------
   Section ("3. R_Param");
   ---------------------------------------------------------------------
   declare
      --  α=1, Δt=0.01, H=0.1 → r = 1*0.01/(2*0.01) = 0.5
      R : constant Real := R_Param (1.0, 0.01, 0.1);
   begin
      Check (Near (R, 0.5), "R_Param 0.5");
   end;
   Check (Near (R_Param (2.0, 0.02, 0.1), 2.0), "R_Param 2.0");
   Check (Near (R_Param (1.0, 1.0E-4, 0.05),
                1.0E-4 / (2.0 * 0.0025)), "R_Param small dt");
   Raised := False;
   begin
      declare
         Dummy : constant Real := R_Param (-1.0, 0.01, 0.1);
         pragma Unreferenced (Dummy);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "R_Param rejects Alpha<=0");
   Raised := False;
   begin
      declare
         Dummy : constant Real := R_Param (1.0, 0.0, 0.1);
         pragma Unreferenced (Dummy);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "R_Param rejects Dt<=0");
   Raised := False;
   begin
      declare
         Dummy : constant Real := R_Param (1.0, 0.01, -0.1);
         pragma Unreferenced (Dummy);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "R_Param rejects H<=0");

   ---------------------------------------------------------------------
   Section ("4. Amplification / unconditional stability");
   ---------------------------------------------------------------------
   declare
      A0 : constant Real := Amplification_Factor (0.0, 1.0);
      A1 : constant Real := Amplification_Factor (1.0, Pi);
      A2 : constant Real := Amplification_Factor (10.0, Pi / 2.0);
      A3 : constant Real := Amplification_Factor (0.5, 0.0);
   begin
      Check (Near (A0, 1.0), "A(r=0)=1");
      Check (Near (A3, 1.0), "A(theta=0)=1");
      --  Nyquist: sin(π/2)=1 → A = (1-4r)/(1+4r)
      Check (Near (A1, (1.0 - 4.0) / (1.0 + 4.0)), "A Nyquist r=1");
      Check (abs (A1) <= 1.0, "|A| Nyquist r=1 <= 1");
      Check (abs (A2) <= 1.0, "|A| mid r=10 <= 1");
      Check (Amplification_Bounded (1.0, Pi), "Bounded Nyquist");
      Check (Amplification_Bounded (100.0, 2.0), "Bounded large r");
      Check (Unconditionally_Stable (0.0), "Stable r=0");
      Check (Unconditionally_Stable (0.5), "Stable r=0.5");
      Check (Unconditionally_Stable (1.0), "Stable r=1");
      Check (Unconditionally_Stable (50.0), "Stable r=50 (>> FTCS limit)");
   end;
   Raised := False;
   begin
      declare
         Dummy : constant Real := Amplification_Factor (-0.1, 1.0);
         pragma Unreferenced (Dummy);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Amplification rejects R<0");
   Raised := False;
   begin
      declare
         Dummy : constant Boolean := Unconditionally_Stable (-1.0);
         pragma Unreferenced (Dummy);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Unconditionally_Stable rejects R<0");

   ---------------------------------------------------------------------
   Section ("5. Heat_CN_Step — N=3 hand check");
   ---------------------------------------------------------------------
   --  N=3, H=1, α=1, Δt=2 → r = 1*2/(2*1)=1
   --  Interior j=2 only. U^n = [0, 1, 0], BCs stay 0.
   --  RHS = r*0 + (1-2r)*1 + r*0 = 1-2 = -1
   --  Fold BC: + r*0 = -1
   --  (1+2r) U = -1 → 3 U = -1 → U = -1/3
   declare
      U0 : constant Grid := [0.0, 1.0, 0.0];
      U1 : constant Grid :=
        Heat_CN_Step (U0, H => 1.0, Dt => 2.0, Alpha => 1.0,
                      Left_BC => 0.0, Right_BC => 0.0);
   begin
      Check (U1'Length = 3, "N=3 result length");
      Check (Near (U1 (1), 0.0), "N=3 left BC");
      Check (Near (U1 (3), 0.0), "N=3 right BC");
      Check (Near (U1 (2), -1.0 / 3.0, 1.0E-12), "N=3 interior -1/3");
   end;

   ---------------------------------------------------------------------
   Section ("6. Heat_CN_Step — N=5 hand-checkable");
   ---------------------------------------------------------------------
   --  α=1, H=1, Δt=1 → r = 1/(2)=0.5
   --  U = [0, a, b, c, 0]; after one step with zero BCs, check
   --  endpoints and that max |U| decreases for a heat bump.
   declare
      U0 : constant Grid := [0.0, 1.0, 2.0, 1.0, 0.0];
      U1 : constant Grid :=
        Heat_CN_Step (U0, 1.0, 1.0, 1.0, 0.0, 0.0);
      Max0, Max1 : Real;
   begin
      Check (U1'Length = 5, "N=5 length");
      Check (Near (U1 (1), 0.0), "N=5 left BC");
      Check (Near (U1 (5), 0.0), "N=5 right BC");
      Max0 := Max_Error (U0, Sample_Zero (5, 1.0));
      Max1 := Max_Error (U1, Sample_Zero (5, 1.0));
      Check (Max1 < Max0, "N=5 heat damps peak");
      --  Symmetry: U1(2)=U1(4)
      Check (Near (U1 (2), U1 (4), 1.0E-12), "N=5 symmetry");
   end;

   ---------------------------------------------------------------------
   Section ("7. Steady state — constant / linear BCs");
   ---------------------------------------------------------------------
   --  Constant field is exact steady state of heat with matching BCs.
   declare
      N  : constant Point_Count := 17;
      H  : constant Real := 1.0 / Real (N - 1);
      U0 : constant Grid := Sample_One (N, H);
      U  : constant Grid :=
        Heat_CN_Advance (U0, H, 0.01, 1.0, 50, 1.0, 1.0);
   begin
      Check (Vec_Near (U, U0, 1.0E-10), "Constant steady state");
   end;
   --  Linear u=x is harmonic (u_xx=0) → exact steady for heat.
   declare
      N  : constant Point_Count := 21;
      H  : constant Real := 1.0 / Real (N - 1);
      U0 : constant Grid := Sample_Linear (N, H);
      --  Perturb interior then relax
      U_Pert : Grid := U0;
      U_End  : Grid (1 .. N);
   begin
      for J in 2 .. N - 1 loop
         U_Pert (J) := U0 (J) + 0.3 * Sin (Pi * X_At (0.0, H, J));
      end loop;
      U_End := Heat_CN_Advance
        (U_Pert, H, 0.005, 1.0, 400, Left_BC => 0.0, Right_BC => 1.0);
      Check (Max_Error (U_End, U0) < 1.0E-3,
             "Long-time CN → linear equilibrium");
      Check (Near (U_End (1), 0.0), "Linear eq left BC");
      Check (Near (U_End (N), 1.0), "Linear eq right BC");
   end;

   ---------------------------------------------------------------------
   Section ("8. Manufactured solution u=exp(-π²αt) sin(πx)");
   ---------------------------------------------------------------------
   declare
      Alpha : constant Real := 1.0;
      N     : constant Point_Count := 33;  -- H = 1/32
      H     : constant Real := 1.0 / Real (N - 1);
      Dt    : constant Real := 1.0E-3;
      T_End : constant Real := 0.05;
      N_St  : constant Positive :=
        Positive (Real'Rounding (T_End / Dt));
      U0, Exact, Num : Grid (1 .. N);
      Err : Real;
   begin
      for J in 1 .. N loop
         U0 (J) := Exact_Heat (X_At (0.0, H, J), 0.0, Alpha);
      end loop;
      Num := Heat_CN_Advance (U0, H, Dt, Alpha, N_St, 0.0, 0.0);
      for J in 1 .. N loop
         Exact (J) :=
           Exact_Heat (X_At (0.0, H, J), Real (N_St) * Dt, Alpha);
      end loop;
      Err := Max_Error (Num, Exact);
      Check (Near (Num (1), 0.0, 1.0E-14), "MMS left BC");
      Check (Near (Num (N), 0.0, 1.0E-14), "MMS right BC");
      Check (Err < 5.0E-4, "MMS max error modest grid");
      Check (L2_Error (Num, Exact, H) < 5.0E-4, "MMS L2 error");
   end;

   ---------------------------------------------------------------------
   Section ("9. Spatial / temporal refinement (O(Δt²+Δx²))");
   ---------------------------------------------------------------------
   declare
      Alpha : constant Real := 1.0;
      T_End : constant Real := 0.02;

      function Run
        (N : Point_Count; Dt : Real) return Real
      is
         H    : constant Real := 1.0 / Real (N - 1);
         N_St : constant Positive :=
           Positive (Real'Rounding (T_End / Dt));
         U0, Exact, Num : Grid (1 .. N);
         T_Act : Real;
      begin
         for J in 1 .. N loop
            U0 (J) := Exact_Heat (X_At (0.0, H, J), 0.0, Alpha);
         end loop;
         Num := Heat_CN_Advance (U0, H, Dt, Alpha, N_St, 0.0, 0.0);
         T_Act := Real (N_St) * Dt;
         for J in 1 .. N loop
            Exact (J) := Exact_Heat (X_At (0.0, H, J), T_Act, Alpha);
         end loop;
         return Max_Error (Num, Exact);
      end Run;

      E_Coarse : constant Real := Run (17, 4.0E-3);
      E_Fine   : constant Real := Run (33, 1.0E-3);
      --  H halved (×1/2) and Dt /4 → expect ~4× smaller error
      Ratio : constant Real := E_Coarse / E_Fine;
   begin
      Check (E_Coarse > 0.0, "Coarse error positive");
      Check (E_Fine > 0.0, "Fine error positive");
      Check (E_Fine < E_Coarse, "Refinement reduces error");
      Check (Ratio > 2.0, "Error drops by >2x (order-ish)");
      Put_Line ("    (coarse=" & E_Coarse'Image
                & " fine=" & E_Fine'Image
                & " ratio=" & Ratio'Image & ")");
   end;

   ---------------------------------------------------------------------
   Section ("10. Large-r stability (CN damps; FTCS would fail)");
   ---------------------------------------------------------------------
   --  r_FTCS = α Δt / H² = 2 r_CN. FTCS needs r_FTCS ≤ 1/2 i.e. r_CN ≤ 1/4.
   --  Pick r_CN = 5 (≫ 1/4) and confirm CN still damps a bump.
   declare
      N     : constant Point_Count := 21;
      H     : constant Real := 1.0 / Real (N - 1);
      Alpha : constant Real := 1.0;
      --  r = α Δt /(2 H²) = 5 → Δt = 10 H²
      Dt    : constant Real := 10.0 * H * H;
      R     : constant Real := R_Param (Alpha, Dt, H);
      U0    : Grid (1 .. N);
      U     : Grid (1 .. N);
      Max0, Max_End : Real := 0.0;
   begin
      Check (Near (R, 5.0, 1.0E-10), "Large r ≈ 5");
      Check (Unconditionally_Stable (R), "Large r still |A|≤1");
      for J in 1 .. N loop
         U0 (J) := Sin (Pi * X_At (0.0, H, J));
      end loop;
      Max0 := Max_Error (U0, Sample_Zero (N, H));
      U := Heat_CN_Advance (U0, H, Dt, Alpha, 20, 0.0, 0.0);
      Max_End := Max_Error (U, Sample_Zero (N, H));
      Check (Max_End < Max0, "Large-r CN damps (no blow-up)");
      Check (Max_End < 1.0, "Large-r amplitude remains O(1)");
      Check (Near (U (1), 0.0), "Large-r left BC");
      Check (Near (U (N), 0.0), "Large-r right BC");
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid_Argument edge cases");
   ---------------------------------------------------------------------
   Raised := False;
   begin
      declare
         U : constant Grid := [0.0, 1.0];  -- length 2
         Dummy : constant Grid :=
           Heat_CN_Step (U, 0.1, 0.01, 1.0);
         pragma Unreferenced (Dummy);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Rejects grid length < 3");

   Raised := False;
   begin
      declare
         U : constant Grid := [0.0, 1.0, 0.0];
         Dummy : constant Grid :=
           Heat_CN_Step (U, -0.1, 0.01, 1.0);
         pragma Unreferenced (Dummy);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Rejects H<=0 in Step");

   Raised := False;
   begin
      declare
         U : constant Grid := [0.0, 1.0, 0.0];
         Dummy : constant Grid :=
           Heat_CN_Step (U, 0.1, -0.01, 1.0);
         pragma Unreferenced (Dummy);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Rejects Dt<=0 in Step");

   Raised := False;
   begin
      declare
         U : constant Grid := [0.0, 1.0, 0.0];
         Dummy : constant Grid :=
           Heat_CN_Step (U, 0.1, 0.01, 0.0);
         pragma Unreferenced (Dummy);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Rejects Alpha<=0 in Step");

   Raised := False;
   begin
      declare
         U : constant Grid := [0.0, 1.0, 0.0];
         Dummy : constant Grid :=
           Heat_CN_Advance (U, 0.1, 0.01, -1.0, 5);
         pragma Unreferenced (Dummy);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Advance rejects Alpha<=0");

   Raised := False;
   begin
      declare
         Dummy : constant Real :=
           L2_Error ([1.0, 2.0], [1.0, 2.0], -1.0);
         pragma Unreferenced (Dummy);
      begin
         null;
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "L2_Error rejects H<=0");

   ---------------------------------------------------------------------
   Section ("12. One-step identity / BC application");
   ---------------------------------------------------------------------
   --  Zero field stays zero.
   declare
      U0 : constant Grid := Sample_Zero (11, 0.1);
      U1 : constant Grid :=
        Heat_CN_Step (U0, 0.1, 0.01, 1.0, 0.0, 0.0);
   begin
      Check (Vec_Near (U0, U1, 1.0E-14), "Zero → zero one step");
   end;
   --  Nonzero next-time BCs are applied immediately.
   declare
      U0 : constant Grid := Sample_Zero (9, 0.125);
      U1 : constant Grid :=
        Heat_CN_Step (U0, 0.125, 0.01, 1.0,
                      Left_BC => 2.0, Right_BC => -1.0);
   begin
      Check (Near (U1 (1), 2.0), "Step applies Left_BC");
      Check (Near (U1 (9), -1.0), "Step applies Right_BC");
   end;
   --  Advance length preserved
   declare
      U0 : constant Grid := Sample_Sin_Pi (25, 1.0 / 24.0);
      U  : constant Grid :=
        Heat_CN_Advance (U0, 1.0 / 24.0, 1.0E-3, 1.0, 10);
   begin
      Check (U'Length = U0'Length, "Advance preserves length");
      Check (Near (U (1), 0.0), "Advance left BC");
      Check (Near (U (25), 0.0), "Advance right BC");
   end;

   ---------------------------------------------------------------------
   Section ("13. Amplification formula spot checks");
   ---------------------------------------------------------------------
   declare
      --  A = (1 - 4r s²)/(1 + 4r s²), s = sin(θ/2)
      R : constant Real := 0.25;
      Th : constant Real := Pi / 3.0;
      S  : constant Real := Sin (Th / 2.0);
      Expected : constant Real :=
        (1.0 - 4.0 * R * S * S) / (1.0 + 4.0 * R * S * S);
   begin
      Check (Near (Amplification_Factor (R, Th), Expected, 1.0E-14),
             "A formula spot check");
   end;
   --  As r→∞ at Nyquist, A → -1
   Check (Near (Amplification_Factor (1.0E6, Pi), -1.0, 1.0E-5),
          "A → -1 as r→∞ Nyquist");
   Check (Amplification_Bounded (1.0E6, Pi), "Still bounded at huge r");

   ---------------------------------------------------------------------
   Section ("14. Sample / helpers extras");
   ---------------------------------------------------------------------
   declare
      Ones : constant Grid := Sample_One (8, 0.5, 0.0);
   begin
      Check (Ones'Length = 8, "Sample_One length");
      Check (Near (Ones (1), 1.0), "Sample_One value");
      Check (Near (Ones (8), 1.0), "Sample_One last");
   end;
   Check (Near (Abs_Error (0.0, 0.0), 0.0), "Abs_Error 0");
   Check (Near (Max_Error ([0.0, 0.0], [0.0, 0.0]), 0.0),
          "Max_Error zeros");

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("========================================");
   Put_Line ("Passed:" & Pass_Count'Image
             & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILURES");
   end if;
end Tests;
