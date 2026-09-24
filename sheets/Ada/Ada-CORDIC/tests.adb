--  Standalone test suite for Cordic (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Cordic; use Cordic;

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

   function Close
     (A, B : Long_Float; Tol : Long_Float := 1.0E-9) return Boolean
   is
   begin
      return abs (A - B) <= Tol
        or else abs (A - B) <= Tol * (1.0 + abs (B));
   end Close;

begin
   Ada.Text_IO.Put_Line ("Cordic test suite");
   Ada.Text_IO.Put_Line ("=================");

   ---------------------------------------------------------------------
   Section ("1. Near / Abs_Error / Rel_Error helpers");
   ---------------------------------------------------------------------
   declare
      E, R : Long_Float;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects far");
      Check (Near (0.0, 0.0), "Near zeros");
      E := Abs_Error (3.0, 1.0);
      Check (Close (E, 2.0), "Abs_Error 3-1");
      Check (Close (Abs_Error (1.0, 1.0), 0.0), "Abs_Error zero");
      Check (Close (Abs_Error (-1.0, 1.0), 2.0), "Abs_Error signed");
      R := Rel_Error (5.1, 5.0);
      Check (Close (R, 0.02, 1.0E-12), "Rel_Error 5.1 vs 5");
      Check (Close (Rel_Error (0.0, 0.0), 0.0), "Rel_Error 0/0");
      Check (Rel_Error (1.0, 0.0) > 1.0E20, "Rel_Error nonzero/0 sentinel");
   end;

   ---------------------------------------------------------------------
   Section ("2. Angle reduce / arctan table / gain");
   ---------------------------------------------------------------------
   declare
      A : Long_Float;
      T0, T1 : Long_Float;
      K40, IK40 : Long_Float;
   begin
      Check (Close (Reduce_Angle (0.0), 0.0), "Reduce 0");
      Check (Close (Reduce_Angle (Pi), Pi), "Reduce +π stays π");
      Check (Close (Reduce_Angle (-Pi), Pi, 1.0E-12)
               or else Close (Reduce_Angle (-Pi), -Pi, 1.0E-12),
             "Reduce −π maps to ±π boundary");
      A := Reduce_Angle (Two_Pi + Quarter_Pi);
      Check (Close (A, Quarter_Pi, 1.0E-12), "Reduce 2π+π/4 → π/4");
      A := Reduce_Angle (-Two_Pi - Quarter_Pi);
      Check (Close (A, -Quarter_Pi, 1.0E-12), "Reduce −2π−π/4 → −π/4");
      A := Reduce_Angle (3.0 * Pi);
      Check (Close (A, Pi, 1.0E-10) or else Close (A, -Pi, 1.0E-10),
             "Reduce 3π → ±π");

      T0 := Arctan_Table (0);
      Check (Close (T0, Quarter_Pi, 1.0E-12), "θ_0 = arctan(1) = π/4");
      T1 := Arctan_Table (1);
      Check (Close (T1, Exact_Arctan (0.5), 1.0E-14), "θ_1 = arctan(1/2)");
      Check (Arctan_Table (2) < T1, "θ_i decreasing");
      Check (Arctan_Table (10) < Arctan_Table (5), "θ_10 < θ_5");

      IK40 := Inv_Gain_K (40);
      K40 := Gain_K (40);
      Check (Close (IK40, Inv_K_Inf, 1.0E-10), "1/K_40 ≈ Inv_K_Inf (=A_∞)");
      Check (Close (K40, K_Inf, 1.0E-10), "K_40 ≈ K_Inf");
      Check (Close (K40 * IK40, 1.0, 1.0E-12), "K * 1/K = 1");
      Check (Close (Inv_Gain_K (1), 1.0 / Exact_Cos (Quarter_Pi), 1.0E-12),
             "1/K_1 = 1/cos(π/4) = √2");
      Check (Inv_Gain_K (2) > Inv_Gain_K (1), "A_n=1/K grows toward A_∞");
      Check (Gain_K (5) < Gain_K (3), "K_n shrinks toward K_∞");
   end;

   ---------------------------------------------------------------------
   Section ("3. Sin_Cos canonical angles (0, π/6, π/4, π/2)");
   ---------------------------------------------------------------------
   declare
      S, C : Long_Float;
      Sqrt3_2 : constant Long_Float := 0.866_025_403_784_438_6;
      Sqrt2_2 : constant Long_Float := 0.707_106_781_186_547_6;
   begin
      Sin_Cos (0.0, S, C);
      Check (Close (S, 0.0, 1.0E-12), "sin 0 = 0");
      Check (Close (C, 1.0, 1.0E-12), "cos 0 = 1");

      Sin_Cos (Half_Pi, S, C);
      Check (Close (S, 1.0, 1.0E-10), "sin π/2 = 1");
      Check (Close (C, 0.0, 1.0E-10), "cos π/2 = 0");

      Sin_Cos (Quarter_Pi, S, C);
      Check (Close (S, Sqrt2_2, 1.0E-10), "sin π/4 = √2/2");
      Check (Close (C, Sqrt2_2, 1.0E-10), "cos π/4 = √2/2");

      Sin_Cos (Pi / 6.0, S, C);
      Check (Close (S, 0.5, 1.0E-10), "sin π/6 = 1/2");
      Check (Close (C, Sqrt3_2, 1.0E-10), "cos π/6 = √3/2");

      Sin_Cos (-Quarter_Pi, S, C);
      Check (Close (S, -Sqrt2_2, 1.0E-10), "sin −π/4");
      Check (Close (C, Sqrt2_2, 1.0E-10), "cos −π/4");

      Sin_Cos (-Half_Pi, S, C);
      Check (Close (S, -1.0, 1.0E-10), "sin −π/2 = −1");
      Check (Close (C, 0.0, 1.0E-10), "cos −π/2 = 0");

      Check (Close (Sin (0.0), 0.0, 1.0E-12), "Sin(0) wrapper");
      Check (Close (Cos (0.0), 1.0, 1.0E-12), "Cos(0) wrapper");
      Check (Close (Sin (Pi / 6.0), 0.5, 1.0E-10), "Sin(π/6) wrapper");
      Check (Close (Cos (Pi / 6.0), Sqrt3_2, 1.0E-10), "Cos(π/6) wrapper");
   end;

   ---------------------------------------------------------------------
   Section ("4. sin²+cos² ≈ 1 identity");
   ---------------------------------------------------------------------
   declare
      S, C, N2 : Long_Float;
      Angles : constant array (Positive range <>) of Long_Float :=
        [0.0, Pi / 6.0, Quarter_Pi, Pi / 3.0, Half_Pi,
         2.0 * Pi / 3.0, Pi, -Quarter_Pi, -Half_Pi, -Pi,
         1.0, -2.5, Two_Pi + 0.3];
   begin
      for A of Angles loop
         Sin_Cos (A, S, C);
         N2 := S * S + C * C;
         Check (Close (N2, 1.0, 1.0E-9),
                "sin²+cos²≈1 at angle sample");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("5. Sin_Cos vs Elementary_Functions oracle");
   ---------------------------------------------------------------------
   declare
      S, C : Long_Float;
      Angles : constant array (Positive range <>) of Long_Float :=
        [0.0, 0.5, 1.0, Half_Pi, 2.0, Pi,
         -0.5, -1.0, -Half_Pi, -Pi,
         Pi + 0.3, 4.0, -4.0, 10.0];
      Ok : Boolean;
   begin
      for A of Angles loop
         Sin_Cos (A, S, C);
         Ok := Close (S, Exact_Sin (A), 1.0E-9)
           and then Close (C, Exact_Cos (A), 1.0E-9);
         Check (Ok, "Sin_Cos matches oracle sample");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("6. Iteration count sensitivity");
   ---------------------------------------------------------------------
   declare
      S8, C8, S40, C40 : Long_Float;
      Err8, Err40 : Long_Float;
   begin
      Sin_Cos (Quarter_Pi, S8, C8, Iterations => 8);
      Sin_Cos (Quarter_Pi, S40, C40, Iterations => 40);
      Err8 := Abs_Error (S8, Exact_Sin (Quarter_Pi));
      Err40 := Abs_Error (S40, Exact_Sin (Quarter_Pi));
      Check (Err40 < Err8, "more iterations → smaller sin error");
      Check (Close (S40, Exact_Sin (Quarter_Pi), 1.0E-12),
             "40 iters very accurate at π/4");
      Check (Abs_Error (S8, Exact_Sin (Quarter_Pi)) < 1.0E-2,
             "8 iters still reasonable");

      Sin_Cos (1.0, S8, C8, Iterations => 4);
      Sin_Cos (1.0, S40, C40, Iterations => 32);
      Check (Abs_Error (S40, Exact_Sin (1.0))
               < Abs_Error (S8, Exact_Sin (1.0)),
             "32 iters beats 4 iters at 1 rad");
   end;

   ---------------------------------------------------------------------
   Section ("7. Quadrant coverage for Sin_Cos");
   ---------------------------------------------------------------------
   declare
      S, C : Long_Float;
   begin
      --  Q1
      Sin_Cos (0.3, S, C);
      Check (S > 0.0 and then C > 0.0, "Q1 signs");
      --  Q2
      Sin_Cos (2.0, S, C);
      Check (S > 0.0 and then C < 0.0, "Q2 signs");
      --  Q3
      Sin_Cos (-2.0, S, C);
      Check (S < 0.0 and then C < 0.0, "Q3 signs");
      --  Q4
      Sin_Cos (-0.3, S, C);
      Check (S < 0.0 and then C > 0.0, "Q4 signs");
      --  π
      Sin_Cos (Pi, S, C);
      Check (Close (S, 0.0, 1.0E-9), "sin π ≈ 0");
      Check (Close (C, -1.0, 1.0E-9), "cos π ≈ −1");
   end;

   ---------------------------------------------------------------------
   Section ("8. Atan2 quadrants and axes");
   ---------------------------------------------------------------------
   declare
      A : Long_Float;
   begin
      A := Atan2 (0.0, 1.0);
      Check (Close (A, 0.0, 1.0E-10), "atan2(0,1)=0");
      A := Atan2 (1.0, 0.0);
      Check (Close (A, Half_Pi, 1.0E-9), "atan2(1,0)=π/2");
      A := Atan2 (0.0, -1.0);
      Check (Close (A, Pi, 1.0E-9), "atan2(0,−1)=π");
      A := Atan2 (-1.0, 0.0);
      Check (Close (A, -Half_Pi, 1.0E-9), "atan2(−1,0)=−π/2");

      A := Atan2 (1.0, 1.0);
      Check (Close (A, Quarter_Pi, 1.0E-9), "atan2(1,1)=π/4");
      A := Atan2 (1.0, -1.0);
      Check (Close (A, 3.0 * Quarter_Pi, 1.0E-9), "atan2(1,−1)=3π/4");
      A := Atan2 (-1.0, -1.0);
      Check (Close (A, -3.0 * Quarter_Pi, 1.0E-9), "atan2(−1,−1)=−3π/4");
      A := Atan2 (-1.0, 1.0);
      Check (Close (A, -Quarter_Pi, 1.0E-9), "atan2(−1,1)=−π/4");

      Check (Close (Atan2 (0.0, 0.0), 0.0), "atan2(0,0)=0 educational");
   end;

   ---------------------------------------------------------------------
   Section ("9. Atan2 vs Exact_Atan2 oracle");
   ---------------------------------------------------------------------
   declare
      type XY is record
         Y, X : Long_Float;
      end record;
      Samples : constant array (Positive range <>) of XY :=
        [(Y => 0.0, X => 1.0), (Y => 1.0, X => 0.0),
         (Y => 0.0, X => -1.0), (Y => -1.0, X => 0.0),
         (Y => 1.0, X => 1.0), (Y => 1.0, X => -1.0),
         (Y => -1.0, X => -1.0), (Y => -1.0, X => 1.0),
         (Y => 3.0, X => 4.0), (Y => -0.7, X => 0.2)];
      Ok : Boolean;
      A  : Long_Float;
   begin
      for S of Samples loop
         A := Atan2 (S.Y, S.X);
         Ok := Close (A, Exact_Atan2 (S.Y, S.X), 1.0E-8);
         Check (Ok, "Atan2 matches Exact_Atan2 sample");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. Magnitude (3,4)=5 and friends");
   ---------------------------------------------------------------------
   declare
      M : Long_Float;
   begin
      M := Magnitude (3.0, 4.0);
      Check (Close (M, 5.0, 1.0E-9), "|(3,4)|=5");
      M := Magnitude (4.0, 3.0);
      Check (Close (M, 5.0, 1.0E-9), "|(4,3)|=5");
      M := Magnitude (-3.0, 4.0);
      Check (Close (M, 5.0, 1.0E-9), "|(−3,4)|=5");
      M := Magnitude (3.0, -4.0);
      Check (Close (M, 5.0, 1.0E-9), "|(3,−4)|=5");
      M := Magnitude (-3.0, -4.0);
      Check (Close (M, 5.0, 1.0E-9), "|(−3,−4)|=5");
      M := Magnitude (0.0, 0.0);
      Check (Close (M, 0.0), "|(0,0)|=0");
      M := Magnitude (5.0, 0.0);
      Check (Close (M, 5.0, 1.0E-10), "|(5,0)|=5");
      M := Magnitude (0.0, 5.0);
      Check (Close (M, 5.0, 1.0E-10), "|(0,5)|=5");
      M := Magnitude (1.0, 1.0);
      Check (Close (M, Exact_Hypot (1.0, 1.0), 1.0E-9), "|√2|");
      M := Magnitude (6.0, 8.0);
      Check (Close (M, 10.0, 1.0E-9), "|(6,8)|=10");
   end;

   ---------------------------------------------------------------------
   Section ("11. Magnitude vs Exact_Hypot grid");
   ---------------------------------------------------------------------
   declare
      Ok : Boolean;
      M  : Long_Float;
      Xs : constant array (Positive range <>) of Long_Float :=
        [-5.0, 0.0, 1.0, 5.0];
      Ys : constant array (Positive range <>) of Long_Float :=
        [-4.0, 0.0, 3.0];
   begin
      for X of Xs loop
         for Y of Ys loop
            M := Magnitude (X, Y);
            Ok := Close (M, Exact_Hypot (X, Y), 1.0E-8);
            Check (Ok, "Magnitude vs Hypot grid cell");
         end loop;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("12. Cross-check: atan2(sin,cos) ≈ reduce(angle)");
   ---------------------------------------------------------------------
   declare
      S, C, A, R : Long_Float;
      Angles : constant array (Positive range <>) of Long_Float :=
        [0.0, 0.4, Quarter_Pi, Half_Pi - 0.05,
         -0.4, -Quarter_Pi, -Half_Pi + 0.05];
   begin
      for Ang of Angles loop
         Sin_Cos (Ang, S, C);
         A := Atan2 (S, C);
         R := Reduce_Angle (Ang);
         --  After fold, angles near ±π/2 are fine; stay inside cone samples
         Check (Close (A, R, 1.0E-7), "atan2(sin,cos) recovers angle");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("13. Constants sanity");
   ---------------------------------------------------------------------
   declare
      --  Touch constants through table / API so the compiler cannot fold
      --  the equality into a static True (avoids -gnatwc / -gnatwk).
      A0 : constant Long_Float := Arctan_Table (0);
      IK : constant Long_Float := Inv_Gain_K (Default_Iterations);
      GK : constant Long_Float := Gain_K (Default_Iterations);
   begin
      Check (Close (A0, Quarter_Pi, 1.0E-12), "table θ_0 vs Quarter_Pi const");
      Check (Close (IK * GK, 1.0, 1.0E-12), "Default_Iterations gain pair");
      Check (Close (IK, Inv_K_Inf, 1.0E-9), "Default A_n ≈ Inv_K_Inf");
      Check (Close (Pi, Exact_Arctan (1.0) * 4.0, 1.0E-14), "Pi vs 4·arctan1");
      Check (Close (Half_Pi, Pi / 2.0, 1.0E-15), "Half_Pi");
      Check (Close (Two_Pi, 2.0 * Pi, 1.0E-15), "Two_Pi");
      Check (Close (Quarter_Pi, Pi / 4.0, 1.0E-15), "Quarter_Pi");
      Check (Close (Inv_K_Inf * K_Inf, 1.0, 1.0E-12), "Inv_K_Inf * K_Inf");
      Check (Close (Abs_Error (Sin (1.0), Exact_Sin (1.0)), 0.0, 1.0E-9),
             "Abs_Error Sin vs oracle ~0");
   end;

   ---------------------------------------------------------------------
   Section ("14. Extra rotation samples / gain table monotonicity");
   ---------------------------------------------------------------------
   declare
      Prev : Long_Float := Inv_Gain_K (1);
      S, C : Long_Float;
   begin
      for N in Iteration_Count range 2 .. 6 loop
         Check (Inv_Gain_K (N) >= Prev - 1.0E-15,
                "Inv_Gain_K (=A_n) monotone non-decreasing");
         Prev := Inv_Gain_K (N);
      end loop;
      Sin_Cos (Pi / 3.0, S, C);
      Check (Close (S, Exact_Sin (Pi / 3.0), 1.0E-9), "sin π/3");
      Check (Close (C, 0.5, 1.0E-9), "cos π/3 = 1/2");
      Sin_Cos (2.0 * Pi / 3.0, S, C);
      Check (Close (S, Exact_Sin (2.0 * Pi / 3.0), 1.0E-9), "sin 2π/3");
      Check (Close (C, Exact_Cos (2.0 * Pi / 3.0), 1.0E-9), "cos 2π/3");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("----------------------------------------");
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
