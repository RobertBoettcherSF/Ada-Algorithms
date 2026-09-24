--  Standalone test suite for Tricubic_Interpolation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Tricubic_Interpolation; use Tricubic_Interpolation;

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

   function Linear_F (X, Y, Z : Float) return Float is
   begin
      return X + 2.0 * Y + 3.0 * Z;
   end Linear_F;

   function Quad_F (X, Y, Z : Float) return Float is
   begin
      return X * X + Y * Y + Z * Z;
   end Quad_F;

   function Cubic_F (X, Y, Z : Float) return Float is
   begin
      return X * X * X + Y * Y * Y + Z * Z * Z;
   end Cubic_F;

begin
   Ada.Text_IO.Put_Line ("Tricubic_Interpolation test suite");
   Ada.Text_IO.Put_Line ("=================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Lerp / domain helpers");
   ---------------------------------------------------------------------
   declare
      G2 : constant Grid_3D := Make_Empty (2, 2, 2);
      G3 : constant Grid_3D := Make_Empty (3, 3, 3);
      G4 : constant Grid_3D := Make_Empty (4, 4, 4);
      Bad : Grid_3D;
   begin
      Check (Near (1.0, 1.0), "Near equal floats");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny floats");
      Check (not Near (1.0, 2.0), "Near rejects floats");
      Check (Near (1.0, 1.0 + Near_Tol / 2.0), "Near within tol");
      Check (Approx (Lerp (0.0, 10.0, 0.3), 3.0), "Lerp 0.3");
      Check (Approx (Lerp (2.0, 2.0, 0.7), 2.0), "Lerp equal");
      Check (Approx (Lerp (0.0, 1.0, 0.0), 0.0), "Lerp t=0");
      Check (Approx (Lerp (0.0, 1.0, 1.0), 1.0), "Lerp t=1");
      Check (Is_Valid_Grid (G4), "Valid 4x4x4");
      Check (not Is_Valid_Grid (Bad), "Invalid empty");
      Check (Large_Enough_Trilinear (G2), "Trilinear ok 2");
      Check (not Large_Enough_Trilinear (Make_Empty (1, 2, 2)),
             "Trilinear reject 1");
      Check (not Large_Enough_Tricubic (G3), "Tricubic reject 3");
      Check (Large_Enough_Tricubic (G4), "Tricubic ok 4");
      Check (In_Domain (G4, 0.0, 0.0, 0.0), "Domain corner 0");
      Check (In_Domain (G4, 3.0, 3.0, 3.0), "Domain corner max");
      Check (In_Domain (G4, 1.5, 2.0, 0.5), "Domain interior");
      Check (not In_Domain (G4, -0.01, 1.0, 1.0), "Reject x<0");
      Check (not In_Domain (G4, 1.0, 3.01, 1.0), "Reject y>max");
      Check (not In_Domain (G4, 1.0, 1.0, 4.0), "Reject z>max");
      Check (not In_Domain (Bad, 0.0, 0.0, 0.0), "Reject invalid grid");
   end;

   ---------------------------------------------------------------------
   Section ("2. Builders / Get / Set / Make_Example");
   ---------------------------------------------------------------------
   declare
      C : Grid_3D := Make_Constant_Field (3, 4, 5, 2.5);
      L : constant Grid_3D := Make_Linear_Field (4, 4, 4);
      Q : constant Grid_3D := Make_Separable_Quadratic (4, 4, 4);
      U : constant Grid_3D := Make_Separable_Cubic (4, 4, 4);
      E : Grid_3D;
   begin
      Check (C.Valid and C.Nx = 3 and C.Ny = 4 and C.Nz = 5,
             "Constant dims 3x4x5");
      Check (Approx (Get (C, 0, 0, 0), 2.5), "Constant get 000");
      Check (Approx (Get (C, 2, 3, 4), 2.5), "Constant get corner");
      Set (C, 1, 2, 3, 9.0);
      Check (Approx (Get (C, 1, 2, 3), 9.0), "Set/Get roundtrip");
      Check (Approx (Get (L, 1, 2, 3), Linear_F (1.0, 2.0, 3.0)),
             "Linear builder (1,2,3)");
      Check (Approx (Get (L, 0, 0, 0), 0.0), "Linear builder origin");
      Check (Approx (Get (Q, 2, 1, 3), Quad_F (2.0, 1.0, 3.0)),
             "Quad builder (2,1,3)");
      Check (Approx (Get (U, 2, 1, 0), Cubic_F (2.0, 1.0, 0.0)),
             "Cubic builder (2,1,0)");
      E := Make_Example (Constant_Field);
      Check (E.Nx = 5 and Approx (Get (E, 2, 2, 2), 7.0),
             "Example constant 5^3=7");
      E := Make_Example (Linear_Field);
      Check (E.Nx = 6 and Approx (Get (E, 1, 1, 1), 6.0),
             "Example linear (1,1,1)=6");
      E := Make_Example (Separable_Quadratic);
      Check (E.Nx = 5 and Approx (Get (E, 2, 2, 2), 12.0),
             "Example quad (2,2,2)=12");
      E := Make_Example (Separable_Cubic);
      Check (E.Nx = 5 and Approx (Get (E, 2, 1, 1), 10.0),
             "Example cubic 8+1+1=10");
   end;

   ---------------------------------------------------------------------
   Section ("3. Constant field exact (both methods)");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_3D := Make_Constant_Field (5, 5, 5, 7.0);
      R : Eval_Result;
      Pts : constant array (1 .. 8, 1 .. 3) of Float :=
        [[0.0, 0.0, 0.0],
         [4.0, 4.0, 4.0],
         [1.0, 2.0, 3.0],
         [0.5, 0.5, 0.5],
         [2.5, 1.25, 3.75],
         [3.9, 0.1, 2.0],
         [1.7, 1.7, 1.7],
         [0.0, 4.0, 2.0]];
   begin
      for P in 1 .. 8 loop
         R := Evaluate_Trilinear (G, Pts (P, 1), Pts (P, 2), Pts (P, 3));
         Check
           (R.Success and Approx (R.Value, 7.0),
            "Const trilin p=" & Integer'Image (P));
         R := Evaluate_Tricubic (G, Pts (P, 1), Pts (P, 2), Pts (P, 3));
         Check
           (R.Success and Approx (R.Value, 7.0),
            "Const tricub p=" & Integer'Image (P));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("4. Linear field exact (both methods)");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_3D := Make_Linear_Field (6, 6, 6);
      R : Eval_Result;
      X, Y, Z, Expect : Float;
      Pts : constant array (1 .. 12, 1 .. 3) of Float :=
        [[0.0, 0.0, 0.0],
         [5.0, 5.0, 5.0],
         [1.0, 2.0, 3.0],
         [0.5, 0.5, 0.5],
         [2.5, 1.25, 3.75],
         [4.9, 0.1, 2.0],
         [1.7, 1.7, 1.7],
         [0.0, 5.0, 2.5],
         [3.0, 0.0, 0.0],
         [0.25, 4.75, 1.0],
         [2.0, 2.0, 2.0],
         [4.5, 3.5, 0.5]];
   begin
      for P in 1 .. 12 loop
         X := Pts (P, 1);
         Y := Pts (P, 2);
         Z := Pts (P, 3);
         Expect := Linear_F (X, Y, Z);
         R := Evaluate_Trilinear (G, X, Y, Z);
         Check
           (R.Success and Approx (R.Value, Expect, 1.0E-4),
            "Linear trilin p=" & Integer'Image (P));
         R := Evaluate_Tricubic (G, X, Y, Z);
         Check
           (R.Success and Approx (R.Value, Expect, 1.0E-4),
            "Linear tricub p=" & Integer'Image (P));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("5. Exact at lattice nodes");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_3D := Make_Separable_Quadratic (5, 5, 5);
      R : Eval_Result;
      Expect : Float;
      Count_Ok : Natural := 0;
   begin
      for I in Axis_Index range 0 .. 4 loop
         for J in Axis_Index range 0 .. 4 loop
            for K in Axis_Index range 0 .. 4 loop
               Expect := Get (G, I, J, K);
               R := Evaluate_Trilinear
                 (G, Float (I), Float (J), Float (K));
               if R.Success and Approx (R.Value, Expect, 1.0E-4) then
                  Count_Ok := Count_Ok + 1;
               end if;
               R := Evaluate_Tricubic
                 (G, Float (I), Float (J), Float (K));
               if R.Success and Approx (R.Value, Expect, 1.0E-4) then
                  Count_Ok := Count_Ok + 1;
               end if;
            end loop;
         end loop;
      end loop;
      --  5^3 nodes × 2 methods = 250; report in chunks via summary checks
      Check (Count_Ok = 250, "All 125 nodes exact (tri+cubic)");
      --  Spot checks with messages
      R := Evaluate_Tricubic (G, 0.0, 0.0, 0.0);
      Check (Approx (R.Value, 0.0), "Node (0,0,0) tricubic");
      R := Evaluate_Tricubic (G, 4.0, 4.0, 4.0);
      Check (Approx (R.Value, 48.0), "Node (4,4,4) tricubic");
      R := Evaluate_Trilinear (G, 2.0, 3.0, 1.0);
      Check (Approx (R.Value, 14.0), "Node (2,3,1) trilinear");
      R := Evaluate_Tricubic (G, 2.0, 3.0, 1.0);
      Check (Approx (R.Value, 14.0), "Node (2,3,1) tricubic");
   end;

   ---------------------------------------------------------------------
   Section ("6. Out of domain / too small / ill-started");
   ---------------------------------------------------------------------
   declare
      G4 : constant Grid_3D := Make_Constant_Field (4, 4, 4, 1.0);
      G3 : constant Grid_3D := Make_Constant_Field (3, 3, 3, 1.0);
      G1 : constant Grid_3D := Make_Constant_Field (1, 1, 1, 1.0);
      Bad : Grid_3D;
      R : Eval_Result;
   begin
      R := Evaluate_Trilinear (G4, -0.1, 1.0, 1.0);
      Check (not R.Success and R.Stat = Out_Of_Domain,
             "Trilin out x");
      R := Evaluate_Tricubic (G4, 1.0, 1.0, 4.0);
      Check (not R.Success and R.Stat = Out_Of_Domain,
             "Tricub out z");
      R := Evaluate_Trilinear (G4, 1.0, -1.0, 1.0);
      Check (R.Stat = Out_Of_Domain, "Trilin out y");
      R := Evaluate_Tricubic (G4, 5.0, 0.0, 0.0);
      Check (R.Stat = Out_Of_Domain, "Tricub out x high");
      R := Evaluate_Tricubic (G3, 1.0, 1.0, 1.0);
      Check (not R.Success and R.Stat = Too_Small_Grid,
             "Tricub too small 3");
      R := Evaluate_Trilinear (G1, 0.0, 0.0, 0.0);
      Check (R.Stat = Too_Small_Grid, "Trilin too small 1");
      R := Evaluate_Trilinear (Bad, 0.0, 0.0, 0.0);
      Check (R.Stat = Ill_Started, "Trilin ill-started");
      R := Evaluate_Tricubic (Bad, 0.0, 0.0, 0.0);
      Check (R.Stat = Ill_Started, "Tricub ill-started");
      R := Evaluate_Trilinear (G4, 0.0, 0.0, 0.0);
      Check (R.Success and R.Stat = Ok, "Trilin Ok status");
      R := Evaluate_Tricubic (G4, 1.5, 1.5, 1.5);
      Check (R.Success and R.Stat = Ok, "Tricub Ok status");
   end;

   ---------------------------------------------------------------------
   Section ("7. Mid-cell: tricubic vs trilinear on nonlinear");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_3D := Make_Separable_Quadratic (6, 6, 6);
      X : constant Float := 2.5;
      Y : constant Float := 2.5;
      Z : constant Float := 2.5;
      Truth : constant Float := Quad_F (X, Y, Z);  -- 3*6.25 = 18.75
      RL, RC : Eval_Result;
      Err_L, Err_C : Float;
   begin
      RL := Evaluate_Trilinear (G, X, Y, Z);
      RC := Evaluate_Tricubic (G, X, Y, Z);
      Check (RL.Success and RC.Success, "Mid-cell both succeed");
      Check (Approx (Truth, 18.75), "Truth 18.75");
      --  Trilinear on convex combination of corners of [2,3]^3:
      --  corner values = i²+j²+k² for i,j,k in {2,3}; average of 8 corners
      --  is not equal to (2.5)^2*3. Tricubic (degree≤2 exact via CR FD)
      --  should match Truth closely.
      Err_L := abs (RL.Value - Truth);
      Err_C := abs (RC.Value - Truth);
      Check (Err_C < 1.0E-3, "Tricubic near quadratic truth");
      Check (Err_L > Err_C + 0.05, "Trilinear worse than tricubic");
      Check (not Near (RL.Value, RC.Value, 0.05),
             "Methods differ mid-cell");
      --  Extra mid-cell samples
      declare
         --  Stay in the open interior so the 4-point stencil needs no
         --  reflection; Catmull–Rom then reproduces degree ≤ 2 exactly.
         Samples : constant array (1 .. 5, 1 .. 3) of Float :=
           [[1.5, 1.5, 1.5],
            [3.5, 2.5, 1.5],
            [2.25, 2.75, 3.25],
            [1.25, 3.75, 2.25],
            [2.0, 3.5, 2.5]];
         Better : Natural := 0;
      begin
         for S in 1 .. 5 loop
            RL := Evaluate_Trilinear
              (G, Samples (S, 1), Samples (S, 2), Samples (S, 3));
            RC := Evaluate_Tricubic
              (G, Samples (S, 1), Samples (S, 2), Samples (S, 3));
            Truth_Local : declare
               T : constant Float :=
                 Quad_F (Samples (S, 1), Samples (S, 2), Samples (S, 3));
            begin
               if abs (RC.Value - T) + 1.0E-4 < abs (RL.Value - T) then
                  Better := Better + 1;
               end if;
               Check
                 (RC.Success and Approx (RC.Value, T, 1.0E-3),
                  "Quad tricubic sample" & Integer'Image (S));
            end Truth_Local;
         end loop;
         Check (Better >= 4, "Tricubic closer on ≥4/5 samples");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Separable cubic nodes + smooth interior");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_3D := Make_Separable_Cubic (5, 5, 5);
      R : Eval_Result;
      Ok_Nodes : Natural := 0;
   begin
      for I in 0 .. 4 loop
         R := Evaluate_Tricubic (G, Float (I), Float (I), Float (I));
         if R.Success
           and then Approx (R.Value, Cubic_F (Float (I), Float (I), Float (I)),
                            1.0E-3)
         then
            Ok_Nodes := Ok_Nodes + 1;
         end if;
      end loop;
      Check (Ok_Nodes = 5, "Cubic diagonal nodes exact");
      R := Evaluate_Tricubic (G, 1.5, 2.5, 0.5);
      Check (R.Success, "Cubic mid-cell succeeds");
      --  Not necessarily exact for degree 3, but finite and finite-diff smooth
      Check (R.Value > 0.0, "Cubic mid-cell positive");
      R := Evaluate_Trilinear (G, 1.5, 2.5, 0.5);
      Check (R.Success, "Cubic mid-cell trilinear succeeds");
   end;

   ---------------------------------------------------------------------
   Section ("9. Edge / face queries (linear preserved)");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_3D := Make_Linear_Field (5, 5, 5);
      R : Eval_Result;
      Face_Pts : constant array (1 .. 10, 1 .. 3) of Float :=
        [[0.0, 1.5, 2.5],
         [4.0, 1.5, 2.5],
         [1.5, 0.0, 2.5],
         [1.5, 4.0, 2.5],
         [1.5, 2.5, 0.0],
         [1.5, 2.5, 4.0],
         [0.0, 0.0, 2.0],
         [4.0, 4.0, 0.0],
         [0.0, 4.0, 4.0],
         [2.0, 0.0, 0.0]];
   begin
      for P in 1 .. 10 loop
         R := Evaluate_Tricubic
           (G, Face_Pts (P, 1), Face_Pts (P, 2), Face_Pts (P, 3));
         Check
           (R.Success
            and Approx
              (R.Value,
               Linear_F (Face_Pts (P, 1), Face_Pts (P, 2), Face_Pts (P, 3)),
               1.0E-4),
            "Face linear tricub p=" & Integer'Image (P));
         R := Evaluate_Trilinear
           (G, Face_Pts (P, 1), Face_Pts (P, 2), Face_Pts (P, 3));
         Check
           (R.Success
            and Approx
              (R.Value,
               Linear_F (Face_Pts (P, 1), Face_Pts (P, 2), Face_Pts (P, 3)),
               1.0E-4),
            "Face linear trilin p=" & Integer'Image (P));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. Sweep / size variants / padding checks");
   ---------------------------------------------------------------------
   declare
      Pass_Sweep : Natural := 0;
   begin
      for N in Axis_Size range 4 .. 8 loop
         declare
            G : constant Grid_3D := Make_Linear_Field (N, N, N);
            R : Eval_Result;
            Mid : constant Float := Float (N - 1) / 2.0;
            Ok_Local : Boolean := True;
         begin
            R := Evaluate_Tricubic (G, Mid, Mid, Mid);
            if not (R.Success
                    and Approx (R.Value, Linear_F (Mid, Mid, Mid), 1.0E-4))
            then
               Ok_Local := False;
            end if;
            R := Evaluate_Trilinear (G, Mid, Mid, Mid);
            if not (R.Success
                    and Approx (R.Value, Linear_F (Mid, Mid, Mid), 1.0E-4))
            then
               Ok_Local := False;
            end if;
            R := Evaluate_Tricubic (G, 0.0, Mid, Float (N - 1));
            if not (R.Success
                    and Approx
                      (R.Value,
                       Linear_F (0.0, Mid, Float (N - 1)), 1.0E-4))
            then
               Ok_Local := False;
            end if;
            if Ok_Local then
               Pass_Sweep := Pass_Sweep + 1;
            end if;
            Check (Ok_Local, "Sweep N=" & Axis_Size'Image (N));
         end;
      end loop;
      Check (Pass_Sweep = 5, "Sweep all N=4..8");

      --  Max size
      declare
         G : constant Grid_3D := Make_Constant_Field (Max_N, Max_N, Max_N, 3.0);
         R : Eval_Result;
      begin
         Check (G.Nx = Max_N, "Max_N grid");
         R := Evaluate_Tricubic (G, 7.5, 8.25, 3.0);
         Check (R.Success and Approx (R.Value, 3.0), "Max_N tricubic");
         R := Evaluate_Trilinear (G, 15.0, 0.0, 7.0);
         Check (R.Success and Approx (R.Value, 3.0), "Max_N trilinear corner");
      end;

      Check (not Near (0.0, 1.0), "Near 0≠1 again");
      --  Boundary-adjacent quadratic: not exact under odd reflection, but
      --  tricubic should still beat trilinear in absolute error.
      declare
         Gq : constant Grid_3D := Make_Separable_Quadratic (6, 6, 6);
         Xb : constant Float := 0.5;
         Yb : constant Float := 2.5;
         Zb : constant Float := 4.5;
         Tb : constant Float := Quad_F (Xb, Yb, Zb);
         Rb_L : constant Eval_Result := Evaluate_Trilinear (Gq, Xb, Yb, Zb);
         Rb_C : constant Eval_Result := Evaluate_Tricubic (Gq, Xb, Yb, Zb);
      begin
         Check (Rb_L.Success and Rb_C.Success, "Boundary-adj both ok");
         Check
           (abs (Rb_C.Value - Tb) < abs (Rb_L.Value - Tb),
            "Boundary-adj tricubic closer");
      end;
      declare
         G2 : constant Grid_3D := Make_Linear_Field (4, 5, 6);
         R2 : Eval_Result;
      begin
         Check (G2.Nx = 4 and G2.Ny = 5 and G2.Nz = 6, "Rect dims 4x5x6");
         R2 := Evaluate_Tricubic (G2, 1.5, 2.5, 3.5);
         Check
           (R2.Success
            and Approx (R2.Value, Linear_F (1.5, 2.5, 3.5), 1.0E-4),
            "Rect linear tricubic");
         R2 := Evaluate_Trilinear (G2, 0.0, 4.0, 5.0);
         Check
           (R2.Success
            and Approx (R2.Value, Linear_F (0.0, 4.0, 5.0), 1.0E-4),
            "Rect linear trilinear corner");
      end;
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
