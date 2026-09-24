--  Standalone test suite for Bicubic_Interpolation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Bicubic_Interpolation; use Bicubic_Interpolation;

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

   function Affine_F (X, Y : Float) return Float is
   begin
      return X + 2.0 * Y + 1.0;
   end Affine_F;

   function Quad_F (X, Y : Float) return Float is
   begin
      return X * X + Y * Y;
   end Quad_F;

   function Cubic_F (X, Y : Float) return Float is
   begin
      return X * X * X + Y * Y * Y;
   end Cubic_F;

begin
   Ada.Text_IO.Put_Line ("Bicubic_Interpolation test suite");
   Ada.Text_IO.Put_Line ("================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Lerp / Cubic_1D / domain helpers");
   ---------------------------------------------------------------------
   declare
      G2  : constant Grid_2D := Make_Empty (2, 2);
      G3  : constant Grid_2D := Make_Empty (3, 3);
      G4  : constant Grid_2D := Make_Empty (4, 4);
      Bad : Grid_2D;
   begin
      Check (Near (1.0, 1.0), "Near equal floats");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny floats");
      Check (not Near (1.0, 2.0), "Near rejects floats");
      Check (Near (1.0, 1.0 + Near_Tol / 2.0), "Near within tol");
      Check (Approx (Lerp (0.0, 10.0, 0.3), 3.0), "Lerp 0.3");
      Check (Approx (Lerp (2.0, 2.0, 0.7), 2.0), "Lerp equal");
      Check (Approx (Lerp (0.0, 1.0, 0.0), 0.0), "Lerp t=0");
      Check (Approx (Lerp (0.0, 1.0, 1.0), 1.0), "Lerp t=1");
      --  Cubic_1D at t=0 → P1; t=1 → P2; linear samples stay linear
      Check (Approx (Cubic_1D (0.0, 1.0, 2.0, 3.0, 0.0), 1.0),
             "Cubic_1D t=0 → P1");
      Check (Approx (Cubic_1D (0.0, 1.0, 2.0, 3.0, 1.0), 2.0),
             "Cubic_1D t=1 → P2");
      Check (Approx (Cubic_1D (0.0, 1.0, 2.0, 3.0, 0.5), 1.5, 1.0E-4),
             "Cubic_1D linear mid");
      Check (Is_Valid_Grid (G4), "Valid 4x4");
      Check (not Is_Valid_Grid (Bad), "Invalid empty");
      Check (Large_Enough_Bilinear (G2), "Bilinear ok 2");
      Check (not Large_Enough_Bilinear (Make_Empty (1, 2)),
             "Bilinear reject 1");
      Check (not Large_Enough_Bicubic (G3), "Bicubic reject 3");
      Check (Large_Enough_Bicubic (G4), "Bicubic ok 4");
      Check (In_Domain (G4, 0.0, 0.0), "Domain corner 0");
      Check (In_Domain (G4, 3.0, 3.0), "Domain corner max");
      Check (In_Domain (G4, 1.5, 2.0), "Domain interior");
      Check (not In_Domain (G4, -0.01, 1.0), "Reject x<0");
      Check (not In_Domain (G4, 1.0, 3.01), "Reject y>max");
      Check (not In_Domain (Bad, 0.0, 0.0), "Reject invalid grid");
   end;

   ---------------------------------------------------------------------
   Section ("2. Builders / Get / Set / Make_Example");
   ---------------------------------------------------------------------
   declare
      C : Grid_2D := Make_Constant_Field (3, 4, 2.5);
      A : constant Grid_2D := Make_Affine_Field (4, 4, 1.0, 2.0, 1.0);
      Q : constant Grid_2D := Make_Separable_Quadratic (4, 4);
      U : constant Grid_2D := Make_Separable_Cubic (4, 4);
      K : constant Grid_2D := Make_Checkerboard (3, 3, 0.0, 1.0);
      E : Grid_2D;
   begin
      Check (C.Valid and C.Nx = 3 and C.Ny = 4, "Constant dims 3x4");
      Check (Approx (Get (C, 0, 0), 2.5), "Constant get 00");
      Check (Approx (Get (C, 2, 3), 2.5), "Constant get corner");
      Set (C, 1, 2, 9.0);
      Check (Approx (Get (C, 1, 2), 9.0), "Set/Get roundtrip");
      Check (Approx (Get (A, 1, 2), Affine_F (1.0, 2.0)),
             "Affine builder (1,2)");
      Check (Approx (Get (A, 0, 0), 1.0), "Affine builder origin");
      Check (Approx (Get (Q, 2, 1), Quad_F (2.0, 1.0)),
             "Quad builder (2,1)");
      Check (Approx (Get (U, 2, 1), Cubic_F (2.0, 1.0)),
             "Cubic builder (2,1)");
      Check (Approx (Get (K, 0, 0), 1.0), "Checker (0,0)=Hi");
      Check (Approx (Get (K, 0, 1), 0.0), "Checker (0,1)=Lo");
      Check (Approx (Get (K, 1, 0), 0.0), "Checker (1,0)=Lo");
      Check (Approx (Get (K, 1, 1), 1.0), "Checker (1,1)=Hi");
      E := Make_Example (Constant_Field);
      Check (E.Nx = 5 and Approx (Get (E, 2, 2), 7.0),
             "Example constant 5x5=7");
      E := Make_Example (Affine_Field);
      Check (E.Nx = 6 and Approx (Get (E, 1, 1), 4.0),
             "Example affine (1,1)=4");
      E := Make_Example (Checkerboard);
      Check (E.Nx = 4 and Approx (Get (E, 0, 0), 1.0),
             "Example checker");
      E := Make_Example (Separable_Cubic);
      Check (E.Nx = 5 and Approx (Get (E, 2, 1), 9.0),
             "Example cubic 8+1=9");
   end;

   ---------------------------------------------------------------------
   Section ("3. Constant field exact (both methods)");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Constant_Field (5, 5, 7.0);
      R : Eval_Result;
      Pts : constant array (1 .. 8, 1 .. 2) of Float :=
        [[0.0, 0.0],
         [4.0, 4.0],
         [1.0, 2.0],
         [0.5, 0.5],
         [2.5, 1.25],
         [3.9, 0.1],
         [1.7, 1.7],
         [0.0, 4.0]];
   begin
      for P in 1 .. 8 loop
         R := Evaluate_Bilinear (G, Pts (P, 1), Pts (P, 2));
         Check
           (R.Success and Approx (R.Value, 7.0),
            "Const bilin p=" & Integer'Image (P));
         R := Evaluate_Bicubic (G, Pts (P, 1), Pts (P, 2));
         Check
           (R.Success and Approx (R.Value, 7.0),
            "Const bicub p=" & Integer'Image (P));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("4. Affine field exact (both methods)");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Affine_Field (6, 6, 1.0, 2.0, 1.0);
      R : Eval_Result;
      X, Y, Expect : Float;
      Pts : constant array (1 .. 12, 1 .. 2) of Float :=
        [[0.0, 0.0],
         [5.0, 5.0],
         [1.0, 2.0],
         [0.5, 0.5],
         [2.5, 1.25],
         [4.9, 0.1],
         [1.7, 1.7],
         [0.0, 5.0],
         [3.0, 0.0],
         [0.25, 4.75],
         [2.0, 2.0],
         [4.5, 3.5]];
   begin
      for P in 1 .. 12 loop
         X := Pts (P, 1);
         Y := Pts (P, 2);
         Expect := Affine_F (X, Y);
         R := Evaluate_Bilinear (G, X, Y);
         Check
           (R.Success and Approx (R.Value, Expect, 1.0E-4),
            "Affine bilin p=" & Integer'Image (P));
         R := Evaluate_Bicubic (G, X, Y);
         Check
           (R.Success and Approx (R.Value, Expect, 1.0E-4),
            "Affine bicub p=" & Integer'Image (P));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("5. Exact at lattice nodes");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Separable_Quadratic (5, 5);
      R : Eval_Result;
      Expect : Float;
      Count_Ok : Natural := 0;
   begin
      for I in Axis_Index range 0 .. 4 loop
         for J in Axis_Index range 0 .. 4 loop
            Expect := Get (G, I, J);
            R := Evaluate_Bilinear (G, Float (I), Float (J));
            if R.Success and Approx (R.Value, Expect, 1.0E-4) then
               Count_Ok := Count_Ok + 1;
            end if;
            R := Evaluate_Bicubic (G, Float (I), Float (J));
            if R.Success and Approx (R.Value, Expect, 1.0E-4) then
               Count_Ok := Count_Ok + 1;
            end if;
         end loop;
      end loop;
      --  5^2 nodes × 2 methods = 50
      Check (Count_Ok = 50, "All 25 nodes exact (bilin+bicub)");
      R := Evaluate_Bicubic (G, 0.0, 0.0);
      Check (Approx (R.Value, 0.0), "Node (0,0) bicubic");
      R := Evaluate_Bicubic (G, 4.0, 4.0);
      Check (Approx (R.Value, 32.0), "Node (4,4) bicubic");
      R := Evaluate_Bilinear (G, 2.0, 3.0);
      Check (Approx (R.Value, 13.0), "Node (2,3) bilinear");
      R := Evaluate_Bicubic (G, 2.0, 3.0);
      Check (Approx (R.Value, 13.0), "Node (2,3) bicubic");
   end;

   ---------------------------------------------------------------------
   Section ("6. Out of domain / too small / ill-started");
   ---------------------------------------------------------------------
   declare
      G4  : constant Grid_2D := Make_Constant_Field (4, 4, 1.0);
      G3  : constant Grid_2D := Make_Constant_Field (3, 3, 1.0);
      G1  : constant Grid_2D := Make_Constant_Field (1, 1, 1.0);
      Bad : Grid_2D;
      R   : Eval_Result;
   begin
      R := Evaluate_Bilinear (G4, -0.1, 1.0);
      Check (not R.Success and R.Stat = Out_Of_Domain, "Bilin out x");
      R := Evaluate_Bicubic (G4, 1.0, 4.0);
      Check (not R.Success and R.Stat = Out_Of_Domain, "Bicub out y");
      R := Evaluate_Bilinear (G4, 1.0, -1.0);
      Check (R.Stat = Out_Of_Domain, "Bilin out y");
      R := Evaluate_Bicubic (G4, 5.0, 0.0);
      Check (R.Stat = Out_Of_Domain, "Bicub out x high");
      R := Evaluate_Bicubic (G3, 1.0, 1.0);
      Check (not R.Success and R.Stat = Too_Small_Grid,
             "Bicub too small 3");
      R := Evaluate_Bilinear (G1, 0.0, 0.0);
      Check (R.Stat = Too_Small_Grid, "Bilin too small 1");
      R := Evaluate_Bilinear (Bad, 0.0, 0.0);
      Check (R.Stat = Ill_Started, "Bilin ill-started");
      R := Evaluate_Bicubic (Bad, 0.0, 0.0);
      Check (R.Stat = Ill_Started, "Bicub ill-started");
      R := Evaluate_Bilinear (G4, 0.0, 0.0);
      Check (R.Success and R.Stat = Ok, "Bilin Ok status");
      R := Evaluate_Bicubic (G4, 1.5, 1.5);
      Check (R.Success and R.Stat = Ok, "Bicub Ok status");
   end;

   ---------------------------------------------------------------------
   Section ("7. Mid-cell: bicubic vs bilinear on nonlinear");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Separable_Quadratic (6, 6);
      X : constant Float := 2.5;
      Y : constant Float := 2.5;
      Truth : constant Float := Quad_F (X, Y);  -- 2*6.25 = 12.5
      RL, RC : Eval_Result;
      Err_L, Err_C : Float;
   begin
      RL := Evaluate_Bilinear (G, X, Y);
      RC := Evaluate_Bicubic (G, X, Y);
      Check (RL.Success and RC.Success, "Mid-cell both succeed");
      Check (Approx (Truth, 12.5), "Truth 12.5");
      Err_L := abs (RL.Value - Truth);
      Err_C := abs (RC.Value - Truth);
      Check (Err_C < 1.0E-3, "Bicubic near quadratic truth");
      Check (Err_L > Err_C + 0.05, "Bilinear worse than bicubic");
      Check (not Near (RL.Value, RC.Value, 0.05),
             "Methods differ mid-cell");
      declare
         Samples : constant array (1 .. 5, 1 .. 2) of Float :=
           [[1.5, 1.5],
            [3.5, 2.5],
            [2.25, 2.75],
            [1.25, 3.75],
            [2.0, 3.5]];
         Better : Natural := 0;
      begin
         for S in 1 .. 5 loop
            RL := Evaluate_Bilinear (G, Samples (S, 1), Samples (S, 2));
            RC := Evaluate_Bicubic (G, Samples (S, 1), Samples (S, 2));
            declare
               T : constant Float :=
                 Quad_F (Samples (S, 1), Samples (S, 2));
            begin
               if abs (RC.Value - T) + 1.0E-4 < abs (RL.Value - T) then
                  Better := Better + 1;
               end if;
               Check
                 (RC.Success and Approx (RC.Value, T, 1.0E-3),
                  "Quad bicubic sample" & Integer'Image (S));
            end;
         end loop;
         Check (Better >= 4, "Bicubic closer on ≥4/5 samples");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Separable cubic nodes + smooth interior");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Separable_Cubic (5, 5);
      R : Eval_Result;
      Ok_Nodes : Natural := 0;
   begin
      for I in 0 .. 4 loop
         R := Evaluate_Bicubic (G, Float (I), Float (I));
         if R.Success
           and then Approx
             (R.Value, Cubic_F (Float (I), Float (I)), 1.0E-3)
         then
            Ok_Nodes := Ok_Nodes + 1;
         end if;
      end loop;
      Check (Ok_Nodes = 5, "Cubic diagonal nodes exact");
      R := Evaluate_Bicubic (G, 1.5, 2.5);
      Check (R.Success, "Cubic mid-cell succeeds");
      Check (R.Value > 0.0, "Cubic mid-cell positive");
      R := Evaluate_Bilinear (G, 1.5, 2.5);
      Check (R.Success, "Cubic mid-cell bilinear succeeds");
   end;

   ---------------------------------------------------------------------
   Section ("9. Edge queries (affine preserved)");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Affine_Field (5, 5, 1.0, 2.0, 1.0);
      R : Eval_Result;
      Edge_Pts : constant array (1 .. 10, 1 .. 2) of Float :=
        [[0.0, 1.5],
         [4.0, 1.5],
         [1.5, 0.0],
         [1.5, 4.0],
         [0.0, 0.0],
         [4.0, 4.0],
         [0.0, 4.0],
         [4.0, 0.0],
         [2.0, 0.0],
         [0.0, 2.5]];
   begin
      for P in 1 .. 10 loop
         R := Evaluate_Bicubic
           (G, Edge_Pts (P, 1), Edge_Pts (P, 2));
         Check
           (R.Success
            and Approx
              (R.Value,
               Affine_F (Edge_Pts (P, 1), Edge_Pts (P, 2)),
               1.0E-4),
            "Edge affine bicub p=" & Integer'Image (P));
         R := Evaluate_Bilinear
           (G, Edge_Pts (P, 1), Edge_Pts (P, 2));
         Check
           (R.Success
            and Approx
              (R.Value,
               Affine_F (Edge_Pts (P, 1), Edge_Pts (P, 2)),
               1.0E-4),
            "Edge affine bilin p=" & Integer'Image (P));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. Resize_2D");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Affine_Field (5, 5, 1.0, 2.0, 1.0);
      RR : Resize_2D_Result;
      Bad : Grid_2D;
   begin
      RR := Resize_2D (G, 5, 5);
      Check (RR.Success and RR.Stat = Ok, "Resize identity ok");
      Check
        (Approx (Get (RR.Grid, 2, 3), Affine_F (2.0, 3.0), 1.0E-3),
         "Resize identity sample");
      RR := Resize_2D (G, 9, 7);
      Check (RR.Success, "Resize up ok");
      Check (RR.Grid.Nx = 9 and RR.Grid.Ny = 7, "Resize up dims");
      --  Corner of upsampled grid maps to source corner
      Check
        (Approx (Get (RR.Grid, 0, 0), Affine_F (0.0, 0.0), 1.0E-3),
         "Resize up corner 00");
      Check
        (Approx (Get (RR.Grid, 8, 6), Affine_F (4.0, 4.0), 1.0E-3),
         "Resize up corner max");
      RR := Resize_2D (G, 0, 5);
      Check (RR.Stat = Too_Small_Grid, "Resize zero Nx");
      RR := Resize_2D (G, Max_N + 1, 4);
      Check (RR.Stat = Out_Of_Domain, "Resize over Max_N");
      RR := Resize_2D (Make_Constant_Field (3, 3, 1.0), 4, 4);
      Check (RR.Stat = Too_Small_Grid, "Resize source too small");
      RR := Resize_2D (Bad, 4, 4);
      Check (RR.Stat = Ill_Started, "Resize ill-started");
   end;

   ---------------------------------------------------------------------
   Section ("11. Sweep / size variants / padding checks");
   ---------------------------------------------------------------------
   declare
      Pass_Sweep : Natural := 0;
   begin
      for N in Axis_Size range 4 .. 8 loop
         declare
            G : constant Grid_2D :=
              Make_Affine_Field (N, N, 1.0, 2.0, 1.0);
            R : Eval_Result;
            Mid : constant Float := Float (N - 1) / 2.0;
            Ok_Local : Boolean := True;
         begin
            R := Evaluate_Bicubic (G, Mid, Mid);
            if not (R.Success
                    and Approx (R.Value, Affine_F (Mid, Mid), 1.0E-4))
            then
               Ok_Local := False;
            end if;
            R := Evaluate_Bilinear (G, Mid, Mid);
            if not (R.Success
                    and Approx (R.Value, Affine_F (Mid, Mid), 1.0E-4))
            then
               Ok_Local := False;
            end if;
            R := Evaluate_Bicubic (G, 0.0, Float (N - 1));
            if not (R.Success
                    and Approx
                      (R.Value, Affine_F (0.0, Float (N - 1)), 1.0E-4))
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

      declare
         G : constant Grid_2D :=
           Make_Constant_Field (Max_N, Max_N, 3.0);
         R : Eval_Result;
      begin
         Check (G.Nx = Max_N, "Max_N grid");
         R := Evaluate_Bicubic (G, 7.5, 8.25);
         Check (R.Success and Approx (R.Value, 3.0), "Max_N bicubic");
         R := Evaluate_Bilinear (G, 63.0, 0.0);
         Check (R.Success and Approx (R.Value, 3.0),
                "Max_N bilinear corner");
      end;

      Check (not Near (0.0, 1.0), "Near 0≠1 again");
      declare
         Gq : constant Grid_2D := Make_Separable_Quadratic (6, 6);
         Xb : constant Float := 0.5;
         Yb : constant Float := 4.5;
         Tb : constant Float := Quad_F (Xb, Yb);
         Rb_L : constant Eval_Result :=
           Evaluate_Bilinear (Gq, Xb, Yb);
         Rb_C : constant Eval_Result :=
           Evaluate_Bicubic (Gq, Xb, Yb);
      begin
         Check (Rb_L.Success and Rb_C.Success, "Boundary-adj both ok");
         Check
           (abs (Rb_C.Value - Tb) < abs (Rb_L.Value - Tb),
            "Boundary-adj bicubic closer");
      end;
      declare
         G2 : constant Grid_2D :=
           Make_Affine_Field (4, 6, 1.0, 2.0, 1.0);
         R2 : Eval_Result;
      begin
         Check (G2.Nx = 4 and G2.Ny = 6, "Rect dims 4x6");
         R2 := Evaluate_Bicubic (G2, 1.5, 3.5);
         Check
           (R2.Success
            and Approx (R2.Value, Affine_F (1.5, 3.5), 1.0E-4),
            "Rect affine bicubic");
         R2 := Evaluate_Bilinear (G2, 0.0, 5.0);
         Check
           (R2.Success
            and Approx (R2.Value, Affine_F (0.0, 5.0), 1.0E-4),
            "Rect affine bilinear corner");
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
