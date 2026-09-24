--  Standalone test suite for Linear_Interpolation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Linear_Interpolation; use Linear_Interpolation;

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
   Ada.Text_IO.Put_Line ("Linear_Interpolation test suite");
   Ada.Text_IO.Put_Line ("===============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Make_Point / Lerp / Lerp_Unclamped");
   ---------------------------------------------------------------------
   declare
      P : constant Point := Make_Point (1.0, 2.0);
      Q : constant Point := Make_Point (1.0, 2.0 + 1.0E-8);
   begin
      Check (Near (1.0, 1.0), "Near equal floats");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny floats");
      Check (not Near (1.0, 2.0), "Near rejects floats");
      Check (Near (P, Q), "Near points");
      Check (Approx (P.X, 1.0) and Approx (P.Y, 2.0), "Make_Point");
      Check (Approx (Lerp (0.0, 10.0, 0.3), 3.0), "Lerp 0.3");
      Check (Approx (Lerp (2.0, 2.0, 0.7), 2.0), "Lerp equal ends");
      Check (Approx (Lerp (0.0, 10.0, -1.0), 0.0), "Lerp clamps low");
      Check (Approx (Lerp (0.0, 10.0, 2.0), 10.0), "Lerp clamps high");
      Check (Approx (Lerp_Unclamped (0.0, 10.0, -1.0), -10.0),
             "Lerp_Unclamped extrapolates low");
      Check (Approx (Lerp_Unclamped (0.0, 10.0, 2.0), 20.0),
             "Lerp_Unclamped extrapolates high");
      Check (Approx (Lerp_Unclamped (0.0, 10.0, 0.5), 5.0),
             "Lerp_Unclamped mid");
   end;

   ---------------------------------------------------------------------
   Section ("2. Inverse_Lerp / Interpolate_Two_Points");
   ---------------------------------------------------------------------
   declare
      I1 : constant Eval_Result := Inverse_Lerp (0.0, 10.0, 3.0);
      I2 : constant Eval_Result := Inverse_Lerp (2.0, 2.0, 5.0);
      I3 : constant Eval_Result := Inverse_Lerp (10.0, 0.0, 2.5);
      T1 : constant Eval_Result :=
        Interpolate_Two_Points (0.0, 0.0, 10.0, 20.0, 5.0);
      T2 : constant Eval_Result :=
        Interpolate_Two_Points (1.0, 1.0, 1.0, 5.0, 2.0);
      T3 : constant Eval_Result :=
        Interpolate_Two_Points (0.0, 1.0, 4.0, 9.0, 2.0);
      T4 : constant Eval_Result :=
        Interpolate_Two_Points (0.0, 0.0, 1.0, 1.0, -1.0);
   begin
      Check (I1.Success and Approx (I1.Value, 0.3), "Inverse_Lerp 0.3");
      Check (not I2.Success and I2.Stat = Singular,
             "Inverse_Lerp Singular when A=B");
      Check (I3.Success and Approx (I3.Value, 0.75),
             "Inverse_Lerp decreasing");
      Check (T1.Success and Approx (T1.Value, 10.0),
             "Two-point mid");
      Check (not T2.Success and T2.Stat = Singular,
             "Two-point Singular when X0=X1");
      Check (T3.Success and Approx (T3.Value, 5.0),
             "Two-point y=2x+1 at x=2");
      Check (T4.Success and Approx (T4.Value, -1.0),
             "Two-point extrapolates");
   end;

   ---------------------------------------------------------------------
   Section ("3. Strictly increasing / monotone / builders");
   ---------------------------------------------------------------------
   declare
      Good : constant Abscissae := [0.0, 1.0, 2.5, 4.0];
      Bad  : constant Abscissae := [0.0, 1.0, 1.0, 2.0];
      Dec  : constant Abscissae := [0.0, 2.0, 1.5];
      Y_Up : constant Ordinates := [0.0, 1.0, 2.0, 5.0];
      Y_Dn : constant Ordinates := [5.0, 2.0, 1.0, 0.0];
      Y_Nm : constant Ordinates := [0.0, 2.0, 1.0, 3.0];
      Y_Fl : constant Ordinates := [0.0, 1.0, 1.0, 2.0];
      Lin  : constant Points := Make_Linear_Data (5, 0.0, 4.0, 1.0, 9.0);
      Ramp : constant Points := Make_Increasing_Ramp (6, 0.0, 1.0, 0.0, 10.0);
      Dr   : constant Points := Make_Decreasing_Ramp (5, 0.0, 4.0, 8.0, 0.0);
      Quad : constant Points := Make_Quadratic_Sample (7, 0.0, 1.0);
   begin
      Check (Is_Strictly_Increasing (Good), "Strict good");
      Check (not Is_Strictly_Increasing (Bad), "Reject equal X");
      Check (not Is_Strictly_Increasing (Dec), "Reject decreasing X");
      Check (Is_Strictly_Monotone (Y_Up), "Strict monotone increasing Y");
      Check (Is_Strictly_Monotone (Y_Dn), "Strict monotone decreasing Y");
      Check (not Is_Strictly_Monotone (Y_Nm), "Reject non-monotone Y");
      Check (not Is_Strictly_Monotone (Y_Fl), "Reject flat segment Y");
      Check (Lin'Length = 5, "Linear data length");
      Check (Approx (Lin (0).X, 0.0) and Approx (Lin (0).Y, 1.0),
             "Linear start (0,1)");
      Check (Approx (Lin (4).X, 4.0) and Approx (Lin (4).Y, 9.0),
             "Linear end (4,9)");
      Check (Approx (Lin (2).Y, 2.0 * Lin (2).X + 1.0),
             "Linear mid on y=2x+1");
      Check (Is_Strictly_Monotone (Ramp), "Ramp monotone");
      Check (Is_Strictly_Monotone (Dr), "Decreasing ramp monotone");
      Check (Is_Strictly_Monotone (Quad), "Quadratic sample monotone");
      Check (Approx (Ramp (0).Y, 0.0) and Approx (Ramp (5).Y, 10.0),
             "Ramp endpoints");
      Check (Approx (Dr (0).Y, 8.0) and Approx (Dr (4).Y, 0.0),
             "Decreasing ramp endpoints");
      Check (Approx (Quad (0).Y, 0.0) and Approx (Quad (6).Y, 1.0),
             "Quadratic endpoints");
   end;

   ---------------------------------------------------------------------
   Section ("4. Make_Example / Split_XY");
   ---------------------------------------------------------------------
   declare
      L : constant Points := Make_Example (Linear_Data);
      R : constant Points := Make_Example (Increasing_Ramp);
      D : constant Points := Make_Example (Decreasing_Ramp);
      Q : constant Points := Make_Example (Quadratic_Sample);
      X : Abscissae (L'Range);
      Y : Ordinates (L'Range);
   begin
      Check (L'Length = 5, "Example Linear length");
      Check (R'Length = 8, "Example Ramp length");
      Check (D'Length = 6, "Example Decreasing length");
      Check (Q'Length = 9, "Example Quadratic length");
      Check (Is_Strictly_Monotone (L), "Example Linear monotone");
      Check (Is_Strictly_Monotone (R), "Example Ramp monotone");
      Check (Is_Strictly_Monotone (D), "Example Decreasing monotone");
      Check (Is_Strictly_Monotone (Q), "Example Quadratic monotone");
      Split_XY (L, X, Y);
      Check (Approx (X (0), L (0).X) and Approx (Y (0), L (0).Y),
             "Split_XY first");
      Check (Approx (X (4), L (4).X) and Approx (Y (4), L (4).Y),
             "Split_XY last");
   end;

   ---------------------------------------------------------------------
   Section ("5. Fit validation: too few / unordered / empty / mismatch");
   ---------------------------------------------------------------------
   declare
      One_X : constant Abscissae := [0.0];
      One_Y : constant Ordinates := [1.0];
      Bad_X : constant Abscissae := [0.0, 1.0, 1.0];
      Bad_Y : constant Ordinates := [0.0, 1.0, 2.0];
      Mis_X : constant Abscissae := [0.0, 1.0];
      Mis_Y : constant Ordinates := [0.0, 1.0, 2.0];
      Dec_X : constant Abscissae := [0.0, 2.0, 1.0];
      Dec_Y : constant Ordinates := [0.0, 1.0, 2.0];
      F1 : constant Fit_Result := Fit (One_X, One_Y);
      F2 : constant Fit_Result := Fit (Bad_X, Bad_Y);
      F3 : constant Fit_Result := Fit (Mis_X, Mis_Y);
      F4 : constant Fit_Result := Fit (Dec_X, Dec_Y);
   begin
      Check (not F1.Success and F1.Stat = Too_Few_Points,
             "Too few points");
      Check (not F2.Success and F2.Stat = Duplicate_Or_Unordered,
             "Duplicate abscissae");
      Check (not F3.Success and F3.Stat = Ill_Started,
             "Mismatched lengths → Ill_Started");
      Check (not F4.Success and F4.Stat = Duplicate_Or_Unordered,
             "Unordered abscissae");
   end;

   ---------------------------------------------------------------------
   Section ("6. Nodes exact under Fit / Evaluate");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Quadratic_Sample);
      F : constant Fit_Result := Fit (P);
      E : Eval_Result;
   begin
      Check (F.Success and F.Stat = Ok, "Quadratic Fit ok");
      Check (F.T.Valid and not F.T.Extrapolate, "Valid / no extrapolate");
      Check (F.T.N = 8, "Quadratic N=8");
      for I in P'Range loop
         E := Evaluate (F.T, P (I).X);
         Check
           (E.Success and Approx (E.Value, P (I).Y, 1.0E-4),
            "Node exact i=" & Integer'Image (Integer (I - P'First)));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("7. Linear data recovers the line");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Linear_Data);
      F : constant Fit_Result := Fit (P);
      E : Eval_Result;
      Xs : constant array (1 .. 9) of Float :=
        [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0];
   begin
      Check (F.Success, "Linear-data Fit");
      for K in Xs'Range loop
         E := Evaluate (F.T, Xs (K));
         Check
           (E.Success and Approx (E.Value, 2.0 * Xs (K) + 1.0, 1.0E-4),
            "Linear recover x=" & Float'Image (Xs (K)));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("8. Piecewise midpoints / Find_Interval / In_Domain");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [0.0, 1.0, 3.0, 6.0];
      Y : constant Ordinates := [0.0, 2.0, 2.0, 8.0];
      F : constant Fit_Result := Fit (X, Y);
      E1 : constant Eval_Result := Evaluate (F.T, 0.5);
      E2 : constant Eval_Result := Evaluate (F.T, 2.0);
      E3 : constant Eval_Result := Evaluate (F.T, 4.5);
      E4 : constant Eval_Result := Evaluate (F.T, 6.0);
   begin
      Check (F.Success, "Piecewise Fit");
      Check (In_Domain (F.T, 0.0) and In_Domain (F.T, 6.0),
             "In_Domain endpoints");
      Check (In_Domain (F.T, 3.0) and not In_Domain (F.T, -0.1),
             "In_Domain interior / outside");
      Check (Find_Interval (F.T, 0.5) = 0, "Interval at 0.5");
      Check (Find_Interval (F.T, 2.0) = 1, "Interval at 2.0");
      Check (Find_Interval (F.T, 6.0) = 2, "Interval at right end");
      Check (E1.Success and Approx (E1.Value, 1.0), "Mid first segment");
      Check (E2.Success and Approx (E2.Value, 2.0), "Flat mid segment");
      Check (E3.Success and Approx (E3.Value, 5.0), "Mid last segment");
      Check (E4.Success and Approx (E4.Value, 8.0), "Right endpoint");
   end;

   ---------------------------------------------------------------------
   Section ("9. Out of domain vs extrapolation");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Increasing_Ramp);
      F0 : constant Fit_Result := Fit (P, Extrapolate => False);
      F1 : constant Fit_Result := Fit (P, Extrapolate => True);
      E0a : constant Eval_Result := Evaluate (F0.T, -0.1);
      E0b : constant Eval_Result := Evaluate (F0.T, 1.1);
      E0c : constant Eval_Result := Evaluate (F0.T, 0.5);
      E1a : constant Eval_Result := Evaluate (F1.T, -0.1);
      E1b : constant Eval_Result := Evaluate (F1.T, 1.1);
      Ill : constant Eval_Result := Evaluate ((others => <>), 0.0);
   begin
      Check (not E0a.Success and E0a.Stat = Out_Of_Domain,
             "OOD low without extrapolate");
      Check (not E0b.Success and E0b.Stat = Out_Of_Domain,
             "OOD high without extrapolate");
      Check (E0c.Success and Approx (E0c.Value, 0.5), "Interior ok");
      Check (E1a.Success and Approx (E1a.Value, -0.1, 1.0E-4),
             "Extrapolate low");
      Check (E1b.Success and Approx (E1b.Value, 1.1, 1.0E-4),
             "Extrapolate high");
      Check (not Ill.Success and Ill.Stat = Ill_Started,
             "Evaluate invalid table");
   end;

   ---------------------------------------------------------------------
   Section ("10. Inverse_Evaluate increasing / decreasing");
   ---------------------------------------------------------------------
   declare
      R : constant Points := Make_Example (Increasing_Ramp);
      D : constant Points := Make_Example (Decreasing_Ramp);
      Fr : constant Fit_Result := Fit (R);
      Fd : constant Fit_Result := Fit (D);
      Ir1 : constant Eval_Result := Inverse_Evaluate (Fr.T, 0.0);
      Ir2 : constant Eval_Result := Inverse_Evaluate (Fr.T, 1.0);
      Ir3 : constant Eval_Result := Inverse_Evaluate (Fr.T, 0.5);
      Id1 : constant Eval_Result := Inverse_Evaluate (Fd.T, 10.0);
      Id2 : constant Eval_Result := Inverse_Evaluate (Fd.T, 0.0);
      Id3 : constant Eval_Result := Inverse_Evaluate (Fd.T, 5.0);
   begin
      Check (Fr.Success and Fd.Success, "Ramp fits");
      Check (Ir1.Success and Approx (Ir1.Value, 0.0), "Inv ramp y=0 → x=0");
      Check (Ir2.Success and Approx (Ir2.Value, 1.0), "Inv ramp y=1 → x=1");
      Check (Ir3.Success and Approx (Ir3.Value, 0.5, 1.0E-4),
             "Inv ramp y=0.5 → x=0.5");
      Check (Id1.Success and Approx (Id1.Value, 0.0), "Inv dec y=10 → x=0");
      Check (Id2.Success and Approx (Id2.Value, 5.0), "Inv dec y=0 → x=5");
      Check (Id3.Success and Approx (Id3.Value, 2.5, 1.0E-4),
             "Inv dec y=5 → x=2.5");
   end;

   ---------------------------------------------------------------------
   Section ("11. Inverse_Evaluate OOD / extrapolate / Singular");
   ---------------------------------------------------------------------
   declare
      R : constant Points := Make_Example (Increasing_Ramp);
      Q : constant Points := Make_Example (Quadratic_Sample);
      --  Non-monotone table for Singular
      Nm_X : constant Abscissae := [0.0, 1.0, 2.0, 3.0];
      Nm_Y : constant Ordinates := [0.0, 2.0, 1.0, 3.0];
      F0 : constant Fit_Result := Fit (R, Extrapolate => False);
      F1 : constant Fit_Result := Fit (R, Extrapolate => True);
      Fn : constant Fit_Result := Fit (Nm_X, Nm_Y);
      Fq : constant Fit_Result := Fit (Q);
      O1 : constant Eval_Result := Inverse_Evaluate (F0.T, -0.5);
      O2 : constant Eval_Result := Inverse_Evaluate (F0.T, 1.5);
      E1 : constant Eval_Result := Inverse_Evaluate (F1.T, -0.5);
      E2 : constant Eval_Result := Inverse_Evaluate (F1.T, 1.5);
      S  : constant Eval_Result := Inverse_Evaluate (Fn.T, 1.0);
      --  Round-trip on quadratic (strictly increasing on [0,1])
      Rt : Eval_Result;
      Ok_Rt : Boolean := True;
   begin
      Check (not O1.Success and O1.Stat = Out_Of_Domain,
             "Inv OOD low");
      Check (not O2.Success and O2.Stat = Out_Of_Domain,
             "Inv OOD high");
      Check (E1.Success and Approx (E1.Value, -0.5, 1.0E-4),
             "Inv extrapolate low");
      Check (E2.Success and Approx (E2.Value, 1.5, 1.0E-4),
             "Inv extrapolate high");
      Check (Fn.Success, "Non-monotone Fit still ok");
      Check (not S.Success and S.Stat = Singular,
             "Inv Singular on non-monotone Y");
      Check (Fq.Success, "Quadratic Fit for round-trip");
      for K in 0 .. 8 loop
         declare
            Yq : constant Float := Float (K) / 8.0;
            --  true x from u^2: for samples at equal x, inverse of piecewise
            --  linear approx to u^2 is not exact √y, but round-trip
            --  Evaluate(Inverse(Y)) ≈ Y.
            Xi : constant Eval_Result := Inverse_Evaluate (Fq.T, Yq);
         begin
            if not Xi.Success then
               Ok_Rt := False;
            else
               Rt := Evaluate (Fq.T, Xi.Value);
               if not Rt.Success or else not Approx (Rt.Value, Yq, 1.0E-4)
               then
                  Ok_Rt := False;
               end if;
            end if;
         end;
      end loop;
      Check (Ok_Rt, "Inv/Eval round-trip on quadratic samples");
   end;

   ---------------------------------------------------------------------
   Section ("12. Fit from Points / Abscissae+Ordinates parity");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Linear_Data);
      X : Abscissae (P'Range);
      Y : Ordinates (P'Range);
      Fp : Fit_Result;
      Fx : Fit_Result;
      E1, E2 : Eval_Result;
   begin
      Split_XY (P, X, Y);
      Fp := Fit (P);
      Fx := Fit (X, Y);
      Check (Fp.Success and Fx.Success, "Both Fit forms ok");
      Check (Fp.T.N = Fx.T.N, "Same N");
      E1 := Evaluate (Fp.T, 2.0);
      E2 := Evaluate (Fx.T, 2.0);
      Check (E1.Success and E2.Success and Approx (E1.Value, E2.Value),
             "Parity Evaluate at x=2");
   end;

   ---------------------------------------------------------------------
   Section ("13. Two-point formula matches Evaluate on 2-knot table");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [1.0, 5.0];
      Y : constant Ordinates := [3.0, 11.0];
      F : constant Fit_Result := Fit (X, Y, Extrapolate => True);
      Xs : constant array (1 .. 5) of Float :=
        [0.0, 1.0, 3.0, 5.0, 7.0];
      Match : Boolean := True;
   begin
      Check (F.Success and F.T.N = 1, "Two-knot Fit");
      for K in Xs'Range loop
         declare
            Ev : constant Eval_Result := Evaluate (F.T, Xs (K));
            Tp : constant Eval_Result :=
              Interpolate_Two_Points (1.0, 3.0, 5.0, 11.0, Xs (K));
         begin
            if not Ev.Success or else not Tp.Success
              or else not Approx (Ev.Value, Tp.Value, 1.0E-5)
            then
               Match := False;
            end if;
         end;
      end loop;
      Check (Match, "Evaluate ≡ Interpolate_Two_Points");
   end;

   ---------------------------------------------------------------------
   Section ("14. Large table (Max_Points) / Cap");
   ---------------------------------------------------------------------
   declare
      P : constant Points :=
        Make_Linear_Data (Max_Points, 0.0, 63.0, 0.0, 126.0);
      F : constant Fit_Result := Fit (P);
      E : Eval_Result;
      Ok_Nodes : Boolean := True;
   begin
      Check (P'Length = Max_Points, "Max_Points length");
      Check (F.Success and F.T.N = Max_Points - 1, "Max Fit ok");
      for I in P'Range loop
         E := Evaluate (F.T, P (I).X);
         if not E.Success or else not Approx (E.Value, P (I).Y, 1.0E-3)
         then
            Ok_Nodes := False;
         end if;
      end loop;
      Check (Ok_Nodes, "All Max_Points nodes exact");
      E := Evaluate (F.T, 31.5);
      Check (E.Success and Approx (E.Value, 63.0, 1.0E-3),
             "Midpoint on large linear table");
   end;

   ---------------------------------------------------------------------
   Section ("15. Status enum coverage");
   ---------------------------------------------------------------------
   declare
      S_Arr : constant array (1 .. 6) of Status :=
        [Ok, Duplicate_Or_Unordered, Too_Few_Points,
         Out_Of_Domain, Ill_Started, Singular];
      Distinct : Boolean := True;
   begin
      for I in S_Arr'Range loop
         for J in S_Arr'Range loop
            if I /= J and then S_Arr (I) = S_Arr (J) then
               Distinct := False;
            end if;
         end loop;
      end loop;
      Check (Distinct, "All Status values distinct");
      Check (Status'Pos (Ok) = 0, "Status'Pos Ok=0");
      Check (Status'Pos (Singular) = 5, "Status'Pos Singular=5");
      Check (Status'Image (Ok) = "OK", "Status'Image Ok");
      Check (Status'Image (Singular) = "SINGULAR", "Status'Image Singular");
      Check (Status'Image (Duplicate_Or_Unordered) = "DUPLICATE_OR_UNORDERED",
             "Status'Image Duplicate_Or_Unordered");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("===============================");
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
