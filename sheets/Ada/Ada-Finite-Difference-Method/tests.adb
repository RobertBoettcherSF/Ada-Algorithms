--  Standalone test suite for Finite_Difference_Method (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;
with Finite_Difference_Method; use Finite_Difference_Method;

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

   function F_Sin (X : Real) return Real is
   begin
      return Sin (X);
   end F_Sin;

   function F_Cos (X : Real) return Real is
   begin
      return Cos (X);
   end F_Cos;

   function F_Quad (X : Real) return Real is
   begin
      --  u(x) = x (1 − x);  −u'' = 2
      return X * (1.0 - X);
   end F_Quad;

   function F_Sine_Poisson (X : Real) return Real is
   begin
      --  u(x) = sin(π x);  −u'' = π² sin(π x)
      return Sin (Pi * X);
   end F_Sine_Poisson;

   function F_Exp (X : Real) return Real is
   begin
      return Exp (X);
   end F_Exp;

   function F_X2 (X : Real) return Real is
   begin
      return X * X;
   end F_X2;

   function Sample_Sin is new Sample (F_Sin);
   function Sample_Cos is new Sample (F_Cos);
   function Sample_Exp is new Sample (F_Exp);
   function Sample_X2  is new Sample (F_X2);

begin
   Put_Line ("Finite_Difference_Method test suite");
   Put_Line ("===================================");

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
      F : constant Grid := Sample_Sin (5, Pi / 4.0, 0.0);
   begin
      Check (F'Length = 5, "Sample length");
      Check (Near (F (1), 0.0, 1.0E-12), "Sample sin(0)");
      Check (Near (F (3), 1.0, 1.0E-12), "Sample sin(pi/2)");
      Check (Near (F (5), 0.0, 1.0E-12), "Sample sin(pi)");
   end;
   declare
      F : constant Grid := Sample_X2 (4, 1.0, 0.0);
   begin
      Check (Near (F (1), 0.0), "Sample x^2 at 0");
      Check (Near (F (2), 1.0), "Sample x^2 at 1");
      Check (Near (F (4), 9.0), "Sample x^2 at 3");
   end;

   ---------------------------------------------------------------------
   Section ("3. Diff_Forward on sin / cos / polynomial");
   ---------------------------------------------------------------------
   declare
      H  : constant Real := Pi / 64.0;
      N  : constant Point_Count := 65;
      F  : constant Grid := Sample_Sin (N, H, 0.0);
      DF : constant Grid := Diff_Forward (F, H);
      Err, Exact : Real;
      Max_E : Real := 0.0;
   begin
      Check (DF'Length = N - 1, "Forward length N-1");
      for K in DF'Range loop
         Exact := Cos (X_At (0.0, H, K));  -- at left point
         Err := Abs_Error (DF (K), Exact);
         if Err > Max_E then
            Max_E := Err;
         end if;
      end loop;
      Check (Max_E < 0.05, "Forward sin' max err coarse");
      Check (Near (DF (1), (F (2) - F (1)) / H), "Forward first stencil");
   end;
   declare
      H  : constant Real := 0.01;
      F  : constant Grid := Sample_X2 (11, H, 0.0);
      DF : constant Grid := Diff_Forward (F, H);
   begin
      --  f=x², f'=2x; forward at x=0: (h²−0)/h = h  (exact 0) → O(h)
      Check (Near (DF (1), H), "Forward x^2 at 0 = h");
      --  at x=0.05 (index 6): exact 0.1; forward uses (0.06²−0.05²)/0.01
      Check (Near (DF (6), (0.06**2 - 0.05**2) / H), "Forward x^2 mid");
   end;
   declare
      H  : constant Real := Pi / 32.0;
      F  : constant Grid := Sample_Cos (33, H, 0.0);
      DF : constant Grid := Diff_Forward (F, H);
      Exact : Real;
      Ok : Boolean := True;
   begin
      for K in 1 .. 10 loop
         Exact := -Sin (X_At (0.0, H, K));
         if Abs_Error (DF (K), Exact) > 0.1 then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "Forward cos' first 10 pts");
   end;

   ---------------------------------------------------------------------
   Section ("4. Diff_Backward");
   ---------------------------------------------------------------------
   declare
      H  : constant Real := Pi / 64.0;
      N  : constant Point_Count := 65;
      F  : constant Grid := Sample_Sin (N, H, 0.0);
      DB : constant Grid := Diff_Backward (F, H);
      Exact, Err : Real;
      Max_E : Real := 0.0;
   begin
      Check (DB'Length = N - 1, "Backward length N-1");
      for K in DB'Range loop
         --  Result(k) at right point index K+1
         Exact := Cos (X_At (0.0, H, K + 1));
         Err := Abs_Error (DB (K), Exact);
         if Err > Max_E then
            Max_E := Err;
         end if;
      end loop;
      Check (Max_E < 0.05, "Backward sin' max err coarse");
   end;
   declare
      H  : constant Real := 0.01;
      F  : constant Grid := [0.0, 0.01, 0.04, 0.09];  -- x^2 at 0,0.01,0.02,0.03
      DB : constant Grid := Diff_Backward (F, H);
   begin
      Check (DB'Length = 3, "Backward short length");
      Check (Near (DB (1), (0.01 - 0.0) / H), "Backward first pair");
   end;

   ---------------------------------------------------------------------
   Section ("5. Diff_Central first derivative");
   ---------------------------------------------------------------------
   declare
      H  : constant Real := Pi / 64.0;
      N  : constant Point_Count := 65;
      F  : constant Grid := Sample_Sin (N, H, 0.0);
      DC : constant Grid := Diff_Central (F, H);
      Exact, Err : Real;
      Max_E : Real := 0.0;
   begin
      Check (DC'Length = N - 2, "Central length N-2");
      for K in DC'Range loop
         Exact := Cos (X_At (0.0, H, K + 1));  -- interior index K+1
         Err := Abs_Error (DC (K), Exact);
         if Err > Max_E then
            Max_E := Err;
         end if;
      end loop;
      Check (Max_E < 5.0E-3, "Central sin' much tighter than forward");
   end;
   declare
      H  : constant Real := 0.05;
      F  : constant Grid := Sample_X2 (21, H, 0.0);
      DC : constant Grid := Diff_Central (F, H);
      --  central on x² is exact (f'''=0): f'(x)=2x
      Ok : Boolean := True;
      Exact : Real;
   begin
      for K in DC'Range loop
         Exact := 2.0 * X_At (0.0, H, K + 1);
         if not Near (DC (K), Exact, 1.0E-12) then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "Central exact on x^2 (cubic remainder 0)");
   end;

   ---------------------------------------------------------------------
   Section ("6. Diff2_Central second derivative");
   ---------------------------------------------------------------------
   declare
      H  : constant Real := Pi / 64.0;
      N  : constant Point_Count := 65;
      F  : constant Grid := Sample_Sin (N, H, 0.0);
      D2 : constant Grid := Diff2_Central (F, H);
      Exact, Err : Real;
      Max_E : Real := 0.0;
   begin
      Check (D2'Length = N - 2, "Diff2 length N-2");
      for K in D2'Range loop
         Exact := -Sin (X_At (0.0, H, K + 1));
         Err := Abs_Error (D2 (K), Exact);
         if Err > Max_E then
            Max_E := Err;
         end if;
      end loop;
      Check (Max_E < 5.0E-3, "Diff2 sin'' accuracy");
   end;
   declare
      H  : constant Real := 0.1;
      F  : constant Grid := Sample_X2 (11, H, 0.0);
      D2 : constant Grid := Diff2_Central (F, H);
      Ok : Boolean := True;
   begin
      for K in D2'Range loop
         if not Near (D2 (K), 2.0, 1.0E-12) then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "Diff2 of x^2 is exactly 2");
   end;
   declare
      H  : constant Real := 0.05;
      F  : constant Grid := Sample_Exp (21, H, 0.0);
      D2 : constant Grid := Diff2_Central (F, H);
      Exact : Real;
      Max_E : Real := 0.0;
   begin
      for K in D2'Range loop
         Exact := Exp (X_At (0.0, H, K + 1));  -- (e^x)'' = e^x
         if Abs_Error (D2 (K), Exact) > Max_E then
            Max_E := Abs_Error (D2 (K), Exact);
         end if;
      end loop;
      Check (Max_E < 0.01, "Diff2 exp'' moderate err");
   end;

   ---------------------------------------------------------------------
   Section ("7. Order of accuracy: forward O(h) vs central O(h^2)");
   ---------------------------------------------------------------------
   declare
      --  Compare max error on sin' at two resolutions
      procedure Max_Fwd_Err (H : Real; N : Point_Count; E : out Real) is
         F  : constant Grid := Sample_Sin (N, H, 0.0);
         DF : constant Grid := Diff_Forward (F, H);
         Exact, Err : Real;
      begin
         E := 0.0;
         for K in DF'Range loop
            Exact := Cos (X_At (0.0, H, K));
            Err := Abs_Error (DF (K), Exact);
            if Err > E then
               E := Err;
            end if;
         end loop;
      end Max_Fwd_Err;

      procedure Max_Cen_Err (H : Real; N : Point_Count; E : out Real) is
         F  : constant Grid := Sample_Sin (N, H, 0.0);
         DC : constant Grid := Diff_Central (F, H);
         Exact, Err : Real;
      begin
         E := 0.0;
         for K in DC'Range loop
            Exact := Cos (X_At (0.0, H, K + 1));
            Err := Abs_Error (DC (K), Exact);
            if Err > E then
               E := Err;
            end if;
         end loop;
      end Max_Cen_Err;

      H1 : constant Real := Pi / 32.0;
      H2 : constant Real := Pi / 64.0;
      E1_F, E2_F, E1_C, E2_C : Real;
      Ratio_F, Ratio_C : Real;
   begin
      Max_Fwd_Err (H1, 33, E1_F);
      Max_Fwd_Err (H2, 65, E2_F);
      Max_Cen_Err (H1, 33, E1_C);
      Max_Cen_Err (H2, 65, E2_C);
      Ratio_F := E1_F / E2_F;
      Ratio_C := E1_C / E2_C;
      Check (E2_F < E1_F, "Forward error decreases on refine");
      Check (E2_C < E1_C, "Central error decreases on refine");
      --  h halves → forward ~2×, central ~4×
      Check (Ratio_F > 1.7 and then Ratio_F < 2.5,
             "Forward ~O(h) ratio ~2");
      Check (Ratio_C > 3.5 and then Ratio_C < 4.5,
             "Central ~O(h^2) ratio ~4");
      Check (E2_C < E2_F, "Central more accurate than forward same h");
   end;

   ---------------------------------------------------------------------
   Section ("8. Solve_Poisson_1D — quadratic exact");
   ---------------------------------------------------------------------
   --  u(x)=x(1−x) on [0,1], u(0)=u(1)=0, −u''=2
   declare
      N  : constant Point_Count := 15;  -- interior
      H  : constant Real := 1.0 / Real (N + 1);
      G  : Grid (1 .. N);
      U  : Grid (1 .. N + 2);
      Exact : Grid (1 .. N + 2);
      X : Real;
   begin
      for J in 1 .. N loop
         G (J) := 2.0;
      end loop;
      U := Solve_Poisson_1D (G, H, 0.0, 0.0);
      Check (U'Length = N + 2, "Poisson quad length");
      Check (Near (U (1), 0.0), "Poisson quad U_Left");
      Check (Near (U (N + 2), 0.0), "Poisson quad U_Right");
      for J in 1 .. N + 2 loop
         X := X_At (0.0, H, J);
         Exact (J) := F_Quad (X);
      end loop;
      Check (Vec_Near (U, Exact, 1.0E-10),
             "Poisson quad matches exact (FD exact on cubics)");
      Check (Near (Max_Error (U, Exact), 0.0, 1.0E-10),
             "Poisson quad Max_Error ~ 0");
      Check (Near (L2_Error (U, Exact, H), 0.0, 1.0E-10),
             "Poisson quad L2 ~ 0");
   end;
   --  Nonzero Dirichlet: u(x)=x^2 on [0,1], −u''=−2? Wait u''=2 so −u''=-2
   declare
      N  : constant Point_Count := 9;
      H  : constant Real := 1.0 / Real (N + 1);
      G  : constant Grid (1 .. N) := [others => -2.0];
      U  : Grid (1 .. N + 2);
      Exact : Grid (1 .. N + 2);
      X : Real;
   begin
      U := Solve_Poisson_1D (G, H, 0.0, 1.0);  -- u(0)=0, u(1)=1
      for J in 1 .. N + 2 loop
         X := X_At (0.0, H, J);
         Exact (J) := X * X;
      end loop;
      Check (Near (U (1), 0.0), "Poisson x^2 left BC");
      Check (Near (U (N + 2), 1.0), "Poisson x^2 right BC");
      Check (Vec_Near (U, Exact, 1.0E-10), "Poisson x^2 exact");
   end;

   ---------------------------------------------------------------------
   Section ("9. Solve_Poisson_1D — sine manufactured");
   ---------------------------------------------------------------------
   declare
      N  : constant Point_Count := 31;
      H  : constant Real := 1.0 / Real (N + 1);
      G  : Grid (1 .. N);
      U  : Grid (1 .. N + 2);
      Exact : Grid (1 .. N + 2);
      X : Real;
      Max_E : Real;
   begin
      for J in 1 .. N loop
         X := X_At (0.0, H, J + 1);  -- interior j+1
         G (J) := Pi * Pi * Sin (Pi * X);
      end loop;
      U := Solve_Poisson_1D (G, H, 0.0, 0.0);
      for J in 1 .. N + 2 loop
         Exact (J) := F_Sine_Poisson (X_At (0.0, H, J));
      end loop;
      Max_E := Max_Error (U, Exact);
      Check (Max_E < 1.0E-3, "Poisson sine Max_Error < 1e-3");
      Check (L2_Error (U, Exact, H) < 1.0E-3, "Poisson sine L2 < 1e-3");
      Check (Near (U (1), 0.0) and then Near (U (N + 2), 0.0),
             "Poisson sine BCs");
   end;
   --  Refinement improves sine Poisson error
   declare
      function Poisson_Sine_Err (N_Int : Point_Count) return Real is
         H  : constant Real := 1.0 / Real (N_Int + 1);
         G  : Grid (1 .. N_Int);
         U  : Grid (1 .. N_Int + 2);
         Exact : Grid (1 .. N_Int + 2);
         X : Real;
      begin
         for J in 1 .. N_Int loop
            X := X_At (0.0, H, J + 1);
            G (J) := Pi * Pi * Sin (Pi * X);
         end loop;
         U := Solve_Poisson_1D (G, H, 0.0, 0.0);
         for J in 1 .. N_Int + 2 loop
            Exact (J) := Sin (Pi * X_At (0.0, H, J));
         end loop;
         return Max_Error (U, Exact);
      end Poisson_Sine_Err;

      E_Coarse : constant Real := Poisson_Sine_Err (15);
      E_Fine   : constant Real := Poisson_Sine_Err (31);
      Ratio    : constant Real := E_Coarse / E_Fine;
   begin
      Check (E_Fine < E_Coarse, "Poisson sine refine improves");
      Check (Ratio > 3.5 and then Ratio < 5.0,
             "Poisson sine ~O(h^2) ratio ~4");
   end;

   ---------------------------------------------------------------------
   Section ("10. Heat_FTCS_Step — constants / stability");
   ---------------------------------------------------------------------
   Check (FTCS_Stable (0.0), "FTCS_Stable 0");
   Check (FTCS_Stable (0.5), "FTCS_Stable 0.5");
   Check (FTCS_Stable (0.25), "FTCS_Stable 0.25");
   Check (not FTCS_Stable (-0.1), "FTCS_Stable rejects negative");
   Check (not FTCS_Stable (0.51), "FTCS_Stable rejects > 1/2");
   declare
      U0 : constant Grid := [3.0, 3.0, 3.0, 3.0, 3.0];
      U1 : constant Grid := Heat_FTCS_Step (U0, 0.25);
   begin
      Check (Vec_Near (U0, U1, 1.0E-14), "Heat preserves constant");
      Check (Near (U1 (1), 3.0) and then Near (U1 (5), 3.0),
             "Heat keeps Dirichlet ends");
   end;
   declare
      U0 : constant Grid := [0.0, 1.0, 0.0];
      U1 : constant Grid := Heat_FTCS_Step (U0, 0.5);
      --  u1 = 1 + 0.5*(0 − 2 + 0) = 0
   begin
      Check (Near (U1 (1), 0.0), "Heat spike left BC");
      Check (Near (U1 (2), 0.0), "Heat spike centre → 0 at r=1/2");
      Check (Near (U1 (3), 0.0), "Heat spike right BC");
   end;
   declare
      U0 : constant Grid := [0.0, 1.0, 2.0, 1.0, 0.0];
      U1 : constant Grid := Heat_FTCS_Step (U0, 0.25);
   begin
      Check (Near (U1 (1), 0.0), "Heat profile left");
      Check (Near (U1 (5), 0.0), "Heat profile right");
      --  j=2: 1 + 0.25*(0-2+2)=1
      Check (Near (U1 (2), 1.0), "Heat profile j=2");
      --  j=3: 2 + 0.25*(1-4+1)=2+0.25*(-2)=1.5
      Check (Near (U1 (3), 1.5), "Heat profile j=3");
      --  j=4: 1 + 0.25*(2-2+0)=1
      Check (Near (U1 (4), 1.0), "Heat profile j=4");
   end;
   --  Multiple steps: heat flattens a bump (max decreases)
   declare
      U : Grid := [0.0, 0.2, 0.5, 1.0, 0.5, 0.2, 0.0];
      M0, M1 : Real;
   begin
      M0 := 1.0;
      for K in 1 .. 20 loop
         U := Heat_FTCS_Step (U, 0.2);
      end loop;
      M1 := 0.0;
      for J in U'Range loop
         if abs (U (J)) > M1 then
            M1 := abs (U (J));
         end if;
      end loop;
      Check (M1 < M0, "Heat damps interior max over steps");
      Check (Near (U (1), 0.0) and then Near (U (7), 0.0),
             "Heat BCs stay zero");
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid_Argument guards");
   ---------------------------------------------------------------------
   Raised := False;
   begin
      declare
         Unused : constant Grid := Diff_Forward ([1.0, 2.0], -0.1);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Diff_Forward rejects H <= 0");

   Raised := False;
   begin
      declare
         Unused : constant Grid := Diff_Forward ([1.0], 0.1);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Diff_Forward rejects Length < 2");

   Raised := False;
   begin
      declare
         Unused : constant Grid := Diff_Backward ([1.0], 0.1);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Diff_Backward rejects Length < 2");

   Raised := False;
   begin
      declare
         Unused : constant Grid := Diff_Central ([1.0, 2.0], 0.1);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Diff_Central rejects Length < 3");

   Raised := False;
   begin
      declare
         Unused : constant Grid := Diff2_Central ([1.0, 2.0], 0.1);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Diff2_Central rejects Length < 3");

   Raised := False;
   begin
      declare
         Unused : constant Grid := Diff2_Central ([1.0, 2.0, 3.0], 0.0);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Diff2_Central rejects H = 0");

   Raised := False;
   begin
      declare
         G : constant Grid := [1.0, 2.0];
         Unused : constant Grid := Solve_Poisson_1D (G, -1.0);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Solve_Poisson_1D rejects H <= 0");

   Raised := False;
   begin
      declare
         Unused : constant Grid := Heat_FTCS_Step ([0.0, 1.0, 0.0], 0.6);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Heat_FTCS_Step rejects r > 1/2");

   Raised := False;
   begin
      declare
         Unused : constant Grid := Heat_FTCS_Step ([0.0, 1.0, 0.0], -0.1);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Heat_FTCS_Step rejects r < 0");

   Raised := False;
   begin
      declare
         Unused : constant Grid := Heat_FTCS_Step ([0.0, 1.0], 0.25);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Heat_FTCS_Step rejects Length < 3");

   Raised := False;
   begin
      declare
         Unused : constant Real := X_At (0.0, -1.0, 1);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "X_At rejects H <= 0");

   Raised := False;
   begin
      declare
         A : constant Grid := [1.0, 2.0];
         B : constant Grid := [1.0];
         Unused : constant Real := L2_Error (A, B, 0.1);
         pragma Unreferenced (Unused);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "L2_Error rejects length mismatch");

   ---------------------------------------------------------------------
   Section ("12. More derivative / Poisson / heat edge cases");
   ---------------------------------------------------------------------
   declare
      F  : constant Grid := [1.0, 2.0, 3.0, 4.0];
      DF : constant Grid := Diff_Forward (F, 1.0);
      DB : constant Grid := Diff_Backward (F, 1.0);
      DC : constant Grid := Diff_Central (F, 1.0);
      D2 : constant Grid := Diff2_Central (F, 1.0);
   begin
      Check (Vec_Near (DF, [1.0, 1.0, 1.0]), "Forward linear slope 1");
      Check (Vec_Near (DB, [1.0, 1.0, 1.0]), "Backward linear slope 1");
      Check (Vec_Near (DC, [1.0, 1.0]), "Central linear slope 1");
      Check (Vec_Near (D2, [0.0, 0.0], 1.0E-14), "Diff2 linear = 0");
   end;
   declare
      --  Tiny Poisson N=1: −u''=2, u(0)=u(1)=0, H=0.5
      --  Only one unknown u_1 at x=0.5; 2 u_1 / H² = 2 ⇒ u_1 = H² = 0.25
      --  Exact quad u(0.5)=0.25
      G : constant Grid := [2.0];
      U : constant Grid := Solve_Poisson_1D (G, 0.5, 0.0, 0.0);
   begin
      Check (U'Length = 3, "Poisson N=1 length 3");
      Check (Near (U (2), 0.25), "Poisson N=1 interior");
   end;
   declare
      U0 : constant Grid := [1.0, 2.0, 3.0, 4.0, 5.0];
      U1 : constant Grid := Heat_FTCS_Step (U0, 0.0);
   begin
      Check (Vec_Near (U0, U1), "Heat r=0 is identity");
   end;
   declare
      H  : constant Real := 0.25;
      F  : constant Grid := Sample_Cos (9, H, 0.0);
      D2 : constant Grid := Diff2_Central (F, H);
      Exact : Real;
      Ok : Boolean := True;
   begin
      for K in D2'Range loop
         Exact := -Cos (X_At (0.0, H, K + 1));
         if Abs_Error (D2 (K), Exact) > 0.02 then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "Diff2 cos'' on coarse grid");
   end;
   declare
      --  Heat with r=1/2 on longer string
      U : Grid (1 .. 9) := [others => 0.0];
   begin
      U (5) := 1.0;
      U := Heat_FTCS_Step (U, 0.5);
      Check (Near (U (4), 0.5) and then Near (U (5), 0.0)
             and then Near (U (6), 0.5),
             "Heat r=1/2 spreads spike to neighbours");
   end;
   declare
      N : constant Point_Count := 7;
      H : constant Real := 1.0 / Real (N + 1);
      G : constant Grid (1 .. N) := [others => 1.0];
      U : constant Grid := Solve_Poisson_1D (G, H, 0.0, 0.0);
      Positive_Interior : Boolean := True;
   begin
      --  −u''=1 > 0 with zero BCs ⇒ u > 0 (maximum principle / positivity)
      for J in 2 .. N + 1 loop
         if U (J) <= 0.0 then
            Positive_Interior := False;
         end if;
      end loop;
      Check (Positive_Interior, "Poisson positivity for g=1");
      Check (U (2) > 0.0 and then U (N / 2 + 2) >= U (2),
             "Poisson peak toward centre");
   end;

   ---------------------------------------------------------------------
   Section ("13. Forward vs central order on exp");
   ---------------------------------------------------------------------
   declare
      H1 : constant Real := 0.1;
      H2 : constant Real := 0.05;
      F1 : constant Grid := Sample_Exp (21, H1, 0.0);
      F2 : constant Grid := Sample_Exp (41, H2, 0.0);
      DF1 : constant Grid := Diff_Forward (F1, H1);
      DF2 : constant Grid := Diff_Forward (F2, H2);
      DC1 : constant Grid := Diff_Central (F1, H1);
      DC2 : constant Grid := Diff_Central (F2, H2);
      E_F1, E_F2, E_C1, E_C2 : Real := 0.0;
      Exact : Real;
   begin
      for K in DF1'Range loop
         Exact := Exp (X_At (0.0, H1, K));
         if Abs_Error (DF1 (K), Exact) > E_F1 then
            E_F1 := Abs_Error (DF1 (K), Exact);
         end if;
      end loop;
      for K in DF2'Range loop
         Exact := Exp (X_At (0.0, H2, K));
         if Abs_Error (DF2 (K), Exact) > E_F2 then
            E_F2 := Abs_Error (DF2 (K), Exact);
         end if;
      end loop;
      for K in DC1'Range loop
         Exact := Exp (X_At (0.0, H1, K + 1));
         if Abs_Error (DC1 (K), Exact) > E_C1 then
            E_C1 := Abs_Error (DC1 (K), Exact);
         end if;
      end loop;
      for K in DC2'Range loop
         Exact := Exp (X_At (0.0, H2, K + 1));
         if Abs_Error (DC2 (K), Exact) > E_C2 then
            E_C2 := Abs_Error (DC2 (K), Exact);
         end if;
      end loop;
      Check (E_F2 < E_F1, "Forward exp refine");
      Check (E_C2 < E_C1, "Central exp refine");
      Check (E_F1 / E_F2 > 1.7, "Forward exp ~O(h)");
      Check (E_C1 / E_C2 > 3.5, "Central exp ~O(h^2)");
   end;

   ---------------------------------------------------------------------
   Section ("14. Sample / Diff composition identity checks");
   ---------------------------------------------------------------------
   declare
      H : constant Real := 0.01;
      F : constant Grid := Sample_Sin (100, H, 0.0);
      --  Differentiating twice ≈ −sin
      D2 : constant Grid := Diff2_Central (F, H);
      Max_E : Real := 0.0;
      Exact : Real;
   begin
      for K in D2'Range loop
         Exact := -Sin (X_At (0.0, H, K + 1));
         if Abs_Error (D2 (K), Exact) > Max_E then
            Max_E := Abs_Error (D2 (K), Exact);
         end if;
      end loop;
      Check (Max_E < 1.0E-4, "Diff2 sin on fine grid");
   end;
   declare
      --  Central first of cos should ≈ −sin
      H : constant Real := 0.02;
      F : constant Grid := Sample_Cos (50, H, 0.0);
      DC : constant Grid := Diff_Central (F, H);
      Max_E : Real := 0.0;
      Exact : Real;
   begin
      for K in DC'Range loop
         Exact := -Sin (X_At (0.0, H, K + 1));
         if Abs_Error (DC (K), Exact) > Max_E then
            Max_E := Abs_Error (DC (K), Exact);
         end if;
      end loop;
      Check (Max_E < 1.0E-3, "Central d/dx cos = -sin");
   end;

   New_Line;
   Put_Line ("===================================");
   Put_Line
     ("Result: " & Natural'Image (Pass_Count) & " passed, "
      & Natural'Image (Fail_Count) & " failed");
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;
end Tests;
