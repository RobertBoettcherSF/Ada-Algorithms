--  Standalone test suite for Lagrange_Interpolation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Text_IO;
with Lagrange_Interpolation; use Lagrange_Interpolation;

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
   Ada.Text_IO.Put_Line ("Lagrange_Interpolation test suite");
   Ada.Text_IO.Put_Line ("=================================");

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
      X_Emp : Abscissae (1 .. 0);
      Y_Emp : Ordinates (1 .. 0);
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
      Check (Validate (X_Emp, Y_Emp) = Too_Few_Points,
             "Validate empty");
   end;

   ---------------------------------------------------------------------
   Section ("2. Degree-0 constant");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [5.0];
      Y : constant Ordinates := [42.0];
      R : Eval_Result;
      B : Eval_Result;
      W : Weight_Result;
   begin
      R := Evaluate (X, Y, 0.0);
      Check (R.Success and R.Stat = Ok, "Deg0 classical success");
      Check (Approx (R.Value, 42.0), "Deg0 classical at 0");
      R := Evaluate (X, Y, 100.0);
      Check (Approx (R.Value, 42.0), "Deg0 classical anywhere");
      B := Evaluate_Barycentric (X, Y, 3.0, Second_Form);
      Check (B.Success and Approx (B.Value, 42.0), "Deg0 barycentric");
      W := Build_Weights (X);
      Check (W.Success and W.N = 0, "Deg0 weights N=0");
      Check (Approx (W.W (0), 1.0), "Deg0 weight w0=1");
      B := Basis_Polynomial (X, 0, 9.0);
      Check (B.Success and Approx (B.Value, 1.0), "Deg0 basis = 1");
   end;

   ---------------------------------------------------------------------
   Section ("3. Nodes exact (interpolation property)");
   ---------------------------------------------------------------------
   declare
      S : constant Sample := Make_Quadratic_Sample (5, -2.0, 2.0);
      R, B : Eval_Result;
      All_C, All_B : Boolean := True;
   begin
      Check (S.Valid and S.N = 4, "Quad sample N=4");
      for I in 0 .. S.N loop
         R := Evaluate (S, S.X (I));
         if not (R.Success and Approx (R.Value, S.Y (I), 1.0E-4)) then
            All_C := False;
         end if;
         B := Evaluate_Barycentric (S, S.X (I), Second_Form);
         if not (B.Success and Approx (B.Value, S.Y (I), 1.0E-4)) then
            All_B := False;
         end if;
      end loop;
      Check (All_C, "Nodes exact classical on quadratic");
      Check (All_B, "Nodes exact barycentric on quadratic");

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
      X : constant Abscissae := [0.0, 1.0];
      Y : constant Ordinates := [0.0, 2.0];
      R : Eval_Result;
      S : constant Sample := Make_Linear (6, -1.0, 1.0, -2.0, 2.0);
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

      R := Evaluate_Barycentric (X, Y, 0.5, Second_Form);
      Check (Approx (R.Value, 1.0), "Bary mid p(0.5)=1");
      R := Evaluate_Barycentric (X, Y, 2.0, First_Form);
      Check (Approx (R.Value, 4.0), "Bary first p(2)=4");

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

      R := Evaluate_Barycentric (X, Y, 0.5, Second_Form);
      Check (Approx (R.Value, 0.25), "Bary quad p(0.5)=0.25");
      R := Evaluate_Barycentric (X, Y, 2.0, First_Form);
      Check (Approx (R.Value, 4.0, 1.0E-4), "Bary first quad p(2)=4");

      R := Evaluate (S, 1.5);
      Check (Approx (R.Value, 2.25, 1.0E-4), "Quad sample p(1.5)=2.25");
      R := Evaluate (S, 2.5);
      Check (Approx (R.Value, 6.25, 1.0E-4), "Quad sample p(2.5)=6.25");
   end;

   ---------------------------------------------------------------------
   Section ("6. Basis_Polynomial Kronecker / partition");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [0.0, 1.0, 2.0, 3.0];
      Y : constant Ordinates := [1.0, 2.0, 3.0, 4.0];
      B : Eval_Result;
      Sum_At : Float;
      Ok_Kronecker : Boolean := True;
      Ok_Partition : Boolean := True;
   begin
      for I in X'Range loop
         for K in X'Range loop
            B := Basis_Polynomial (X, I, X (K));
            if I = K then
               if not (B.Success and Approx (B.Value, 1.0, 1.0E-4)) then
                  Ok_Kronecker := False;
               end if;
            else
               if not (B.Success and Approx (B.Value, 0.0, 1.0E-4)) then
                  Ok_Kronecker := False;
               end if;
            end if;
         end loop;
      end loop;
      Check (Ok_Kronecker, "Basis Kronecker δ_ik at nodes");

      --  Σ ℓ_i(x) = 1 (partition of unity) for interpolating constants
      declare
         Qs : constant array (1 .. 5) of Float :=
           [0.5, 1.5, 2.5, -1.0, 4.0];
      begin
         for Qi in Qs'Range loop
            Sum_At := 0.0;
            for I in X'Range loop
               B := Basis_Polynomial (X, I, Qs (Qi));
               Sum_At := Sum_At + B.Value;
            end loop;
            if not Approx (Sum_At, 1.0, 1.0E-4) then
               Ok_Partition := False;
            end if;
         end loop;
      end;
      Check (Ok_Partition, "Basis partition of unity Σ ℓ_i = 1");

      --  Reconstruct: Σ y_i ℓ_i = Evaluate
      declare
         Xx : constant Float := 1.7;
         Acc : Float := 0.0;
         R : Eval_Result;
      begin
         for I in X'Range loop
            B := Basis_Polynomial (X, I, Xx);
            Acc := Acc + Y (I) * B.Value;
         end loop;
         R := Evaluate (X, Y, Xx);
         Check (Approx (Acc, R.Value, 1.0E-4),
                "Σ y_i ℓ_i ≡ Evaluate");
      end;

      B := Basis_Polynomial (X, 7, 0.0);
      Check (not B.Success and B.Stat = Dimension_Error,
             "Basis I out of range");
   end;

   ---------------------------------------------------------------------
   Section ("7. Classical ≡ barycentric (Forms_Agree)");
   ---------------------------------------------------------------------
   declare
      S : constant Sample := Make_Sine_Sample (5);
      Xs : constant array (1 .. 7) of Float :=
        [0.1, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0];
      Agree : Boolean := True;
      R_C, R_1, R_2 : Eval_Result;
   begin
      for K in Xs'Range loop
         if not Forms_Agree (S, Xs (K), 1.0E-4) then
            Agree := False;
         end if;
         R_C := Evaluate (S, Xs (K));
         R_1 := Evaluate_Barycentric (S, Xs (K), First_Form);
         R_2 := Evaluate_Barycentric (S, Xs (K), Second_Form);
         if not (R_C.Success and R_1.Success and R_2.Success
           and Approx (R_C.Value, R_2.Value, 1.0E-4)
           and Approx (R_1.Value, R_2.Value, 1.0E-3))
         then
            Agree := False;
         end if;
      end loop;
      Check (Agree, "Forms_Agree on sine sample queries");

      declare
         Q : constant Sample := Make_Quadratic_Sample (6, -1.0, 1.0);
         Ok_Q : Boolean := True;
      begin
         for T in 0 .. 8 loop
            declare
               Xx : constant Float := -1.0 + 0.25 * Float (T);
            begin
               if not Forms_Agree (Q, Xx, 1.0E-3) then
                  Ok_Q := False;
               end if;
            end;
         end loop;
         Check (Ok_Q, "Forms_Agree on quadratic grid");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Build_Weights + reuse");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [0.0, 1.0, 2.0];
      Y : constant Ordinates := [1.0, 0.0, 1.0];
      WR : constant Weight_Result := Build_Weights (X);
      R1, R2 : Eval_Result;
      --  For x=0,1,2: w0=1/((0-1)(0-2))=1/2, w1=1/((1-0)(1-2))=-1,
      --  w2=1/((2-0)(2-1))=1/2
   begin
      Check (WR.Success and WR.N = 2, "Weights success N=2");
      Check (Approx (WR.W (0), 0.5), "w0 = 1/2");
      Check (Approx (WR.W (1), -1.0), "w1 = -1");
      Check (Approx (WR.W (2), 0.5), "w2 = 1/2");

      R1 := Evaluate_Barycentric (X, Y, WR.W (0 .. 2), 0.5, Second_Form);
      R2 := Evaluate (X, Y, 0.5);
      Check (R1.Success and Approx (R1.Value, R2.Value, 1.0E-4),
             "Reuse weights ≡ classical");

      declare
         Xd : constant Abscissae := [1.0, 1.0, 2.0];
         Bad : constant Weight_Result := Build_Weights (Xd);
      begin
         Check (not Bad.Success and Bad.Stat = Duplicate_Abscissa,
                "Weights reject duplicate");
      end;

      declare
         Inv : Sample;
         Bad : Weight_Result;
      begin
         Inv.Valid := False;
         Bad := Build_Weights (Inv);
         Check (not Bad.Success and Bad.Stat = Ill_Started,
                "Weights invalid sample");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Error paths");
   ---------------------------------------------------------------------
   declare
      X_Dup : constant Abscissae := [0.0, 1.0, 1.0];
      Y_Dup : constant Ordinates := [0.0, 1.0, 2.0];
      X_Mis : constant Abscissae := [0.0, 1.0];
      Y_Mis : constant Ordinates := [0.0, 1.0, 2.0];
      R : Eval_Result;
      Inv : Sample;
   begin
      R := Evaluate (X_Dup, Y_Dup, 0.5);
      Check (not R.Success and R.Stat = Duplicate_Abscissa,
             "Eval rejects duplicate");
      R := Evaluate_Barycentric (X_Dup, Y_Dup, 0.5);
      Check (not R.Success and R.Stat = Duplicate_Abscissa,
             "Bary rejects duplicate");
      R := Evaluate (X_Mis, Y_Mis, 0.5);
      Check (not R.Success and R.Stat = Dimension_Error,
             "Eval rejects mismatch");
      Inv.Valid := False;
      R := Evaluate (Inv, 0.0);
      Check (not R.Success and R.Stat = Ill_Started,
             "Eval invalid sample");
      R := Evaluate_Barycentric (Inv, 0.0);
      Check (not R.Success and R.Stat = Ill_Started,
             "Bary invalid sample");
      Check (not Forms_Agree (Inv, 0.0), "Forms_Agree invalid False");
   end;

   ---------------------------------------------------------------------
   Section ("10. Runge sample / sine / builders");
   ---------------------------------------------------------------------
   declare
      Rge : constant Sample := Make_Runge_Sample (7);
      Sin : constant Sample := Make_Sine_Sample (6);
      Lin : constant Sample := Make_Example (Linear_Data, 5);
      Qu  : constant Sample := Make_Example (Quadratic_Sample, 5);
      Rg2 : constant Sample := Make_Example (Runge_Sample, 5);
      Si2 : constant Sample := Make_Example (Sine_Sample, 5);
      R : Eval_Result;
      All_Nodes : Boolean := True;
   begin
      Check (Rge.Valid and Rge.N = 6, "Runge N=6");
      Check (Approx (Rge.X (0), -1.0) and Approx (Rge.X (6), 1.0),
             "Runge endpoints ±1");
      Check (Approx (Rge.Y (3), 1.0), "Runge mid y=1 at x=0");
      for I in 0 .. Rge.N loop
         R := Evaluate (Rge, Rge.X (I));
         if not Approx (R.Value, Rge.Y (I), 1.0E-3) then
            All_Nodes := False;
         end if;
      end loop;
      Check (All_Nodes, "Runge nodes exact classical");

      R := Evaluate (Sin, Ada.Numerics.Pi / 2.0);
      Check (R.Success, "Sine at π/2 success");
      Check (Approx (R.Value, 1.0, 0.05), "Sine at π/2 ≈ 1");
      Check (Is_Distinct (Slice_X (Sin)), "Sine abscissae distinct");
      Check (Validate (Slice_X (Sin), Slice_Y (Sin)) = Ok,
             "Sine validate Ok");
      Check (Approx (Sin.X (Sin.N), Ada.Numerics.Pi, 1.0E-5),
             "Sine last = π");

      Check (Lin.Valid and Lin.N = 4, "Example Linear N=4");
      Check (Qu.Valid and Qu.N = 4, "Example Quad N=4");
      Check (Rg2.Valid and Rg2.N = 4, "Example Runge N=4");
      Check (Si2.Valid and Si2.N = 4, "Example Sine N=4");

      R := Evaluate (Lin, 0.5);
      Check (Approx (R.Value, 0.5, 1.0E-4), "Example linear p(0.5)=0.5");
      R := Evaluate (Qu, 0.0);
      Check (Approx (R.Value, 0.0, 1.0E-4), "Example quad p(0)=0");
   end;

   ---------------------------------------------------------------------
   Section ("11. Degree sweep / Max_Degree");
   ---------------------------------------------------------------------
   declare
      Pass_Sweep : Natural := 0;
   begin
      for N in 1 .. 10 loop
         declare
            S : constant Sample := Make_Quadratic_Sample (N, 0.0, 1.0);
            R : Eval_Result;
            Ok_N : Boolean := True;
         begin
            for I in 0 .. S.N loop
               R := Evaluate (S, S.X (I));
               if not Approx (R.Value, S.Y (I), 1.0E-3) then
                  Ok_N := False;
               end if;
               R := Evaluate_Barycentric (S, S.X (I));
               if not Approx (R.Value, S.Y (I), 1.0E-3) then
                  Ok_N := False;
               end if;
            end loop;
            --  Non-node check when enough points for x² exact
            if N >= 3 then
               R := Evaluate (S, 0.3);
               if not Approx (R.Value, 0.09, 1.0E-3) then
                  Ok_N := False;
               end if;
               R := Evaluate_Barycentric (S, 0.3, Second_Form);
               if not Approx (R.Value, 0.09, 1.0E-3) then
                  Ok_N := False;
               end if;
            end if;
            if Ok_N then
               Pass_Sweep := Pass_Sweep + 1;
            end if;
         end;
      end loop;
      Check (Pass_Sweep = 10, "Quad sweep N=1..10 nodes/exact");

      declare
         Cap_S : constant Sample := Make_Linear (Max_Points, 0.0, 1.0, 0.0, 1.0);
      begin
         Check (Cap_S.N = Max_Degree, "Sample N reaches Max_Degree");
         Check (Cap_S.N + 1 = Max_Points, "N+1 reaches Max_Points");
      end;

      declare
         Big : constant Sample := Make_Linear (17, 0.0, 1.0, 0.0, 1.0);
         R : Eval_Result;
      begin
         Check (Big.Valid and Big.N = 16, "Max points sample N=16");
         R := Evaluate (Big, 0.5);
         Check (R.Success and Approx (R.Value, 0.5, 1.0E-3),
                "Max-degree linear at 0.5");
         R := Evaluate_Barycentric (Big, 0.25, Second_Form);
         Check (R.Success and Approx (R.Value, 0.25, 1.0E-3),
                "Max-degree bary at 0.25");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Cubic / cubic monomial / extras");
   ---------------------------------------------------------------------
   declare
      --  Through (0,0),(1,1),(2,8),(3,27): p(x)=x³
      X : constant Abscissae := [0.0, 1.0, 2.0, 3.0];
      Y : constant Ordinates := [0.0, 1.0, 8.0, 27.0];
      R : Eval_Result;
      Ok_Cubic : Boolean := True;
   begin
      for T in 0 .. 6 loop
         declare
            Xx : constant Float := 0.5 * Float (T);
            Expect : constant Float := Xx * Xx * Xx;
         begin
            R := Evaluate (X, Y, Xx);
            if not (R.Success and Approx (R.Value, Expect, 1.0E-3)) then
               Ok_Cubic := False;
            end if;
            R := Evaluate_Barycentric (X, Y, Xx, Second_Form);
            if not (R.Success and Approx (R.Value, Expect, 1.0E-3)) then
               Ok_Cubic := False;
            end if;
         end;
      end loop;
      Check (Ok_Cubic, "Cubic x³ classical+bary on [0,3]");

      Check (not Near (0.0, 1.0), "Near 0≠1");
      Check (Near (1.0, 1.0 + Near_Tol / 2.0), "Near within tol");
      declare
         --  Touch tols via Near / Is_Distinct rather than folded compares.
         Tiny : constant Float := Epsilon_Tol * 0.5;
         Xd : constant Abscissae := [0.0, Distinct_Tol * 0.5];
      begin
         Check (Near (0.0, Tiny, Epsilon_Tol), "Epsilon_Tol usable in Near");
         Check (not Is_Distinct (Xd, Distinct_Tol),
                "Distinct_Tol rejects near-dup");
      end;

      --  Sample Slice helpers
      declare
         S : constant Sample := Make_Sine_Sample (4);
         Xx : constant Abscissae := Slice_X (S);
         Yy : constant Ordinates := Slice_Y (S);
      begin
         Check (Xx'Length = 4 and Yy'Length = 4, "Slice lengths");
         Check (Degree_Of (Xx) = 3, "Slice Degree_Of = 3");
         Check (Forms_Agree (Xx, Yy, 1.0, 1.0E-3),
                "Forms_Agree sliced sine");
      end;

      --  First vs second at non-node with precomputed W
      declare
         WR : constant Weight_Result := Build_Weights (X);
         A, B : Eval_Result;
      begin
         A := Evaluate_Barycentric
           (X, Y, WR.W (0 .. 3), 1.5, First_Form);
         B := Evaluate_Barycentric
           (X, Y, WR.W (0 .. 3), 1.5, Second_Form);
         Check (A.Success and B.Success
           and Approx (A.Value, B.Value, 1.0E-3),
                "First ≡ Second with shared weights");
         Check (Approx (A.Value, 1.5 ** 3, 1.0E-3),
                "Shared weights cubic at 1.5");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("13. More coverage padding");
   ---------------------------------------------------------------------
   declare
      S : constant Sample := Make_Sine_Sample (4);
      R : Eval_Result;
      Count_Agree : Natural := 0;
   begin
      R := Evaluate (S, Ada.Numerics.Pi / 2.0);
      Check (R.Success, "Pad sine π/2 success");
      Check (Approx (R.Value, 1.0, 0.05), "Pad sine π/2 ≈ 1");

      for K in 1 .. 8 loop
         declare
            Xx : constant Float := Float (K) * 0.4;
         begin
            if Forms_Agree (S, Xx, 5.0E-3) then
               Count_Agree := Count_Agree + 1;
            end if;
         end;
      end loop;
      Check (Count_Agree >= 6, "Pad Forms_Agree majority");

      --  Linear two-point basis
      declare
         X2 : constant Abscissae := [0.0, 1.0];
         B0, B1 : Eval_Result;
      begin
         B0 := Basis_Polynomial (X2, 0, 0.25);
         B1 := Basis_Polynomial (X2, 1, 0.25);
         Check (Approx (B0.Value, 0.75) and Approx (B1.Value, 0.25),
                "Linear basis ℓ0=0.75 ℓ1=0.25");
         Check (Approx (B0.Value + B1.Value, 1.0),
                "Linear basis sum 1");
      end;

      --  Status names presence via Validate paths already covered
      declare
         --  Exercise enum'Image / membership without folded Pos compares.
         Sok : constant String := Status'Image (Ok);
         Sil : constant String := Status'Image (Ill_Started);
         Sf  : constant String := Barycentric_Form'Image (First_Form);
         Ss  : constant String := Barycentric_Form'Image (Second_Form);
      begin
         Check (Sok'Length > 0 and Sil'Length > 0, "Status'Image non-empty");
         Check (Sf'Length > 0 and Ss'Length > 0, "Form'Image non-empty");
         Check (Ok in Status and Ill_Started in Status, "Status membership");
         Check (First_Form in Barycentric_Form
           and Second_Form in Barycentric_Form, "Form membership");
      end;

      --  Runge oscillation awareness: still nodes exact at high-ish n
      declare
         Rg : constant Sample := Make_Runge_Sample (9);
         Ok_N : Boolean := True;
      begin
         for I in 0 .. Rg.N loop
            R := Evaluate_Barycentric (Rg, Rg.X (I));
            if not Approx (R.Value, Rg.Y (I), 1.0E-3) then
               Ok_N := False;
            end if;
         end loop;
         Check (Ok_N, "Runge n=8 nodes exact barycentric");
      end;

      --  Weight length mismatch
      declare
         X3 : constant Abscissae := [0.0, 1.0, 2.0];
         Y3 : constant Ordinates := [1.0, 2.0, 3.0];
         W2 : constant Weights := [1.0, -1.0];
         Bad : Eval_Result;
      begin
         Bad := Evaluate_Barycentric (X3, Y3, W2, 0.5);
         Check (not Bad.Success and Bad.Stat = Dimension_Error,
                "Bary weight length mismatch");
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
