--  Standalone test suite for Kalman_Filter (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Elementary_Functions;
with Kalman_Filter; use Kalman_Filter;

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
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   --  Tiny deterministic LCG for reproducible noise (mod 2^31-1).
   Seed : Natural := 12345;
   Modulus : constant Natural := 2147483647;  --  2^31 - 1

   function Next_Unit return Real is
      --  Park-Miller step without overflowing Integer multiply:
      --  use Long_Integer intermediate.
      S : Long_Integer := Long_Integer (Seed);
   begin
      S := (S * 16807) mod Long_Integer (Modulus);
      Seed := Natural (S);
      return Real (Seed) / Real (Modulus);
   end Next_Unit;

   function Next_Gauss return Real is
      U1, U2 : Real;
      use Ada.Numerics.Elementary_Functions;
      Two_Pi : constant Float := 6.283185307179586;
   begin
      U1 := Next_Unit;
      if U1 < 1.0E-12 then
         U1 := 1.0E-12;
      end if;
      U2 := Next_Unit;
      return Real (Sqrt (-2.0 * Log (Float (U1)))
                     * Cos (Two_Pi * Float (U2)));
   end Next_Gauss;

begin
   Put_Line ("Kalman_Filter test suite");
   Put_Line ("========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Identity / Zero helpers");
   ---------------------------------------------------------------------
   declare
      I2 : constant Matrix := Identity (2);
      Zv : constant Vector := Zero_Vector (3);
      Zm : constant Matrix := Zero_Matrix (2, 3);
      Raised : Boolean := False;
   begin
      Check (Near (1.0, 1.0 + 1.0E-9), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Approx (I2 (1, 1), 1.0) and then Approx (I2 (2, 2), 1.0),
             "Identity diagonal ones");
      Check (Approx (I2 (1, 2), 0.0) and then Approx (I2 (2, 1), 0.0),
             "Identity off-diagonal zeros");
      Check (Approx (Zv (1), 0.0) and then Approx (Zv (3), 0.0),
             "Zero_Vector elements 0");
      Check (Approx (Zm (1, 1), 0.0) and then Approx (Zm (2, 3), 0.0),
             "Zero_Matrix elements 0");
      begin
         declare
            Unused : Matrix := Identity (0);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Identity(0) raises");
   end;

   ---------------------------------------------------------------------
   Section ("2. Matrix multiply / transpose / add");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 2.0], [3.0, 4.0]];
      B : constant Matrix (1 .. 2, 1 .. 2) :=
        [[0.0, 1.0], [1.0, 0.0]];
      A_T : constant Matrix := Transpose (A);
      AB : constant Matrix := A * B;
      ApB : constant Matrix := A + B;
      V : constant Vector (1 .. 2) := [1.0, 0.0];
      AV : constant Vector := A * V;
   begin
      Check (Approx (A_T (1, 2), 3.0) and then Approx (A_T (2, 1), 2.0),
             "Transpose swaps (1,2)");
      Check (Approx (AB (1, 1), 2.0) and then Approx (AB (1, 2), 1.0),
             "A*B row1");
      Check (Approx (AB (2, 1), 4.0) and then Approx (AB (2, 2), 3.0),
             "A*B row2");
      Check (Approx (ApB (1, 1), 1.0) and then Approx (ApB (1, 2), 3.0),
             "A+B");
      Check (Approx (AV (1), 1.0) and then Approx (AV (2), 3.0),
             "A*v first column");
      Check (Approx (Scale (V, 2.0) (1), 2.0), "Scale vector");
      Check (Approx (Scale (A, 0.5) (2, 2), 2.0), "Scale matrix");
   end;

   ---------------------------------------------------------------------
   Section ("3. Solve / Invert small SPD");
   ---------------------------------------------------------------------
   declare
      S : constant Matrix (1 .. 2, 1 .. 2) :=
        [[4.0, 1.0], [1.0, 3.0]];
      Inv : constant Matrix := Invert (S);
      Prod : constant Matrix := S * Inv;
      RHS : constant Matrix (1 .. 2, 1 .. 1) :=
        [1 => [1 => 5.0], 2 => [1 => 5.0]];
      X : constant Matrix := Solve (S, RHS);
      Raised : Boolean := False;
   begin
      Check (Approx (Prod (1, 1), 1.0, 1.0E-5)
               and then Approx (Prod (2, 2), 1.0, 1.0E-5),
             "S * Invert(S) ~ I diag");
      Check (Approx (Prod (1, 2), 0.0, 1.0E-5)
               and then Approx (Prod (2, 1), 0.0, 1.0E-5),
             "S * Invert(S) ~ I off");
      --  4x+y=5, x+3y=5 => x=10/11, y=15/11
      Check (Approx (X (1, 1), 10.0 / 11.0, 1.0E-5), "Solve x=10/11");
      Check (Approx (X (2, 1), 15.0 / 11.0, 1.0E-5), "Solve y=15/11");
      begin
         declare
            Singular : constant Matrix (1 .. 2, 1 .. 2) :=
              [[1.0, 2.0], [2.0, 4.0]];
            Unused : Matrix := Invert (Singular);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Invert singular raises Degenerate_Geometry");
   end;

   ---------------------------------------------------------------------
   Section ("4. Scalar predict hand-checked formulas");
   ---------------------------------------------------------------------
   declare
      St : Scalar_State := (X => 2.0, P => 3.0);
   begin
      Scalar_Predict (St, F => 2.0, B => 1.0, U => 4.0, Q => 0.5);
      Check (Approx (St.X, 8.0), "Scalar_Predict x=8");
      Check (Approx (St.P, 12.5), "Scalar_Predict P=12.5");

      St := (X => 1.0, P => 1.0);
      Scalar_Predict (St, F => 1.0, B => 0.0, U => 0.0, Q => 0.0);
      Check (Approx (St.X, 1.0) and then Approx (St.P, 1.0),
             "Identity predict leaves state");

      St := (X => 5.0, P => 2.0);
      Scalar_Predict (St, F => 0.0, B => 3.0, U => 2.0, Q => 1.0);
      Check (Approx (St.X, 6.0), "Predict with F=0 uses B u");
      Check (Approx (St.P, 1.0), "Predict F=0 => P=Q");
   end;

   ---------------------------------------------------------------------
   Section ("5. Scalar update with known numbers");
   ---------------------------------------------------------------------
   declare
      St : Scalar_State := (X => 0.0, P => 1.0);
      Y, K : Real;
   begin
      Scalar_Update (St, Z => 2.0, H => 1.0, R => 1.0,
                     Innovation => Y, Gain => K);
      Check (Approx (Y, 2.0), "Innovation y=2");
      Check (Approx (K, 0.5), "Gain K=0.5");
      Check (Approx (St.X, 1.0), "Updated x=1");
      Check (Approx (St.P, 0.5), "Joseph P=0.5");

      Scalar_Update (St, Z => 1.0, H => 1.0, R => 1.0,
                     Innovation => Y, Gain => K);
      Check (Approx (Y, 0.0), "Second innovation 0");
      Check (Approx (K, 1.0 / 3.0), "Second gain 1/3");
      Check (Approx (St.X, 1.0), "x unchanged when y=0");
      Check (Approx (St.P, 1.0 / 3.0), "P = 1/3 after 2nd update");
   end;

   ---------------------------------------------------------------------
   Section ("6. Scalar_Step = predict then update");
   ---------------------------------------------------------------------
   declare
      A, B : Scalar_State := (X => 1.0, P => 4.0);
      Y1, K1, Y2, K2 : Real;
   begin
      Scalar_Step (A, F => 1.0, B => 0.0, U => 0.0, Q => 1.0,
                   Z => 3.0, H => 1.0, R => 1.0,
                   Innovation => Y1, Gain => K1);
      Scalar_Predict (B, 1.0, 0.0, 0.0, 1.0);
      Scalar_Update (B, 3.0, 1.0, 1.0, Y2, K2);
      Check (Approx (A.X, B.X) and then Approx (A.P, B.P),
             "Scalar_Step matches Predict+Update state");
      Check (Approx (Y1, Y2) and then Approx (K1, K2),
             "Scalar_Step matches innovation/gain");
      Check (Approx (A.X, 8.0 / 3.0), "Step x = 8/3");
      Check (Approx (A.P, 5.0 / 6.0), "Step P = 5/6");
   end;

   ---------------------------------------------------------------------
   Section ("7. Joseph P stays non-negative (scalar SPD)");
   ---------------------------------------------------------------------
   declare
      St : Scalar_State := (X => 0.0, P => 10.0);
      Y, K : Real;
      All_Nonneg : Boolean := True;
   begin
      for I in 1 .. 20 loop
         Scalar_Step (St, F => 1.0, B => 0.0, U => 0.0, Q => 0.01,
                      Z => 0.0, H => 1.0, R => 0.5,
                      Innovation => Y, Gain => K);
         if St.P < -1.0E-12 then
            All_Nonneg := False;
         end if;
      end loop;
      Check (All_Nonneg, "Joseph keeps P >= 0 over 20 steps");
      Check (St.P > 0.0, "P remains strictly positive with Q>0");
      Check (St.P < 10.0, "P decreased from large prior");
   end;

   ---------------------------------------------------------------------
   Section ("8. Constant signal + noise: mean converges");
   ---------------------------------------------------------------------
   declare
      True_Level : constant Real := 5.0;
      St : Scalar_State := (X => 0.0, P => 100.0);
      Y, K : Real;
      Z : Real;
      Sum_X : Real := 0.0;
      N_Avg : constant Positive := 40;
   begin
      Seed := 99;
      for I in 1 .. 80 loop
         Z := True_Level + 0.5 * Next_Gauss;
         Scalar_Step (St, F => 1.0, B => 0.0, U => 0.0, Q => 1.0E-4,
                      Z => Z, H => 1.0, R => 0.25,
                      Innovation => Y, Gain => K);
         if I > 40 then
            Sum_X := Sum_X + St.X;
         end if;
      end loop;
      Check (abs (Sum_X / Real (N_Avg) - True_Level) < 0.35,
             "Filter mean near true level 5");
      Check (abs (St.X - True_Level) < 0.8,
             "Final estimate within ~0.8 of truth");
      Check (St.P < 1.0, "Posterior variance shrunk");
   end;

   ---------------------------------------------------------------------
   Section ("9. Perfect measurement R→0 pulls estimate to z");
   ---------------------------------------------------------------------
   declare
      St : Scalar_State := (X => 10.0, P => 1.0);
      Y, K : Real;
   begin
      Scalar_Update (St, Z => 3.0, H => 1.0, R => 1.0E-18,
                     Innovation => Y, Gain => K);
      Check (Approx (St.X, 3.0, 1.0E-5), "R~0 pulls x to z=3");
      Check (Approx (K, 1.0, 1.0E-5), "R~0 => K~1");
      Check (St.P < 1.0E-6, "R~0 => P~0");
   end;

   ---------------------------------------------------------------------
   Section ("10. Static model Q=0: variance decreases");
   ---------------------------------------------------------------------
   declare
      St : Scalar_State := (X => 0.0, P => 4.0);
      Y, K : Real;
      Prev_P : Real;
      Decreased : Boolean := True;
   begin
      for I in 1 .. 8 loop
         Prev_P := St.P;
         Scalar_Step (St, F => 1.0, B => 0.0, U => 0.0, Q => 0.0,
                      Z => 1.0, H => 1.0, R => 1.0,
                      Innovation => Y, Gain => K);
         if St.P >= Prev_P - 1.0E-15 then
            Decreased := False;
         end if;
      end loop;
      Check (Decreased, "Each update with Q=0 reduces P");
      Check (St.P < 0.5, "P well below initial 4");
      Check (Approx (St.X, 1.0, 0.2), "Estimate near repeated z=1");
   end;

   ---------------------------------------------------------------------
   Section ("11. Singular R=0 & H=0 edge raises");
   ---------------------------------------------------------------------
   declare
      St : Scalar_State := (X => 1.0, P => 0.0);
      Y, K : Real;
      Raised : Boolean := False;
   begin
      begin
         Scalar_Update (St, Z => 5.0, H => 0.0, R => 0.0,
                        Innovation => Y, Gain => K);
      exception
         when Degenerate_Geometry =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "H=0 R=0 P=0 raises Degenerate_Geometry");

      Raised := False;
      St := (X => 0.0, P => 1.0);
      begin
         Scalar_Predict (St, F => 1.0, B => 0.0, U => 0.0, Q => -1.0);
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Q<0 raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("12. Innovation residual typically shrinks after update");
   ---------------------------------------------------------------------
   declare
      St : Scalar_State := (X => 0.0, P => 2.0);
      Y, K : Real;
      Pre_Abs, Post_Abs : Real;
      Z : constant Real := 4.0;
      H : constant Real := 1.0;
   begin
      Pre_Abs := abs (Z - H * St.X);
      Scalar_Update (St, Z => Z, H => H, R => 1.0,
                     Innovation => Y, Gain => K);
      Post_Abs := abs (Z - H * St.X);
      Check (Approx (abs (Y), Pre_Abs),
             "Innovation equals pre-fit residual");
      Check (Post_Abs < Pre_Abs, "Post-fit |residual| < pre-fit");
      Check (Post_Abs < 2.0, "Post-fit residual moderate");
   end;

   ---------------------------------------------------------------------
   Section ("13. 2-D identity / constant-velocity-lite step");
   ---------------------------------------------------------------------
   declare
      St : Filter_State (N => 2);
      Mdl : Model (N => 2, M => 1);
      Z : Vector (1 .. 1);
      Inn : Vector (1 .. 1);
      G : Matrix (1 .. 2, 1 .. 1);
      Dt : constant Real := 1.0;
   begin
      Mdl.F := [[1.0, Dt], [0.0, 1.0]];
      Mdl.H := [1 => [1.0, 0.0]];
      Mdl.Q := [[0.01, 0.0], [0.0, 0.01]];
      Mdl.R := [1 => [1 => 0.25]];
      Mdl.Has_Control := False;
      St.X := [0.0, 1.0];
      St.P := Identity (2);

      Z := [1 => 1.2];
      Filter_Step (St, Mdl, Z, Inn, G);
      Check (St.X (1) > 0.5 and then St.X (1) < 1.5,
             "2-D pos estimate near measurement");
      Check (abs (St.X (2) - 1.0) < 0.5, "Velocity still near 1");
      Check (St.P (1, 1) < 1.0, "Pos variance reduced");
      Check (G'Length (1) = 2 and then G'Length (2) = 1,
             "Gain shape 2x1");

      declare
         St2 : Filter_State (N => 2);
         M2 : Model (N => 2, M => 2);
         Z2 : constant Vector (1 .. 2) := [3.0, 4.0];
         Inn2 : Vector (1 .. 2);
         G2 : Matrix (1 .. 2, 1 .. 2);
      begin
         M2.F := Identity (2);
         M2.H := Identity (2);
         M2.Q := Scale (Identity (2), 0.0);
         M2.R := Identity (2);
         M2.Has_Control := False;
         St2.X := [0.0, 0.0];
         St2.P := Scale (Identity (2), 4.0);
         Filter_Step (St2, M2, Z2, Inn2, G2);
         Check (Approx (St2.X (1), 2.4, 0.1)
                  and then Approx (St2.X (2), 3.2, 0.1),
                "Identity 2-D blends prior 0 with z (K=0.8)");
         Check (Approx (St2.X (1), 0.8 * 3.0) and then
                Approx (St2.X (2), 0.8 * 4.0),
                "Exact K=0.8 blend");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("14. Vector predict with control B u");
   ---------------------------------------------------------------------
   declare
      St : Filter_State (N => 2);
      F : constant Matrix (1 .. 2, 1 .. 2) := Identity (2);
      Q : constant Matrix (1 .. 2, 1 .. 2) :=
        Scale (Identity (2), 0.1);
      B : constant Matrix (1 .. 2, 1 .. 1) :=
        [1 => [1 => 1.0], 2 => [1 => 0.0]];
      U : constant Vector (1 .. 1) := [1 => 2.0];
   begin
      St.X := [1.0, 3.0];
      St.P := Identity (2);
      Predict (St, F, Q, B, U, Use_B => True);
      Check (Approx (St.X (1), 3.0), "Control adds B u to x1");
      Check (Approx (St.X (2), 3.0), "x2 unchanged by B");
      Check (Approx (St.P (1, 1), 1.1), "P <- P+Q diag");
   end;

   ---------------------------------------------------------------------
   Section ("15. Multi-step random-walk RMSE vs raw measurements");
   ---------------------------------------------------------------------
   declare
      True_X : Real := 0.0;
      St : Scalar_State := (X => 0.0, P => 1.0);
      Y, K, Z, Noise : Real;
      Squared_Err_Filt : Real := 0.0;
      Squared_Err_Raw  : Real := 0.0;
      Steps : constant Positive := 100;
      Rmse_F, Rmse_R : Real;
      use Ada.Numerics.Elementary_Functions;
   begin
      Seed := 2026;
      for I in 1 .. Steps loop
         True_X := True_X + 0.1 * Next_Gauss;
         Noise := 1.0 * Next_Gauss;
         Z := True_X + Noise;
         Scalar_Step (St, F => 1.0, B => 0.0, U => 0.0, Q => 0.05,
                      Z => Z, H => 1.0, R => 1.0,
                      Innovation => Y, Gain => K);
         Squared_Err_Filt := Squared_Err_Filt + (St.X - True_X) ** 2;
         Squared_Err_Raw  := Squared_Err_Raw  + (Z - True_X) ** 2;
      end loop;
      Rmse_F := Real (Sqrt (Float (Squared_Err_Filt / Real (Steps))));
      Rmse_R := Real (Sqrt (Float (Squared_Err_Raw / Real (Steps))));
      Check (Rmse_F < Rmse_R, "Filter RMSE < raw measurement RMSE");
      Check (Rmse_F < 1.2, "Filter RMSE reasonable (<1.2)");
      Check (Rmse_R > 0.5, "Raw RMSE reflects measurement noise");
      Put_Line ("  info: RMSE_filter=" & Rmse_F'Image
                & " RMSE_raw=" & Rmse_R'Image);
   end;

   ---------------------------------------------------------------------
   Section ("16. Vector Joseph keeps diagonal non-negative");
   ---------------------------------------------------------------------
   declare
      St : Filter_State (N => 2);
      Mdl : Model (N => 2, M => 1);
      Z : Vector (1 .. 1);
      Inn : Vector (1 .. 1);
      G : Matrix (1 .. 2, 1 .. 1);
      Ok : Boolean := True;
   begin
      Mdl.F := Identity (2);
      Mdl.H := [1 => [1.0, 0.0]];
      Mdl.Q := Scale (Identity (2), 0.05);
      Mdl.R := [1 => [1 => 0.5]];
      Mdl.Has_Control := False;
      St.X := [0.0, 0.0];
      St.P := Scale (Identity (2), 5.0);
      Seed := 7;
      for I in 1 .. 15 loop
         Z := [1 => Next_Gauss];
         Filter_Step (St, Mdl, Z, Inn, G);
         if St.P (1, 1) < -1.0E-9 or else St.P (2, 2) < -1.0E-9 then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "Vector Joseph P diagonal >= 0");
      Check (St.P (1, 1) < 5.0, "Pos variance reduced from 5");
   end;

   ---------------------------------------------------------------------
   Section ("17. Capacity / dimension edge cases");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean := False;
      St1 : Filter_State (N => 1);
      F : constant Matrix (1 .. 1, 1 .. 1) := [1 => [1 => 1.0]];
      Q : constant Matrix (1 .. 1, 1 .. 1) := [1 => [1 => 0.0]];
   begin
      St1.X := [1 => 0.0];
      St1.P := [1 => [1 => 1.0]];
      Predict (St1, F, Q);
      Check (Approx (St1.X (1), 0.0), "1-D vector predict ok");

      declare
         Inn : Vector (1 .. 1);
         G : Matrix (1 .. 1, 1 .. 1);
         H : constant Matrix (1 .. 1, 1 .. 1) := [1 => [1 => 1.0]];
         R : constant Matrix (1 .. 1, 1 .. 1) := [1 => [1 => 1.0]];
         Z : constant Vector (1 .. 1) := [1 => 2.0];
      begin
         Update (St1, Z, H, R, Inn, G);
         Check (Approx (St1.X (1), 1.0), "1-D vector update x=1");
         Check (Approx (St1.P (1, 1), 0.5), "1-D Joseph P=0.5");
      end;

      begin
         declare
            Bad : constant Matrix (1 .. 2, 1 .. 2) :=
              [[0.0, 0.0], [0.0, 0.0]];
            Unused : Matrix := Invert (Bad);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Invert(0) raises Degenerate_Geometry");
   end;

   New_Line;
   Put_Line ("================================");
   Put_Line ("Passed :" & Pass_Count'Image);
   Put_Line ("Failed :" & Fail_Count'Image);
   Put_Line ("================================");
   pragma Assert (Fail_Count = 0);
end Tests;
