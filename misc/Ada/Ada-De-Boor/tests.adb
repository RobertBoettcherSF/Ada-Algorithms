--  Standalone test suite for De_Boor (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with De_Boor; use De_Boor;

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

   --  Tiny inline cubic De Casteljau oracle for Bézier ↔ B-spline check.
   function Casteljau_Cubic_2D
     (P0, P1, P2, P3 : Point_2D; T : Float) return Point_2D
   is
      A, B, C, D, E, F : Point_2D;
   begin
      A := Lerp (P0, P1, T);
      B := Lerp (P1, P2, T);
      C := Lerp (P2, P3, T);
      D := Lerp (A, B, T);
      E := Lerp (B, C, T);
      F := Lerp (D, E, T);
      return F;
   end Casteljau_Cubic_2D;

   function Casteljau_Cubic_1D
     (C0, C1, C2, C3 : Float; T : Float) return Float
   is
   begin
      declare
         A : constant Float := Lerp (C0, C1, T);
         B : constant Float := Lerp (C1, C2, T);
         C : constant Float := Lerp (C2, C3, T);
         D : constant Float := Lerp (A, B, T);
         E : constant Float := Lerp (B, C, T);
      begin
         return Lerp (D, E, T);
      end;
   end Casteljau_Cubic_1D;

begin
   Ada.Text_IO.Put_Line ("De_Boor test suite");
   Ada.Text_IO.Put_Line ("==================");

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
   end;

   ---------------------------------------------------------------------
   Section ("2. Knot builders / Is_Valid_Knots / Expected count");
   ---------------------------------------------------------------------
   declare
      K1 : constant Knot_Vector := Make_Uniform_Clamped (2, 1);
      K3 : constant Knot_Vector := Make_Bezier_Knots (3);
      KQ : constant Knot_Vector := Make_Uniform_Clamped (4, 2);
      KC : constant Knot_Vector := Make_Uniform_Clamped (5, 3);
      Bad_Dec : constant Knot_Vector := [0.0, 1.0, 0.5, 1.0];
      Bad_Len : constant Knot_Vector := [0.0, 0.0, 1.0, 1.0];
   begin
      Check (Expected_Knot_Count (2, 1) = 4, "Expected knots linear");
      Check (Expected_Knot_Count (4, 3) = 8, "Expected knots cubic Bézier");
      Check (Expected_Knot_Count (5, 3) = 9, "Expected knots 5 ctrl p=3");
      Check (K1'Length = 4, "Linear knots length 4");
      Check (Approx (K1 (0), 0.0) and Approx (K1 (1), 0.0),
             "Linear knots start clamp");
      Check (Approx (K1 (2), 1.0) and Approx (K1 (3), 1.0),
             "Linear knots end clamp");
      Check (K3'Length = 8, "Bézier knots length 8");
      Check (Approx (K3 (0), 0.0) and Approx (K3 (3), 0.0),
             "Bézier knots leading 0");
      Check (Approx (K3 (4), 1.0) and Approx (K3 (7), 1.0),
             "Bézier knots trailing 1");
      Check (Is_Valid_Knots (K1, 1, 2), "Valid linear knots");
      Check (Is_Valid_Knots (K3, 3, 4), "Valid Bézier knots");
      Check (Is_Valid_Knots (KQ, 2, 4), "Valid quadratic uniform");
      Check (Is_Valid_Knots (KC, 3, 5), "Valid cubic uniform");
      Check (not Is_Valid_Knots (Bad_Dec, 1, 2), "Reject decreasing");
      Check (not Is_Valid_Knots (Bad_Len, 3, 4), "Reject wrong length");
      Check (KQ'Length = 7, "Quad knots length 7");
      --  Uniform clamped 4 ctrl degree 2: [0,0,0, 0.5, 1,1,1]
      Check (Approx (KQ (3), 0.5), "Quad interior knot 0.5");
   end;

   ---------------------------------------------------------------------
   Section ("3. Domain / Find_Span");
   ---------------------------------------------------------------------
   declare
      K  : constant Knot_Vector := Make_Uniform_Clamped (5, 3);
      --  knots: 0,0,0,0, 0.5, 1,1,1,1  (n=4, p=3 → interior index 4)
      S0, S1, Sm, Sb : Span_Result;
   begin
      Check (Approx (Domain_Low (K, 3), 0.0), "Domain low = 0");
      Check (Approx (Domain_High (K, 3, 5), 1.0), "Domain high = 1");
      Check (In_Domain (K, 3, 5, 0.0), "In domain 0");
      Check (In_Domain (K, 3, 5, 1.0), "In domain 1");
      Check (In_Domain (K, 3, 5, 0.5), "In domain 0.5");
      Check (not In_Domain (K, 3, 5, -0.1), "Out domain -0.1");
      Check (not In_Domain (K, 3, 5, 1.1), "Out domain 1.1");

      S0 := Find_Span (K, 3, 5, 0.0);
      Check (S0.Success and S0.Index = 3, "Span at 0 → k=3 (=p)");
      S1 := Find_Span (K, 3, 5, 1.0);
      Check (S1.Success and S1.Index = 4, "Span at 1 → k=n=4");
      Sm := Find_Span (K, 3, 5, 0.25);
      Check (Sm.Success and Sm.Index = 3, "Span at 0.25 → k=3");
      Sb := Find_Span (K, 3, 5, 0.75);
      Check (Sb.Success and Sb.Index = 4, "Span at 0.75 → k=4");
      Check (Find_Span (K, 3, 5, -1.0).Stat = Out_Of_Domain,
             "Find_Span OOD low");
      Check (Find_Span (K, 3, 5, 2.0).Stat = Out_Of_Domain,
             "Find_Span OOD high");
   end;

   ---------------------------------------------------------------------
   Section ("4. Clamped endpoints = first / last control");
   ---------------------------------------------------------------------
   declare
      Line : constant Curve_2D := Make_Example_2D (Linear_Ramp);
      Bez  : constant Curve_2D := Make_Example_2D (Cubic_Bezier_Unit);
      Quad : constant Curve_2D := Make_Example_2D (Uniform_Quadratic);
      Cub  : constant Curve_2D := Make_Example_2D (Clamped_Cubic);
      R0, R1 : Eval_Result_2D;
      L1 : constant Curve_1D := Make_Example_1D (Linear_Ramp);
      E0, E1 : Eval_Result_1D;
   begin
      R0 := Evaluate_Curve (Line, 0.0);
      R1 := Evaluate_Curve (Line, 1.0);
      Check (R0.Success and R0.Stat = Ok, "Line t=0 ok");
      Check (Near (R0.Point, Line.Controls (0)), "Line S(0)=c0");
      Check (Near (R1.Point, Line.Controls (1)), "Line S(1)=c1");

      R0 := Evaluate_Curve (Bez, 0.0);
      R1 := Evaluate_Curve (Bez, 1.0);
      Check (Near (R0.Point, Bez.Controls (0)), "Bez S(0)=c0");
      Check (Near (R1.Point, Bez.Controls (3)), "Bez S(1)=c3");

      R0 := Evaluate_Curve (Quad, 0.0);
      R1 := Evaluate_Curve (Quad, 1.0);
      Check (Near (R0.Point, Quad.Controls (0)), "Quad S(0)=c0");
      Check (Near (R1.Point, Quad.Controls (3)), "Quad S(1)=c3");

      R0 := Evaluate_Curve (Cub, 0.0);
      R1 := Evaluate_Curve (Cub, 1.0);
      Check (Near (R0.Point, Cub.Controls (0)), "Cub S(0)=c0");
      Check (Near (R1.Point, Cub.Controls (4)), "Cub S(1)=c4");

      E0 := Evaluate_Curve (L1, 0.0);
      E1 := Evaluate_Curve (L1, 1.0);
      Check (Approx (E0.Value, 0.0), "1D line S(0)");
      Check (Approx (E1.Value, 1.0), "1D line S(1)");
   end;

   ---------------------------------------------------------------------
   Section ("5. Degree-1 linear interpolant");
   ---------------------------------------------------------------------
   declare
      L  : constant Curve_2D :=
        Make_Linear_Interpolant_2D
          (Make_Point (0.0, 0.0), Make_Point (10.0, 20.0));
      L1 : constant Curve_1D := Make_Linear_Interpolant_1D (-1.0, 3.0);
      R  : Eval_Result_2D;
      R1 : Eval_Result_1D;
      Ctrl : constant Controls_1D := Make_Linear_1D (0.0, 1.0);
      Knot : constant Knot_Vector := Make_Uniform_Clamped (2, 1);
   begin
      R := Evaluate_Curve (L, 0.5);
      Check (R.Success, "Line mid success");
      Check (Near (R.Point, Make_Point (5.0, 10.0)), "Line mid (5,10)");
      R := Evaluate_Curve (L, 0.25);
      Check (Near (R.Point, Make_Point (2.5, 5.0)), "Line t=0.25");
      R := Evaluate_Curve (L, 0.75);
      Check (Near (R.Point, Make_Point (7.5, 15.0)), "Line t=0.75");

      R1 := Evaluate_Curve (L1, 0.5);
      Check (Approx (R1.Value, 1.0), "1D line mid = 1");
      R1 := Evaluate_Curve (L1, 0.0);
      Check (Approx (R1.Value, -1.0), "1D line t=0");
      R1 := Evaluate_Curve (L1, 1.0);
      Check (Approx (R1.Value, 3.0), "1D line t=1");

      R1 := Evaluate (Ctrl, Knot, 1, 0.3);
      Check (Approx (R1.Value, 0.3), "Raw Evaluate linear 0.3");
   end;

   ---------------------------------------------------------------------
   Section ("6. Cubic Bézier equivalence (De Boor vs Casteljau)");
   ---------------------------------------------------------------------
   declare
      P0 : constant Point_2D := Make_Point (0.0, 0.0);
      P1 : constant Point_2D := Make_Point (0.0, 1.0);
      P2 : constant Point_2D := Make_Point (1.0, 1.0);
      P3 : constant Point_2D := Make_Point (1.0, 0.0);
      Curve : constant Curve_2D :=
        Make_Cubic_Bezier_As_BSpline_2D (P0, P1, P2, P3);
      R : Eval_Result_2D;
      Oracle : Point_2D;
      All_Ok : Boolean := True;
      Ts : constant array (1 .. 9) of Float :=
        [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0];
   begin
      for T of Ts loop
         R := Evaluate_Curve (Curve, T);
         Oracle := Casteljau_Cubic_2D (P0, P1, P2, P3, T);
         if not (R.Success and then Near (R.Point, Oracle, 1.0E-4)) then
            All_Ok := False;
            Ada.Text_IO.Put_Line
              ("    mismatch at t=" & T'Image
               & " got (" & R.Point.X'Image & "," & R.Point.Y'Image
               & ") expect (" & Oracle.X'Image & "," & Oracle.Y'Image & ")");
         end if;
      end loop;
      Check (All_Ok, "Cubic Bézier De Boor ≡ Casteljau (9 samples)");

      --  Known mid: unit-square cubic B(0.5)=(0.5, 0.75)
      R := Evaluate_Curve (Curve, 0.5);
      Check (Near (R.Point, Make_Point (0.5, 0.75)),
             "Unit-square B(0.5)=(0.5,0.75)");

      --  1D Bézier equivalence
      declare
         C0 : constant Float := 0.0;
         C1 : constant Float := 1.0;
         C2 : constant Float := 2.0;
         C3 : constant Float := 3.0;
         Ctrl : constant Controls_1D := Make_Cubic_Bezier_1D (C0, C1, C2, C3);
         Knot : constant Knot_Vector := Make_Bezier_Knots (3);
         E : Eval_Result_1D;
         Ok1 : Boolean := True;
      begin
         for T of Ts loop
            E := Evaluate (Ctrl, Knot, 3, T);
            if not (E.Success
                    and then Approx
                      (E.Value, Casteljau_Cubic_1D (C0, C1, C2, C3, T),
                       1.0E-4))
            then
               Ok1 := False;
            end if;
         end loop;
         Check (Ok1, "1D cubic Bézier ≡ Casteljau");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Mid-span smoothness sample (uniform quadratic)");
   ---------------------------------------------------------------------
   declare
      Q : constant Curve_2D := Make_Example_2D (Uniform_Quadratic);
      --  Sample densely; consecutive points should move continuously
      Prev, Curr : Eval_Result_2D;
      Max_Jump : Float := 0.0;
      Jump : Float;
      N : constant := 40;
   begin
      Prev := Evaluate_Curve (Q, 0.0);
      Check (Prev.Success, "Quad start ok");
      for I in 1 .. N loop
         Curr := Evaluate_Curve (Q, Float (I) / Float (N));
         Check (Curr.Success, "Quad sample ok @" & I'Image);
         Jump := Dist (Prev.Point, Curr.Point);
         if Jump > Max_Jump then
            Max_Jump := Jump;
         end if;
         Prev := Curr;
      end loop;
      --  Chord of control polygon is O(1); per-step jump should be small
      Check (Max_Jump < 0.2, "Quad max consecutive jump < 0.2");

      --  At interior knot 0.5, left/right limits agree (C1 for quadratic
      --  open with simple knots — at least C0 continuity)
      declare
         Left  : constant Eval_Result_2D :=
           Evaluate_Curve (Q, 0.5 - 1.0E-4);
         Right : constant Eval_Result_2D :=
           Evaluate_Curve (Q, 0.5 + 1.0E-4);
         Mid   : constant Eval_Result_2D := Evaluate_Curve (Q, 0.5);
      begin
         Check (Near (Left.Point, Mid.Point, 1.0E-3),
                "C0 left of interior knot");
         Check (Near (Right.Point, Mid.Point, 1.0E-3),
                "C0 right of interior knot");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Invalid knots / out of domain / dimension errors");
   ---------------------------------------------------------------------
   declare
      Ctrl : constant Controls_2D :=
        Make_Linear_2D (Make_Point (0.0, 0.0), Make_Point (1.0, 1.0));
      Good : constant Knot_Vector := Make_Uniform_Clamped (2, 1);
      Dec  : constant Knot_Vector := [0.0, 1.0, 0.5, 1.0];
      Short : constant Knot_Vector := [0.0, 1.0];
      R : Eval_Result_2D;
      R1 : Eval_Result_1D;
      Empty_C : Controls_1D (1 .. 0);
   begin
      R := Evaluate (Ctrl, Dec, 1, 0.5);
      Check (R.Stat = Invalid_Knots and not R.Success,
             "Decreasing knots → Invalid_Knots");
      R := Evaluate (Ctrl, Short, 1, 0.5);
      Check (R.Stat = Invalid_Knots and not R.Success,
             "Short knots → Invalid_Knots");
      R := Evaluate (Ctrl, Good, 1, -0.5);
      Check (R.Stat = Out_Of_Domain and not R.Success,
             "X < domain → Out_Of_Domain");
      R := Evaluate (Ctrl, Good, 1, 1.5);
      Check (R.Stat = Out_Of_Domain and not R.Success,
             "X > domain → Out_Of_Domain");

      --  Degree >= Num_Controls
      R := Evaluate (Ctrl, Good, 2, 0.5);
      Check (R.Stat = Dimension_Error or R.Stat = Invalid_Knots,
             "Degree too high vs controls");

      R1 := Evaluate (Empty_C, Good, 0, 0.0);
      Check (R1.Stat = Dimension_Error and not R1.Success,
             "Empty controls → Dimension_Error");
   end;

   ---------------------------------------------------------------------
   Section ("9. 3D evaluate / cubic Bézier 3D");
   ---------------------------------------------------------------------
   declare
      P0 : constant Point_3D := Make_Point (0.0, 0.0, 0.0);
      P1 : constant Point_3D := Make_Point (1.0, 0.0, 0.0);
      P2 : constant Point_3D := Make_Point (1.0, 1.0, 0.0);
      P3 : constant Point_3D := Make_Point (1.0, 1.0, 1.0);
      Ctrl : constant Controls_3D := Make_Cubic_Bezier_3D (P0, P1, P2, P3);
      Knot : constant Knot_Vector := Make_Bezier_Knots (3);
      R0, R1, Rm : Eval_Result_3D;
      Line : constant Controls_3D := Make_Linear_3D (P0, P3);
      LK   : constant Knot_Vector := Make_Uniform_Clamped (2, 1);
      RL   : Eval_Result_3D;
   begin
      R0 := Evaluate (Ctrl, Knot, 3, 0.0);
      R1 := Evaluate (Ctrl, Knot, 3, 1.0);
      Check (R0.Success and Near (R0.Point, P0), "3D Bez S(0)");
      Check (R1.Success and Near (R1.Point, P3), "3D Bez S(1)");
      Rm := Evaluate (Ctrl, Knot, 3, 0.5);
      Check (Rm.Success, "3D Bez mid success");
      --  Mid of this cubic: average Bernstein
      --  B(0.5)=1/8 P0 + 3/8 P1 + 3/8 P2 + 1/8 P3
      --  = (0,0,0)/8 + 3(1,0,0)/8 + 3(1,1,0)/8 + (1,1,1)/8
      --  = (0+3+3+1, 0+0+3+1, 0+0+0+1)/8 = (7,4,1)/8
      Check (Near (Rm.Point, Make_Point (0.875, 0.5, 0.125)),
             "3D Bez B(0.5)=(7/8,1/2,1/8)");

      RL := Evaluate (Line, LK, 1, 0.5);
      Check (Near (RL.Point, Make_Point (0.5, 0.5, 0.5)),
             "3D linear mid");
   end;

   ---------------------------------------------------------------------
   Section ("10. Uniform clamped cubic samples / convex hull smoke");
   ---------------------------------------------------------------------
   declare
      Cub : constant Curve_2D := Make_Example_2D (Clamped_Cubic);
      R : Eval_Result_2D;
      Inside : Boolean := True;
   begin
      for K in 0 .. 20 loop
         R := Evaluate_Curve (Cub, Float (K) / 20.0);
         if not R.Success then
            Inside := False;
         elsif R.Point.X < -0.05 or else R.Point.X > 1.05
           or else R.Point.Y < -0.05 or else R.Point.Y > 1.05
         then
            Inside := False;
         end if;
      end loop;
      Check (Inside, "Clamped cubic samples near hull [0,1]^2");
   end;

   ---------------------------------------------------------------------
   Section ("11. Degree-0 constant / max degree smoke");
   ---------------------------------------------------------------------
   declare
      --  Degree 0: one control, knots [0,1]
      C0 : constant Controls_1D (0 .. 0) := [42.0];
      K0 : constant Knot_Vector := [0.0, 1.0];
      E  : Eval_Result_1D;
   begin
      Check (Is_Valid_Knots (K0, 0, 1), "Degree-0 knots valid");
      E := Evaluate (C0, K0, 0, 0.3);
      Check (E.Success and Approx (E.Value, 42.0), "Degree-0 const");
      E := Evaluate (C0, K0, 0, 0.0);
      Check (E.Success and Approx (E.Value, 42.0), "Degree-0 at 0");
      E := Evaluate (C0, K0, 0, 1.0);
      Check (E.Success and Approx (E.Value, 42.0), "Degree-0 at 1");
   end;

   declare
      --  Max degree Bézier: p=8, 9 controls, knots 0^9 1^9
      P : constant := 8;
      Ctrl : Controls_1D (0 .. P);
      Knot : constant Knot_Vector := Make_Bezier_Knots (P);
      E : Eval_Result_1D;
   begin
      for I in Ctrl'Range loop
         Ctrl (I) := Float (I);
      end loop;
      Check (Is_Valid_Knots (Knot, P, P + 1), "Max-degree Bézier knots");
      E := Evaluate (Ctrl, Knot, P, 0.0);
      Check (E.Success and Approx (E.Value, 0.0), "Max-deg S(0)=c0");
      E := Evaluate (Ctrl, Knot, P, 1.0);
      Check (E.Success and Approx (E.Value, Float (P)), "Max-deg S(1)=cn");
      E := Evaluate (Ctrl, Knot, P, 0.5);
      Check (E.Success, "Max-deg mid success");
   end;

   ---------------------------------------------------------------------
   Section ("12. Curve record / example kinds / Make_* builders");
   ---------------------------------------------------------------------
   declare
      Ex : Curve_2D;
      R  : Eval_Result_2D;
   begin
      Ex := Make_Example_2D (Linear_Ramp);
      Check (Ex.Degree = 1 and Ex.N_Ctrl = 2, "Example Linear_Ramp meta");
      Ex := Make_Example_2D (Cubic_Bezier_Unit);
      Check (Ex.Degree = 3 and Ex.N_Ctrl = 4, "Example Cubic_Bezier meta");
      Ex := Make_Example_2D (Uniform_Quadratic);
      Check (Ex.Degree = 2 and Ex.N_Ctrl = 4, "Example Uniform_Quad meta");
      Ex := Make_Example_2D (Clamped_Cubic);
      Check (Ex.Degree = 3 and Ex.N_Ctrl = 5, "Example Clamped_Cubic meta");

      R := Evaluate_Curve (Make_Example_2D (Cubic_Bezier_Unit), 0.5);
      Check (Near (R.Point, Make_Point (0.5, 0.75)),
             "Example unit cubic mid");

      declare
         C1 : constant Curve_1D := Make_Example_1D (Uniform_Quadratic);
         E  : Eval_Result_1D;
      begin
         Check (C1.Degree = 2 and C1.N_Ctrl = 4, "1D Uniform_Quad meta");
         E := Evaluate_Curve (C1, 0.0);
         Check (Approx (E.Value, 0.0), "1D quad S(0)");
         E := Evaluate_Curve (C1, 1.0);
         Check (Approx (E.Value, 0.0), "1D quad S(1)");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("13. Raw Make_Linear / Make_Cubic controls");
   ---------------------------------------------------------------------
   declare
      L2 : constant Controls_2D :=
        Make_Linear_2D (Make_Point (0.0, 0.0), Make_Point (1.0, 0.0));
      Cu : constant Controls_2D :=
        Make_Cubic_Bezier_2D
          (Make_Point (0.0, 0.0),
           Make_Point (1.0, 0.0),
           Make_Point (0.0, 1.0),
           Make_Point (1.0, 1.0));
   begin
      Check (L2'Length = 2, "Make_Linear_2D length");
      Check (Cu'Length = 4, "Make_Cubic_Bezier_2D length");
      Check (Near (Cu (3), Make_Point (1.0, 1.0)), "Cubic P3");
   end;

   ---------------------------------------------------------------------
   Section ("14. Extra span / multi-span uniform samples");
   ---------------------------------------------------------------------
   declare
      --  6 controls, degree 2 → knots length 9: 0,0,0, 1/4,2/4,3/4, 1,1,1
      Ctrl : constant Controls_1D :=
        [0.0, 1.0, 2.0, 3.0, 4.0, 5.0];
      Knot : constant Knot_Vector := Make_Uniform_Clamped (6, 2);
      E : Eval_Result_1D;
      S : Span_Result;
      Prev : Float := 0.0;
      Mono : Boolean := True;
   begin
      Check (Knot'Length = 9, "6ctrl p=2 knots len 9");
      Check (Approx (Knot (3), 0.25), "Interior 0.25");
      Check (Approx (Knot (4), 0.5), "Interior 0.5");
      Check (Approx (Knot (5), 0.75), "Interior 0.75");

      E := Evaluate (Ctrl, Knot, 2, 0.0);
      Check (E.Success and Approx (E.Value, 0.0), "Multi S(0)=0");
      E := Evaluate (Ctrl, Knot, 2, 1.0);
      Check (E.Success and Approx (E.Value, 5.0), "Multi S(1)=5");

      --  Increasing controls → nondecreasing curve samples
      Prev := Evaluate (Ctrl, Knot, 2, 0.0).Value;
      for I in 1 .. 20 loop
         E := Evaluate (Ctrl, Knot, 2, Float (I) / 20.0);
         if E.Value + 1.0E-4 < Prev then
            Mono := False;
         end if;
         Prev := E.Value;
      end loop;
      Check (Mono, "Increasing controls → monotone samples");

      S := Find_Span (Knot, 2, 6, 0.1);
      Check (S.Success and S.Index = 2, "Span 0.1 → k=2");
      S := Find_Span (Knot, 2, 6, 0.4);
      Check (S.Success and S.Index = 3, "Span 0.4 → k=3");
      S := Find_Span (Knot, 2, 6, 0.6);
      Check (S.Success and S.Index = 4, "Span 0.6 → k=4");
      S := Find_Span (Knot, 2, 6, 0.9);
      Check (S.Success and S.Index = 5, "Span 0.9 → k=5");
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
