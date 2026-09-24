--  Standalone test suite for Bilinear_Interpolation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Bilinear_Interpolation; use Bilinear_Interpolation;

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

   function Affine_F (X, Y, A, B, C : Float) return Float is
   begin
      return A * X + B * Y + C;
   end Affine_F;

begin
   Ada.Text_IO.Put_Line ("Bilinear_Interpolation test suite");
   Ada.Text_IO.Put_Line ("=================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Lerp / domain helpers");
   ---------------------------------------------------------------------
   declare
      G1 : constant Grid_1D := Make_Empty_1D (4);
      G2 : constant Grid_2D := Make_Empty_2D (2, 2);
      G3 : constant Grid_2D := Make_Empty_2D (3, 3);
      Bad1 : Grid_1D;
      Bad2 : Grid_2D;
   begin
      Check (Near (1.0, 1.0), "Near equal floats");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny floats");
      Check (not Near (1.0, 2.0), "Near rejects floats");
      Check (Near (1.0, 1.0 + Near_Tol / 2.0), "Near within tol");
      Check (Approx (Lerp (0.0, 10.0, 0.3), 3.0), "Lerp 0.3");
      Check (Approx (Lerp (2.0, 2.0, 0.7), 2.0), "Lerp equal");
      Check (Approx (Lerp (0.0, 1.0, 0.0), 0.0), "Lerp t=0");
      Check (Approx (Lerp (0.0, 1.0, 1.0), 1.0), "Lerp t=1");
      Check (Is_Valid_Grid (G1), "Valid 1D N=4");
      Check (Is_Valid_Grid (G2), "Valid 2D 2x2");
      Check (not Is_Valid_Grid (Bad1), "Invalid empty 1D");
      Check (not Is_Valid_Grid (Bad2), "Invalid empty 2D");
      Check (Large_Enough_Linear (G1), "Linear ok N=4");
      Check (not Large_Enough_Linear (Make_Empty_1D (1)),
             "Linear reject N=1");
      Check (Large_Enough_Bilinear (G2), "Bilinear ok 2x2");
      Check (not Large_Enough_Bilinear (Make_Empty_2D (1, 3)),
             "Bilinear reject Nx=1");
      Check (not Large_Enough_Bilinear (Make_Empty_2D (3, 1)),
             "Bilinear reject Ny=1");
      Check (In_Domain (G1, 0.0), "1D domain 0");
      Check (In_Domain (G1, 3.0), "1D domain max");
      Check (In_Domain (G1, 1.5), "1D domain mid");
      Check (not In_Domain (G1, -0.01), "1D reject x<0");
      Check (not In_Domain (G1, 3.01), "1D reject x>max");
      Check (In_Domain (G3, 0.0, 0.0), "2D domain corner 0");
      Check (In_Domain (G3, 2.0, 2.0), "2D domain corner max");
      Check (In_Domain (G3, 1.5, 0.5), "2D domain interior");
      Check (not In_Domain (G3, -0.01, 1.0), "2D reject x<0");
      Check (not In_Domain (G3, 1.0, 2.01), "2D reject y>max");
      Check (not In_Domain (Bad2, 0.0, 0.0), "2D reject invalid");
   end;

   ---------------------------------------------------------------------
   Section ("2. Builders / Get / Set / Make_Example");
   ---------------------------------------------------------------------
   declare
      C1 : Grid_1D := Make_Constant_1D (5, 3.5);
      C2 : Grid_2D := Make_Constant_2D (3, 4, 2.5);
      L1 : constant Grid_1D := Make_Linear_1D (5, 0.0, 8.0);
      L2 : constant Grid_2D := Make_Linear_2D (4, 4, 1.0, 2.0, 1.0);
      Ch : constant Grid_2D := Make_Checkerboard_2D (4, 4, 0.0, 1.0);
      Rp : constant Grid_2D := Make_Ramp_2D (5, 5);
      E  : Grid_2D;
   begin
      Check (C1.Valid and C1.N = 5, "Constant 1D dims");
      Check (Approx (Get (C1, 0), 3.5), "Constant 1D get 0");
      Check (Approx (Get (C1, 4), 3.5), "Constant 1D get last");
      Set (C1, 2, 9.0);
      Check (Approx (Get (C1, 2), 9.0), "1D Set/Get roundtrip");
      Check (C2.Valid and C2.Nx = 3 and C2.Ny = 4, "Constant 2D dims");
      Check (Approx (Get (C2, 0, 0), 2.5), "Constant 2D get 00");
      Check (Approx (Get (C2, 2, 3), 2.5), "Constant 2D get corner");
      Set (C2, 1, 2, 9.0);
      Check (Approx (Get (C2, 1, 2), 9.0), "2D Set/Get roundtrip");
      Check (Approx (Get (L1, 0), 0.0), "Linear 1D start");
      Check (Approx (Get (L1, 4), 8.0), "Linear 1D end");
      Check (Approx (Get (L1, 2), 4.0), "Linear 1D mid");
      Check (Approx (Get (L2, 1, 2), Affine_F (1.0, 2.0, 1.0, 2.0, 1.0)),
             "Linear 2D (1,2)");
      Check (Approx (Get (L2, 0, 0), 1.0), "Linear 2D origin=C");
      Check (Approx (Get (Ch, 0, 0), 1.0), "Checker (0,0)=Hi");
      Check (Approx (Get (Ch, 1, 0), 0.0), "Checker (1,0)=Lo");
      Check (Approx (Get (Ch, 1, 1), 1.0), "Checker (1,1)=Hi");
      Check (Approx (Get (Rp, 2, 3), 2.0 + 6.0), "Ramp (2,3)=8");
      E := Make_Example (Constant_Field);
      Check (E.Nx = 5 and Approx (Get (E, 2, 2), 7.0),
             "Example constant 5x5=7");
      E := Make_Example (Linear_Field);
      Check (E.Nx = 6 and Approx (Get (E, 1, 1), 4.0),
             "Example linear (1,1)=4");
      E := Make_Example (Checkerboard);
      Check (E.Nx = 4 and Approx (Get (E, 0, 1), 0.0),
             "Example checker (0,1)=Lo");
      E := Make_Example (Ramp);
      Check (E.Nx = 5 and Approx (Get (E, 3, 1), 5.0),
             "Example ramp (3,1)=5");
   end;

   ---------------------------------------------------------------------
   Section ("3. Constant field exact");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Constant_2D (5, 5, 7.0);
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
         R := Evaluate (G, Pts (P, 1), Pts (P, 2));
         Check
           (R.Success and Approx (R.Value, 7.0),
            "Const bilinear p=" & Integer'Image (P));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("4. Affine / linear field exact (bilinear reproduces affine)");
   ---------------------------------------------------------------------
   declare
      A : constant Float := 1.0;
      B : constant Float := 2.0;
      C : constant Float := 1.0;
      G : constant Grid_2D := Make_Linear_2D (6, 6, A, B, C);
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
         Expect := Affine_F (X, Y, A, B, C);
         R := Evaluate (G, X, Y);
         Check
           (R.Success and Approx (R.Value, Expect, 1.0E-4),
            "Affine bilinear p=" & Integer'Image (P));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("5. Exact at lattice nodes");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Ramp_2D (5, 5);
      R : Eval_Result;
      Expect : Float;
      Count_Ok : Natural := 0;
   begin
      for I in 0 .. 4 loop
         for J in 0 .. 4 loop
            Expect := Float (I) + 2.0 * Float (J);
            R := Evaluate (G, Float (I), Float (J));
            if R.Success and Approx (R.Value, Expect, 1.0E-5) then
               Count_Ok := Count_Ok + 1;
            end if;
         end loop;
      end loop;
      Check (Count_Ok = 25, "All 25 nodes exact on ramp");
      --  Spot checks
      R := Evaluate (G, 0.0, 0.0);
      Check (R.Success and Approx (R.Value, 0.0), "Node (0,0)");
      R := Evaluate (G, 4.0, 4.0);
      Check (R.Success and Approx (R.Value, 12.0), "Node (4,4)");
      R := Evaluate (G, 2.0, 3.0);
      Check (R.Success and Approx (R.Value, 8.0), "Node (2,3)");
   end;

   ---------------------------------------------------------------------
   Section ("6. Unit-square closed form");
   ---------------------------------------------------------------------
   declare
      --  Corners: f00=0, f10=1, f01=2, f11=3 → f=(1-t)(1-u)*0 + ...
      V : Float;
   begin
      V := Evaluate_Unit_Square (0.0, 1.0, 2.0, 3.0, 0.0, 0.0);
      Check (Approx (V, 0.0), "Unit square (0,0)=F00");
      V := Evaluate_Unit_Square (0.0, 1.0, 2.0, 3.0, 1.0, 0.0);
      Check (Approx (V, 1.0), "Unit square (1,0)=F10");
      V := Evaluate_Unit_Square (0.0, 1.0, 2.0, 3.0, 0.0, 1.0);
      Check (Approx (V, 2.0), "Unit square (0,1)=F01");
      V := Evaluate_Unit_Square (0.0, 1.0, 2.0, 3.0, 1.0, 1.0);
      Check (Approx (V, 3.0), "Unit square (1,1)=F11");
      V := Evaluate_Unit_Square (0.0, 1.0, 2.0, 3.0, 0.5, 0.5);
      Check (Approx (V, 1.5), "Unit square center=1.5");
      V := Evaluate_Unit_Square (1.0, 1.0, 1.0, 1.0, 0.3, 0.7);
      Check (Approx (V, 1.0), "Unit square constant");
   end;

   --  Explicit Compare Evaluate vs closed form on corners of a cell
   declare
      G : constant Grid_2D := Make_Linear_2D (4, 4, 3.0, -1.0, 0.5);
      R : Eval_Result;
      F00, F10, F01, F11, Closed : Float;
      X, Y, Tx, Ty : Float;
      Ix, Iy : constant Integer := 1;
   begin
      F00 := Get (G, Axis_Index (Ix),     Axis_Index (Iy));
      F10 := Get (G, Axis_Index (Ix + 1), Axis_Index (Iy));
      F01 := Get (G, Axis_Index (Ix),     Axis_Index (Iy + 1));
      F11 := Get (G, Axis_Index (Ix + 1), Axis_Index (Iy + 1));
      Tx := 0.3;
      Ty := 0.6;
      X := Float (Ix) + Tx;
      Y := Float (Iy) + Ty;
      Closed := Evaluate_Unit_Square (F00, F10, F01, F11, Tx, Ty);
      R := Evaluate (G, X, Y);
      Check (R.Success and Approx (R.Value, Closed, 1.0E-5),
             "Evaluate matches unit-square formula");
      --  Four corners of that cell
      R := Evaluate (G, Float (Ix), Float (Iy));
      Check (R.Success and Approx (R.Value, F00), "Cell corner F00");
      R := Evaluate (G, Float (Ix + 1), Float (Iy));
      Check (R.Success and Approx (R.Value, F10), "Cell corner F10");
      R := Evaluate (G, Float (Ix), Float (Iy + 1));
      Check (R.Success and Approx (R.Value, F01), "Cell corner F01");
      R := Evaluate (G, Float (Ix + 1), Float (Iy + 1));
      Check (R.Success and Approx (R.Value, F11), "Cell corner F11");
   end;

   ---------------------------------------------------------------------
   Section ("7. Linear 1-D helper");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_1D := Make_Linear_1D (5, 0.0, 8.0);
      R : Eval_Result;
   begin
      R := Evaluate_Linear_1D (G, 0.0);
      Check (R.Success and Approx (R.Value, 0.0), "1D at 0");
      R := Evaluate_Linear_1D (G, 4.0);
      Check (R.Success and Approx (R.Value, 8.0), "1D at 4");
      R := Evaluate_Linear_1D (G, 2.0);
      Check (R.Success and Approx (R.Value, 4.0), "1D at 2");
      R := Evaluate_Linear_1D (G, 1.5);
      Check (R.Success and Approx (R.Value, 3.0), "1D at 1.5");
      R := Evaluate_Linear_1D (G, 0.25);
      Check (R.Success and Approx (R.Value, 0.5), "1D at 0.25");
      R := Evaluate_Linear_1D (Make_Constant_1D (4, 5.0), 2.5);
      Check (R.Success and Approx (R.Value, 5.0), "1D constant");
      R := Evaluate_Linear_1D (Make_Empty_1D (1), 0.0);
      Check (not R.Success and R.Stat = Too_Small_Grid,
             "1D too small");
      R := Evaluate_Linear_1D (G, -0.1);
      Check (not R.Success and R.Stat = Out_Of_Domain, "1D OOD low");
      R := Evaluate_Linear_1D (G, 4.1);
      Check (not R.Success and R.Stat = Out_Of_Domain, "1D OOD high");
      declare
         Bad : Grid_1D;
      begin
         R := Evaluate_Linear_1D (Bad, 0.0);
         Check (not R.Success and R.Stat = Ill_Started, "1D ill started");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Out of domain / too small / ill started");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Constant_2D (4, 4, 1.0);
      Tiny : constant Grid_2D := Make_Empty_2D (1, 4);
      Bad : Grid_2D;
      R : Eval_Result;
      RR : Resize_2D_Result;
   begin
      R := Evaluate (G, -0.01, 1.0);
      Check (not R.Success and R.Stat = Out_Of_Domain, "OOD x<0");
      R := Evaluate (G, 1.0, 3.01);
      Check (not R.Success and R.Stat = Out_Of_Domain, "OOD y>max");
      R := Evaluate (G, 3.5, 1.0);
      Check (not R.Success and R.Stat = Out_Of_Domain, "OOD x>max");
      R := Evaluate (G, 1.0, -1.0);
      Check (not R.Success and R.Stat = Out_Of_Domain, "OOD y<0");
      R := Evaluate (Tiny, 0.0, 0.0);
      Check (not R.Success and R.Stat = Too_Small_Grid, "Too small Nx");
      R := Evaluate (Make_Empty_2D (4, 1), 0.0, 0.0);
      Check (not R.Success and R.Stat = Too_Small_Grid, "Too small Ny");
      R := Evaluate (Bad, 0.0, 0.0);
      Check (not R.Success and R.Stat = Ill_Started, "Ill started eval");
      RR := Resize_2D (Bad, 4, 4);
      Check (not RR.Success and RR.Stat = Ill_Started, "Ill started resize");
      RR := Resize_2D (Tiny, 4, 4);
      Check (not RR.Success and RR.Stat = Too_Small_Grid,
             "Resize too small src");
      RR := Resize_2D (G, 0, 4);
      Check (not RR.Success and RR.Stat = Too_Small_Grid,
             "Resize New_Nx=0");
      RR := Resize_2D (G, 4, 0);
      Check (not RR.Success and RR.Stat = Too_Small_Grid,
             "Resize New_Ny=0");
      RR := Resize_2D (G, Max_N + 1, 4);
      Check (not RR.Success and RR.Stat = Out_Of_Domain,
             "Resize New_Nx>Max");
   end;

   ---------------------------------------------------------------------
   Section ("9. Resize_2D identity and upsample");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Linear_2D (4, 4, 1.0, 2.0, 0.0);
      RR : Resize_2D_Result;
      R : Eval_Result;
      Expect : Float;
      Ok_Count : Natural := 0;
   begin
      RR := Resize_2D (G, 4, 4);
      Check (RR.Success and RR.Grid.Nx = 4 and RR.Grid.Ny = 4,
             "Resize identity dims");
      for I in Axis_Index range 0 .. 3 loop
         for J in Axis_Index range 0 .. 3 loop
            Expect := Float (I) + 2.0 * Float (J);
            if Approx (Get (RR.Grid, I, J), Expect, 1.0E-4) then
               Ok_Count := Ok_Count + 1;
            end if;
         end loop;
      end loop;
      Check (Ok_Count = 16, "Resize identity preserves affine");

      RR := Resize_2D (G, 7, 7);
      Check (RR.Success and RR.Grid.Nx = 7, "Resize upsample dims");
      --  Corners of upsampled grid should match source corners
      Check (Approx (Get (RR.Grid, 0, 0), 0.0, 1.0E-4),
             "Upsample corner (0,0)");
      Check (Approx (Get (RR.Grid, 6, 6),
                     Get (G, 3, 3), 1.0E-4),
             "Upsample corner (6,6)");
      --  Midpoint of affine field
      R := Evaluate (G, 1.5, 1.5);
      Check (R.Success and Approx (R.Value, 1.5 + 3.0, 1.0E-4),
             "Affine mid (1.5,1.5)=4.5");
      --  Upsampled node that maps to (1.5,1.5): i=3 → x=3*3/6=1.5
      Check (Approx (Get (RR.Grid, 3, 3), 4.5, 1.0E-4),
             "Upsample mid node (3,3)=4.5");

      RR := Resize_2D (G, 1, 1);
      Check (RR.Success and Approx (Get (RR.Grid, 0, 0), 0.0, 1.0E-4),
             "Resize to 1x1 samples origin");
   end;

   ---------------------------------------------------------------------
   Section ("10. Compare corners / mixed cell values");
   ---------------------------------------------------------------------
   declare
      G : Grid_2D := Make_Empty_2D (3, 3);
      R : Eval_Result;
      Closed : Float;
   begin
      --  Manual corners for cell (0,0): F00=1, F10=3, F01=5, F11=7
      Set (G, 0, 0, 1.0);
      Set (G, 1, 0, 3.0);
      Set (G, 0, 1, 5.0);
      Set (G, 1, 1, 7.0);
      --  Fill rest so grid is valid for other cells
      Set (G, 2, 0, 0.0);
      Set (G, 2, 1, 0.0);
      Set (G, 0, 2, 0.0);
      Set (G, 1, 2, 0.0);
      Set (G, 2, 2, 0.0);

      R := Evaluate (G, 0.0, 0.0);
      Check (R.Success and Approx (R.Value, 1.0), "Compare corner F00");
      R := Evaluate (G, 1.0, 0.0);
      Check (R.Success and Approx (R.Value, 3.0), "Compare corner F10");
      R := Evaluate (G, 0.0, 1.0);
      Check (R.Success and Approx (R.Value, 5.0), "Compare corner F01");
      R := Evaluate (G, 1.0, 1.0);
      Check (R.Success and Approx (R.Value, 7.0), "Compare corner F11");

      Closed := Evaluate_Unit_Square (1.0, 3.0, 5.0, 7.0, 0.25, 0.75);
      R := Evaluate (G, 0.25, 0.75);
      Check (R.Success and Approx (R.Value, Closed, 1.0E-5),
             "Mixed cell matches closed form");
      --  Explicit arithmetic: (1-0.25)(1-0.75)*1 + 0.25*(1-0.75)*3
      --    + (1-0.25)*0.75*5 + 0.25*0.75*7
      --  = 0.75*0.25*1 + 0.25*0.25*3 + 0.75*0.75*5 + 0.25*0.75*7
      --  = 0.1875 + 0.1875 + 2.8125 + 1.3125 = 4.5
      Check (Approx (Closed, 4.5), "Mixed cell arithmetic 4.5");
   end;

   ---------------------------------------------------------------------
   Section ("11. Right-endpoint / boundary cells");
   ---------------------------------------------------------------------
   declare
      G : constant Grid_2D := Make_Linear_2D (3, 3, 1.0, 1.0, 0.0);
      R : Eval_Result;
   begin
      R := Evaluate (G, 2.0, 2.0);
      Check (R.Success and Approx (R.Value, 4.0), "Right endpoint (2,2)");
      R := Evaluate (G, 2.0, 0.0);
      Check (R.Success and Approx (R.Value, 2.0), "Right edge (2,0)");
      R := Evaluate (G, 0.0, 2.0);
      Check (R.Success and Approx (R.Value, 2.0), "Top edge (0,2)");
      R := Evaluate (G, 1.999, 1.0);
      Check (R.Success and Approx (R.Value, 2.999, 1.0E-3),
             "Near right edge");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result: " & Natural'Image (Pass_Count) & " Passed, "
      & Natural'Image (Fail_Count) & " Failed");
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
