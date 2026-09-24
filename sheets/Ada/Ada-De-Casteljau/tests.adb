--  Standalone test suite for De_Casteljau (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with De_Casteljau; use De_Casteljau;

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

begin
   Ada.Text_IO.Put_Line ("De_Casteljau test suite");
   Ada.Text_IO.Put_Line ("=======================");

   ---------------------------------------------------------------------
   Section ("1. Near / Lerp / Dist / Add / Sub / Scale");
   ---------------------------------------------------------------------
   declare
      A : constant Point_2D := Make_Point (0.0, 0.0);
      B : constant Point_2D := Make_Point (2.0, 4.0);
      C : constant Point_2D := Lerp (A, B, 0.5);
      D : constant Point_3D := Make_Point (1.0, 2.0, 3.0);
      E : constant Point_3D := Make_Point (4.0, 6.0, 8.0);
      M : constant Point_3D := Lerp (D, E, 0.5);
   begin
      Check (Near (1.0, 1.0), "Near equal floats");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny floats");
      Check (not Near (1.0, 2.0), "Near rejects floats");
      Check (Approx (Lerp (0.0, 10.0, 0.3), 3.0), "Lerp scalar 0.3");
      Check (Approx (Lerp (2.0, 2.0, 0.7), 2.0), "Lerp scalar equal");
      Check (Near (C, Make_Point (1.0, 2.0)), "Lerp 2D midpoint");
      --  Dist (0,0)-(2,4) = sqrt(4+16)=sqrt(20)≈4.472136
      Check (Approx (Dist (A, B), 4.472136, 1.0E-4), "Dist 2D 0→(2,4)");
      Check (Approx (Dist (A, A), 0.0), "Dist 2D zero");
      Check (Near (Add (A, B), B), "Add 2D");
      Check (Near (Sub (B, B), A), "Sub 2D zero");
      Check (Near (Scale (B, 0.5), Make_Point (1.0, 2.0)), "Scale 2D");
      Check (Near (M, Make_Point (2.5, 4.0, 5.5)), "Lerp 3D mid");
      Check (Approx (Dist (D, E), 7.071068, 1.0E-4), "Dist 3D");
      Check (Near (Add (D, E), Make_Point (5.0, 8.0, 11.0)), "Add 3D");
      Check (Near (Sub (E, D), Make_Point (3.0, 4.0, 5.0)), "Sub 3D");
      Check (Near (Scale (D, 2.0), Make_Point (2.0, 4.0, 6.0)),
             "Scale 3D");
      Check (In_Unit_Interval (0.0), "In_Unit 0");
      Check (In_Unit_Interval (1.0), "In_Unit 1");
      Check (In_Unit_Interval (0.5), "In_Unit 0.5");
      Check (not In_Unit_Interval (-0.1), "In_Unit rejects -");
      Check (not In_Unit_Interval (1.1), "In_Unit rejects +");
   end;

   ---------------------------------------------------------------------
   Section ("2. Degree_Of / builders / examples");
   ---------------------------------------------------------------------
   declare
      L1 : constant Controls_1D := Make_Line_1D (0.0, 1.0);
      L2 : constant Controls_2D :=
        Make_Line_2D (Make_Point (0.0, 0.0), Make_Point (1.0, 1.0));
      Q  : constant Controls_2D :=
        Make_Quadratic_2D
          (Make_Point (0.0, 0.0),
           Make_Point (0.5, 1.0),
           Make_Point (1.0, 0.0));
      Cu : constant Controls_2D := Make_Example_2D (Cubic_Unit_Square);
      Cs : constant Controls_2D := Make_Example_2D (Cubic_S_Curve);
      C3 : constant Controls_3D :=
        Make_Cubic_3D
          (Make_Point (0.0, 0.0, 0.0),
           Make_Point (1.0, 0.0, 0.0),
           Make_Point (1.0, 1.0, 0.0),
           Make_Point (1.0, 1.0, 1.0));
   begin
      Check (Degree_Of (L1) = 1, "Degree line 1D");
      Check (Degree_Of (L2) = 1, "Degree line 2D");
      Check (Degree_Of (Q) = 2, "Degree quadratic");
      Check (Degree_Of (Cu) = 3, "Degree cubic square");
      Check (Degree_Of (Cs) = 3, "Degree cubic S");
      Check (Degree_Of (C3) = 3, "Degree cubic 3D");
      Check (Near (Cu (0), Make_Point (0.0, 0.0)), "Square P0");
      Check (Near (Cu (1), Make_Point (0.0, 1.0)), "Square P1");
      Check (Near (Cu (2), Make_Point (1.0, 1.0)), "Square P2");
      Check (Near (Cu (3), Make_Point (1.0, 0.0)), "Square P3");
      Check (Near (Make_Example_2D (Line_Segment) (1),
                  Make_Point (1.0, 0.0)),
             "Example line P1");
      Check (Near (Make_Example_2D (Quadratic_Arch) (1),
                  Make_Point (0.5, 1.0)),
             "Example arch P1");
      Check (Approx (Make_Example_1D (Line_Segment) (0), 0.0),
             "Example 1D line P0");
      Check (Approx (Make_Example_1D (Cubic_S_Curve) (1), 1.0),
             "Example 1D S P1");
   end;

   ---------------------------------------------------------------------
   Section ("3. Endpoints B(0)=P0, B(1)=Pn");
   ---------------------------------------------------------------------
   declare
      Line : constant Controls_2D := Make_Example_2D (Line_Segment);
      Arch : constant Controls_2D := Make_Example_2D (Quadratic_Arch);
      Sq   : constant Controls_2D := Make_Example_2D (Cubic_Unit_Square);
      S    : constant Controls_2D := Make_Example_2D (Cubic_S_Curve);
      R0, R1 : Eval_Result_2D;
      S1     : constant Controls_1D := Make_Example_1D (Cubic_S_Curve);
      E0, E1 : Eval_Result_1D;
   begin
      R0 := Evaluate (Line, 0.0);
      R1 := Evaluate (Line, 1.0);
      Check (R0.Success and R0.Stat = Ok, "Line t=0 ok");
      Check (Near (R0.Point, Line (0)), "Line B(0)=P0");
      Check (Near (R1.Point, Line (1)), "Line B(1)=P1");

      R0 := Evaluate (Arch, 0.0);
      R1 := Evaluate (Arch, 1.0);
      Check (Near (R0.Point, Arch (0)), "Arch B(0)=P0");
      Check (Near (R1.Point, Arch (2)), "Arch B(1)=P2");

      R0 := Evaluate (Sq, 0.0);
      R1 := Evaluate (Sq, 1.0);
      Check (Near (R0.Point, Sq (0)), "Square B(0)=P0");
      Check (Near (R1.Point, Sq (3)), "Square B(1)=P3");

      R0 := Evaluate (S, 0.0);
      R1 := Evaluate (S, 1.0);
      Check (Near (R0.Point, S (0)), "S B(0)=P0");
      Check (Near (R1.Point, S (3)), "S B(1)=P3");

      E0 := Evaluate (S1, 0.0);
      E1 := Evaluate (S1, 1.0);
      Check (Approx (E0.Value, S1 (0)), "1D S B(0)");
      Check (Approx (E1.Value, S1 (3)), "1D S B(1)");
   end;

   ---------------------------------------------------------------------
   Section ("4. Linear Bézier / midpoint of line");
   ---------------------------------------------------------------------
   declare
      L  : constant Controls_2D :=
        Make_Line_2D (Make_Point (0.0, 0.0), Make_Point (10.0, 20.0));
      L1 : constant Controls_1D := Make_Line_1D (-1.0, 3.0);
      R  : Eval_Result_2D;
      R1 : Eval_Result_1D;
   begin
      R := Evaluate (L, 0.5);
      Check (R.Success, "Line mid success");
      Check (Near (R.Point, Make_Point (5.0, 10.0)), "Line mid (5,10)");
      R := Evaluate (L, 0.25);
      Check (Near (R.Point, Make_Point (2.5, 5.0)), "Line t=0.25");
      R := Evaluate (L, 0.75);
      Check (Near (R.Point, Make_Point (7.5, 15.0)), "Line t=0.75");

      R1 := Evaluate (L1, 0.5);
      Check (Approx (R1.Value, 1.0), "1D line mid = 1");
      R1 := Evaluate (L1, 0.0);
      Check (Approx (R1.Value, -1.0), "1D line t=0");
      R1 := Evaluate (L1, 1.0);
      Check (Approx (R1.Value, 3.0), "1D line t=1");

      --  Constant (degree 0)
      declare
         C0 : constant Controls_1D (0 .. 0) := [42.0];
         E  : constant Eval_Result_1D := Evaluate (C0, 0.3);
      begin
         Check (E.Success and Approx (E.Value, 42.0), "Degree-0 const");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. Quadratic known values");
   ---------------------------------------------------------------------
   declare
      --  B(t) = (1-t)^2 P0 + 2(1-t)t P1 + t^2 P2
      --  Arch: (0,0),(0.5,1),(1,0) → at t=0.5: (0.5, 0.5)
      Arch : constant Controls_2D := Make_Example_2D (Quadratic_Arch);
      R    : Eval_Result_2D;
   begin
      R := Evaluate (Arch, 0.5);
      Check (Near (R.Point, Make_Point (0.5, 0.5)), "Arch B(0.5)=(0.5,0.5)");
      R := Evaluate (Arch, 0.25);
      --  (0.75)^2*(0,0) + 2*0.75*0.25*(0.5,1) + (0.25)^2*(1,0)
      --  = (0,0) + 0.375*(0.5,1) + 0.0625*(1,0) = (0.1875+0.0625, 0.375)
      --  = (0.25, 0.375)
      Check (Near (R.Point, Make_Point (0.25, 0.375)),
             "Arch B(0.25)=(0.25,0.375)");
   end;

   ---------------------------------------------------------------------
   Section ("6. Split then evaluate continuity");
   ---------------------------------------------------------------------
   declare
      Sq   : constant Controls_2D := Make_Example_2D (Cubic_Unit_Square);
      Sp   : constant Split_Result_2D := Split (Sq, 0.4);
      Left : Controls_2D (0 .. Sp.Degree);
      Right : Controls_2D (0 .. Sp.Degree);
      Orig : Eval_Result_2D;
      EL, ER : Eval_Result_2D;
   begin
      Check (Sp.Success, "Split success");
      Check (Sp.Degree = 3, "Split degree 3");
      Check (Sp.Stat = Ok, "Split t=0.4 Ok");
      for I in 0 .. Sp.Degree loop
         Left (I)  := Sp.Left (I);
         Right (I) := Sp.Right (I);
      end loop;
      --  Join: Left at t=1 equals Right at t=0 equals B(0.4)
      Orig := Evaluate (Sq, 0.4);
      EL   := Evaluate (Left, 1.0);
      ER   := Evaluate (Right, 0.0);
      Check (Near (EL.Point, Orig.Point), "Left(1)=B(0.4)");
      Check (Near (ER.Point, Orig.Point), "Right(0)=B(0.4)");
      Check (Near (Sp.Left (0), Sq (0)), "Left starts at P0");
      Check (Near (Sp.Right (Sp.Degree), Sq (3)), "Right ends at P3");
      Check (Near (Sp.Left (Sp.Degree), Sp.Right (0)),
             "Left end = Right start");

      --  Reparam: B_left(u) = B(0.4*u); B_right(u) = B(0.4+0.6*u)
      EL := Evaluate (Left, 0.5);
      Orig := Evaluate (Sq, 0.4 * 0.5);
      Check (Near (EL.Point, Orig.Point, 1.0E-4),
             "Left reparam u=0.5");
      ER := Evaluate (Right, 0.5);
      Orig := Evaluate (Sq, 0.4 + 0.6 * 0.5);
      Check (Near (ER.Point, Orig.Point, 1.0E-4),
             "Right reparam u=0.5");
   end;

   declare
      Arch : constant Controls_2D := Make_Example_2D (Quadratic_Arch);
      Sp   : constant Split_Result_2D := Split (Arch, 0.5);
      Left : Controls_2D (0 .. 2);
      Right : Controls_2D (0 .. 2);
      Orig, EL : Eval_Result_2D;
   begin
      for I in 0 .. 2 loop
         Left (I)  := Sp.Left (I);
         Right (I) := Sp.Right (I);
      end loop;
      Orig := Evaluate (Arch, 0.5);
      EL   := Evaluate (Left, 1.0);
      Check (Near (EL.Point, Orig.Point), "Quad split join");
      Check (Near (Evaluate (Right, 0.0).Point, Orig.Point),
             "Quad split right start");
      Check (Near (Evaluate (Left, 0.0).Point, Arch (0)),
             "Quad left start P0");
      Check (Near (Evaluate (Right, 1.0).Point, Arch (2)),
             "Quad right end P2");
   end;

   ---------------------------------------------------------------------
   Section ("7. Bernstein vs De Casteljau (cubic)");
   ---------------------------------------------------------------------
   declare
      Sq : constant Controls_2D := Make_Example_2D (Cubic_Unit_Square);
      S  : constant Controls_2D := Make_Example_2D (Cubic_S_Curve);
      Ts : constant array (1 .. 7) of Float :=
        [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0];
      DC, BR : Eval_Result_2D;
   begin
      for K in Ts'Range loop
         DC := Evaluate (Sq, Ts (K));
         BR := Evaluate_Bernstein (Sq, Ts (K));
         Check (DC.Success and BR.Success
                and Near (DC.Point, BR.Point, 1.0E-4),
                "Bern≈DC square t=" & Ts (K)'Image);
         DC := Evaluate (S, Ts (K));
         BR := Evaluate_Bernstein (S, Ts (K));
         Check (DC.Success and BR.Success
                and Near (DC.Point, BR.Point, 1.0E-4),
                "Bern≈DC S t=" & Ts (K)'Image);
      end loop;
   end;

   declare
      C1 : constant Controls_1D := Make_Example_1D (Cubic_S_Curve);
      DC, BR : Eval_Result_1D;
      T1D : constant array (1 .. 4) of Float :=
        [0.0, 0.33, 0.66, 1.0];
   begin
      for K in T1D'Range loop
         DC := Evaluate (C1, T1D (K));
         BR := Evaluate_Bernstein (C1, T1D (K));
         Check (Approx (DC.Value, BR.Value, 1.0E-4),
                "Bern≈DC 1D sample");
      end loop;
   end;

   declare
      C3 : constant Controls_3D :=
        Make_Cubic_3D
          (Make_Point (0.0, 0.0, 0.0),
           Make_Point (1.0, 0.0, 1.0),
           Make_Point (1.0, 1.0, 0.0),
           Make_Point (0.0, 1.0, 1.0));
      DC, BR : Eval_Result_3D;
   begin
      DC := Evaluate (C3, 0.5);
      BR := Evaluate_Bernstein (C3, 0.5);
      Check (Near (DC.Point, BR.Point, 1.0E-4), "Bern≈DC 3D mid");
      Check (Near (Evaluate (C3, 0.0).Point, C3 (0)), "3D B(0)");
      Check (Near (Evaluate (C3, 1.0).Point, C3 (3)), "3D B(1)");
   end;

   ---------------------------------------------------------------------
   Section ("8. Binomial / Bernstein basis");
   ---------------------------------------------------------------------
   begin
      Check (Approx (Binomial (0, 0), 1.0), "C(0,0)=1");
      Check (Approx (Binomial (5, 0), 1.0), "C(5,0)=1");
      Check (Approx (Binomial (5, 5), 1.0), "C(5,5)=1");
      Check (Approx (Binomial (5, 2), 10.0), "C(5,2)=10");
      Check (Approx (Binomial (10, 3), 120.0), "C(10,3)=120");
      Check (Approx (Binomial (16, 8), 12870.0, 1.0), "C(16,8)");
      --  Partition of unity: sum_i b_{i,n}(t) = 1
      declare
         S : Float;
      begin
         for N in 1 .. 6 loop
            S := 0.0;
            for I in 0 .. N loop
               S := S + Bernstein (I, N, 0.3);
            end loop;
            Check (Approx (S, 1.0, 1.0E-5),
                   "Bern sum=1 n=" & N'Image);
         end loop;
      end;
      Check (Approx (Bernstein (0, 3, 0.0), 1.0), "b00 at 0");
      Check (Approx (Bernstein (3, 3, 1.0), 1.0), "b33 at 1");
      Check (Approx (Bernstein (1, 3, 0.0), 0.0), "b13 at 0");
   end;

   ---------------------------------------------------------------------
   Section ("9. Extrapolation status / empty / bad dims");
   ---------------------------------------------------------------------
   declare
      L  : constant Controls_2D := Make_Example_2D (Line_Segment);
      R  : Eval_Result_2D;
      Sp : Split_Result_2D;
   begin
      R := Evaluate (L, -0.5);
      Check (R.Success and R.Stat = Extrapolated, "t<0 Extrapolated");
      --  Linear: B(-0.5) = (1-(-0.5))*(0,0)+(-0.5)*(1,0)=(-0.5,0)? Wait
      --  (1-t)P0+tP1 with t=-0.5: 1.5*(0,0)+(-0.5)*(1,0)=(-0.5,0)
      Check (Near (R.Point, Make_Point (-0.5, 0.0)), "extrap value");
      R := Evaluate (L, 1.5);
      Check (R.Success and R.Stat = Extrapolated, "t>1 Extrapolated");
      Check (Near (R.Point, Make_Point (1.5, 0.0)), "extrap t=1.5");

      Sp := Split (L, -0.25);
      Check (Sp.Success and Sp.Stat = Extrapolated, "Split extrap");

      --  Empty controls via zero-length array
      declare
         E : constant Controls_1D := Controls_1D'(1 .. 0 => <>);
         ER : constant Eval_Result_1D := Evaluate (E, 0.5);
         ES : constant Split_Result_1D := Split (E, 0.5);
         EB : constant Eval_Result_1D := Evaluate_Bernstein (E, 0.5);
      begin
         Check (not ER.Success and ER.Stat = Empty, "Eval empty");
         Check (not ES.Success and ES.Stat = Empty, "Split empty");
         Check (not EB.Success and EB.Stat = Empty, "Bern empty");
      end;

   end;

   ---------------------------------------------------------------------
   Section ("10. Split identity at endpoints");
   ---------------------------------------------------------------------
   declare
      Sq : constant Controls_2D := Make_Example_2D (Cubic_Unit_Square);
      S0 : constant Split_Result_2D := Split (Sq, 0.0);
      S1 : constant Split_Result_2D := Split (Sq, 1.0);
   begin
      Check (S0.Success and S1.Success, "Split 0/1 success");
      --  At t=0: Left is degenerate all P0; Right is original
      Check (Near (S0.Right (0), Sq (0))
             and Near (S0.Right (1), Sq (1))
             and Near (S0.Right (2), Sq (2))
             and Near (S0.Right (3), Sq (3)),
             "Split t=0 Right=original");
      Check (Near (S0.Left (0), Sq (0))
             and Near (S0.Left (3), Sq (0)),
             "Split t=0 Left≈P0");
      --  At t=1: Left=original; Right all Pn
      Check (Near (S1.Left (0), Sq (0))
             and Near (S1.Left (1), Sq (1))
             and Near (S1.Left (2), Sq (2))
             and Near (S1.Left (3), Sq (3)),
             "Split t=1 Left=original");
      Check (Near (S1.Right (0), Sq (3))
             and Near (S1.Right (3), Sq (3)),
             "Split t=1 Right≈Pn");
   end;

   ---------------------------------------------------------------------
   Section ("11. 1D split continuity / 3D split");
   ---------------------------------------------------------------------
   declare
      C  : constant Controls_1D := Make_Example_1D (Cubic_S_Curve);
      Sp : constant Split_Result_1D := Split (C, 0.3);
      L  : Controls_1D (0 .. Sp.Degree);
      R  : Controls_1D (0 .. Sp.Degree);
      Orig, EL, ER : Eval_Result_1D;
   begin
      Check (Sp.Success, "1D split success");
      for I in 0 .. Sp.Degree loop
         L (I) := Sp.Left (I);
         R (I) := Sp.Right (I);
      end loop;
      Orig := Evaluate (C, 0.3);
      EL   := Evaluate (L, 1.0);
      ER   := Evaluate (R, 0.0);
      Check (Approx (EL.Value, Orig.Value, 1.0E-5), "1D Left(1)=B");
      Check (Approx (ER.Value, Orig.Value, 1.0E-5), "1D Right(0)=B");
   end;

   declare
      C3 : constant Controls_3D :=
        Make_Line_3D
          (Make_Point (0.0, 0.0, 0.0), Make_Point (2.0, 4.0, 6.0));
      Sp : constant Split_Result_3D := Split (C3, 0.5);
      Mid : constant Eval_Result_3D := Evaluate (C3, 0.5);
   begin
      Check (Sp.Success, "3D line split");
      Check (Near (Mid.Point, Make_Point (1.0, 2.0, 3.0)),
             "3D line mid");
      Check (Near (Sp.Left (1), Mid.Point)
             and Near (Sp.Right (0), Mid.Point),
             "3D split join at mid");
   end;

   ---------------------------------------------------------------------
   Section ("12. High degree / many samples");
   ---------------------------------------------------------------------
   declare
      --  Degree 8: points on a line so B(t)=(1-t)P0+tPn still
      C : Controls_1D (0 .. 8);
      R : Eval_Result_1D;
   begin
      for I in C'Range loop
         C (I) := Float (I);  --  0,1,...,8 — NOT collinear in param sense
         --  Actually for Bézier, evenly spaced controls on a line:
         --  P_i = i/8 give B(t)=t; here P_i=i so B(t)=8t for linear case
         --  Wait: only degree-1 is exactly linear for arbitrary controls.
         --  For collinear equally spaced P_i = a + (b-a)*i/n, B(t)=a+(b-a)t.
         C (I) := Float (I) / 8.0;
      end loop;
      R := Evaluate (C, 0.0);
      Check (Approx (R.Value, 0.0), "deg8 B(0)=0");
      R := Evaluate (C, 1.0);
      Check (Approx (R.Value, 1.0), "deg8 B(1)=1");
      R := Evaluate (C, 0.5);
      Check (Approx (R.Value, 0.5, 1.0E-5), "deg8 collinear B(0.5)");
      Check (Degree_Of (C) = 8, "Degree_Of 8");
   end;

   declare
      Sq : constant Controls_2D := Make_Example_2D (Cubic_Unit_Square);
      R  : Eval_Result_2D;
      Prev : Point_2D := Evaluate (Sq, 0.0).Point;
      Step : constant Float := 0.05;
      T    : Float := Step;
      OK   : Boolean := True;
   begin
      while T <= 1.0 + 1.0E-6 loop
         R := Evaluate (Sq, Float'Min (T, 1.0));
         if Dist (Prev, R.Point) > 1.0 then
            OK := False;
         end if;
         Prev := R.Point;
         T := T + Step;
      end loop;
      Check (OK, "Cubic square path continuous samples");
      --  Mid of unit-square cubic: known formula
      --  B(0.5)= 1/8 P0 + 3/8 P1 + 3/8 P2 + 1/8 P3
      --  = 1/8(0,0)+3/8(0,1)+3/8(1,1)+1/8(1,0)=(0.5, 0.75)
      R := Evaluate (Sq, 0.5);
      Check (Near (R.Point, Make_Point (0.5, 0.75)),
             "Square B(0.5)=(0.5,0.75)");
   end;

   ---------------------------------------------------------------------
   Section ("13. Convex hull / endpoint tangents smoke");
   ---------------------------------------------------------------------
   declare
      --  For a Bézier, B'(0)=n(P1-P0); at small h, (B(h)-B(0))/h ≈ B'(0)
      Sq : constant Controls_2D := Make_Example_2D (Cubic_Unit_Square);
      --  n=3, P1-P0=(0,1), so B'(0)=(0,3)
      B0 : constant Point_2D := Evaluate (Sq, 0.0).Point;
      Bh : constant Point_2D := Evaluate (Sq, 0.001).Point;
      Approx_Deriv : constant Point_2D :=
        Scale (Sub (Bh, B0), 1.0 / 0.001);
   begin
      Check (Near (Approx_Deriv, Make_Point (0.0, 3.0), 0.05),
             "Endpoint tangent ≈ n(P1-P0)");
   end;

   declare
      Arch : constant Controls_2D := Make_Example_2D (Quadratic_Arch);
      --  All evaluated points should stay in bounding box [0,1]x[0,1]
      R : Eval_Result_2D;
      Inside : Boolean := True;
   begin
      for K in 0 .. 20 loop
         R := Evaluate (Arch, Float (K) / 20.0);
         if R.Point.X < -1.0E-5 or else R.Point.X > 1.0 + 1.0E-5
           or else R.Point.Y < -1.0E-5 or else R.Point.Y > 1.0 + 1.0E-5
         then
            Inside := False;
         end if;
      end loop;
      Check (Inside, "Arch samples in [0,1]^2 hull");
   end;

   ---------------------------------------------------------------------
   Section ("14. Max degree / status notes");
   ---------------------------------------------------------------------
   declare
      C : Controls_1D (0 .. Max_Degree);
      R : Eval_Result_1D;
   begin
      for I in C'Range loop
         C (I) := 0.0;
      end loop;
      C (0) := 1.0;
      C (Max_Degree) := 2.0;
      R := Evaluate (C, 0.0);
      Check (R.Success and Approx (R.Value, 1.0), "Max degree B(0)");
      R := Evaluate (C, 1.0);
      Check (R.Success and Approx (R.Value, 2.0), "Max degree B(1)");
      Check (Degree_Of (C) = Max_Degree, "Degree_Of Max");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("----------------------------------");
   Ada.Text_IO.Put_Line
     ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
