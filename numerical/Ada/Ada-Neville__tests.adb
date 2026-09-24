--  Standalone test suite for Neville (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;
with Ada.Text_IO;
with Neville; use Neville;

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

begin
   Ada.Text_IO.Put_Line ("Neville test suite");
   Ada.Text_IO.Put_Line ("==================");

   ---------------------------------------------------------------------
   Section ("1. Near / Is_Distinct / Degree_Of / Validate");
   ---------------------------------------------------------------------
   declare
      X_Ok  : constant Abscissae := [0.0, 1.0, 2.0];
      Y_Ok  : constant Ordinates := [0.0, 1.0, 4.0];
      X_Dup : constant Abscissae := [0.0, 1.0, 1.0];
      Y_Dup : constant Ordinates := [0.0, 1.0, 2.0];
      X_Mis : constant Abscissae := [0.0, 1.0];
      Y_Mis : constant Ordinates := [0.0, 1.0, 2.0];
      X_One : constant Abscissae := [3.0];
      Y_One : constant Ordinates := [7.0];
   begin
      Check (Near (1.0, 1.0), "Near equal floats");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny floats");
      Check (not Near (1.0, 2.0), "Near rejects floats");
      Check (Is_Distinct (X_Ok), "Is_Distinct ok");
      Check (not Is_Distinct (X_Dup), "Is_Distinct rejects dup");
      Check (Is_Distinct (X_One), "Is_Distinct singleton");
      Check (Degree_Of (X_Ok) = 2, "Degree_Of X = 2");
      Check (Degree_Of (Y_Ok) = 2, "Degree_Of Y = 2");
      Check (Degree_Of (X_One) = 0, "Degree_Of singleton = 0");
      Check (Validate (X_Ok, Y_Ok) = Ok, "Validate ok");
      Check (Validate (X_Dup, Y_Dup) = Duplicate_Abscissa,
             "Validate duplicate");
      Check (Validate (X_Mis, Y_Mis) = Dimension_Error,
             "Validate mismatch");
      Check (Validate (X_One, Y_One) = Ok, "Validate degree-0");
   end;

   ---------------------------------------------------------------------
   Section ("2. Degree-0 constant");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [5.0];
      Y : constant Ordinates := [42.0];
      R : Eval_Result;
      T : Tableau_Result;
   begin
      R := Evaluate (X, Y, 0.0);
      Check (R.Success and R.Stat = Ok, "Deg0 success");
      Check (Approx (R.Value, 42.0), "Deg0 value at 0");
      R := Evaluate (X, Y, 100.0);
      Check (Approx (R.Value, 42.0), "Deg0 value anywhere");
      T := Evaluate_Tableau (X, Y, 3.0);
      Check (T.Success and Approx (T.Value, 42.0), "Deg0 tableau");
      Check (Approx (T.Table (0, 0), 42.0), "Deg0 diagonal");
      Check (T.N = 0, "Deg0 N=0");
   end;

   ---------------------------------------------------------------------
   Section ("3. Nodes exact (interpolation property)");
   ---------------------------------------------------------------------
   declare
      S : constant Sample := Make_Quadratic_Sample (5, -2.0, 2.0);
      R : Eval_Result;
      All_Nodes : Boolean := True;
   begin
      Check (S.Valid and S.N = 4, "Quad sample N=4");
      for I in 0 .. S.N loop
         R := Evaluate (S, S.X (I));
         if not (R.Success and Approx (R.Value, S.Y (I), 1.0E-4)) then
            All_Nodes := False;
         end if;
      end loop;
      Check (All_Nodes, "Nodes exact on quadratic sample");

      declare
         L : constant Sample := Make_Linear (4, 0.0, 3.0, 1.0, 7.0);
         Ok_Nodes : Boolean := True;
      begin
         for I in 0 .. L.N loop
            R := Evaluate (L, L.X (I));
            if not Approx (R.Value, L.Y (I), 1.0E-4) then
               Ok_Nodes := False;
            end if;
         end loop;
         Check (Ok_Nodes, "Nodes exact on linear sample");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("4. Linear exact");
   ---------------------------------------------------------------------
   declare
      --  Through (0,0), (1,2): p(x)=2x
      X : constant Abscissae := [0.0, 1.0];
      Y : constant Ordinates := [0.0, 2.0];
      R : Eval_Result;
      S : constant Sample := Make_Linear (6, -1.0, 1.0, -2.0, 2.0);
      --  line y = 2x on [-1,1]
   begin
      R := Evaluate (X, Y, 0.5);
      Check (R.Success, "Linear mid success");
      Check (Approx (R.Value, 1.0), "Linear mid p(0.5)=1");
      R := Evaluate (X, Y, 0.25);
      Check (Approx (R.Value, 0.5), "Linear p(0.25)=0.5");
      R := Evaluate (X, Y, 2.0);
      Check (Approx (R.Value, 4.0), "Linear extrapolate p(2)=4");
      R := Evaluate (X, Y, -1.0);
      Check (Approx (R.Value, -2.0), "Linear extrapolate p(-1)=-2");

      R := Evaluate (S, 0.0);
      Check (Approx (R.Value, 0.0), "Make_Linear p(0)=0");
      R := Evaluate (S, 0.5);
      Check (Approx (R.Value, 1.0), "Make_Linear p(0.5)=1");
      R := Evaluate (S, -0.5);
      Check (Approx (R.Value, -1.0), "Make_Linear p(-0.5)=-1");
   end;

   ---------------------------------------------------------------------
   Section ("5. Quadratic exact");
   ---------------------------------------------------------------------
   declare
      --  Through (-1,1), (0,0), (1,1): p(x)=x²
      X : constant Abscissae := [-1.0, 0.0, 1.0];
      Y : constant Ordinates := [1.0, 0.0, 1.0];
      R : Eval_Result;
      S : constant Sample := Make_Quadratic_Sample (4, 0.0, 3.0);
   begin
      R := Evaluate (X, Y, 0.5);
      Check (R.Success and Approx (R.Value, 0.25), "Quad p(0.5)=0.25");
      R := Evaluate (X, Y, 2.0);
      Check (Approx (R.Value, 4.0), "Quad p(2)=4");
      R := Evaluate (X, Y, -0.5);
      Check (Approx (R.Value, 0.25), "Quad p(-0.5)=0.25");
      R := Evaluate (X, Y, 0.0);
      Check (Approx (R.Value, 0.0), "Quad p(0)=0");

      --  Sample of x²: evaluate at non-node
      R := Evaluate (S, 1.5);
      Check (Approx (R.Value, 2.25, 1.0E-4), "Quad sample p(1.5)=2.25");
      R := Evaluate (S, 2.5);
      Check (Approx (R.Value, 6.25, 1.0E-4), "Quad sample p(2.5)=6.25");
   end;

   ---------------------------------------------------------------------
   Section ("6. Lagrange ≡ Neville");
   ---------------------------------------------------------------------
   declare
      S : constant Sample := Make_Sine_Sample (5);
      R_N, R_L : Eval_Result;
      Agree : Boolean := True;
      Xs : constant array (1 .. 7) of Float :=
        [0.1, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0];
   begin
      for K in Xs'Range loop
         R_N := Evaluate (S, Xs (K));
         R_L := Evaluate_Lagrange (S, Xs (K));
         if not (R_N.Success and R_L.Success
           and Approx (R_N.Value, R_L.Value, 1.0E-4))
         then
            Agree := False;
         end if;
      end loop;
      Check (Agree, "Lagrange≡Neville on sine sample");

      declare
         Q : constant Sample := Make_Quadratic_Sample (6, -1.0, 1.0);
         Ok2 : Boolean := True;
      begin
         for K in 0 .. 10 loop
            declare
               T : constant Float := -1.0 + 0.2 * Float (K);
            begin
               R_N := Evaluate (Q, T);
               R_L := Evaluate_Lagrange (Q, T);
               if not Approx (R_N.Value, R_L.Value, 1.0E-4) then
                  Ok2 := False;
               end if;
            end;
         end loop;
         Check (Ok2, "Lagrange≡Neville on quadratic");
      end;

      --  Direct arrays
      declare
         Xa : constant Abscissae := [0.0, 1.0, 2.0, 3.0];
         Ya : constant Ordinates := [1.0, 0.0, 1.0, 0.0];
      begin
         R_N := Evaluate (Xa, Ya, 1.5);
         R_L := Evaluate_Lagrange (Xa, Ya, 1.5);
         Check (Approx (R_N.Value, R_L.Value, 1.0E-5),
                "Lagrange≡Neville at 1.5");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Duplicate abscissa rejected");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [0.0, 1.0, 1.0 + 1.0E-9, 2.0];
      Y : constant Ordinates := [0.0, 1.0, 2.0, 3.0];
      --  Nearly duplicate (within Distinct_Tol=1e-6)
      X2 : constant Abscissae := [0.0, 1.0, 1.0, 2.0];
      Y2 : constant Ordinates := [0.0, 1.0, 2.0, 3.0];
      R : Eval_Result;
      T : Tableau_Result;
      L : Eval_Result;
   begin
      R := Evaluate (X2, Y2, 0.5);
      Check (not R.Success and R.Stat = Duplicate_Abscissa,
             "Eval rejects exact dup");
      T := Evaluate_Tableau (X2, Y2, 0.5);
      Check (not T.Success and T.Stat = Duplicate_Abscissa,
             "Tableau rejects exact dup");
      L := Evaluate_Lagrange (X2, Y2, 0.5);
      Check (not L.Success and L.Stat = Duplicate_Abscissa,
             "Lagrange rejects exact dup");
      R := Evaluate (X, Y, 0.5);
      Check (not R.Success and R.Stat = Duplicate_Abscissa,
             "Eval rejects near-dup");
   end;

   ---------------------------------------------------------------------
   Section ("8. Dimension / empty / ill-started");
   ---------------------------------------------------------------------
   declare
      X2 : constant Abscissae := [0.0, 1.0];
      Y3 : constant Ordinates := [0.0, 1.0, 2.0];
      R  : Eval_Result;
      Bad : Sample;
   begin
      R := Evaluate (X2, Y3, 0.5);
      Check (not R.Success and R.Stat = Dimension_Error,
             "Mismatched lengths");
      Bad.Valid := False;
      R := Evaluate (Bad, 0.0);
      Check (not R.Success and R.Stat = Ill_Started,
             "Invalid sample Ill_Started");
   end;

   ---------------------------------------------------------------------
   Section ("9. Tableau diagonal and p0n");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [0.0, 1.0, 2.0];
      Y : constant Ordinates := [1.0, 3.0, 2.0];
      T : constant Tableau_Result := Evaluate_Tableau (X, Y, 0.5);
      R : constant Eval_Result := Evaluate (X, Y, 0.5);
   begin
      Check (T.Success, "Tableau success");
      Check (T.N = 2, "Tableau N=2");
      Check (Approx (T.Table (0, 0), 1.0), "Diag p00=y0");
      Check (Approx (T.Table (1, 1), 3.0), "Diag p11=y1");
      Check (Approx (T.Table (2, 2), 2.0), "Diag p22=y2");
      Check (Approx (T.Value, R.Value, 1.0E-6),
             "Tableau value = Evaluate");
      Check (Approx (T.Table (0, 2), T.Value), "p0n = Value");
      --  First column of span 1: linear between neighbors
      --  p01 at x=0.5: lerp y0,y1 → 2.0
      Check (Approx (T.Table (0, 1), 2.0), "p01 linear = 2");
   end;

   ---------------------------------------------------------------------
   Section ("10. Builders / examples / Slice");
   ---------------------------------------------------------------------
   declare
      L : constant Sample := Make_Example (Linear_Data, 5);
      Q : constant Sample := Make_Example (Quadratic_Sample, 5);
      Rg : constant Sample := Make_Example (Runge_Sample, 7);
      Sn : constant Sample := Make_Example (Sine_Sample, 6);
      Xs : Abscissae (0 .. 4);
      Ys : Ordinates (0 .. 4);
   begin
      Check (L.Valid and L.N = 4, "Example linear");
      Check (Q.Valid and Q.N = 4, "Example quadratic");
      Check (Rg.Valid and Rg.N = 6, "Example Runge");
      Check (Sn.Valid and Sn.N = 5, "Example sine");
      Check (Approx (L.X (0), 0.0) and Approx (L.X (4), 1.0),
             "Linear x ends [0,1]");
      Check (Approx (L.Y (0), 0.0) and Approx (L.Y (4), 1.0),
             "Linear y ends [0,1]");
      Check (Approx (Q.Y (0), Q.X (0) * Q.X (0), 1.0E-5),
             "Quad y=x² at first");
      Check (Approx (Rg.X (0), -1.0) and Approx (Rg.X (6), 1.0),
             "Runge x ends [-1,1]");
      Check (Approx (Rg.Y (3), 1.0, 1.0E-4),
             "Runge y(0)=1");  -- middle of 7 pts is x=0
      Check (Approx (Sn.X (0), 0.0), "Sine x0=0");
      Check (Approx (Sn.Y (0), 0.0, 1.0E-5), "Sine y0=0");
      Check (Approx (Sn.Y (Sn.N), 0.0, 1.0E-4), "Sine y(π)≈0");

      Xs := Slice_X (L);
      Ys := Slice_Y (L);
      Check (Xs'Length = 5 and Ys'Length = 5, "Slice lengths");
      Check (Approx (Xs (2), L.X (2)), "Slice_X mid");
   end;

   ---------------------------------------------------------------------
   Section ("11. Runge sample / educational note");
   ---------------------------------------------------------------------
   declare
      S : constant Sample := Make_Runge_Sample (9);
      R : Eval_Result;
      F : Float;
      --  At nodes exact; between nodes high-degree may oscillate
      Node_Ok : Boolean := True;
   begin
      for I in 0 .. S.N loop
         R := Evaluate (S, S.X (I));
         F := 1.0 / (1.0 + 25.0 * S.X (I) * S.X (I));
         if not Approx (R.Value, F, 1.0E-4) then
            Node_Ok := False;
         end if;
      end loop;
      Check (Node_Ok, "Runge nodes exact");
      R := Evaluate (S, 0.0);
      Check (Approx (R.Value, 1.0, 1.0E-4), "Runge p(0)=1");
   end;

   ---------------------------------------------------------------------
   Section ("12. Sine sample vs sin");
   ---------------------------------------------------------------------
   declare
      S : constant Sample := Make_Sine_Sample (8);
      R : Eval_Result;
      Close : Boolean := True;
      Xq : Float;
   begin
      for K in 0 .. 20 loop
         Xq := Float (K) * Ada.Numerics.Pi / 20.0;
         R := Evaluate (S, Xq);
         --  Degree-7 poly through 8 sine nodes: modest tol interior
         if not R.Success
           or else abs (R.Value - Math.Sin (Xq)) > 0.05
         then
            Close := False;
         end if;
      end loop;
      Check (Close, "Sine sample near sin (tol 0.05)");
   end;

   ---------------------------------------------------------------------
   Section ("13. Cubic known / manual tableau");
   ---------------------------------------------------------------------
   declare
      --  p(x)=x³ through 4 points
      X : constant Abscissae := [-1.0, 0.0, 1.0, 2.0];
      Y : constant Ordinates := [-1.0, 0.0, 1.0, 8.0];
      R : Eval_Result;
      T : Tableau_Result;
   begin
      R := Evaluate (X, Y, 0.5);
      Check (Approx (R.Value, 0.125, 1.0E-4), "Cubic p(0.5)=0.125");
      R := Evaluate (X, Y, 1.5);
      Check (Approx (R.Value, 3.375, 1.0E-4), "Cubic p(1.5)=3.375");
      R := Evaluate (X, Y, -0.5);
      Check (Approx (R.Value, -0.125, 1.0E-4), "Cubic p(-0.5)");
      T := Evaluate_Tableau (X, Y, 0.5);
      Check (Approx (T.Value, 0.125, 1.0E-4), "Tableau cubic");
      Check (Approx (Evaluate_Lagrange (X, Y, 0.5).Value, 0.125, 1.0E-4),
             "Lagrange cubic");
   end;

   ---------------------------------------------------------------------
   Section ("14. Max degree / many points");
   ---------------------------------------------------------------------
   declare
      S : constant Sample := Make_Linear (Max_Points, 0.0, 1.0, 0.0, 1.0);
      R : Eval_Result;
   begin
      Check (S.N = Max_Degree, "Max_Points → Max_Degree");
      R := Evaluate (S, 0.0);
      Check (R.Success and Approx (R.Value, 0.0), "Max deg p(0)");
      R := Evaluate (S, 1.0);
      Check (R.Success and Approx (R.Value, 1.0), "Max deg p(1)");
      R := Evaluate (S, 0.37);
      Check (Approx (R.Value, 0.37, 1.0E-4), "Max deg p(0.37)");
      Check (Degree_Of (Slice_X (S)) = Max_Degree, "Degree_Of max");
   end;

   ---------------------------------------------------------------------
   Section ("15. Extrapolation / off-grid queries");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [1.0, 2.0, 3.0];
      Y : constant Ordinates := [2.0, 4.0, 6.0];  -- p(x)=2x
      R : Eval_Result;
   begin
      R := Evaluate (X, Y, 0.0);
      Check (Approx (R.Value, 0.0), "Extrap p(0)=0");
      R := Evaluate (X, Y, 10.0);
      Check (Approx (R.Value, 20.0), "Extrap p(10)=20");
      R := Evaluate (X, Y, 2.5);
      Check (Approx (R.Value, 5.0), "Interior p(2.5)=5");
   end;

   ---------------------------------------------------------------------
   Section ("16. Tableau vs Evaluate agreement suite");
   ---------------------------------------------------------------------
   declare
      Kinds : constant array (1 .. 4) of Example_Kind :=
        [Linear_Data, Quadratic_Sample, Runge_Sample, Sine_Sample];
      All_Ok : Boolean := True;
   begin
      for K of Kinds loop
         declare
            S : constant Sample := Make_Example (K, 5);
            R : Eval_Result;
            T : Tableau_Result;
            Q : Float;
         begin
            for I in 0 .. 8 loop
               Q := S.X (0)
                 + (S.X (S.N) - S.X (0)) * Float (I) / 8.0;
               R := Evaluate (S, Q);
               T := Evaluate_Tableau (S, Q);
               if not (R.Success and T.Success
                 and Approx (R.Value, T.Value, 1.0E-5))
               then
                  All_Ok := False;
               end if;
            end loop;
         end;
      end loop;
      Check (All_Ok, "Tableau≡Evaluate all examples");
   end;

   ---------------------------------------------------------------------
   Section ("17. Status names / constants");
   ---------------------------------------------------------------------
   declare
      MD : Natural := Max_Degree;
      MP : Natural := Max_Points;
      NT : Float := Near_Tol;
      DT : Float := Distinct_Tol;
   begin
      Check (Status'Pos (Ok) = 0, "Status Ok pos");
      Check (Status'Pos (Duplicate_Abscissa) = 1, "Status Dup pos");
      Check (Status'Pos (Too_Few_Points) = 2, "Status Too_Few pos");
      Check (Status'Pos (Dimension_Error) = 3, "Status Dim pos");
      Check (Status'Pos (Ill_Started) = 4, "Status Ill pos");
      --  Touch variables so the compiler cannot fold the comparisons away.
      MD := MD + 0;
      MP := MP + 0;
      NT := NT + 0.0;
      DT := DT + 0.0;
      Check (MD = 16, "Max_Degree=16");
      Check (MP = 17, "Max_Points=17");
      Check (NT > 0.0, "Near_Tol positive");
      Check (DT > 0.0, "Distinct_Tol positive");
   end;

   ---------------------------------------------------------------------
   Section ("18. Two-point / three-point edge cases");
   ---------------------------------------------------------------------
   declare
      X2 : constant Abscissae := [-2.0, 4.0];
      Y2 : constant Ordinates := [3.0, 9.0];  -- slope=1, p=x+5
      X3 : constant Abscissae := [0.0, 1.0, 4.0];
      Y3 : constant Ordinates := [0.0, 1.0, 2.0];
      R  : Eval_Result;
   begin
      R := Evaluate (X2, Y2, 1.0);
      Check (Approx (R.Value, 6.0), "Two-pt p(1)=6");
      R := Evaluate (X2, Y2, -2.0);
      Check (Approx (R.Value, 3.0), "Two-pt node");
      R := Evaluate (X3, Y3, 0.0);
      Check (Approx (R.Value, 0.0), "Three-pt node0");
      R := Evaluate (X3, Y3, 1.0);
      Check (Approx (R.Value, 1.0), "Three-pt node1");
      R := Evaluate (X3, Y3, 4.0);
      Check (Approx (R.Value, 2.0), "Three-pt node2");
   end;

   ---------------------------------------------------------------------
   Section ("19. Sample Evaluate overload / Lagrange overload");
   ---------------------------------------------------------------------
   declare
      S : constant Sample := Make_Linear (3, 0.0, 2.0, 0.0, 4.0);
      R : Eval_Result;
      T : Tableau_Result;
   begin
      R := Evaluate (S, 1.0);
      Check (Approx (R.Value, 2.0), "Sample Evaluate");
      R := Evaluate_Lagrange (S, 1.0);
      Check (Approx (R.Value, 2.0), "Sample Lagrange");
      T := Evaluate_Tableau (S, 1.0);
      Check (Approx (T.Value, 2.0), "Sample Tableau");
   end;

   ---------------------------------------------------------------------
   Section ("20. Extra node sweeps for coverage");
   ---------------------------------------------------------------------
   declare
      Pass_Sweep : Natural := 0;
   begin
      for N in Point_Count range 1 .. 10 loop
         declare
            S : constant Sample :=
              Make_Quadratic_Sample (N, -1.0, 1.0);
            R : Eval_Result;
            Ok_N : Boolean := True;
         begin
            for I in 0 .. S.N loop
               R := Evaluate (S, S.X (I));
               if not Approx (R.Value, S.Y (I), 1.0E-3) then
                  Ok_N := False;
               end if;
            end loop;
            --  Off-node: x=0.3 → 0.09
            R := Evaluate (S, 0.3);
            if N >= 3 and then not Approx (R.Value, 0.09, 1.0E-3) then
               Ok_N := False;
            end if;
            if Ok_N then
               Pass_Sweep := Pass_Sweep + 1;
            end if;
         end;
      end loop;
      Check (Pass_Sweep = 10, "Quad sweep N=1..10 nodes/exact");

      --  More individual checks to pad coverage
      declare
         S : constant Sample := Make_Sine_Sample (4);
         R : Eval_Result;
      begin
         R := Evaluate (S, Ada.Numerics.Pi / 2.0);
         Check (R.Success, "Sine at π/2 success");
         Check (Approx (R.Value, 1.0, 0.05), "Sine at π/2 ≈ 1");
         Check (Is_Distinct (Slice_X (S)), "Sine abscissae distinct");
         Check (Validate (Slice_X (S), Slice_Y (S)) = Ok,
                "Sine validate Ok");
         Check (not Near (0.0, 1.0), "Near 0≠1");
         Check (Near (1.0, 1.0 + Near_Tol / 2.0), "Near within tol");
         Check (Approx (S.X (S.N), Ada.Numerics.Pi, 1.0E-5),
                "Sine last = π");
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
