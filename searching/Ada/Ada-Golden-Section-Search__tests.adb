with Ada.Command_Line;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Text_IO;
with Golden_Section_Search;

procedure Tests is
   use Ada.Numerics.Long_Elementary_Functions;
   use Ada.Text_IO;
   use Golden_Section_Search;

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   Tight : constant Search_Config :=
     (Tol => 1.0E-9, Max_Iterations => 200);

   procedure Check (Condition : Boolean; Name : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("FAIL: " & Name);
      end if;
   end Check;

   function Width (R : Search_Result) return Scalar is
     (R.Bracket.Right - R.Bracket.Left);

begin
   Put_Line ("Golden-section search test suite");

   Check (Near (Golden_Ratio, (1.0 + Sqrt (5.0)) / 2.0, 1.0E-14),
          "golden ratio formula");
   Check (Near (Tau, 1.0 / Golden_Ratio, 1.0E-14), "tau identities");
   Check (Near (Tau * Tau, 1.0 - Tau, 1.0E-14), "tau recurrence");
   Check (Near (2.0, 2.0), "Near equal");
   Check (not Near (2.0, 2.1, 0.01), "Near unequal");

   declare
      P : constant Probe_Pair := Golden_Probes (0.0, 10.0);
   begin
      Check (P.Lower > 0.0 and then P.Lower < P.Upper,
             "lower probe ordering");
      Check (P.Upper < 10.0, "upper probe ordering");
      Check (Near (P.Lower, 10.0 * (1.0 - Tau), 1.0E-13),
             "lower probe value");
      Check (Near (P.Upper, 10.0 * Tau, 1.0E-13),
             "upper probe value");
      Check (Near (P.Upper - P.Lower, 10.0 * (2.0 * Tau - 1.0),
                   1.0E-13), "probe separation");
   end;

   for I in 1 .. 24 loop
      declare
         Margin : constant Scalar := Scalar (I) / 10.0;
         R : constant Search_Result := Minimize
           (Quartic_Unimodal'Access, 1.5 - Margin, 1.5 + 2.0 * Margin,
            Tight);
      begin
         Check (Near (R.X_Star, 1.5, 2.0E-5),
                "quartic minimum" & Integer'Image (I));
         Check (R.F_Star <= 1.0E-10,
                "quartic value" & Integer'Image (I));
         Check (R.Bracket.Left <= R.X_Star
                and then R.X_Star <= R.Bracket.Right,
                "quartic result bracketed" & Integer'Image (I));
         Check (Width (R) <= Tight.Tol,
                "quartic tolerance" & Integer'Image (I));
      end;
   end loop;

   for I in 1 .. 24 loop
      declare
         Margin : constant Scalar := Scalar (I) / 8.0;
         R : constant Search_Result := Maximize
           (Negative_Quadratic_Max'Access, 3.0 - 2.0 * Margin,
            3.0 + Margin, Tight);
      begin
         Check (Near (R.X_Star, 3.0, 2.0E-5),
                "quadratic maximum" & Integer'Image (I));
         Check (R.F_Star >= -1.0E-10,
                "quadratic max value" & Integer'Image (I));
         Check (R.Iterations > 0,
                "maximum iterates" & Integer'Image (I));
      end;
   end loop;

   for I in 1 .. 16 loop
      declare
         Margin : constant Scalar := Scalar (I) / 5.0;
         R : constant Search_Result := Minimize
           (Sphere_On_Line'Access, 1.0 - Margin, 1.0 + Margin, Tight);
      begin
         Check (Near (R.X_Star, 1.0, 2.0E-5),
                "sphere line minimum" & Integer'Image (I));
         Check (R.F_Star <= 1.0E-9,
                "sphere line value" & Integer'Image (I));
      end;
   end loop;

   declare
      R1 : constant Search_Result := Minimize
        (Increasing_Boundary'Access, -4.0, 7.0, Tight);
      R2 : constant Search_Result := Maximize
        (Increasing_Boundary'Access, -4.0, 7.0, Tight);
      R3 : constant Search_Result := Minimize
        (Decreasing_Boundary'Access, -4.0, 7.0, Tight);
      R4 : constant Search_Result := Maximize
        (Decreasing_Boundary'Access, -4.0, 7.0, Tight);
   begin
      Check (Near (R1.X_Star, -4.0, Tight.Tol), "minimum left boundary");
      Check (Near (R2.X_Star, 7.0, Tight.Tol), "maximum right boundary");
      Check (Near (R3.X_Star, 7.0, Tight.Tol), "minimum right boundary");
      Check (Near (R4.X_Star, -4.0, Tight.Tol), "maximum left boundary");
      Check (R1.F_Star = -4.0, "left boundary value");
      Check (R3.F_Star = -7.0, "right boundary value");
   end;

   for I in 2 .. 12 loop
      declare
         Cfg : constant Search_Config :=
           (Tol => 1.0E-30, Max_Iterations => I);
         R : constant Search_Result := Minimize
           (Quartic_Unimodal'Access, 0.0, 3.0, Cfg);
         Bound : Scalar := 3.0;
      begin
         for K in 1 .. I loop
            Bound := Bound * Tau;
         end loop;
         Check (R.Iterations = I, "iteration cap" & Integer'Image (I));
         Check (Width (R) <= Bound * (1.0 + 1.0E-12),
                "geometric shrink" & Integer'Image (I));
      end;
   end loop;

   declare
      Loose : constant Search_Config :=
        (Tol => 1.0E-3, Max_Iterations => 200);
      Fine : constant Search_Config :=
        (Tol => 1.0E-8, Max_Iterations => 200);
      RL : constant Search_Result := Minimize
        (Quartic_Unimodal'Access, -2.0, 5.0, Loose);
      RF : constant Search_Result := Minimize
        (Quartic_Unimodal'Access, -2.0, 5.0, Fine);
   begin
      Check (Width (RF) < Width (RL), "smaller Tol shrinks more");
      Check (RF.Iterations > RL.Iterations, "smaller Tol iterates more");
      Check (Width (RL) <= Loose.Tol, "loose Tol reached");
      Check (Width (RF) <= Fine.Tol, "fine Tol reached");
   end;

   for I in 1 .. 12 loop
      declare
         Margin : constant Scalar := 1.0 + Scalar (I) / 4.0;
         R_Min : constant Search_Result := Fibonacci_Search
           (Quartic_Unimodal'Access, 1.5 - Margin, 1.5 + Margin,
            Find_Minimum, Tight);
         R_Max : constant Search_Result := Fibonacci_Search
           (Negative_Quadratic_Max'Access, 3.0 - Margin, 3.0 + Margin,
            Find_Maximum, Tight);
      begin
         Check (Near (R_Min.X_Star, 1.5, 3.0E-5),
                "Fibonacci minimum" & Integer'Image (I));
         Check (Near (R_Max.X_Star, 3.0, 3.0E-5),
                "Fibonacci maximum" & Integer'Image (I));
         Check (Width (R_Min) <= 2.0 * Tight.Tol,
                "Fibonacci bracket" & Integer'Image (I));
      end;
   end loop;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            R : constant Search_Result := Minimize
              (Quartic_Unimodal'Access, 1.0, 1.0, Tight);
         begin
            Check (R.Iterations = Natural'Last, "unreachable invalid equal");
         end;
      exception
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, "reject A = B");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            R : constant Search_Result := Maximize
              (Negative_Quadratic_Max'Access, 2.0, -2.0, Tight);
         begin
            Check (R.Iterations = Natural'Last, "unreachable reversed");
         end;
      exception
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, "reject A > B");
   end;

   declare
      Raised : Boolean := False;
      Bad : constant Search_Config :=
        (Tol => 0.0, Max_Iterations => 10);
   begin
      begin
         declare
            R : constant Search_Result := Minimize
              (Quartic_Unimodal'Access, 0.0, 3.0, Bad);
         begin
            Check (R.Iterations = Natural'Last, "unreachable zero Tol");
         end;
      exception
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, "reject zero Tol");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            P : constant Probe_Pair := Golden_Probes (2.0, 2.0);
         begin
            Check (P.Lower > P.Upper, "unreachable invalid probes");
         end;
      exception
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, "reject invalid probes");
   end;

   Put_Line ("Pass_Count=" & Natural'Image (Pass_Count));
   Put_Line ("Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count /= 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
