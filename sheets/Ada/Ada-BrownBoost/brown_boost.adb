with Ada.Numerics.Generic_Elementary_Functions;

package body Brown_Boost is

   package Value_Math is new Ada.Numerics.Generic_Elementary_Functions (Value_Type);
   use Value_Math;

   Pi : constant Value_Type := 3.14159_26535_89793_23846;

   -- Approximation for the error function (A&S 7.1.26)
   function Erf (X : Value_Type) return Value_Type is
      P  : constant Value_Type := 0.3275911;
      A1 : constant Value_Type := 0.254829592;
      A2 : constant Value_Type := -0.284496736;
      A3 : constant Value_Type := 1.421413741;
      A4 : constant Value_Type := -1.453152027;
      A5 : constant Value_Type := 1.061405429;
      Sign : constant Value_Type := (if X < 0.0 then -1.0 else 1.0);
      Abs_X : constant Value_Type := abs X;
      T  : constant Value_Type := 1.0 / (1.0 + P * Abs_X);
      Y  : Value_Type;
   begin
      Y := 1.0 - ((((A5 * T + A4) * T + A3) * T + A2) * T + A1) * T * Exp (-Abs_X * Abs_X);
      return Sign * Y;
   end Erf;

   -- Loss function potential evaluated by BrownBoost
   function Phi (Z, C : Value_Type) return Value_Type is
   begin
      return 1.0 - Erf (Z / Sqrt (C));
   end Phi;

   -- Helper to iterate all possible thresholds and find the best stump
   procedure Find_Best_Stump
     (Features : Feature_Matrix;
      Labels   : Label_Array;
      Weights  : in Feature_Vector;
      Best     : out Decision_Stump;
      Max_Adv  : out Value_Type)
   is
      Adv, Thresh, Pred, Y, Dir : Value_Type;
   begin
      Max_Adv := -1.0;
      Best := (Feature => Features'First (2), Threshold => 0.0, Direction => 1.0);

      for F in Features'Range (2) loop
         for I in Features'Range (1) loop
            Thresh := Features (I, F);
            for D in 1 .. 2 loop
               Dir := (if D = 1 then 1.0 else -1.0);
               Adv := 0.0;
               for J in Features'Range (1) loop
                  Y := (if Labels (J) = Label_Positive then 1.0 else -1.0);
                  Pred := (if Features (J, F) * Dir >= Thresh * Dir then 1.0 else -1.0);
                  Adv := Adv + Weights (J) * Pred * Y;
               end loop;
               if Adv > Max_Adv then
                  Max_Adv := Adv;
                  Best := (Feature => F, Threshold => Thresh, Direction => Dir);
               end if;
            end loop;
         end loop;
      end loop;
   end Find_Best_Stump;

   -- Bisection substep to resolve Alpha analytically when U is locked
   function Solve_Alpha
     (Z, R : in Feature_Vector;
      U, C : Value_Type) return Value_Type
   is
      Low_A  : Value_Type := 0.0;
      High_A : Value_Type := 1.0;
      Mid_A, F_Mid : Value_Type;
      
      function F1 (A : Value_Type) return Value_Type is
         Sum : Value_Type := 0.0;
      begin
         for I in Z'Range loop
            Sum := Sum + Z (I) * Exp (- ((R (I) + A * Z (I) + U)**2) / C);
         end loop;
         return Sum;
      end F1;
   begin
      if F1 (0.0) <= 0.0 then
         return 0.0;
      end if;

      while F1 (High_A) > 0.0 loop
         High_A := High_A * 2.0;
         if High_A > 1000.0 then return High_A; end if;
      end loop;

      for I in 1 .. 50 loop
         Mid_A := (Low_A + High_A) / 2.0;
         F_Mid := F1 (Mid_A);
         if F_Mid > 0.0 then
            Low_A := Mid_A;
         else
            High_A := Mid_A;
         end if;
      end loop;
      return (Low_A + High_A) / 2.0;
   end Solve_Alpha;

   -- Solver Variant 1: JBoost's Bisection approach
   procedure Solve_Bisection
     (Features : Feature_Matrix;
      Labels   : Label_Array;
      Margins  : in Feature_Vector;
      Stump    : Decision_Stump;
      S, C     : Value_Type;
      Alpha, T : out Value_Type)
   is
      V_Target : Value_Type := 0.0;
      Low_U, High_U, Mid_U : Value_Type;
      V_Mid, A_Mid : Value_Type;
      Z : Feature_Vector (Features'Range (1));
   begin
      for I in Features'Range (1) loop
         declare
            Pred : constant Value_Type :=
               (if Features (I, Stump.Feature) * Stump.Direction >= Stump.Threshold * Stump.Direction
                then 1.0 else -1.0);
            Y : constant Value_Type := (if Labels (I) = Label_Positive then 1.0 else -1.0);
         begin
            Z (I) := Pred * Y;
            V_Target := V_Target + Phi (Margins (I) + S, C);
         end;
      end loop;

      Low_U := 0.0;
      High_U := S;
      Mid_U := S;
      A_Mid := 0.0;

      for Iter in 1 .. 50 loop
         Mid_U := (Low_U + High_U) / 2.0;
         A_Mid := Solve_Alpha (Z, Margins, Mid_U, C);
         
         V_Mid := 0.0;
         for I in Features'Range (1) loop
            V_Mid := V_Mid + Phi (Margins (I) + A_Mid * Z (I) + Mid_U, C);
         end loop;
         
         -- Phi(z) is decreasing, so if V_Mid > V_Target, increase the argument U
         if V_Mid > V_Target then
            Low_U := Mid_U;
         else
            High_U := Mid_U;
         end if;
      end loop;

      Alpha := A_Mid;
      T := S - Mid_U;
      if T < 0.0001 then
          T := 0.0001; 
      end if;
   end Solve_Bisection;

   -- Solver Variant 2: Freund's original Newton Method approach
   procedure Solve_Newton
     (Features : Feature_Matrix;
      Labels   : Label_Array;
      Margins  : in Feature_Vector;
      Stump    : Decision_Stump;
      S, C     : Value_Type;
      Alpha, T : out Value_Type)
   is
      A_Curr, U_Curr : Value_Type;
      V_Target : Value_Type := 0.0;
      Z : Feature_Vector (Features'Range (1));
      F1, F2 : Value_Type;
      JA, JB, JD, J_Det, C_Jac : Value_Type;
      dA, dU : Value_Type;
      K : constant Value_Type := 2.0 / Sqrt (Pi * C);
   begin
      for I in Features'Range (1) loop
         declare
            Pred : constant Value_Type :=
               (if Features (I, Stump.Feature) * Stump.Direction >= Stump.Threshold * Stump.Direction
                then 1.0 else -1.0);
            Y : constant Value_Type := (if Labels (I) = Label_Positive then 1.0 else -1.0);
         begin
            Z (I) := Pred * Y;
            V_Target := V_Target + Phi (Margins (I) + S, C);
         end;
      end loop;

      A_Curr := 0.1;
      U_Curr := S * 0.9;

      for Iter in 1 .. 20 loop
         F1 := 0.0;
         F2 := -V_Target;
         JA := 0.0;
         JB := 0.0;
         JD := 0.0;

         for I in Features'Range (1) loop
            declare
               Arg : constant Value_Type := Margins (I) + A_Curr * Z (I) + U_Curr;
               E   : constant Value_Type := Exp (- (Arg**2) / C);
            begin
               F1 := F1 + Z (I) * E;
               F2 := F2 + Phi (Arg, C);
               JA := JA - (2.0 / C) * Arg * E;
               JB := JB - (2.0 / C) * Z (I) * Arg * E;
               JD := JD - K * E;
            end;
         end loop;

         C_Jac := -K * F1; 

         J_Det := JA * JD - JB * C_Jac;
         if abs (J_Det) < 1.0e-12 then
            exit;
         end if;

         dA := - (JD * F1 - JB * F2) / J_Det;
         dU := - (-C_Jac * F1 + JA * F2) / J_Det;

         A_Curr := A_Curr + dA;
         U_Curr := U_Curr + dU;

         if A_Curr < 0.0 then A_Curr := 0.0; end if;
         if U_Curr < 0.0 then U_Curr := 0.0; end if;
         if U_Curr > S then U_Curr := S; end if;

         exit when abs (dA) < 1.0e-5 and abs (dU) < 1.0e-5;
      end loop;

      Alpha := A_Curr;
      T := S - U_Curr;
      if T <= 0.0 then
          T := 0.0001;
      end if;
   end Solve_Newton;

   function Train
     (Features : Feature_Matrix;
      Labels   : Label_Array;
      C        : Value_Type;
      Variant  : Solver_Variant;
      Capacity : Positive := 100) return Ensemble_Model
   is
      M : Ensemble_Model (Capacity);
      S : Value_Type := C;
      Margins : Feature_Vector (Features'Range (1)) := [others => 0.0];
      Weights : Feature_Vector (Features'Range (1));
      Best_Stump : Decision_Stump;
      Max_Adv : Value_Type;
      Alpha, T : Value_Type;
   begin
      if Features'First (1) /= Labels'First then
         raise Invalid_Data;
      end if;

      while S > 0.0001 and M.Size < Capacity loop
         -- 1. Derive weights via exponential decay mapped to margins and time left
         declare
            Sum_W : Value_Type := 0.0;
            Max_E : Value_Type := -1.0e300;
         begin
            -- Utilize log-sum-exp stabilization to avoid underflow
            for I in Features'Range (1) loop
               declare
                  E : constant Value_Type := - ((Margins (I) + S)**2) / C;
               begin
                  if E > Max_E then
                     Max_E := E;
                  end if;
               end;
            end loop;

            for I in Features'Range (1) loop
               Weights (I) := Exp (- ((Margins (I) + S)**2) / C - Max_E);
               Sum_W := Sum_W + Weights (I);
            end loop;

            for I in Features'Range (1) loop
               Weights (I) := Weights (I) / Sum_W;
            end loop;
         end;

         -- 2. Extract optimal weak learner based on normalized weighting
         Find_Best_Stump (Features, Labels, Weights, Best_Stump, Max_Adv);
         if Max_Adv <= 0.0001 then
            exit;
         end if;

         -- 3. Solve constraint non-linear equation systems to discover step properties
         case Variant is
            when Bisection_Solver =>
               Solve_Bisection (Features, Labels, Margins, Best_Stump, S, C, Alpha, T);
            when Newton_Solver =>
               Solve_Newton (Features, Labels, Margins, Best_Stump, S, C, Alpha, T);
         end case;

         -- 4. Advance margins based on newly generated Alpha and model predictions
         for I in Features'Range (1) loop
            declare
               Pred : constant Value_Type :=
                  (if Features (I, Best_Stump.Feature) * Best_Stump.Direction >= Best_Stump.Threshold * Best_Stump.Direction
                   then 1.0 else -1.0);
               Y : constant Value_Type := (if Labels (I) = Label_Positive then 1.0 else -1.0);
            begin
               Margins (I) := Margins (I) + Alpha * Pred * Y;
            end;
         end loop;

         -- 5. Tick remaining time
         S := S - T;

         M.Size := M.Size + 1;
         M.Models (M.Size) := (Stump => Best_Stump, Alpha => Alpha);
      end loop;

      return M;
   end Train;

   function Predict
     (Model    : Ensemble_Model;
      Features : Feature_Vector) return Class_Label
   is
      Sum : Value_Type := 0.0;
   begin
      if Model.Size = 0 then
         return Label_Negative;
      end if;

      for I in 1 .. Model.Size loop
         declare
            Stump : Decision_Stump renames Model.Models (I).Stump;
            Alpha : Value_Type renames Model.Models (I).Alpha;
            P : constant Value_Type :=
               (if Features (Stump.Feature) * Stump.Direction >= Stump.Threshold * Stump.Direction
                then 1.0 else -1.0);
         begin
            Sum := Sum + Alpha * P;
         end;
      end loop;

      if Sum >= 0.0 then
         return Label_Positive;
      else
         return Label_Negative;
      end if;
   end Predict;

end Brown_Boost;
