--  Standalone test suite for Monotone_Cubic_Interpolation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Monotone_Cubic_Interpolation; use Monotone_Cubic_Interpolation;

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
   Ada.Text_IO.Put_Line ("Monotone_Cubic_Interpolation test suite");
   Ada.Text_IO.Put_Line ("=======================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Lerp / Make_Point / Hermite basis");
   ---------------------------------------------------------------------
   declare
      P : constant Point := Make_Point (1.0, 2.0);
      Q : constant Point := Make_Point (1.0, 2.0 + 1.0E-8);
   begin
      Check (Near (1.0, 1.0), "Near equal floats");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny floats");
      Check (not Near (1.0, 2.0), "Near rejects floats");
      Check (Approx (Lerp (0.0, 10.0, 0.3), 3.0), "Lerp 0.3");
      Check (Approx (Lerp (2.0, 2.0, 0.7), 2.0), "Lerp equal");
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
      Check (Approx (H00 (0.5) + H01 (0.5), 1.0), "H00+H01 partition");
   end;

   ---------------------------------------------------------------------
   Section ("2. Strictly increasing / monotone samples / builders");
   ---------------------------------------------------------------------
   declare
      Good : constant Abscissae := [0.0, 1.0, 2.5, 4.0];
      Bad  : constant Abscissae := [0.0, 1.0, 1.0, 2.0];
      Dec  : constant Abscissae := [0.0, 2.0, 1.5];
      Y_Up : constant Ordinates := [0.0, 1.0, 2.0, 5.0];
      Y_Dn : constant Ordinates := [5.0, 2.0, 1.0, 0.0];
      Y_Nm : constant Ordinates := [0.0, 2.0, 1.0, 3.0];
      Lin  : constant Points := Make_Linear_Data (5, 0.0, 4.0, 1.0, 9.0);
      Ramp : constant Points := Make_Increasing_Ramp (6, 0.0, 1.0, 0.0, 10.0);
      Sig  : constant Points := Make_Sigmoid_Sample (7, -1.0, 1.0);
      NM   : constant Points := Make_Non_Monotone_Sample (9, 0.0, 1.0);
   begin
      Check (Is_Strictly_Increasing (Good), "Strict good");
      Check (not Is_Strictly_Increasing (Bad), "Reject equal");
      Check (not Is_Strictly_Increasing (Dec), "Reject decreasing");
      Check (Is_Monotone_Samples (Y_Up), "Monotone increasing Y");
      Check (Is_Monotone_Samples (Y_Dn), "Monotone decreasing Y");
      Check (not Is_Monotone_Samples (Y_Nm), "Reject non-monotone Y");
      Check (Lin'Length = 5, "Linear data length");
      Check (Approx (Lin (0).X, 0.0) and Approx (Lin (0).Y, 1.0),
             "Linear start (0,1)");
      Check (Approx (Lin (4).X, 4.0) and Approx (Lin (4).Y, 9.0),
             "Linear end (4,9)");
      Check (Approx (Lin (2).Y, 2.0 * Lin (2).X + 1.0),
             "Linear mid on y=2x+1");
      Check (Is_Monotone_Samples (Ramp), "Ramp monotone");
      Check (Is_Monotone_Samples (Sig), "Sigmoid monotone");
      Check (not Is_Monotone_Samples (NM), "Non-monotone sample");
      Check (Approx (Ramp (0).Y, 0.0) and Approx (Ramp (5).Y, 10.0),
             "Ramp endpoints");
      Check (Sig (0).Y < Sig (Sig'Last).Y, "Sigmoid rises");
   end;

   ---------------------------------------------------------------------
   Section ("3. Make_Example / Split_XY");
   ---------------------------------------------------------------------
   declare
      L : constant Points := Make_Example (Linear_Data);
      R : constant Points := Make_Example (Increasing_Ramp);
      S : constant Points := Make_Example (Sigmoid_Sample);
      N : constant Points := Make_Example (Non_Monotone_Sample);
      X : Abscissae (L'Range);
      Y : Ordinates (L'Range);
   begin
      Check (L'Length = 5, "Example Linear length");
      Check (R'Length = 8, "Example Ramp length");
      Check (S'Length = 9, "Example Sigmoid length");
      Check (N'Length = 9, "Example NonMonotone length");
      Check (Is_Monotone_Samples (L), "Example Linear monotone");
      Check (Is_Monotone_Samples (R), "Example Ramp monotone");
      Check (Is_Monotone_Samples (S), "Example Sigmoid monotone");
      Check (not Is_Monotone_Samples (N), "Example NonMonotone not");
      Split_XY (L, X, Y);
      Check (Approx (X (0), L (0).X) and Approx (Y (0), L (0).Y),
             "Split_XY first");
      Check (Approx (X (4), L (4).X) and Approx (Y (4), L (4).Y),
             "Split_XY last");
   end;

   ---------------------------------------------------------------------
   Section ("4. Fit validation: too few / not increasing / empty");
   ---------------------------------------------------------------------
   declare
      One_X : constant Abscissae := [0.0];
      One_Y : constant Ordinates := [1.0];
      Bad_X : constant Abscissae := [0.0, 1.0, 1.0];
      Bad_Y : constant Ordinates := [0.0, 1.0, 2.0];
      Mis_X : constant Abscissae := [0.0, 1.0];
      Mis_Y : constant Ordinates := [0.0, 1.0, 2.0];
      F1 : constant Fit_Result := Fit (One_X, One_Y);
      F2 : constant Fit_Result := Fit (Bad_X, Bad_Y);
      F3 : constant Fit_Result := Fit (Mis_X, Mis_Y);
   begin
      Check (not F1.Success and F1.Stat = Too_Few_Points,
             "Too few points");
      Check (not F2.Success and F2.Stat = Not_Strictly_Increasing,
             "Not strictly increasing");
      Check (not F3.Success and F3.Stat = Ill_Started,
             "Mismatched lengths → Ill_Started");
   end;

   ---------------------------------------------------------------------
   Section ("5. Nodes exact under monotone Fit");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Sigmoid_Sample);
      F : constant Fit_Result := Fit (P);
      E : Eval_Result;
   begin
      Check (F.Success and F.Stat = Ok, "Sigmoid Fit ok");
      Check (F.S.Valid and F.S.Kind = Monotone_Cubic, "Kind/valid");
      Check (F.S.N = 8, "Sigmoid N=8");
      for I in P'Range loop
         E := Evaluate (F.S, P (I).X);
         Check
           (E.Success and Approx (E.Value, P (I).Y, 1.0E-4),
            "Node exact i=" & Integer'Image (Integer (I - P'First)));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("6. Linear data: monotone cubic recovers the line");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Linear_Data);
      F : constant Fit_Result := Fit_Monotone (P);
      E : Eval_Result;
      Xs : constant array (1 .. 9) of Float :=
        [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0];
   begin
      Check (F.Success, "Linear-data Fit");
      for K in Xs'Range loop
         E := Evaluate (F.S, Xs (K));
         Check
           (E.Success and Approx (E.Value, 2.0 * Xs (K) + 1.0, 1.0E-4),
            "Linear recover x=" & Float'Image (Xs (K)));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("7. Monotone data → monotone dense samples");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Increasing_Ramp);
      F : constant Fit_Result := Fit (P);
      E_Prev, E_Cur : Eval_Result;
      Mono : Boolean := True;
      Xq : Float;
      Steps : constant := 40;
   begin
      Check (F.Success, "Ramp Fit");
      E_Prev := Evaluate (F.S, P (P'First).X);
      Check (E_Prev.Success, "Ramp first eval");
      for K in 1 .. Steps loop
         Xq := Float (K) / Float (Steps);  -- domain [0,1]
         E_Cur := Evaluate (F.S, Xq);
         if not E_Cur.Success
           or else E_Cur.Value + 1.0E-5 < E_Prev.Value
         then
            Mono := False;
         end if;
         E_Prev := E_Cur;
      end loop;
      Check (Mono, "Ramp dense samples monotone non-decreasing");
   end;

   declare
      P : constant Points := Make_Example (Sigmoid_Sample);
      F : constant Fit_Result := Fit (P);
      E_Prev, E_Cur : Eval_Result;
      Mono : Boolean := True;
      Xq : Float;
      Steps : constant := 50;
      X0 : constant Float := P (P'First).X;
      X1 : constant Float := P (P'Last).X;
   begin
      Check (F.Success, "Sigmoid Fit for dense mono");
      E_Prev := Evaluate (F.S, X0);
      for K in 1 .. Steps loop
         Xq := X0 + (X1 - X0) * Float (K) / Float (Steps);
         E_Cur := Evaluate (F.S, Xq);
         if not E_Cur.Success
           or else E_Cur.Value + 1.0E-5 < E_Prev.Value
         then
            Mono := False;
         end if;
         E_Prev := E_Cur;
      end loop;
      Check (Mono, "Sigmoid dense samples monotone");
   end;

   ---------------------------------------------------------------------
   Section ("8. Out of domain");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Increasing_Ramp);
      F : constant Fit_Result := Fit (P);
      E1 : constant Eval_Result := Evaluate (F.S, -0.1);
      E2 : constant Eval_Result := Evaluate (F.S, 1.1);
      E3 : constant Eval_Result := Evaluate (F.S, 0.5);
   begin
      Check (not E1.Success and E1.Stat = Out_Of_Domain, "OOD left");
      Check (not E2.Success and E2.Stat = Out_Of_Domain, "OOD right");
      Check (E3.Success and E3.Stat = Ok, "In domain mid");
      Check (not In_Domain (F.S, -0.1), "In_Domain false left");
      Check (In_Domain (F.S, 0.0), "In_Domain left end");
      Check (In_Domain (F.S, 1.0), "In_Domain right end");
   end;

   ---------------------------------------------------------------------
   Section ("9. Linear fitter vs monotone: no overshoot on monotone");
   ---------------------------------------------------------------------
   declare
      --  Steep-then-flat monotone data where unrestricted Hermite can
      --  overshoot; FC should stay in [ymin,ymax].
      X : constant Abscissae := [0.0, 1.0, 2.0, 3.0, 4.0];
      Y : constant Ordinates := [0.0, 0.0, 1.0, 1.0, 1.0];
      FM : constant Fit_Result := Fit_Monotone (X, Y);
      FL : constant Fit_Result := Fit_Linear (X, Y);
      FH : constant Fit_Result := Fit_Hermite_FD (X, Y);
      EM, EL : Eval_Result;
      Y_Min : constant Float := 0.0;
      Y_Max : constant Float := 1.0;
      Over : Boolean := False;
      Xq : Float;
   begin
      Check (FM.Success and FL.Success and FH.Success,
             "Three fitters ok on plateau data");
      Check (FM.S.Kind = Monotone_Cubic, "Monotone kind");
      Check (FL.S.Kind = Linear, "Linear kind");
      Check (FH.S.Kind = Finite_Difference_Hermite, "FD Hermite kind");

      for K in 0 .. 40 loop
         Xq := Float (K) / 10.0;  -- 0 .. 4
         EM := Evaluate (FM.S, Xq);
         if EM.Success then
            if EM.Value < Y_Min - 1.0E-4
              or else EM.Value > Y_Max + 1.0E-4
            then
               Over := True;
            end if;
         end if;
      end loop;
      Check (not Over, "Monotone Fit no overshoot outside [0,1]");

      --  Linear stays in range by construction
      declare
         Lin_Ok : Boolean := True;
      begin
         for K in 0 .. 40 loop
            Xq := Float (K) / 10.0;
            EL := Evaluate (FL.S, Xq);
            if not EL.Success
              or else EL.Value < Y_Min - 1.0E-5
              or else EL.Value > Y_Max + 1.0E-5
            then
               Lin_Ok := False;
            end if;
         end loop;
         Check (Lin_Ok, "Linear Fit stays in [0,1]");
      end;

      --  Compare midpoints: both should be between adjacent y
      EM := Evaluate (FM.S, 1.5);
      EL := Evaluate (FL.S, 1.5);
      Check (EM.Success and EL.Success, "Mid evals ok");
      Check (EM.Value >= 0.0 - 1.0E-4 and EM.Value <= 1.0 + 1.0E-4,
             "Monotone mid in range");
      Check (Approx (EL.Value, 0.5, 1.0E-4), "Linear mid = 0.5");
   end;

   ---------------------------------------------------------------------
   Section ("10. Decreasing monotone data");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Linear_Data (6, 0.0, 5.0, 10.0, 0.0);
      F : constant Fit_Result := Fit (P);
      E_Prev, E_Cur : Eval_Result;
      Mono : Boolean := True;
      Xq : Float;
   begin
      Check (F.Success, "Decreasing Fit");
      Check (Is_Monotone_Samples (P), "Decreasing samples monotone");
      E_Prev := Evaluate (F.S, 0.0);
      for K in 1 .. 30 loop
         Xq := 5.0 * Float (K) / 30.0;
         E_Cur := Evaluate (F.S, Xq);
         if not E_Cur.Success
           or else E_Cur.Value > E_Prev.Value + 1.0E-5
         then
            Mono := False;
         end if;
         E_Prev := E_Cur;
      end loop;
      Check (Mono, "Decreasing dense samples non-increasing");
   end;

   ---------------------------------------------------------------------
   Section ("11. Non-monotone data: Fit still works; nodes exact");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Non_Monotone_Sample);
      F : constant Fit_Result := Fit (P);
      E : Eval_Result;
   begin
      Check (F.Success, "Non-monotone Fit still succeeds");
      Check (not Is_Monotone_Samples (P), "Data not monotone");
      for I in P'Range loop
         E := Evaluate (F.S, P (I).X);
         Check
           (E.Success and Approx (E.Value, P (I).Y, 1.0E-4),
            "NM node exact i=" & Integer'Image (Integer (I - P'First)));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("12. Find_Interval / In_Domain / endpoints");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Linear_Data (4, 0.0, 3.0, 0.0, 3.0);
      F : constant Fit_Result := Fit (P);
      I0, I1, I2, I3 : Natural;
   begin
      Check (F.Success, "Interval Fit");
      I0 := Find_Interval (F.S, 0.0);
      I1 := Find_Interval (F.S, 1.5);
      I2 := Find_Interval (F.S, 2.0);
      I3 := Find_Interval (F.S, 3.0);
      Check (I0 = 0, "Interval at left end");
      Check (I1 = 1, "Interval mid");
      Check (I2 = 2, "Interval at knot");
      Check (I3 = 2, "Interval at right end → N-1");
      Check (Approx (Evaluate (F.S, 0.0).Value, 0.0), "Eval left");
      Check (Approx (Evaluate (F.S, 3.0).Value, 3.0), "Eval right");
   end;

   ---------------------------------------------------------------------
   Section ("13. Fit_Linear nodes and midpoints");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Linear_Data);
      F : constant Fit_Result := Fit_Linear (P);
      E : Eval_Result;
   begin
      Check (F.Success and F.S.Kind = Linear, "Fit_Linear ok");
      for I in P'Range loop
         E := Evaluate (F.S, P (I).X);
         Check
           (E.Success and Approx (E.Value, P (I).Y),
            "Linear node i=" & Integer'Image (Integer (I - P'First)));
      end loop;
      E := Evaluate (F.S, 0.5);
      Check (E.Success and Approx (E.Value, 2.0 * 0.5 + 1.0),
             "Linear mid 0.5");
   end;

   ---------------------------------------------------------------------
   Section ("14. Fit_Hermite_FD nodes exact");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Sigmoid_Sample);
      F : constant Fit_Result := Fit_Hermite_FD (P);
      E : Eval_Result;
   begin
      Check (F.Success and F.S.Kind = Finite_Difference_Hermite,
             "FD Hermite Fit");
      for I in P'Range loop
         E := Evaluate (F.S, P (I).X);
         Check
           (E.Success and Approx (E.Value, P (I).Y, 1.0E-4),
            "FD node i=" & Integer'Image (Integer (I - P'First)));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("15. Flat plateau: zero tangents at flat");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [0.0, 1.0, 2.0, 3.0];
      Y : constant Ordinates := [0.0, 1.0, 1.0, 2.0];
      F : constant Fit_Result := Fit (X, Y);
      E : Eval_Result;
   begin
      Check (F.Success, "Plateau Fit");
      --  Flat middle → m1 and m2 should be 0
      Check (Approx (F.S.M (1), 0.0, 1.0E-5), "m1=0 on flat");
      Check (Approx (F.S.M (2), 0.0, 1.0E-5), "m2=0 on flat");
      E := Evaluate (F.S, 1.5);
      Check (E.Success and Approx (E.Value, 1.0, 1.0E-4),
             "Flat mid stays 1");
      Check (Approx (Evaluate (F.S, 0.0).Value, 0.0), "Plateau left");
      Check (Approx (Evaluate (F.S, 3.0).Value, 2.0), "Plateau right");
   end;

   ---------------------------------------------------------------------
   Section ("16. Two-point edge case");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [0.0, 1.0];
      Y : constant Ordinates := [2.0, 5.0];
      F : constant Fit_Result := Fit (X, Y);
      E : Eval_Result;
   begin
      Check (F.Success and F.S.N = 1, "Two-point Fit");
      Check (Approx (F.S.M (0), 3.0) and Approx (F.S.M (1), 3.0),
             "Two-point tangents = δ");
      E := Evaluate (F.S, 0.5);
      Check (E.Success and Approx (E.Value, 3.5, 1.0E-4),
             "Two-point mid");
   end;

   ---------------------------------------------------------------------
   Section ("17. Points overloads / Fit alias");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Increasing_Ramp);
      F1 : constant Fit_Result := Fit (P);
      F2 : constant Fit_Result := Fit_Monotone (P);
      F3 : constant Fit_Result := Fit_Linear (P);
      F4 : constant Fit_Result := Fit_Hermite_FD (P);
   begin
      Check (F1.Success and F2.Success, "Fit / Fit_Monotone Points");
      Check (F3.Success and F4.Success, "Linear / FD Points");
      Check (F1.S.Kind = Monotone_Cubic and F2.S.Kind = Monotone_Cubic,
             "Alias same kind");
      Check (Approx (F1.S.M (0), F2.S.M (0))
               and Approx (F1.S.M (F1.S.N), F2.S.M (F2.S.N)),
             "Alias same end tangents");
   end;

   ---------------------------------------------------------------------
   Section ("18. Invalid Evaluate on unfitted spline");
   ---------------------------------------------------------------------
   declare
      S : Spline;
      E : constant Eval_Result := Evaluate (S, 0.0);
   begin
      Check (not E.Success and E.Stat = Ill_Started,
             "Unfitted → Ill_Started");
      Check (not In_Domain (S, 0.0), "Unfitted not in domain");
   end;

   ---------------------------------------------------------------------
   Section ("19. Larger sigmoid grid monotonicity");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Sigmoid_Sample (16, -3.0, 3.0);
      F : constant Fit_Result := Fit (P);
      E_Prev, E_Cur : Eval_Result;
      Mono : Boolean := True;
      X0 : constant Float := P (P'First).X;
      X1 : constant Float := P (P'Last).X;
      Xq : Float;
   begin
      Check (F.Success, "Large sigmoid Fit");
      Check (Is_Monotone_Samples (P), "Large sigmoid data mono");
      E_Prev := Evaluate (F.S, X0);
      for K in 1 .. 80 loop
         Xq := X0 + (X1 - X0) * Float (K) / 80.0;
         E_Cur := Evaluate (F.S, Xq);
         if not E_Cur.Success
           or else E_Cur.Value + 1.0E-4 < E_Prev.Value
         then
            Mono := False;
         end if;
         E_Prev := E_Cur;
      end loop;
      Check (Mono, "Large sigmoid dense monotone");
      --  Nodes
      for I in P'Range loop
         E_Cur := Evaluate (F.S, P (I).X);
         Check
           (E_Cur.Success and Approx (E_Cur.Value, P (I).Y, 1.0E-4),
            "Large node i=" & Integer'Image (Integer (I - P'First)));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("20. Status enum coverage");
   ---------------------------------------------------------------------
   declare
      S_Arr : constant array (1 .. 5) of Status :=
        [Ok, Not_Strictly_Increasing, Too_Few_Points,
         Out_Of_Domain, Ill_Started];
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
      Check (Status'Pos (Ill_Started) = 4, "Status'Pos Ill_Started=4");
      Check (Status'Image (Ok) = "OK", "Status'Image Ok");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("=======================================");
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
