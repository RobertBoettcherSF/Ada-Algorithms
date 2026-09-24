--  Standalone test suite for Cubic_Interpolation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Text_IO;
with Cubic_Interpolation; use Cubic_Interpolation;

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

   function Approx (A, B : Float; Tol : Float := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Cubic (X : Float) return Float is
   begin
      return X * X * X - 2.0 * X * X + X;
   end Cubic;

begin
   Ada.Text_IO.Put_Line ("Cubic_Interpolation test suite");
   Ada.Text_IO.Put_Line ("===============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Lerp / Cubic_1D / Hermite basis");
   ---------------------------------------------------------------------
   declare
      T : Float;
      Part : Boolean;
   begin
      Check (Near (1.0, 1.0), "Near equal floats");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny floats");
      Check (not Near (1.0, 2.0), "Near rejects floats");
      Check (Approx (Lerp (0.0, 10.0, 0.0), 0.0), "Lerp t=0");
      Check (Approx (Lerp (0.0, 10.0, 1.0), 10.0), "Lerp t=1");
      Check (Approx (Lerp (0.0, 10.0, 0.5), 5.0), "Lerp t=0.5");

      --  Cubic_1D at endpoints returns P1 / P2
      Check (Approx (Cubic_1D (0.0, 1.0, 2.0, 3.0, 0.0), 1.0),
             "Cubic_1D t=0 → P1");
      Check (Approx (Cubic_1D (0.0, 1.0, 2.0, 3.0, 1.0), 2.0),
             "Cubic_1D t=1 → P2");
      --  Affine samples P=i: CR is exact for linear
      Check (Approx (Cubic_1D (0.0, 1.0, 2.0, 3.0, 0.5), 1.5),
             "Cubic_1D linear mid");
      Check (Approx (Cubic_1D (10.0, 11.0, 12.0, 13.0, 0.25), 11.25),
             "Cubic_1D linear quarter");

      Check (Approx (H00 (0.0), 1.0) and Approx (H00 (1.0), 0.0),
             "H00 endpoints");
      Check (Approx (H01 (0.0), 0.0) and Approx (H01 (1.0), 1.0),
             "H01 endpoints");
      Check (Approx (H10 (0.0), 0.0) and Approx (H10 (1.0), 0.0),
             "H10 endpoints");
      Check (Approx (H11 (0.0), 0.0) and Approx (H11 (1.0), 0.0),
             "H11 endpoints");
      Check (Approx (H00 (0.5) + H01 (0.5), 1.0), "H00+H01 @0.5");
      Check (Approx (H10 (0.5), 0.125), "H10(0.5)=1/8");
      Check (Approx (H11 (0.5), -0.125), "H11(0.5)=-1/8");

      Part := True;
      for K in 0 .. 10 loop
         T := Float (K) * 0.1;
         if not Approx (H00 (T) + H01 (T), 1.0) then
            Part := False;
         end if;
      end loop;
      Check (Part, "H00+H01 partition on [0,1]");
   end;

   ---------------------------------------------------------------------
   Section ("2. Grid builders / Get / Set / domain");
   ---------------------------------------------------------------------
   declare
      G   : Grid_1D;
      Emp : Grid_1D;
      R   : Eval_Result;
   begin
      G := Make_Empty_Grid (5);
      Check (Is_Valid_Grid (G) and G.N = 5, "Make_Empty_Grid");
      Check (Approx (Get (G, 0), 0.0) and Approx (Get (G, 4), 0.0),
             "Empty zeros");
      Set (G, 2, 42.0);
      Check (Approx (Get (G, 2), 42.0), "Set/Get");

      G := Make_Ramp_Grid (8, 0.0, 7.0);
      Check (G.N = 8 and Approx (Get (G, 0), 0.0)
             and Approx (Get (G, 7), 7.0), "Ramp ends");
      Check (Approx (Get (G, 3), 3.0), "Ramp mid index");
      Check (In_Domain (G, 0.0) and In_Domain (G, 7.0)
             and In_Domain (G, 3.5), "Ramp in domain");
      Check (not In_Domain (G, -0.1) and not In_Domain (G, 7.1),
             "Ramp OOD");
      Check (Large_Enough_Catmull_Rom (G), "Ramp large enough CR");

      Emp.Valid := False;
      Check (not Is_Valid_Grid (Emp), "Invalid grid");
      Check (not Large_Enough_Catmull_Rom (Emp), "Invalid not CR");
      Check (not In_Domain (Emp, 0.0), "Invalid not in domain");

      G := Make_Ramp_Grid (3, 0.0, 2.0);
      Check (Is_Valid_Grid (G) and not Large_Enough_Catmull_Rom (G),
             "N=3 too small for CR");
      R := Evaluate_Catmull_Rom (G, 1.0);
      Check (not R.Success and R.Stat = Too_Few_Points,
             "CR Too_Few_Points N=3");

      G := Make_Example_Grid (Linear_Ramp);
      Check (G.N = 8 and Approx (Get (G, 4), 4.0), "Example ramp");
      G := Make_Example_Grid (Known_Cubic);
      Check (G.N = 9 and Approx (Get (G, 0), Cubic (0.0)),
             "Example known cubic left");
      G := Make_Example_Grid (Sine_Sample);
      Check (G.N = 9 and Approx (Get (G, 0), 0.0, 1.0E-5),
             "Example sine left");
   end;

   ---------------------------------------------------------------------
   Section ("3. Catmull–Rom exact at integer nodes");
   ---------------------------------------------------------------------
   declare
      G : Grid_1D := Make_Ramp_Grid (10, 0.0, 9.0);
      R : Eval_Result;
      All_Ok : Boolean := True;
   begin
      for I in 0 .. 9 loop
         R := Evaluate_Catmull_Rom (G, Float (I));
         if not (R.Success and Approx (R.Value, Float (I))) then
            All_Ok := False;
         end if;
      end loop;
      Check (All_Ok, "CR exact at all integer nodes (ramp)");

      G := Make_Known_Cubic_Grid (8, 0.0, 1.0);
      --  Lattice Values(i)=p(t_i) with t mapped; nodes still return Values(i)
      All_Ok := True;
      for I in 0 .. Integer (G.N) - 1 loop
         R := Evaluate_Catmull_Rom (G, Float (I));
         if not (R.Success and Approx (R.Value, Get (G, Sample_Index (I))))
         then
            All_Ok := False;
         end if;
      end loop;
      Check (All_Ok, "CR exact at nodes (known-cubic samples)");

      G := Make_Sine_Grid (12, 0.0, Ada.Numerics.Pi);
      All_Ok := True;
      for I in 0 .. Integer (G.N) - 1 loop
         R := Evaluate_Catmull_Rom (G, Float (I));
         if not (R.Success and Approx (R.Value, Get (G, Sample_Index (I))))
         then
            All_Ok := False;
         end if;
      end loop;
      Check (All_Ok, "CR exact at nodes (sine)");
   end;

   ---------------------------------------------------------------------
   Section ("4. Catmull–Rom affine / mid-cell / edges");
   ---------------------------------------------------------------------
   declare
      G : Grid_1D := Make_Ramp_Grid (8, 0.0, 7.0);
      R : Eval_Result;
      All_Ok : Boolean := True;
      X : Float;
   begin
      --  Affine: CR + odd reflection exact on closed domain
      for K in 0 .. 70 loop
         X := Float (K) * 0.1;
         if X <= 7.0 then
            R := Evaluate_Catmull_Rom (G, X);
            if not (R.Success and Approx (R.Value, X, 1.0E-4)) then
               All_Ok := False;
            end if;
         end if;
      end loop;
      Check (All_Ok, "CR affine exact sweep");

      R := Evaluate_Catmull_Rom (G, 0.0);
      Check (R.Success and Approx (R.Value, 0.0), "CR left edge");
      R := Evaluate_Catmull_Rom (G, 7.0);
      Check (R.Success and Approx (R.Value, 7.0), "CR right edge");
      R := Evaluate_Catmull_Rom (G, 3.5);
      Check (R.Success and Approx (R.Value, 3.5), "CR mid-cell affine");

      --  Constant field
      G := Make_Ramp_Grid (6, 5.0, 5.0);
      All_Ok := True;
      for K in 0 .. 50 loop
         X := Float (K) * 0.1;
         if X <= 5.0 then
            R := Evaluate_Catmull_Rom (G, X);
            if not (R.Success and Approx (R.Value, 5.0)) then
               All_Ok := False;
            end if;
         end if;
      end loop;
      Check (All_Ok, "CR constant field");
   end;

   ---------------------------------------------------------------------
   Section ("5. Catmull–Rom out of domain / ill-started");
   ---------------------------------------------------------------------
   declare
      G   : Grid_1D := Make_Ramp_Grid (5, 0.0, 4.0);
      Bad : Grid_1D;
      R   : Eval_Result;
   begin
      R := Evaluate_Catmull_Rom (G, -0.01);
      Check (not R.Success and R.Stat = Out_Of_Domain, "CR OOD left");
      R := Evaluate_Catmull_Rom (G, 4.01);
      Check (not R.Success and R.Stat = Out_Of_Domain, "CR OOD right");
      R := Evaluate_Catmull_Rom (G, -100.0);
      Check (not R.Success and R.Stat = Out_Of_Domain, "CR OOD far");

      Bad.Valid := False;
      Bad.N := 0;
      R := Evaluate_Catmull_Rom (Bad, 0.0);
      Check (not R.Success and R.Stat = Ill_Started, "CR Ill_Started");

      G := Make_Empty_Grid (4);
      for I in Sample_Index range 0 .. 3 loop
         Set (G, I, Float (I * I));
      end loop;
      R := Evaluate_Catmull_Rom (G, 1.5);
      Check (R.Success and R.Stat = Ok, "CR min N=4 interior");
   end;

   ---------------------------------------------------------------------
   Section ("6. Interpolate_Four_Points exact on known cubic");
   ---------------------------------------------------------------------
   declare
      Xs : Abscissae (0 .. 3);
      Ys : Ordinates (0 .. 3);
      R  : Eval_Result;
      All_Ok : Boolean := True;
      X  : Float;
   begin
      Make_Known_Cubic_Four (0.0, 3.0, Xs, Ys);
      --  Exact at the four nodes
      for K in 0 .. 3 loop
         R := Interpolate_Four_Points
           (Xs (0), Ys (0), Xs (1), Ys (1),
            Xs (2), Ys (2), Xs (3), Ys (3),
            Xs (K));
         if not (R.Success and Approx (R.Value, Ys (K), 1.0E-4)) then
            All_Ok := False;
         end if;
      end loop;
      Check (All_Ok, "Four-point exact at nodes");

      --  Unique cubic: p(x)=x³−2x²+x recovered everywhere
      All_Ok := True;
      for K in 0 .. 60 loop
         X := Float (K) * 0.05;
         R := Interpolate_Four_Points
           (Xs (0), Ys (0), Xs (1), Ys (1),
            Xs (2), Ys (2), Xs (3), Ys (3),
            X);
         if not (R.Success and Approx (R.Value, Cubic (X), 2.0E-4)) then
            All_Ok := False;
         end if;
      end loop;
      Check (All_Ok, "Four-point recovers known cubic on [0,3]");

      --  Array overload
      R := Interpolate_Four_Points (Xs, Ys, 1.5);
      Check (R.Success and Approx (R.Value, Cubic (1.5), 2.0E-4),
             "Four-point array overload @1.5");

      --  Outside the knot span still defined (global poly)
      R := Interpolate_Four_Points (Xs, Ys, -1.0);
      Check (R.Success and Approx (R.Value, Cubic (-1.0), 5.0E-4),
             "Four-point extrapolates as cubic");
      R := Interpolate_Four_Points (Xs, Ys, 4.0);
      Check (R.Success and Approx (R.Value, Cubic (4.0), 5.0E-4),
             "Four-point beyond right");
   end;

   ---------------------------------------------------------------------
   Section ("7. Four-point duplicate / too few / ill-started");
   ---------------------------------------------------------------------
   declare
      R  : Eval_Result;
      X3 : constant Abscissae (0 .. 2) := [0.0, 1.0, 2.0];
      Y3 : constant Ordinates (0 .. 2) := [0.0, 1.0, 4.0];
      X5 : constant Abscissae (0 .. 4) := [0.0, 1.0, 2.0, 3.0, 4.0];
      Y5 : constant Ordinates (0 .. 4) := [0.0, 1.0, 2.0, 3.0, 4.0];
      Xe : Abscissae (1 .. 0);
      Ye : Ordinates (1 .. 0);
   begin
      R := Interpolate_Four_Points
        (0.0, 0.0, 0.0, 1.0, 2.0, 4.0, 3.0, 9.0, 1.0);
      Check (not R.Success and R.Stat = Duplicate_Abscissa,
             "Four-point duplicate X0=X1");
      R := Interpolate_Four_Points
        (0.0, 0.0, 1.0, 1.0, 1.0, 4.0, 3.0, 9.0, 1.5);
      Check (not R.Success and R.Stat = Duplicate_Abscissa,
             "Four-point duplicate X1=X2");

      R := Interpolate_Four_Points (X3, Y3, 1.0);
      Check (not R.Success and R.Stat = Too_Few_Points,
             "Four-point array Too_Few");
      R := Interpolate_Four_Points (X5, Y5, 1.0);
      Check (not R.Success and R.Stat = Ill_Started,
             "Four-point array >4 Ill_Started");
      R := Interpolate_Four_Points (Xe, Ye, 0.0);
      Check (not R.Success and R.Stat = Ill_Started,
             "Four-point empty Ill_Started");
   end;

   ---------------------------------------------------------------------
   Section ("8. Four-point Lagrange vs Newton consistency");
   ---------------------------------------------------------------------
   declare
      --  Arbitrary distinct points (not a monomial sample)
      R : Eval_Result;
      --  Classical Lagrange at a query for cross-check
      function Lag
        (X0, Y0, X1, Y1, X2, Y2, X3, Y3, X : Float) return Float
      is
         L0, L1, L2, L3 : Float;
      begin
         L0 := ((X - X1) / (X0 - X1)) * ((X - X2) / (X0 - X2))
           * ((X - X3) / (X0 - X3));
         L1 := ((X - X0) / (X1 - X0)) * ((X - X2) / (X1 - X2))
           * ((X - X3) / (X1 - X3));
         L2 := ((X - X0) / (X2 - X0)) * ((X - X1) / (X2 - X1))
           * ((X - X3) / (X2 - X3));
         L3 := ((X - X0) / (X3 - X0)) * ((X - X1) / (X3 - X1))
           * ((X - X2) / (X3 - X2));
         return Y0 * L0 + Y1 * L1 + Y2 * L2 + Y3 * L3;
      end Lag;
      Xq : Float;
      All_Ok : Boolean := True;
   begin
      for K in 0 .. 20 loop
         Xq := -1.0 + Float (K) * 0.25;
         R := Interpolate_Four_Points
           (0.0, 1.0, 1.0, 2.0, 2.5, -1.0, 4.0, 3.0, Xq);
         if not (R.Success and Approx
           (R.Value,
            Lag (0.0, 1.0, 1.0, 2.0, 2.5, -1.0, 4.0, 3.0, Xq),
            1.0E-4))
         then
            All_Ok := False;
         end if;
      end loop;
      Check (All_Ok, "Newton matches Lagrange on irregular 4-tuple");
   end;

   ---------------------------------------------------------------------
   Section ("9. Thin FD Hermite fit / evaluate / OOD");
   ---------------------------------------------------------------------
   declare
      FR : Fit_Result;
      R  : Eval_Result;
      X  : Abscissae (0 .. 4);
      Y  : Ordinates (0 .. 4);
      All_Ok : Boolean := True;
      T  : Float;
      Dup_X : constant Abscissae (0 .. 2) := [0.0, 1.0, 1.0];
      Dup_Y : constant Ordinates (0 .. 2) := [0.0, 1.0, 2.0];
      One_X : constant Abscissae (0 .. 0) := [0.0];
      One_Y : constant Ordinates (0 .. 0) := [1.0];
   begin
      for I in 0 .. 4 loop
         X (I) := Float (I);
         Y (I) := 2.0 * Float (I) + 1.0;  -- linear → FD Hermite exact
      end loop;
      FR := Fit_FD (X, Y);
      Check (FR.Success and FR.S.Valid and FR.Stat = Ok, "Fit_FD linear");
      for K in 0 .. 40 loop
         T := Float (K) * 0.1;
         R := Evaluate_FD_Hermite (FR.S, T);
         if not (R.Success and Approx (R.Value, 2.0 * T + 1.0, 1.0E-4)) then
            All_Ok := False;
         end if;
      end loop;
      Check (All_Ok, "FD Hermite exact on linear");

      R := Evaluate_FD_Hermite (FR.S, -0.1);
      Check (not R.Success and R.Stat = Out_Of_Domain, "FD Hermite OOD left");
      R := Evaluate_FD_Hermite (FR.S, 4.1);
      Check (not R.Success and R.Stat = Out_Of_Domain, "FD Hermite OOD right");
      Check (In_Domain (FR.S, 0.0) and In_Domain (FR.S, 4.0),
             "FD Hermite In_Domain ends");
      Check (not In_Domain (FR.S, -1.0), "FD Hermite reject OOD");

      FR := Fit_FD (Dup_X, Dup_Y);
      Check (not FR.Success and FR.Stat = Duplicate_Abscissa,
             "Fit_FD Duplicate_Abscissa");
      FR := Fit_FD (One_X, One_Y);
      Check (not FR.Success and FR.Stat = Too_Few_Points,
             "Fit_FD Too_Few_Points");

      FR := Make_Example_FD (Linear_Ramp);
      Check (FR.Success, "Make_Example_FD ramp");
      R := Evaluate_FD_Hermite (FR.S, 2.5);
      Check (R.Success and Approx (R.Value, 2.0 * 2.5 + 1.0, 1.0E-4),
             "Example FD ramp @2.5");

      FR := Make_Example_FD (Known_Cubic);
      Check (FR.Success, "Make_Example_FD known cubic");
      --  Nodes exact
      All_Ok := True;
      for I in 0 .. FR.S.N loop
         R := Evaluate_FD_Hermite (FR.S, FR.S.X (I));
         if not (R.Success and Approx (R.Value, FR.S.Y (I))) then
            All_Ok := False;
         end if;
      end loop;
      Check (All_Ok, "FD Hermite exact at knots (known cubic)");

      FR := Make_Example_FD (Sine_Sample);
      Check (FR.Success, "Make_Example_FD sine");
      R := Evaluate_FD_Hermite (FR.S, 0.0);
      Check (R.Success and Approx (R.Value, 0.0, 1.0E-5), "FD sine @0");
      R := Evaluate_FD_Hermite (FR.S, Ada.Numerics.Pi);
      Check (R.Success and Approx (R.Value, 0.0, 1.0E-4), "FD sine @π");
   end;

   ---------------------------------------------------------------------
   Section ("10. Strictly increasing / Sample_1D domain helpers");
   ---------------------------------------------------------------------
   declare
      Good : constant Abscissae := [0.0, 1.0, 2.5, 4.0];
      Bad  : constant Abscissae := [0.0, 1.0, 1.0, 2.0];
      Dec  : constant Abscissae := [0.0, 2.0, 1.5];
      One  : constant Abscissae := [3.0];
      S    : Sample_1D;
   begin
      Check (Is_Strictly_Increasing (Good), "Strict good");
      Check (not Is_Strictly_Increasing (Bad), "Reject equal");
      Check (not Is_Strictly_Increasing (Dec), "Reject decreasing");
      Check (Is_Strictly_Increasing (One), "Singleton increasing");

      S.N := 3;
      S.X (0) := 0.0;
      S.X (1) := 1.0;
      S.X (2) := 2.0;
      S.X (3) := 3.0;
      S.Valid := True;
      Check (In_Domain (S, 0.0) and In_Domain (S, 1.5)
             and In_Domain (S, 3.0), "Sample_1D in domain");
      Check (not In_Domain (S, -0.1) and not In_Domain (S, 3.1),
             "Sample_1D OOD");
      S.Valid := False;
      Check (not In_Domain (S, 1.0), "Invalid Sample_1D");
   end;

   ---------------------------------------------------------------------
   Section ("11. Cubic_1D matches bicubic Keys formula spot checks");
   ---------------------------------------------------------------------
   declare
      --  Hand-expanded CR at t=0.5 for (0,1,4,9) — squares
      --  0.5*(2*1 + (-0+4)*0.5 + (0-5+16-9)*0.25 + (0+3-12+9)*0.125)
      --  = 0.5*(2 + 2 + 2*0.25 + 0*0.125) = 0.5*(2+2+0.5)=2.25
      V : Float;
   begin
      V := Cubic_1D (0.0, 1.0, 4.0, 9.0, 0.5);
      Check (Approx (V, 2.25, 1.0E-5), "Cubic_1D squares mid → 2.25");
      V := Cubic_1D (1.0, 1.0, 1.0, 1.0, 0.37);
      Check (Approx (V, 1.0), "Cubic_1D flat");
      V := Cubic_1D (-1.0, 0.0, 1.0, 2.0, 0.0);
      Check (Approx (V, 0.0), "Cubic_1D odd-ish left");
      V := Cubic_1D (-1.0, 0.0, 1.0, 2.0, 1.0);
      Check (Approx (V, 1.0), "Cubic_1D odd-ish right");
   end;

   ---------------------------------------------------------------------
   Section ("12. Sweep / size variants / status matrix");
   ---------------------------------------------------------------------
   declare
      G : Grid_1D;
      R : Eval_Result;
      FR : Fit_Result;
      Ok_Nodes : Boolean;
   begin
      for N in Sample_Count range 4 .. 16 loop
         G := Make_Ramp_Grid (N, 0.0, Float (N - 1));
         Ok_Nodes := True;
         for I in 0 .. N - 1 loop
            R := Evaluate_Catmull_Rom (G, Float (I));
            if not (R.Success and Approx (R.Value, Float (I))) then
               Ok_Nodes := False;
            end if;
         end loop;
         Check (Ok_Nodes, "CR nodes N=" & N'Image);
      end loop;

      G := Make_Sine_Grid (16, 0.0, Ada.Numerics.Pi);
      R := Evaluate_Catmull_Rom (G, 7.5);
      Check (R.Success, "CR sine mid-cell succeeds");

      --  Status matrix quick hits
      R := Evaluate_Catmull_Rom (Make_Ramp_Grid (2, 0.0, 1.0), 0.5);
      Check (R.Stat = Too_Few_Points, "Status Too_Few CR");
      R := Evaluate_Catmull_Rom (Make_Ramp_Grid (5, 0.0, 4.0), 9.0);
      Check (R.Stat = Out_Of_Domain, "Status OOD CR");
      FR := Fit_FD ([0.0, 0.0], [1.0, 2.0]);
      Check (FR.Stat = Duplicate_Abscissa, "Status Duplicate Fit_FD");
      R := Interpolate_Four_Points
        (0.0, 0.0, 1.0, 1.0, 2.0, 4.0, 3.0, 9.0, 1.0);
      Check (R.Stat = Ok and Approx (R.Value, 1.0), "Status Ok four-pt");
   end;

   ---------------------------------------------------------------------
   Section ("13. Known-cubic grid vs four-point agreement at shared t");
   ---------------------------------------------------------------------
   declare
      --  Four lattice-independent knots; compare Newton to true cubic
      Xs : Abscissae (0 .. 3);
      Ys : Ordinates (0 .. 3);
      R  : Eval_Result;
      G  : constant Grid_1D := Make_Ramp_Grid (5, 0.0, 4.0);
   begin
      Make_Known_Cubic_Four (-1.0, 2.0, Xs, Ys);
      R := Interpolate_Four_Points (Xs, Ys, 0.5);
      Check (R.Success and Approx (R.Value, Cubic (0.5), 2.0E-4),
             "Known cubic four @0.5");
      R := Interpolate_Four_Points (Xs, Ys, -0.5);
      Check (R.Success and Approx (R.Value, Cubic (-0.5), 2.0E-4),
             "Known cubic four @-0.5");
      --  Grid still usable independently
      R := Evaluate_Catmull_Rom (G, 2.0);
      Check (R.Success and Approx (R.Value, 2.0), "Ramp CR @2 after four-pt");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("================================");
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
