--------------------------------------------------------------------------------
-- Package Body Alopex (ISO/IEC 8652:2023 Ada)
--------------------------------------------------------------------------------

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Numerics.Float_Random;

package body Alopex is

   -- Generic math instantiation for high-precision domain type
   package Math is new Ada.Numerics.Generic_Elementary_Functions (Weight_Type);

   -- Helper: Generate Gaussian random variable using Box-Muller transform
   function Random_Normal
     (Gen : in out Ada.Numerics.Float_Random.Generator;
      Mean : Weight_Type;
      StdDev : Temperature_Type) return Weight_Type
   is
      use Ada.Numerics.Float_Random;
      U1, U2 : Float;
      R      : Float;
      Pi     : constant Float := 3.14159265358979323846;
   begin
      -- Guard against zero log argument
      loop
         U1 := Float(Random(Gen));
         exit when U1 > 0.0;
      end loop;
      U2 := Float(Random(Gen));

      R := Sqrt (-2.0 * Log (U1)) * Cos (2.0 * Pi * U2);
      return Mean + Weight_Type(R) * Weight_Type(StdDev);
   end Random_Normal;

   -- Helper function: Euclidean Norm
   function Euclidean_Norm (V : Weight_Vector) return Weight_Type is
      Sum : Weight_Type := 0.0;
   begin
      for X of V loop
         Sum := Sum + X * X;
      end loop;
      return Math.Sqrt (Sum);
   end Euclidean_Norm;

   -- Core ALOPEX engine shared by variants
   procedure Core_Optimize
     (Initial_Weights   : in Weight_Vector;
      Objective         : not null access function (W : Weight_Vector) return Cost_Type;
      Max_Iterations    : in Positive;
      Learning_Rate     : in Learning_Rate_Type;
      Initial_Temp      : in Temperature_Type;
      Has_Cooling       : in Boolean;
      Cooling_Rate      : in Temperature_Type;
      Is_Minimization   : in Boolean;
      Final_Weights     : out Weight_Vector;
      Best_Cost         : out Cost_Type;
      Iterations_Run    : out Natural)
   is
      use Ada.Numerics.Float_Random;

      Gen          : Generator;
      Current_W    : Weight_Vector := Initial_Weights;
      Delta_W      : Weight_Vector (Initial_Weights'Range) := [others => 0.0];

      Current_R    : Cost_Type;
      Prev_R       : Cost_Type;
      Delta_R      : Cost_Type;

      Best_W       : Weight_Vector := Initial_Weights;
      Current_Temp : Temperature_Type := Initial_Temp;

      Effective_LR : Learning_Rate_Type := Learning_Rate;
   begin
      if Initial_Weights'Length = 0 then
         raise Empty_Vector_Error with "Initial weights vector cannot be empty.";
      end if;

      -- Evaluate initial objective
      begin
         Current_R := Objective (Current_W);
      exception
         when others =>
            raise Invalid_Parameter_Error with "Objective function raised an exception on initial weights.";
      end;

      Best_Cost := Current_R;
      Best_W := Current_W;
      Prev_R := Current_R;

      -- Set learning rate sign based on optimization goal
      if Is_Minimization and then Effective_LR > 0.0 then
         Effective_LR := -Effective_LR;
      elsif not Is_Minimization and then Effective_LR < 0.0 then
         Effective_LR := -Effective_LR;
      end if;

      -- Main ALOPEX iteration loop
      for Iter in 1 .. Max_Iterations loop
         Iterations_Run := Iter;

         -- Step 1: Generate stochastic perturbation vector r_i(n) ~ N(0, T^2)
         declare
            R_Vector : Weight_Vector(Current_W'Range);
         begin
            for I in R_Vector'Range loop
               R_Vector(I) := Random_Normal (Gen, 0.0, Current_Temp);
            end loop;

            -- Step 2: Compute new weights
            -- For n = 1 (first iteration), Delta_W is zero or initial perturbation
            if Iter = 1 then
               for I in Current_W'Range loop
                  Delta_W(I) := R_Vector(I);
                  Current_W(I) := Current_W(I) + Delta_W(I);
               end loop;
            else
               -- Standard ALOPEX update equation:
               -- Delta W_ij(n) = gamma * Delta W_ij(n-1) * Delta R(n) + r_i(n)
               Delta_R := Current_R - Prev_R;
               for I in Current_W'Range loop
                  declare
                     Step_Change : constant Weight_Type :=
                       Weight_Type(Effective_LR) * Delta_W(I) * Weight_Type(Delta_R) + R_Vector(I);
                  begin
                     Delta_W(I) := Step_Change;
                     Current_W(I) := Current_W(I) + Step_Change;
                  end;
               end loop;
            end if;
         end;

         -- Step 3: Evaluate objective at new weights
         Prev_R := Current_R;
         begin
            Current_R := Objective (Current_W);
         exception
            when others =>
               raise Convergence_Error with "Objective function evaluation failed during optimization.";
         end;

         -- Update best known solution
         if Is_Minimization then
            if Current_R < Best_Cost then
               Best_Cost := Current_R;
               Best_W := Current_W;
            end if;
         else
            if Current_R > Best_Cost then
               Best_Cost := Current_R;
               Best_W := Current_W;
            end if;
         end if;

         -- Apply adaptive cooling if requested
         if Has_Cooling then
            Current_Temp := Current_Temp * Cooling_Rate;
         end if;
      end loop;

      Final_Weights := Best_W;
   exception
      when others =>
         -- Ensure outputs are populated even on unexpected propagation
         Final_Weights := Initial_Weights;
         raise;
   end Core_Optimize;

   -- 1. General Optimize
   procedure Optimize
     (Initial_Weights : in Weight_Vector;
      Objective       : not null access function (W : Weight_Vector) return Cost_Type;
      Max_Iterations  : in Positive;
      Learning_Rate   : in Learning_Rate_Type;
      Temperature     : in Temperature_Type;
      Final_Weights   : out Weight_Vector;
      Best_Cost       : out Cost_Type;
      Iterations_Run  : out Natural)
   is
      Is_Min : constant Boolean := (Learning_Rate < 0.0);
   begin
      Core_Optimize
        (Initial_Weights => Initial_Weights,
         Objective       => Objective,
         Max_Iterations  => Max_Iterations,
         Learning_Rate   => Learning_Rate,
         Initial_Temp    => Temperature,
         Has_Cooling     => False,
         Cooling_Rate    => 1.0,
         Is_Minimization => Is_Min,
         Final_Weights   => Final_Weights,
         Best_Cost       => Best_Cost,
         Iterations_Run  => Iterations_Run);
   end Optimize;

   -- 2. Minimize
   procedure Minimize
     (Initial_Weights : in Weight_Vector;
      Objective       : not null access function (W : Weight_Vector) return Cost_Type;
      Max_Iterations  : in Positive;
      Learning_Rate   : in Learning_Rate_Type;
      Temperature     : in Temperature_Type;
      Final_Weights   : out Weight_Vector;
      Best_Cost       : out Cost_Type;
      Iterations_Run  : out Natural)
   is
   begin
      if Learning_Rate <= 0.0 then
         raise Invalid_Parameter_Error with "Minimization learning rate magnitude must be positive.";
      end if;

      Core_Optimize
        (Initial_Weights => Initial_Weights,
         Objective       => Objective,
         Max_Iterations  => Max_Iterations,
         Learning_Rate   => -Learning_Rate, -- Enforce negative for minimization
         Initial_Temp    => Temperature,
         Has_Cooling     => False,
         Cooling_Rate    => 1.0,
         Is_Minimization => True,
         Final_Weights   => Final_Weights,
         Best_Cost       => Best_Cost,
         Iterations_Run  => Iterations_Run);
   end Minimize;

   -- 3. Maximize
   procedure Maximize
     (Initial_Weights : in Weight_Vector;
      Objective       : not null access function (W : Weight_Vector) return Cost_Type;
      Max_Iterations  : in Positive;
      Learning_Rate   : in Learning_Rate_Type;
      Temperature     : in Temperature_Type;
      Final_Weights   : out Weight_Vector;
      Best_Cost       : out Cost_Type;
      Iterations_Run  : out Natural)
   is
   begin
      if Learning_Rate <= 0.0 then
         raise Invalid_Parameter_Error with "Maximization learning rate magnitude must be positive.";
      end if;

      Core_Optimize
        (Initial_Weights => Initial_Weights,
         Objective       => Objective,
         Max_Iterations  => Max_Iterations,
         Learning_Rate   => Learning_Rate, -- Enforce positive for maximization
         Initial_Temp    => Temperature,
         Has_Cooling     => False,
         Cooling_Rate    => 1.0,
         Is_Minimization => False,
         Final_Weights   => Final_Weights,
         Best_Cost       => Best_Cost,
         Iterations_Run  => Iterations_Run);
   end Maximize;

   -- 4. Optimize_Adaptive
   procedure Optimize_Adaptive
     (Initial_Weights   : in Weight_Vector;
      Objective         : not null access function (W : Weight_Vector) return Cost_Type;
      Max_Iterations    : in Positive;
      Learning_Rate     : in Learning_Rate_Type;
      Initial_Temp      : in Temperature_Type;
      Cooling_Rate      : in Temperature_Type;
      Is_Minimization   : in Boolean;
      Final_Weights     : out Weight_Vector;
      Best_Cost         : out Cost_Type;
      Iterations_Run    : out Natural)
   is
   begin
      Core_Optimize
        (Initial_Weights => Initial_Weights,
         Objective       => Objective,
         Max_Iterations  => Max_Iterations,
         Learning_Rate   => Learning_Rate,
         Initial_Temp    => Initial_Temp,
         Has_Cooling     => True,
         Cooling_Rate    => Cooling_Rate,
         Is_Minimization => Is_Minimization,
         Final_Weights   => Final_Weights,
         Best_Cost       => Best_Cost,
         Iterations_Run  => Iterations_Run);
   end Optimize_Adaptive;

end Alopex;
