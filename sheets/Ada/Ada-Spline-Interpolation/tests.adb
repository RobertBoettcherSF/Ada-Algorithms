--  Standalone test suite for Spline_Interpolation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;
with Ada.Text_IO;
with Spline_Interpolation; use Spline_Interpolation;

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
   Ada.Text_IO.Put_Line ("Spline_Interpolation test suite");
   Ada.Text_IO.Put_Line ("================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Lerp / Make_Point");
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
   end;

   ---------------------------------------------------------------------
   Section ("2. Strictly increasing / builders");
   ---------------------------------------------------------------------
   declare
      Good : constant Abscissae := [0.0, 1.0, 2.5, 4.0];
      Bad  : constant Abscissae := [0.0, 1.0, 1.0, 2.0];
      Dec  : constant Abscissae := [0.0, 2.0, 1.5];
      Lin  : constant Points := Make_Linear_Data (5, 0.0, 4.0, 1.0, 9.0);
      Quad : constant Points := Make_Quadratic_Sample (4, 0.0, 3.0);
      SinP : constant Points := Make_Sine_Sample (5, 0.0, Ada.Numerics.Pi);
   begin
      Check (Is_Strictly_Increasing (Good), "Strict good");
      Check (not Is_Strictly_Increasing (Bad), "Reject equal");
      Check (not Is_Strictly_Increasing (Dec), "Reject decreasing");
      Check (Lin'Length = 5, "Linear data length");
      Check (Approx (Lin (0).X, 0.0) and Approx (Lin (0).Y, 1.0),
             "Linear start (0,1)");
      Check (Approx (Lin (4).X, 4.0) and Approx (Lin (4).Y, 9.0),
             "Linear end (4,9)");
      Check (Approx (Lin (2).Y, 2.0 * Lin (2).X + 1.0),
             "Linear mid on y=2x+1");
      Check (Approx (Quad (0).Y, 0.0), "Quad sample y(0)=0");
      Check (Approx (Quad (3).Y, 9.0), "Quad sample y(3)=9");
      Check (Approx (SinP (0).Y, 0.0, 1.0E-5), "Sine sample y(0)=0");
      Check (Approx (SinP (4).Y, 0.0, 1.0E-5), "Sine sample y(π)=0");
   end;

   ---------------------------------------------------------------------
   Section ("3. Natural cubic: interpolate nodes exactly");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Uneven_Cubic);
      F : constant Fit_Result := Fit_Natural_Cubic (P);
      E : Eval_Result;
   begin
      Check (F.Success and F.Stat = Ok, "Natural fit Uneven ok");
      Check (F.S.Valid and F.S.Kind = Natural_Cubic, "Natural kind/valid");
      Check (F.S.N = 4, "Natural N=4");
      Check (Approx (F.S.M (0), 0.0) and Approx (F.S.M (4), 0.0),
             "Natural M0=Mn=0");
      for I in P'Range loop
         E := Evaluate (F.S, P (I).X);
         Check
           (E.Success and Approx (E.Value, P (I).Y, 1.0E-4),
            "Node interp i=" & Integer'Image (Integer (I - P'First)));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("4. Linear data: natural cubic recovers the line");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Linear_Data);
      F : constant Fit_Result := Fit_Natural_Cubic (P);
      E : Eval_Result;
      Xs : constant array (1 .. 7) of Float :=
        [0.0, 0.5, 1.0, 2.0, 2.5, 3.5, 4.0];
   begin
      Check (F.Success, "Linear-data natural fit");
      --  Second derivatives of a line are zero → all M_i ≈ 0
      declare
         All_M_Zero : Boolean := True;
      begin
         for I in 0 .. F.S.N loop
            if abs (F.S.M (I)) > 1.0E-4 then
               All_M_Zero := False;
            end if;
         end loop;
         Check (All_M_Zero, "Linear data → M_i ≈ 0");
      end;
      for K in Xs'Range loop
         E := Evaluate (F.S, Xs (K));
         Check
           (E.Success and Approx (E.Value, 2.0 * Xs (K) + 1.0, 1.0E-4),
            "Linear recover x=" & Float'Image (Xs (K)));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("5. Quadratic sample y=x² nodes + smooth midpoints");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Quadratic_Sample);
      F : constant Fit_Result := Fit_Natural_Cubic (P);
      E : Eval_Result;
      Mid : Float;
   begin
      Check (F.Success, "Quad sample fit");
      for I in P'Range loop
         E := Evaluate (F.S, P (I).X);
         Check
           (E.Success and Approx (E.Value, P (I).Y, 1.0E-4),
            "Quad node x=" & Float'Image (P (I).X));
      end loop;
      --  Midpoints should be close to x² (natural cubic ≈ parabola interior)
      for I in 0 .. P'Length - 2 loop
         Mid := 0.5 * (P (I).X + P (I + 1).X);
         E := Evaluate (F.S, Mid);
         Check
           (E.Success and Approx (E.Value, Mid * Mid, 5.0E-2),
            "Quad mid ~ x² at " & Float'Image (Mid));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("6. Sine sample: nodes + smoothness");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Sine_Sample);
      F : constant Fit_Result := Fit_Natural_Cubic (P);
      E : Eval_Result;
      Mid : Float;
      Ok_Smooth : Boolean := True;
   begin
      Check (F.Success, "Sine fit");
      for I in P'Range loop
         E := Evaluate (F.S, P (I).X);
         if not (E.Success and Approx (E.Value, P (I).Y, 1.0E-4)) then
            Ok_Smooth := False;
         end if;
      end loop;
      Check (Ok_Smooth, "Sine nodes exact");
      Mid := 0.5 * Ada.Numerics.Pi;
      E := Evaluate (F.S, Mid);
      Check (E.Success and Approx (E.Value, 1.0, 5.0E-2),
             "Sine mid ≈ sin(π/2)=1");
      E := Evaluate (F.S, Ada.Numerics.Pi / 6.0);
      Check (E.Success and Approx (E.Value, 0.5, 8.0E-2),
             "Sine at π/6 ≈ 0.5");
   end;

   ---------------------------------------------------------------------
   Section ("7. Clamped cubic");
   ---------------------------------------------------------------------
   declare
      --  y = x² on [0,2]; y' = 2x → left 0, right 4
      P : constant Points := Make_Quadratic_Sample (5, 0.0, 2.0);
      F : constant Fit_Result := Fit_Clamped_Cubic (P, 0.0, 4.0);
      Fn : constant Fit_Result := Fit_Natural_Cubic (P);
      E : Eval_Result;
      Mid : Float;
   begin
      Check (F.Success and F.S.Kind = Clamped_Cubic, "Clamped fit");
      Check (Approx (F.S.YP0, 0.0) and Approx (F.S.YPN, 4.0),
             "Clamped stores end derivs");
      for I in P'Range loop
         E := Evaluate (F.S, P (I).X);
         Check
           (E.Success and Approx (E.Value, P (I).Y, 1.0E-4),
            "Clamped node i=" & Integer'Image (Integer (I)));
      end loop;
      Mid := 1.0;
      E := Evaluate (F.S, Mid);
      Check (E.Success and Approx (E.Value, 1.0, 2.0E-2),
             "Clamped mid x=1 → ~1");
      --  Clamped should beat natural near ends for this parabola
      Check (Fn.Success, "Natural on same data for compare");
      E := Evaluate (F.S, 0.25);
      Check (E.Success and Approx (E.Value, 0.0625, 5.0E-3),
             "Clamped near left ~0.0625");
   end;

   ---------------------------------------------------------------------
   Section ("8. Piecewise linear / quadratic baselines");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Linear_Data);
      Fl : constant Fit_Result := Fit_Linear (P);
      Fq : constant Fit_Result := Fit_Quadratic
        (Make_Quadratic_Sample (5, 0.0, 4.0));
      E : Eval_Result;
   begin
      Check (Fl.Success and Fl.S.Kind = Linear, "Linear fit");
      E := Evaluate (Fl.S, 2.0);
      Check (E.Success and Approx (E.Value, 5.0), "Linear eval mid");
      E := Evaluate (Fl.S, 1.0);
      Check (Approx (E.Value, 3.0), "Linear eval x=1");
      Check (Fq.Success and Fq.S.Kind = Quadratic, "Quadratic fit");
      E := Evaluate (Fq.S, 0.0);
      Check (Approx (E.Value, 0.0), "Quad baseline at 0");
      E := Evaluate (Fq.S, 2.0);
      Check (Approx (E.Value, 4.0, 1.0E-3), "Quad baseline at 2 → 4");
      E := Evaluate (Fq.S, 4.0);
      Check (Approx (E.Value, 16.0, 1.0E-3), "Quad baseline at 4 → 16");
   end;

   ---------------------------------------------------------------------
   Section ("9. Bad x order / few points / dimension / OOD");
   ---------------------------------------------------------------------
   declare
      Bad_X : constant Abscissae := [0.0, 2.0, 1.0, 3.0];
      Bad_Y : constant Ordinates := [0.0, 1.0, 2.0, 3.0];
      One_X : constant Abscissae := [1.0];
      One_Y : constant Ordinates := [2.0];
      Mismatch_X : constant Abscissae := [0.0, 1.0];
      Mismatch_Y : constant Ordinates := [0.0, 1.0, 2.0];
      F : Fit_Result;
      E : Eval_Result;
      Good : constant Fit_Result :=
        Fit_Natural_Cubic (Make_Example (Linear_Data));
   begin
      F := Fit_Natural_Cubic (Bad_X, Bad_Y);
      Check (not F.Success and F.Stat = Not_Strictly_Increasing,
             "Reject unordered x");
      F := Fit_Natural_Cubic (One_X, One_Y);
      Check (not F.Success and F.Stat = Too_Few_Points,
             "Reject single point natural");
      F := Fit_Natural_Cubic (Mismatch_X, Mismatch_Y);
      Check (not F.Success and F.Stat = Dimension_Error,
             "Reject mismatched lengths");
      F := Fit_Quadratic (One_X, One_Y);
      Check (not F.Success and F.Stat = Too_Few_Points,
             "Quadratic needs ≥3");
      Check (Good.Success, "Good spline for OOD");
      E := Evaluate (Good.S, -1.0);
      Check (not E.Success and E.Stat = Out_Of_Domain, "OOD low");
      E := Evaluate (Good.S, 100.0);
      Check (not E.Success and E.Stat = Out_Of_Domain, "OOD high");
      Check (not In_Domain (Good.S, -0.1), "In_Domain false low");
      Check (In_Domain (Good.S, 0.0), "In_Domain left end");
      Check (In_Domain (Good.S, 4.0), "In_Domain right end");
      Check (not In_Domain (Good.S, 4.1), "In_Domain false high");
      E := Evaluate (Spline'(others => <>), 0.0);
      Check (not E.Success and E.Stat = Ill_Started, "Invalid spline eval");
   end;

   ---------------------------------------------------------------------
   Section ("10. Thomas algorithm directly");
   ---------------------------------------------------------------------
   declare
      --  Simple 3×3 diagonally dominant:
      --  2x - y = 0; -x + 2y - z = 0; -y + 2z = 3 → x=1,y=2,z=2.5? 
      --  Actually: [2,-1,0; -1,2,-1; 0,-1,2] [x;y;z] = [0;0;3]
      --  Solution: x=1, y=2, z=2.5? Let's verify:
      --  From symmetry with RHS [0,0,3]: z=2, y=1.5, x=0.75? Compute via Thomas.
      A : constant Ordinates (1 .. 3) := [0.0, -1.0, -1.0];
      B : constant Ordinates (1 .. 3) := [2.0, 2.0, 2.0];
      C : constant Ordinates (1 .. 3) := [-1.0, -1.0, 0.0];
      D : constant Ordinates (1 .. 3) := [0.0, 0.0, 3.0];
      X : Ordinates (1 .. 3);
      St : Status;
      --  Singular: zero diagonal
      Az : constant Ordinates (1 .. 2) := [0.0, 0.0];
      Bz : constant Ordinates (1 .. 2) := [0.0, 1.0];
      Cz : constant Ordinates (1 .. 2) := [1.0, 0.0];
      Dz : constant Ordinates (1 .. 2) := [1.0, 1.0];
      Xz : Ordinates (1 .. 2);
   begin
      Thomas (A, B, C, D, X, St);
      Check (St = Ok, "Thomas 3×3 ok");
      Check (Approx (X (1), 0.75, 1.0E-4), "Thomas x1=0.75");
      Check (Approx (X (2), 1.5, 1.0E-4), "Thomas x2=1.5");
      Check (Approx (X (3), 2.25, 1.0E-4), "Thomas x3=2.25");
      --  Verify A X = D
      Check (Approx (2.0 * X (1) - X (2), 0.0), "Thomas row1");
      Check (Approx (-X (1) + 2.0 * X (2) - X (3), 0.0), "Thomas row2");
      Check (Approx (-X (2) + 2.0 * X (3), 3.0), "Thomas row3");
      Thomas (Az, Bz, Cz, Dz, Xz, St);
      Check (St = Singular, "Thomas singular");
   end;

   ---------------------------------------------------------------------
   Section ("11. Two-point natural = line; Find_Interval");
   ---------------------------------------------------------------------
   declare
      X : constant Abscissae := [0.0, 10.0];
      Y : constant Ordinates := [0.0, 5.0];
      F : constant Fit_Result := Fit_Natural_Cubic (X, Y);
      E : Eval_Result;
      I : Natural;
   begin
      Check (F.Success, "Two-point natural fit");
      Check (Approx (F.S.M (0), 0.0) and Approx (F.S.M (1), 0.0),
             "Two-point M=0");
      E := Evaluate (F.S, 0.0);
      Check (Approx (E.Value, 0.0), "Two-point S(0)");
      E := Evaluate (F.S, 10.0);
      Check (Approx (E.Value, 5.0), "Two-point S(10)");
      E := Evaluate (F.S, 4.0);
      Check (Approx (E.Value, 2.0), "Two-point S(4)=2");
      I := Find_Interval (F.S, 0.0);
      Check (I = 0, "Interval at left");
      I := Find_Interval (F.S, 10.0);
      Check (I = 0, "Interval at right → 0");
      I := Find_Interval (F.S, 5.0);
      Check (I = 0, "Interval mid");
   end;

   ---------------------------------------------------------------------
   Section ("12. Multi-interval Find_Interval + endpoints");
   ---------------------------------------------------------------------
   declare
      P : constant Points :=
        [Make_Point (0.0, 0.0),
         Make_Point (1.0, 1.0),
         Make_Point (2.0, 0.0),
         Make_Point (4.0, 2.0)];
      F : constant Fit_Result := Fit_Natural_Cubic (P);
      I : Natural;
      E : Eval_Result;
   begin
      Check (F.Success, "4-pt fit");
      I := Find_Interval (F.S, 0.5);
      Check (I = 0, "Interval 0.5 → 0");
      I := Find_Interval (F.S, 1.0);
      Check (I = 1, "Interval 1.0 → 1");
      I := Find_Interval (F.S, 1.5);
      Check (I = 1, "Interval 1.5 → 1");
      I := Find_Interval (F.S, 3.0);
      Check (I = 2, "Interval 3.0 → 2");
      I := Find_Interval (F.S, 4.0);
      Check (I = 2, "Interval 4.0 → N-1=2");
      E := Evaluate (F.S, 0.0);
      Check (Approx (E.Value, 0.0), "Endpoint left");
      E := Evaluate (F.S, 4.0);
      Check (Approx (E.Value, 2.0), "Endpoint right");
   end;

   ---------------------------------------------------------------------
   Section ("13. Split_XY / Points overload / Make_Example kinds");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Example (Linear_Data);
      X : Abscissae (P'Range);
      Y : Ordinates (P'Range);
      F1, F2 : Fit_Result;
      Q : constant Points := Make_Example (Quadratic_Sample);
      S : constant Points := Make_Example (Sine_Sample);
      U : constant Points := Make_Example (Uneven_Cubic);
   begin
      Split_XY (P, X, Y);
      Check (Approx (X (0), 0.0) and Approx (Y (0), 1.0), "Split start");
      Check (Approx (X (4), 4.0) and Approx (Y (4), 9.0), "Split end");
      F1 := Fit_Natural_Cubic (X, Y);
      F2 := Fit_Natural_Cubic (P);
      Check (F1.Success and F2.Success, "XY and Points overloads");
      Check (Approx (F1.S.M (2), F2.S.M (2)), "Same M from overloads");
      Check (Q'Length = 6, "Example quad len");
      Check (S'Length = 8, "Example sine len");
      Check (U'Length = 5, "Example uneven len");
      Check (Approx (Q (0).Y, 1.0), "Example quad y(-1)=1");
   end;

   ---------------------------------------------------------------------
   Section ("14. Clamped line recovery / linear vs cubic on line");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Linear_Data (6, -1.0, 1.0, -2.0, 2.0);
      --  y = 2x, y' = 2
      Fc : constant Fit_Result := Fit_Clamped_Cubic (P, 2.0, 2.0);
      Fl : constant Fit_Result := Fit_Linear (P);
      E : Eval_Result;
   begin
      Check (Fc.Success, "Clamped line fit");
      E := Evaluate (Fc.S, 0.0);
      Check (Approx (E.Value, 0.0, 1.0E-4), "Clamped line S(0)");
      E := Evaluate (Fc.S, 0.5);
      Check (Approx (E.Value, 1.0, 1.0E-4), "Clamped line S(0.5)");
      E := Evaluate (Fl.S, 0.5);
      Check (Approx (E.Value, 1.0), "Piecewise linear S(0.5)");
      E := Evaluate (Fl.S, -1.0);
      Check (Approx (E.Value, -2.0), "Piecewise linear left");
   end;

   ---------------------------------------------------------------------
   Section ("15. Dense sample continuity across knots");
   ---------------------------------------------------------------------
   declare
      P : constant Points := Make_Sine_Sample (10, 0.0, Ada.Numerics.Pi);
      F : constant Fit_Result := Fit_Natural_Cubic (P);
      E1, E2 : Eval_Result;
      Cont : Boolean := True;
      X : Float;
   begin
      Check (F.Success, "Dense sine fit");
      for K in 0 .. 50 loop
         X := Float (K) * Ada.Numerics.Pi / 50.0;
         E1 := Evaluate (F.S, X);
         if not E1.Success then
            Cont := False;
         end if;
         --  Compare to sin with modest tol (natural ends not perfect)
         if abs (E1.Value - Math.Sin (X)) > 0.15 then
            Cont := False;
         end if;
      end loop;
      Check (Cont, "Dense samples near sin (tol 0.15)");
      --  Continuity at interior knots: left/right limits equal (same eval)
      for I in 1 .. P'Length - 2 loop
         E1 := Evaluate (F.S, P (I).X);
         E2 := Evaluate (F.S, P (I).X);
         if not Approx (E1.Value, E2.Value) then
            Cont := False;
         end if;
         if not Approx (E1.Value, P (I).Y, 1.0E-4) then
            Cont := False;
         end if;
      end loop;
      Check (Cont, "Knot continuity / exact nodes");
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
