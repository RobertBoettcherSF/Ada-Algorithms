--  Standalone test suite for Hermite_Interpolation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;
with Ada.Text_IO;
with Hermite_Interpolation; use Hermite_Interpolation;

procedure Tests is

   package Math renames Ada.Numerics.Elementary_Functions;

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

   function Cubic_D (X : Float) return Float is
   begin
      return 3.0 * X * X - 4.0 * X + 1.0;
   end Cubic_D;

begin
   Ada.Text_IO.Put_Line ("Hermite_Interpolation test suite");
   Ada.Text_IO.Put_Line ("================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Make_Point / Hermite basis identities");
   ---------------------------------------------------------------------
   declare
      P : constant Point := Make_Point (1.0, 2.0);
      Q : constant Point := Make_Point (1.0, 2.0 + 1.0E-8);
      T : Float;
   begin
      Check (Near (1.0, 1.0), "Near equal floats");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny floats");
      Check (not Near (1.0, 2.0), "Near rejects floats");
      Check (Near (P, Q), "Near points");
      Check (Approx (P.X, 1.0) and Approx (P.Y, 2.0), "Make_Point");

      Check (Approx (H00 (0.0), 1.0) and Approx (H00 (1.0), 0.0),
             "H00 endpoints");
      Check (Approx (H01 (0.0), 0.0) and Approx (H01 (1.0), 1.0),
             "H01 endpoints");
      Check (Approx (H10 (0.0), 0.0) and Approx (H10 (1.0), 0.0),
             "H10 endpoints");
      Check (Approx (H11 (0.0), 0.0) and Approx (H11 (1.0), 0.0),
             "H11 endpoints");
      Check (Approx (H00 (0.5) + H01 (0.5), 1.0), "H00+H01 partition @0.5");
      Check (Approx (H00 (0.25) + H01 (0.25), 1.0),
             "H00+H01 partition @0.25");
      Check (Approx (H00 (0.75) + H01 (0.75), 1.0),
             "H00+H01 partition @0.75");

      --  Cardinal: H00'(0)=0, H10'(0)=1, H01'(0)=0, H11'(0)=0 (numerically
      --  via small step for educational check of endpoint slopes of bases).
      T := 1.0E-4;
      Check (Approx ((H00 (T) - H00 (0.0)) / T, 0.0, 1.0E-3),
             "H00'~0 at 0");
      Check (Approx ((H10 (T) - H10 (0.0)) / T, 1.0, 1.0E-3),
             "H10'~1 at 0");
      Check (Approx ((H01 (1.0) - H01 (1.0 - T)) / T, 0.0, 1.0E-3),
             "H01'~0 at 1");
      Check (Approx ((H11 (1.0) - H11 (1.0 - T)) / T, 1.0, 1.0E-3),
             "H11'~1 at 1");
   end;

   ---------------------------------------------------------------------
   Section ("2. Strictly increasing / Find_Interval / In_Domain");
   ---------------------------------------------------------------------
   declare
      Good : constant Abscissae := [0.0, 1.0, 2.5, 4.0];
      Bad  : constant Abscissae := [0.0, 1.0, 1.0, 2.0];
      Dec  : constant Abscissae := [0.0, 2.0, 1.5];
      One  : constant Abscissae := [3.0];
      FR   : Fit_Result;
      Emp  : Fit_Result;
   begin
      Check (Is_Strictly_Increasing (Good), "Strict good");
      Check (not Is_Strictly_Increasing (Bad), "Reject equal");
      Check (not Is_Strictly_Increasing (Dec), "Reject decreasing");
      Check (Is_Strictly_Increasing (One), "Singleton increasing");

      FR := Fit_Two_Point (0.0, 0.0, 1.0, 1.0, 1.0, 1.0);
      Check (FR.Success and FR.S.Valid, "Two-point fit for domain");
      Check (In_Domain (FR.S, 0.0), "In_Domain left");
      Check (In_Domain (FR.S, 0.5), "In_Domain mid");
      Check (In_Domain (FR.S, 1.0), "In_Domain right");
      Check (not In_Domain (FR.S, -0.1), "Reject left OOD");
      Check (not In_Domain (FR.S, 1.1), "Reject right OOD");
      Check (Find_Interval (FR.S, 0.0) = 0, "Find_Interval left");
      Check (Find_Interval (FR.S, 0.9) = 0, "Find_Interval mid");
      Check (Find_Interval (FR.S, 1.0) = 0, "Find_Interval right→0");

      Emp.S.Valid := False;
      Check (not In_Domain (Emp.S, 0.0), "Invalid spline not in domain");
   end;

   ---------------------------------------------------------------------
   Section ("3. Evaluate_Cubic_Interval / Fit_Two_Point");
   ---------------------------------------------------------------------
   declare
      --  Match cubic p(x)=x³−2x²+x on [0,2] with analytic ends.
      R   : Eval_Result;
      FR  : Fit_Result;
      X0  : constant Float := 0.0;
      X1  : constant Float := 2.0;
      All_Ok : Boolean := True;
   begin
      R := Evaluate_Cubic_Interval
        (X0, Cubic (X0), Cubic_D (X0),
         X1, Cubic (X1), Cubic_D (X1),
         0.0);
      Check (R.Success and Approx (R.Value, Cubic (0.0)),
             "Interval at left endpoint");
      R := Evaluate_Cubic_Interval
        (X0, Cubic (X0), Cubic_D (X0),
         X1, Cubic (X1), Cubic_D (X1),
         2.0);
      Check (R.Success and Approx (R.Value, Cubic (2.0)),
             "Interval at right endpoint");
      R := Evaluate_Cubic_Interval
        (X0, Cubic (X0), Cubic_D (X0),
         X1, Cubic (X1), Cubic_D (X1),
         1.0);
      Check (R.Success and Approx (R.Value, Cubic (1.0), 1.0E-4),
             "Interval mid = cubic(1)");
      R := Evaluate_Cubic_Interval
        (X0, Cubic (X0), Cubic_D (X0),
         X1, Cubic (X1), Cubic_D (X1),
         -0.5);
      Check (not R.Success and R.Stat = Out_Of_Domain,
             "Interval OOD left");
      R := Evaluate_Cubic_Interval
        (X0, Cubic (X0), Cubic_D (X0),
         X1, Cubic (X1), Cubic_D (X1),
         2.5);
      Check (not R.Success and R.Stat = Out_Of_Domain,
             "Interval OOD right");
      R := Evaluate_Cubic_Interval
        (1.0, 0.0, 0.0, 1.0, 1.0, 0.0, 1.0);
      Check (not R.Success and R.Stat = Dimension_Error,
             "Interval X1=X0 Dimension_Error");

      FR := Fit_Two_Point
        (X0, Cubic (X0), Cubic_D (X0),
         X1, Cubic (X1), Cubic_D (X1));
      Check (FR.Success and FR.S.Kind = Two_Point and FR.S.N = 1,
             "Fit_Two_Point ok");
      for K in 0 .. 8 loop
         declare
            Xq : constant Float := Float (K) * 0.25;
            Ev : constant Eval_Result := Evaluate (FR.S, Xq);
         begin
            if not (Ev.Success
                    and then Approx (Ev.Value, Cubic (Xq), 1.0E-4))
            then
               All_Ok := False;
            end if;
         end;
      end loop;
      Check (All_Ok, "Two-point recovers cubic on grid");

      FR := Fit_Two_Point (1.0, 0.0, 0.0, 1.0, 1.0, 0.0);
      Check (not FR.Success and FR.Stat = Dimension_Error,
             "Fit_Two_Point rejects X1≤X0");
   end;

   ---------------------------------------------------------------------
   Section ("4. Known cubic: nodes + derivatives exact");
   ---------------------------------------------------------------------
   declare
      FR : constant Fit_Result := Make_Known_Cubic (5, 0.0, 2.0);
      All_Nodes : Boolean := True;
      All_Mid   : Boolean := True;
      Ev : Eval_Result;
      --  Numerical derivative at nodes via central difference on Evaluate.
      H  : constant Float := 1.0E-3;
      Left, Right : Eval_Result;
      Deriv_Ok : Boolean := True;
   begin
      Check (FR.Success and FR.S.N = 4, "Known cubic N=4");
      Check (FR.S.Kind = User_Tangents, "Known cubic kind User_Tangents");

      for I in 0 .. FR.S.N loop
         Ev := Evaluate (FR.S, FR.S.X (I));
         if not (Ev.Success
                 and then Approx (Ev.Value, FR.S.Y (I), 1.0E-4))
         then
            All_Nodes := False;
         end if;
         if not Approx (FR.S.Y (I), Cubic (FR.S.X (I)), 1.0E-5) then
            All_Nodes := False;
         end if;
         if not Approx (FR.S.M (I), Cubic_D (FR.S.X (I)), 1.0E-5) then
            All_Nodes := False;
         end if;
      end loop;
      Check (All_Nodes, "Nodes + stored y/m match cubic");

      for K in 1 .. 7 loop
         declare
            Xq : constant Float := Float (K) * 0.25;
         begin
            Ev := Evaluate (FR.S, Xq);
            if not (Ev.Success
                    and then Approx (Ev.Value, Cubic (Xq), 2.0E-4))
            then
               All_Mid := False;
            end if;
         end;
      end loop;
      Check (All_Mid, "Interior samples match cubic");

      --  Derivative match at interior node x=1.0 (index 2 of 0..4 on [0,2]).
      Left := Evaluate (FR.S, 1.0 - H);
      Right := Evaluate (FR.S, 1.0 + H);
      Check (Left.Success and Right.Success, "Deriv probe evals ok");
      if Left.Success and Right.Success then
         Deriv_Ok := Approx
           ((Right.Value - Left.Value) / (2.0 * H),
            Cubic_D (1.0), 5.0E-3);
      else
         Deriv_Ok := False;
      end if;
      Check (Deriv_Ok, "Numerical derivative ≈ cubic' at x=1");
   end;

   ---------------------------------------------------------------------
   Section ("5. Fit user tangents / Fit_FD / OOD / errors");
   ---------------------------------------------------------------------
   declare
      X  : constant Abscissae := [0.0, 1.0, 2.0, 3.0];
      Y  : constant Ordinates := [0.0, 1.0, 0.0, 1.0];
      M  : constant Tangents  := [1.0, -1.0, 1.0, -1.0];
      FR : Fit_Result;
      Ev : Eval_Result;
      X_Bad : constant Abscissae := [0.0, 2.0, 1.0];
      Y_Bad : constant Ordinates := [0.0, 1.0, 2.0];
      M_Bad : constant Tangents  := [0.0, 0.0, 0.0];
      X_One : constant Abscissae := [0.0];
      Y_One : constant Ordinates := [1.0];
      M_One : constant Tangents  := [0.0];
      X_Mis : constant Abscissae := [0.0, 1.0];
      Y_Mis : constant Ordinates := [0.0, 1.0, 2.0];
      M_Mis : constant Tangents  := [0.0, 0.0];
      P : Points (0 .. 3);
   begin
      FR := Fit (X, Y, M);
      Check (FR.Success and FR.S.Valid and FR.S.N = 3, "Fit user ok");
      Ev := Evaluate (FR.S, 0.0);
      Check (Ev.Success and Approx (Ev.Value, 0.0), "Fit user at x0");
      Ev := Evaluate (FR.S, 1.0);
      Check (Ev.Success and Approx (Ev.Value, 1.0), "Fit user at x1");
      Ev := Evaluate (FR.S, 3.0);
      Check (Ev.Success and Approx (Ev.Value, 1.0), "Fit user at xn");
      Ev := Evaluate (FR.S, -1.0);
      Check (not Ev.Success and Ev.Stat = Out_Of_Domain, "OOD left");
      Ev := Evaluate (FR.S, 4.0);
      Check (not Ev.Success and Ev.Stat = Out_Of_Domain, "OOD right");

      FR := Fit_FD (X, Y);
      Check (FR.Success and FR.S.Kind = Finite_Difference, "Fit_FD ok");
      Check (Approx (FR.S.M (0), (Y (1) - Y (0)) / (X (1) - X (0))),
             "Fit_FD m0 = first secant");
      Check (Approx (FR.S.M (3), (Y (3) - Y (2)) / (X (3) - X (2))),
             "Fit_FD mn = last secant");
      Ev := Evaluate (FR.S, 1.5);
      Check (Ev.Success, "Fit_FD evaluate mid");

      FR := Fit (X_Bad, Y_Bad, M_Bad);
      Check (not FR.Success and FR.Stat = Not_Strictly_Increasing,
             "Fit rejects non-increasing");
      FR := Fit (X_One, Y_One, M_One);
      Check (not FR.Success and FR.Stat = Too_Few_Points,
             "Fit Too_Few_Points");
      FR := Fit (X_Mis, Y_Mis, M_Mis);
      Check (not FR.Success and FR.Stat = Dimension_Error,
             "Fit XY length mismatch");
      FR := Fit (X, Y, M_Mis);
      Check (not FR.Success and FR.Stat = Dimension_Error,
             "Fit M length mismatch");

      for I in P'Range loop
         P (I) := Make_Point (X (I), Y (I));
      end loop;
      FR := Fit (P, M);
      Check (FR.Success, "Fit Points+M overload");
      FR := Fit_FD (P);
      Check (FR.Success, "Fit_FD Points overload");

      Ev := Evaluate (Spline'(others => <>), 0.0);
      Check (not Ev.Success and Ev.Stat = Ill_Started,
             "Evaluate invalid Ill_Started");
   end;

   ---------------------------------------------------------------------
   Section ("6. Linear ramp exact / sine sample");
   ---------------------------------------------------------------------
   declare
      FR : Fit_Result;
      Ev : Eval_Result;
      All_Lin : Boolean := True;
      All_Sin : Boolean := True;
   begin
      FR := Make_Linear_Ramp (6, 0.0, 5.0, 1.0, 11.0);
      Check (FR.Success and FR.S.N = 5, "Linear ramp fit");
      for K in 0 .. 10 loop
         declare
            Xq : constant Float := Float (K) * 0.5;
         begin
            Ev := Evaluate (FR.S, Xq);
            if not (Ev.Success
                    and then Approx (Ev.Value, 2.0 * Xq + 1.0, 1.0E-4))
            then
               All_Lin := False;
            end if;
         end;
      end loop;
      Check (All_Lin, "Linear ramp exact on grid");

      FR := Make_Sine_Sample (9, 0.0, Ada.Numerics.Pi);
      Check (FR.Success and FR.S.N = 8, "Sine sample fit");
      for I in 0 .. FR.S.N loop
         Ev := Evaluate (FR.S, FR.S.X (I));
         if not (Ev.Success
                 and then Approx (Ev.Value, Math.Sin (FR.S.X (I)), 1.0E-4))
         then
            All_Sin := False;
         end if;
         if not Approx (FR.S.M (I), Math.Cos (FR.S.X (I)), 1.0E-4) then
            All_Sin := False;
         end if;
      end loop;
      Check (All_Sin, "Sine nodes + analytic derivatives");
      Ev := Evaluate (FR.S, Ada.Numerics.Pi / 2.0);
      Check (Ev.Success and Approx (Ev.Value, 1.0, 5.0E-3),
             "Sine ≈ 1 at π/2");
   end;

   ---------------------------------------------------------------------
   Section ("7. Make_Example / Split_XY");
   ---------------------------------------------------------------------
   declare
      C : constant Fit_Result := Make_Example (Known_Cubic);
      S : constant Fit_Result := Make_Example (Sine_Sample);
      L : constant Fit_Result := Make_Example (Linear_Ramp);
      P : Points (0 .. 2);
      X : Abscissae (0 .. 2);
      Y : Ordinates (0 .. 2);
   begin
      Check (C.Success and C.S.N = 4, "Example Known_Cubic");
      Check (S.Success and S.S.N = 8, "Example Sine_Sample");
      Check (L.Success and L.S.N = 5, "Example Linear_Ramp");
      Check (Approx (L.S.Y (0), 1.0) and Approx (L.S.Y (5), 11.0),
             "Example ramp endpoints");

      P (0) := Make_Point (0.0, 1.0);
      P (1) := Make_Point (1.0, 2.0);
      P (2) := Make_Point (2.0, 4.0);
      Split_XY (P, X, Y);
      Check (Approx (X (0), 0.0) and Approx (Y (0), 1.0), "Split first");
      Check (Approx (X (2), 2.0) and Approx (Y (2), 4.0), "Split last");
   end;

   ---------------------------------------------------------------------
   Section ("8. Osculatory / Newton confluent");
   ---------------------------------------------------------------------
   declare
      --  Two nodes of known cubic → unique degree ≤ 3 = same cubic.
      X2 : constant Abscissae := [0.0, 2.0];
      Y2 : constant Ordinates := [Cubic (0.0), Cubic (2.0)];
      M2 : constant Tangents  := [Cubic_D (0.0), Cubic_D (2.0)];
      R  : Eval_Result;
      All_C : Boolean := True;
      --  Three sine nodes.
      X3 : Abscissae (0 .. 2);
      Y3 : Ordinates (0 .. 2);
      M3 : Tangents  (0 .. 2);
      H  : Float;
      All_S : Boolean := True;
      X_Bad : constant Abscissae := [0.0, 1.0, 0.5];
      Y_Bad : constant Ordinates := [0.0, 1.0, 0.5];
      M_Bad : constant Tangents  := [1.0, 1.0, 1.0];
      X_Mis : constant Abscissae := [0.0, 1.0];
      Y_Mis : constant Ordinates := [0.0];
      M_Mis : constant Tangents  := [0.0, 0.0];
   begin
      for K in 0 .. 8 loop
         declare
            Xq : constant Float := Float (K) * 0.25;
         begin
            R := Evaluate_Osculatory (X2, Y2, M2, Xq);
            if not (R.Success
                    and then Approx (R.Value, Cubic (Xq), 2.0E-4))
            then
               All_C := False;
            end if;
         end;
      end loop;
      Check (All_C, "Osculatory two-point = cubic");

      H := Ada.Numerics.Pi / 2.0;
      for I in 0 .. 2 loop
         X3 (I) := Float (I) * H;
         Y3 (I) := Math.Sin (X3 (I));
         M3 (I) := Math.Cos (X3 (I));
      end loop;
      for I in 0 .. 2 loop
         R := Evaluate_Osculatory (X3, Y3, M3, X3 (I));
         if not (R.Success
                 and then Approx (R.Value, Y3 (I), 1.0E-4))
         then
            All_S := False;
         end if;
      end loop;
      Check (All_S, "Osculatory sine nodes exact");
      R := Evaluate_Osculatory (X3, Y3, M3, Ada.Numerics.Pi / 4.0);
      Check (R.Success and Approx (R.Value, Math.Sin (Ada.Numerics.Pi / 4.0),
             5.0E-3),
             "Osculatory sine at π/4");

      R := Evaluate_Osculatory (X_Bad, Y_Bad, M_Bad, 0.5);
      Check (not R.Success and R.Stat = Not_Strictly_Increasing,
             "Osculatory rejects non-increasing");
      R := Evaluate_Osculatory (X_Mis, Y_Mis, M_Mis, 0.5);
      Check (not R.Success and R.Stat = Dimension_Error,
             "Osculatory dimension mismatch");

      --  Single node: constant + linear term → H(x)=y0+m0(x-x0)
      declare
         Xs : constant Abscissae := [1.0];
         Ys : constant Ordinates := [3.0];
         Ms : constant Tangents  := [2.0];
      begin
         R := Evaluate_Osculatory (Xs, Ys, Ms, 1.0);
         Check (R.Success and Approx (R.Value, 3.0), "Osculatory node");
         R := Evaluate_Osculatory (Xs, Ys, Ms, 2.0);
         Check (R.Success and Approx (R.Value, 5.0),
                "Osculatory Taylor line");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. FD vs user tangents on cubic; multi-interval");
   ---------------------------------------------------------------------
   declare
      --  Sample cubic at 4 knots; Fit with analytic M → exact;
      --  Fit_FD → approximate (still interpolates nodes).
      X : Abscissae (0 .. 3);
      Y : Ordinates (0 .. 3);
      M : Tangents  (0 .. 3);
      FR_U, FR_F : Fit_Result;
      Ev : Eval_Result;
      Nodes_U, Nodes_F : Boolean := True;
      Exact_U : Boolean := True;
   begin
      for I in 0 .. 3 loop
         X (I) := Float (I);
         Y (I) := Cubic (X (I));
         M (I) := Cubic_D (X (I));
      end loop;
      FR_U := Fit (X, Y, M);
      FR_F := Fit_FD (X, Y);
      Check (FR_U.Success and FR_F.Success, "User and FD fits");

      for I in 0 .. 3 loop
         Ev := Evaluate (FR_U.S, X (I));
         if not (Ev.Success and Approx (Ev.Value, Y (I), 1.0E-4)) then
            Nodes_U := False;
         end if;
         Ev := Evaluate (FR_F.S, X (I));
         if not (Ev.Success and Approx (Ev.Value, Y (I), 1.0E-4)) then
            Nodes_F := False;
         end if;
      end loop;
      Check (Nodes_U, "User-tangent nodes exact");
      Check (Nodes_F, "FD nodes exact (interpolation)");

      for K in 0 .. 12 loop
         declare
            Xq : constant Float := Float (K) * 0.25;
         begin
            Ev := Evaluate (FR_U.S, Xq);
            if not (Ev.Success
                    and then Approx (Ev.Value, Cubic (Xq), 2.0E-4))
            then
               Exact_U := False;
            end if;
         end;
      end loop;
      Check (Exact_U, "User tangents recover cubic everywhere");

      --  FD endpoint tangents match one-sided secants.
      Check (Approx (FR_F.S.M (0), (Y (1) - Y (0)) / (X (1) - X (0))),
             "FD m0 one-sided");
      Check (Approx (FR_F.S.M (3), (Y (3) - Y (2)) / (X (3) - X (2))),
             "FD mn one-sided");
      --  Interior average of adjacent secants.
      Check (Approx
               (FR_F.S.M (1),
                0.5 * ((Y (1) - Y (0)) / (X (1) - X (0))
                       + (Y (2) - Y (1)) / (X (2) - X (1)))),
             "FD m1 average secants");
   end;

   ---------------------------------------------------------------------
   Section ("10. Caps / Status / Max constants");
   ---------------------------------------------------------------------
   declare
      Distinct : Boolean := True;
      Count    : Natural := 0;
      Cap_Fit  : constant Fit_Result :=
                   Make_Known_Cubic (Max_Points, 0.0, 1.0);
      Osc_X : Abscissae (0 .. Max_Osculatory_Nodes - 1);
      Osc_Y : Ordinates (0 .. Max_Osculatory_Nodes - 1);
      Osc_M : Tangents  (0 .. Max_Osculatory_Nodes - 1);
      Osc_R : Eval_Result;
   begin
      Check (Point_Count'Last = Max_Points, "Point_Count last");
      Check (Cap_Fit.Success and Cap_Fit.S.N = Max_Points - 1,
             "Fit succeeds at Max_Points");
      Check (Status'Pos (Ok) = 0, "Status'Pos Ok=0");
      Check (Status'Pos (Dimension_Error) = 5,
             "Status'Pos Dimension_Error=5");
      Check (Status'Image (Ok) = "OK", "Status'Image Ok");
      Check (Status'Image (Out_Of_Domain) = "OUT_OF_DOMAIN",
             "Status'Image OOD");
      for A in Status loop
         Count := Count + 1;
         for B in Status loop
            if A /= B and then Status'Pos (A) = Status'Pos (B) then
               Distinct := False;
            end if;
         end loop;
      end loop;
      Check (Count = 6, "Status has 6 values");
      Check (Distinct, "All Status values distinct");
      Check (Fit_Kind'Pos (User_Tangents) = 0, "Fit_Kind User=0");
      Check (Fit_Kind'Pos (Two_Point) = 2, "Fit_Kind Two_Point=2");
      Check (Example_Kind'Pos (Known_Cubic) = 0, "Example Known=0");

      --  Osculatory at Max_Osculatory_Nodes (linear y=x, m=1).
      for I in Osc_X'Range loop
         Osc_X (I) := Float (I);
         Osc_Y (I) := Float (I);
         Osc_M (I) := 1.0;
      end loop;
      Osc_R := Evaluate_Osculatory (Osc_X, Osc_Y, Osc_M, 3.5);
      Check (Osc_R.Success and Approx (Osc_R.Value, 3.5, 1.0E-3),
             "Osculatory at Max_Osculatory_Nodes");
      Check (Osc_X'Length = Max_Osculatory_Nodes,
             "Osc array length = Max_Osculatory_Nodes");
   end;

   ---------------------------------------------------------------------
   Section ("11. Extra basis / interval edge cases");
   ---------------------------------------------------------------------
   declare
      --  Identity: Evaluate_Cubic_Interval with m=0,y linear → lerp.
      R : Eval_Result;
      T : Float;
      Part : Boolean := True;
   begin
      --  Zero end slopes → smoothstep (not linear lerp):
      --  f(t)=y0 h00(t)+y1 h01(t); at t=0.3, h01=0.216 → f=2.16.
      R := Evaluate_Cubic_Interval
        (0.0, 0.0, 0.0, 1.0, 10.0, 0.0, 0.3);
      Check (R.Success and Approx (R.Value, 10.0 * H01 (0.3), 1.0E-5),
             "Zero-slope → smoothstep");
      R := Evaluate_Cubic_Interval
        (0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 0.4);
      Check (R.Success and Approx (R.Value, 0.4, 1.0E-4),
             "Unit slope line y=x");

      for K in 0 .. 10 loop
         T := Float (K) * 0.1;
         if not Approx (H00 (T) + H01 (T), 1.0, 1.0E-5) then
            Part := False;
         end if;
      end loop;
      Check (Part, "H00+H01=1 on [0,1] grid");

      Check (Approx (H10 (0.5), 0.125, 1.0E-5), "H10(0.5)=1/8");
      Check (Approx (H11 (0.5), -0.125, 1.0E-5), "H11(0.5)=-1/8");
      Check (Approx (H00 (0.5), 0.5, 1.0E-5), "H00(0.5)=1/2");
      Check (Approx (H01 (0.5), 0.5, 1.0E-5), "H01(0.5)=1/2");

      --  Empty / zero-length Points Fit_FD
      declare
         P0 : Points (1 .. 0);
         FR : constant Fit_Result := Fit_FD (P0);
      begin
         Check (not FR.Success and FR.Stat = Ill_Started,
                "Fit_FD empty Points Ill_Started");
      end;
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
