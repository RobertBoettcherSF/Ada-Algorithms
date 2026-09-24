--  Standalone test suite for Polynomial_Interpolation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Text_IO;
with Polynomial_Interpolation; use Polynomial_Interpolation;

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
   Ada.Text_IO.Put_Line ("Polynomial_Interpolation test suite");
   Ada.Text_IO.Put_Line ("===================================");

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
   Section ("2. Degree-0 constant (all forms)");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [5.0];
      Y : constant Ordinates := [42.0];
      R : Eval_Result;
      T : Tableau_Result;
      D : DD_Result;
   begin
      R := Evaluate_Lagrange (X, Y, 0.0);
      Check (R.Success and Approx (R.Value, 42.0), "Deg0 Lagrange");
      R := Evaluate_Newton (X, Y, 100.0);
      Check (R.Success and Approx (R.Value, 42.0), "Deg0 Newton");
      R := Evaluate_Neville (X, Y, -3.0);
      Check (R.Success and Approx (R.Value, 42.0), "Deg0 Neville");
      T := Evaluate_Neville_Tableau (X, Y, 3.0);
      Check (T.Success and Approx (T.Value, 42.0), "Deg0 Neville tableau");
      Check (Approx (T.Table (0, 0), 42.0), "Deg0 diagonal");
      Check (T.N = 0, "Deg0 N=0");
      D := Build_Divided_Differences (X, Y);
      Check (D.Success and Approx (D.Coeffs (0), 42.0), "Deg0 DD coeff");
      R := Evaluate_Monomial (X, Y, 9.0);
      Check (R.Success and Approx (R.Value, 42.0), "Deg0 monomial");
   end;

   ---------------------------------------------------------------------
   Section ("3. Degree-1 linear exact");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [0.0, 1.0];
      Y : constant Ordinates := [0.0, 2.0];
      R : Eval_Result;
   begin
      R := Evaluate_Lagrange (X, Y, 0.5);
      Check (R.Success and Approx (R.Value, 1.0), "Lin L p(0.5)=1");
      R := Evaluate_Newton (X, Y, 0.25);
      Check (Approx (R.Value, 0.5), "Lin N p(0.25)=0.5");
      R := Evaluate_Neville (X, Y, 2.0);
      Check (Approx (R.Value, 4.0), "Lin Nv p(2)=4");
      R := Evaluate_Monomial (X, Y, -1.0);
      Check (Approx (R.Value, -2.0), "Lin M p(-1)=-2");
      Check (Forms_Agree (X, Y, 0.3), "Lin forms agree");
   end;

   ---------------------------------------------------------------------
   Section ("4. Degree-2 quadratic exact");
   ---------------------------------------------------------------------
   declare
      --  Through (0,0),(1,1),(2,4): p(x)=x²
      X : constant Abscissae := [0.0, 1.0, 2.0];
      Y : constant Ordinates := [0.0, 1.0, 4.0];
      R : Eval_Result;
      D : DD_Result;
      M : Monomial_Result;
   begin
      R := Evaluate_Lagrange (X, Y, 1.5);
      Check (Approx (R.Value, 2.25), "Quad L p(1.5)=2.25");
      R := Evaluate_Newton (X, Y, 0.5);
      Check (Approx (R.Value, 0.25), "Quad N p(0.5)=0.25");
      R := Evaluate_Neville (X, Y, 3.0);
      Check (Approx (R.Value, 9.0), "Quad Nv p(3)=9");
      D := Build_Divided_Differences (X, Y);
      Check (D.Success, "Quad DD success");
      Check (Approx (D.Coeffs (0), 0.0), "Quad a0=0");
      Check (Approx (D.Coeffs (1), 1.0), "Quad a1=1");
      Check (Approx (D.Coeffs (2), 1.0), "Quad a2=1");
      M := Fit_Monomial (X, Y);
      Check (M.Success, "Quad monomial fit");
      Check (Approx (M.Coeffs (0), 0.0, 1.0E-4), "Quad c0≈0");
      Check (Approx (M.Coeffs (1), 0.0, 1.0E-4), "Quad c1≈0");
      Check (Approx (M.Coeffs (2), 1.0, 1.0E-4), "Quad c2≈1");
      Check (Forms_Agree (X, Y, 1.7), "Quad forms agree");
   end;

   ---------------------------------------------------------------------
   Section ("5. Nodes exact (interpolation property)");
   ---------------------------------------------------------------------
   declare
      S : constant Sample := Make_Quadratic_Sample (5, -2.0, 2.0);
      R : Eval_Result;
      All_L, All_N, All_Nv : Boolean := True;
   begin
      Check (S.Valid and S.N = 4, "Quad sample N=4");
      for I in 0 .. S.N loop
         R := Evaluate_Lagrange (S, S.X (I));
         if not (R.Success and Approx (R.Value, S.Y (I), 1.0E-4)) then
            All_L := False;
         end if;
         R := Evaluate_Newton (S, S.X (I));
         if not Approx (R.Value, S.Y (I), 1.0E-4) then
            All_N := False;
         end if;
         R := Evaluate_Neville (S, S.X (I));
         if not Approx (R.Value, S.Y (I), 1.0E-4) then
            All_Nv := False;
         end if;
      end loop;
      Check (All_L, "Nodes exact Lagrange");
      Check (All_N, "Nodes exact Newton");
      Check (All_Nv, "Nodes exact Neville");

      declare
         L : constant Sample := Make_Linear (4, 0.0, 3.0, 1.0, 7.0);
         Ok_Nodes : Boolean := True;
      begin
         for I in 0 .. L.N loop
            R := Evaluate_Newton (L, L.X (I));
            if not Approx (R.Value, L.Y (I), 1.0E-4) then
               Ok_Nodes := False;
            end if;
         end loop;
         Check (Ok_Nodes, "Nodes exact on linear sample");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Duplicate abscissa rejected");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [0.0, 1.0, 1.0 + 1.0E-9];
      Y : constant Ordinates := [0.0, 1.0, 2.0];
      R : Eval_Result;
      D : DD_Result;
   begin
      --  Within Distinct_Tol → duplicate
      R := Evaluate_Lagrange (X, Y, 0.5);
      Check (R.Stat = Duplicate_Abscissa, "Dup Lagrange rejected");
      R := Evaluate_Newton (X, Y, 0.5);
      Check (R.Stat = Duplicate_Abscissa, "Dup Newton rejected");
      R := Evaluate_Neville (X, Y, 0.5);
      Check (R.Stat = Duplicate_Abscissa, "Dup Neville rejected");
      D := Build_Divided_Differences (X, Y);
      Check (D.Stat = Duplicate_Abscissa, "Dup DD rejected");
      R := Evaluate_Monomial (X, Y, 0.5);
      Check (R.Stat = Duplicate_Abscissa, "Dup monomial rejected");
   end;

   ---------------------------------------------------------------------
   Section ("7. Dimension / empty / Ill_Started");
   ---------------------------------------------------------------------
   declare
      X2 : constant Abscissae := [0.0, 1.0];
      Y3 : constant Ordinates := [0.0, 1.0, 2.0];
      Bad : Sample;
      R   : Eval_Result;
      D   : DD_Result;
      T   : Tableau_Result;
      M   : Monomial_Result;
   begin
      R := Evaluate_Lagrange (X2, Y3, 0.0);
      Check (R.Stat = Dimension_Error, "Mismatch Lagrange");
      R := Evaluate_Newton (X2, Y3, 0.0);
      Check (R.Stat = Dimension_Error, "Mismatch Newton");
      R := Evaluate_Neville (X2, Y3, 0.0);
      Check (R.Stat = Dimension_Error, "Mismatch Neville");
      Bad.Valid := False;
      R := Evaluate_Lagrange (Bad, 0.0);
      Check (R.Stat = Ill_Started, "Ill Sample Lagrange");
      R := Evaluate_Newton (Bad, 0.0);
      Check (R.Stat = Ill_Started, "Ill Sample Newton");
      R := Evaluate_Neville (Bad, 0.0);
      Check (R.Stat = Ill_Started, "Ill Sample Neville");
      D := Build_Divided_Differences (Bad);
      Check (D.Stat = Ill_Started, "Ill Sample DD");
      T := Evaluate_Neville_Tableau (Bad, 0.0);
      Check (T.Stat = Ill_Started, "Ill Sample Tableau");
      M := Fit_Monomial (Bad);
      Check (M.Stat = Ill_Started, "Ill Sample monomial");
      Check (not Forms_Agree (Bad, 0.0), "Ill Forms_Agree false");
   end;

   ---------------------------------------------------------------------
   Section ("8. Cross-check Lagrange ≡ Newton ≡ Neville");
   ---------------------------------------------------------------------
   declare
      S : constant Sample := Make_Sine_Sample (6);
      Xs : constant array (1 .. 5) of Float :=
        [0.2, 0.7, 1.2, 2.0, 2.8];
      All_Ok : Boolean := True;
      R_L, R_N, R_Nv : Eval_Result;
   begin
      for K in Xs'Range loop
         if not Forms_Agree (S, Xs (K), 1.0E-4) then
            All_Ok := False;
         end if;
         R_L  := Evaluate_Lagrange (S, Xs (K));
         R_N  := Evaluate_Newton (S, Xs (K));
         R_Nv := Evaluate_Neville (S, Xs (K));
         if not (Near (R_L.Value, R_N.Value, 1.0E-4)
           and then Near (R_L.Value, R_Nv.Value, 1.0E-4))
         then
            All_Ok := False;
         end if;
      end loop;
      Check (All_Ok, "Sine sample forms agree @ 5 queries");

      declare
         Q : constant Sample := Make_Quadratic_Sample (7, -1.0, 1.0);
         Ok2 : Boolean := True;
      begin
         for I in 0 .. Q.N loop
            if not Forms_Agree (Q, Q.X (I), 1.0E-4) then
               Ok2 := False;
            end if;
         end loop;
         Check (Ok2, "Quad forms agree at nodes");
         Check (Forms_Agree (Q, 0.37, 1.0E-4), "Quad forms @ 0.37");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Neville tableau matches Evaluate_Neville");
   ---------------------------------------------------------------------
   declare
      S : constant Sample := Make_Linear (5, -1.0, 1.0, -2.0, 2.0);
      R : Eval_Result;
      T : Tableau_Result;
   begin
      R := Evaluate_Neville (S, 0.25);
      T := Evaluate_Neville_Tableau (S, 0.25);
      Check (R.Success and T.Success, "Neville eval+tableau success");
      Check (Approx (R.Value, T.Value), "Neville value ≡ tableau");
      Check (Approx (R.Value, 0.5), "Make_Linear p(0.25)=0.5");
      Check (T.N = S.N, "Tableau N matches sample");
   end;

   ---------------------------------------------------------------------
   Section ("10. Newton DD then nested eval");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [1.0, 2.0, 4.0];
      Y : constant Ordinates := [1.0, 4.0, 16.0];  -- y=x²
      D : constant DD_Result := Build_Divided_Differences (X, Y);
      R : Eval_Result;
   begin
      Check (D.Success, "DD build success");
      R := Evaluate_Newton (X, D.Coeffs (0 .. D.N), 3.0);
      Check (Approx (R.Value, 9.0, 1.0E-4), "Newton nested p(3)=9");
      R := Evaluate_Newton (X, Y, 3.0);
      Check (Approx (R.Value, 9.0, 1.0E-4), "Newton build+eval p(3)=9");
   end;

   ---------------------------------------------------------------------
   Section ("11. Monomial Vandermonde (tiny n)");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [0.0, 1.0, 2.0, 3.0];
      Y : constant Ordinates := [1.0, 0.0, 1.0, 10.0];
      --  Not a special poly — just fit & compare to Lagrange
      R_M, R_L : Eval_Result;
      M : Monomial_Result;
      Big : Sample;
   begin
      M := Fit_Monomial (X, Y);
      Check (M.Success and M.N = 3, "Monomial fit n=3");
      R_M := Evaluate_Monomial (X, Y, 1.5);
      R_L := Evaluate_Lagrange (X, Y, 1.5);
      Check (R_M.Success and R_L.Success, "Monomial vs Lagrange success");
      Check (Approx (R_M.Value, R_L.Value, 1.0E-3),
             "Monomial ≡ Lagrange @ 1.5");
      Check (Approx (Evaluate_Monomial (M.Coeffs (0 .. M.N), 0.0),
                     1.0, 1.0E-3),
             "Monomial Horner at node0");

      --  Reject oversized monomial
      Big := Make_Quadratic_Sample (12, -1.0, 1.0);
      M := Fit_Monomial (Big);
      Check (M.Stat = Dimension_Error, "Monomial rejects n>8");
      R_M := Evaluate_Monomial (Big, 0.0);
      Check (R_M.Stat = Dimension_Error, "Eval monomial rejects n>8");
   end;

   ---------------------------------------------------------------------
   Section ("12. Runge sample (nodes exact; recommend spline)");
   ---------------------------------------------------------------------
   declare
      S : constant Sample := Make_Runge_Sample (9);
      R : Eval_Result;
      Nodes_Ok : Boolean := True;
      Note : constant String := Recommend (Newton_Form, 14);
   begin
      Check (S.Valid and S.N = 8, "Runge N=8");
      for I in 0 .. S.N loop
         R := Evaluate_Neville (S, S.X (I));
         if not Approx (R.Value, S.Y (I), 1.0E-3) then
            Nodes_Ok := False;
         end if;
      end loop;
      Check (Nodes_Ok, "Runge nodes exact Neville");
      Check (Forms_Agree (S, 0.0, 1.0E-3), "Runge forms @ 0");
      Check (Note'Length > 10, "Recommend Newton high-n note");
      Check (Recommend (Monomial_Vandermonde, 3)'Length > 10,
             "Recommend monomial note");
      Check (Recommend (Lagrange_Form, 4)'Length > 10,
             "Recommend Lagrange small-n");
      Check (Recommend (Lagrange_Form, 12)'Length > 10,
             "Recommend Lagrange large-n");
      Check (Recommend (Neville_Form, 5)'Length > 10,
             "Recommend Neville note");
   end;

   ---------------------------------------------------------------------
   Section ("13. Builders / Make_Example / Slice");
   ---------------------------------------------------------------------
   declare
      L : constant Sample := Make_Example (Linear_Data, 4);
      Q : constant Sample := Make_Example (Quadratic_Sample, 5);
      Rg : constant Sample := Make_Example (Runge_Sample, 6);
      Sn : constant Sample := Make_Example (Sine_Sample, 7);
      R : Eval_Result;
   begin
      Check (L.Valid and L.N = 3, "Example linear");
      Check (Q.Valid and Q.N = 4, "Example quadratic");
      Check (Rg.Valid and Rg.N = 5, "Example Runge");
      Check (Sn.Valid and Sn.N = 6, "Example sine");
      Check (Is_Distinct (Slice_X (L)), "Slice_X distinct");
      Check (Degree_Of (Slice_Y (Q)) = 4, "Slice_Y degree");
      R := Evaluate_Newton (L, 0.5);
      Check (Approx (R.Value, 0.5, 1.0E-4), "Example linear p(0.5)");
      R := Evaluate_Lagrange (Q, 0.0);
      Check (Approx (R.Value, 0.0, 1.0E-4), "Example quad p(0)=0");
      Check (Approx (Sn.X (Sn.N), Ada.Numerics.Pi, 1.0E-5),
             "Sine last = π");
      R := Evaluate_Neville (Sn, Ada.Numerics.Pi / 2.0);
      Check (R.Success, "Sine at π/2 success");
      Check (Approx (R.Value, 1.0, 0.05), "Sine at π/2 ≈ 1");
   end;

   ---------------------------------------------------------------------
   Section ("14. Sample overloads");
   ---------------------------------------------------------------------
   declare
      S : constant Sample := Make_Linear (3, 0.0, 2.0, 0.0, 4.0);
      R : Eval_Result;
      T : Tableau_Result;
      D : DD_Result;
      M : Monomial_Result;
   begin
      R := Evaluate_Lagrange (S, 1.0);
      Check (Approx (R.Value, 2.0), "Sample Lagrange");
      R := Evaluate_Newton (S, 1.0);
      Check (Approx (R.Value, 2.0), "Sample Newton");
      R := Evaluate_Neville (S, 1.0);
      Check (Approx (R.Value, 2.0), "Sample Neville");
      T := Evaluate_Neville_Tableau (S, 1.0);
      Check (Approx (T.Value, 2.0), "Sample Tableau");
      D := Build_Divided_Differences (S);
      Check (D.Success, "Sample DD");
      M := Fit_Monomial (S);
      Check (M.Success, "Sample monomial fit");
      R := Evaluate_Monomial (S, 1.0);
      Check (Approx (R.Value, 2.0, 1.0E-4), "Sample monomial eval");
      Check (Forms_Agree (S, 1.0), "Sample Forms_Agree");
   end;

   ---------------------------------------------------------------------
   Section ("15. Extra coverage sweeps");
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
               R := Evaluate_Newton (S, S.X (I));
               if not Approx (R.Value, S.Y (I), 1.0E-3) then
                  Ok_N := False;
               end if;
               R := Evaluate_Lagrange (S, S.X (I));
               if not Approx (R.Value, S.Y (I), 1.0E-3) then
                  Ok_N := False;
               end if;
            end loop;
            R := Evaluate_Neville (S, 0.3);
            if N >= 3 and then not Approx (R.Value, 0.09, 1.0E-3) then
               Ok_N := False;
            end if;
            if N >= 2 and then N <= 9
              and then not Forms_Agree (S, 0.15, 1.0E-3)
            then
               Ok_N := False;
            end if;
            if Ok_N then
               Pass_Sweep := Pass_Sweep + 1;
            end if;
         end;
      end loop;
      Check (Pass_Sweep = 10, "Quad sweep N=1..10 all forms");

      --  Pad individual checks
      declare
         S : constant Sample := Make_Sine_Sample (4);
         R : Eval_Result;
         Note2 : constant String := Recommend (Newton_Form, 3);
      begin
         R := Evaluate_Lagrange (S, Ada.Numerics.Pi / 2.0);
         Check (R.Success, "Sine Lagrange π/2");
         Check (Approx (R.Value, 1.0, 0.05), "Sine L ≈ 1");
         Check (Is_Distinct (Slice_X (S)), "Sine abscissae distinct");
         Check (Validate (Slice_X (S), Slice_Y (S)) = Ok,
                "Sine validate Ok");
         Check (not Near (0.0, 1.0), "Near 0≠1");
         Check (Near (1.0, 1.0 + Near_Tol / 2.0), "Near within tol");
         Check (Note2'Length > 5, "Recommend Newton small-n");
         Check (Degree_Of (Slice_X (S)) = S.N, "Degree_Of = Sample.N");
         Check (Slice_X (S)'Length = S.N + 1, "Slice_X length = N+1");
         Check (Slice_Y (S)'Length = Slice_X (S)'Length, "Slice XY same len");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("16. Uneven abscissae / three-point manual");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [-2.0, 0.0, 3.0];
      Y : constant Ordinates := [4.0, 0.0, 9.0];  -- still x²
      R : Eval_Result;
   begin
      R := Evaluate_Lagrange (X, Y, 1.0);
      Check (Approx (R.Value, 1.0, 1.0E-4), "Uneven L p(1)=1");
      R := Evaluate_Newton (X, Y, -1.0);
      Check (Approx (R.Value, 1.0, 1.0E-4), "Uneven N p(-1)=1");
      R := Evaluate_Neville (X, Y, 2.0);
      Check (Approx (R.Value, 4.0, 1.0E-4), "Uneven Nv p(2)=4");
      Check (Forms_Agree (X, Y, 0.5), "Uneven forms agree");
      R := Evaluate_Monomial (X, Y, 1.5);
      Check (Approx (R.Value, 2.25, 1.0E-3), "Uneven M p(1.5)=2.25");
   end;

   ---------------------------------------------------------------------
   Section ("17. Newton coeffs length mismatch");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [0.0, 1.0, 2.0];
      C : constant Newton_Coeffs := [1.0, 2.0];  -- wrong length
      R : Eval_Result;
   begin
      R := Evaluate_Newton (X, C, 0.5);
      Check (R.Stat = Dimension_Error, "Newton coeff length mismatch");
   end;

   ---------------------------------------------------------------------
   Section ("18. Two-pt / three-pt spot checks");
   ---------------------------------------------------------------------
   declare
      X2 : constant Abscissae := [-2.0, 4.0];
      Y2 : constant Ordinates := [3.0, 9.0];  -- line: slope=1, p(1)=6
      X3 : constant Abscissae := [0.0, 1.0, 4.0];
      Y3 : constant Ordinates := [0.0, 1.0, 2.0];
      R : Eval_Result;
   begin
      R := Evaluate_Neville (X2, Y2, 1.0);
      Check (Approx (R.Value, 6.0), "Two-pt p(1)=6");
      R := Evaluate_Lagrange (X2, Y2, -2.0);
      Check (Approx (R.Value, 3.0), "Two-pt node");
      R := Evaluate_Newton (X3, Y3, 0.0);
      Check (Approx (R.Value, 0.0), "Three-pt node0");
      R := Evaluate_Neville (X3, Y3, 1.0);
      Check (Approx (R.Value, 1.0), "Three-pt node1");
      R := Evaluate_Lagrange (X3, Y3, 4.0);
      Check (Approx (R.Value, 2.0), "Three-pt node2");
      Check (Forms_Agree (X3, Y3, 2.0, 1.0E-4), "Three-pt forms @ 2");
   end;

   ---------------------------------------------------------------------
   Section ("19. Monomial Horner identity / DD table shape");
   ---------------------------------------------------------------------
   declare
      C : constant Monomial_Coeffs := [2.0, 3.0, 1.0];  -- 2+3x+x²
      X : constant Abscissae := [0.0, 1.0, 2.0];
      Y : constant Ordinates := [0.0, 1.0, 4.0];
      D : constant DD_Result := Build_Divided_Differences (X, Y);
   begin
      Check (Approx (Evaluate_Monomial (C, 2.0), 12.0), "Horner 2+3*2+4");
      Check (Approx (Evaluate_Monomial (C, 0.0), 2.0), "Horner at 0");
      Check (D.Success and D.N = 2, "DD N=2");
      Check (Approx (D.Table (0, 0), 0.0), "DD T00=y0");
      Check (Approx (D.Table (1, 0), 1.0), "DD T10=y1");
      Check (Approx (D.Table (2, 0), 4.0), "DD T20=y2");
   end;

   ---------------------------------------------------------------------
   Section ("20. More builder / Runge / linear midpoints");
   ---------------------------------------------------------------------
   declare
      L : constant Sample := Make_Linear (6, -1.0, 1.0, -2.0, 2.0);
      R : Eval_Result;
      Ok_Mids : Boolean := True;
   begin
      R := Evaluate_Newton (L, 0.0);
      Check (Approx (R.Value, 0.0), "Make_Linear p(0)=0");
      R := Evaluate_Lagrange (L, 0.5);
      Check (Approx (R.Value, 1.0), "Make_Linear p(0.5)=1");
      for I in 0 .. L.N loop
         R := Evaluate_Neville (L, L.X (I));
         if not Approx (R.Value, L.Y (I), 1.0E-4) then
            Ok_Mids := False;
         end if;
      end loop;
      Check (Ok_Mids, "Linear builder nodes");
      Check (Forms_Agree (L, -0.3), "Linear forms @ -0.3");

      declare
         Rg : constant Sample := Make_Runge_Sample (5);
         All_F : Boolean := True;
         Qs : constant array (1 .. 3) of Float := [0.0, 0.25, -0.5];
      begin
         for Qi in Qs'Range loop
            if not Forms_Agree (Rg, Qs (Qi), 5.0E-4) then
               All_F := False;
            end if;
         end loop;
         Check (All_F, "Runge-5 forms at 3 queries");
         Check (Near (Rg.X (Rg.N / 2), 0.0) or else
                Approx (Rg.Y (Rg.N / 2), 1.0, 1.0E-4),
                "Runge mid near x=0 or y=1");
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
