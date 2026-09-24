-- replicator_equation.adb
-- Implementation of the Replicator Equation and its variants.

package body Replicator_Equation is

   ----------------------------------------------------------------------------
   -- Helper: Normalize
   ----------------------------------------------------------------------------
   function Normalize (Population : Population_Vector) return Population_Vector is
      Result : Population_Vector(Population'Range);
      Sum    : Float := 0.0;
   begin
      if Population'Length = 0 then
         raise Invalid_Population with "Population vector cannot be empty.";
      end if;
      
      for I in Population'Range loop
         if Population(I) < 0.0 then
            raise Invalid_Population with "Population frequencies cannot be negative.";
         end if;
         Sum := Sum + Population(I);
      end loop;

      if Sum = 0.0 then
         raise Invalid_Population with "Population vector sum cannot be zero.";
      end if;

      for I in Population'Range loop
         Result(I) := Population(I) / Sum;
      end loop;

      return Result;
   end Normalize;

   ----------------------------------------------------------------------------
   -- Helper: Calculate_Fitness
   ----------------------------------------------------------------------------
   function Calculate_Fitness (Population : Population_Vector; Payoff : Payoff_Matrix) return Population_Vector is
      Result : Population_Vector(Population'Range) := (others => 0.0);
   begin
      if Population'Length /= Payoff'Length(1) or Population'Length /= Payoff'Length(2) then
         raise Dimension_Mismatch with "Payoff matrix dimensions must match Population vector length.";
      end if;

      for I in Payoff'Range(1) loop
         for J in Payoff'Range(2) loop
            Result(I) := Result(I) + Payoff(I, J) * Population(J);
         end loop;
      end loop;

      return Result;
   end Calculate_Fitness;

   ----------------------------------------------------------------------------
   -- Helper: Average_Fitness
   ----------------------------------------------------------------------------
   function Average_Fitness (Population : Population_Vector; Fitness : Population_Vector) return Float is
      Avg_Fitness : Float := 0.0;
   begin
      if Population'Length /= Fitness'Length then
         raise Dimension_Mismatch with "Population and Fitness vector dimensions must match.";
      end if;

      for I in Population'Range loop
         Avg_Fitness := Avg_Fitness + (Population(I) * Fitness(I));
      end loop;

      return Avg_Fitness;
   end Average_Fitness;

   ----------------------------------------------------------------------------
   -- 1. Step_Discrete
   ----------------------------------------------------------------------------
   function Step_Discrete (Population : Population_Vector; Payoff : Payoff_Matrix) return Population_Vector is
      Norm_Pop    : Population_Vector := Normalize(Population);
      Fitness     : Population_Vector := Calculate_Fitness(Norm_Pop, Payoff);
      Avg_Fitness : Float := Average_Fitness(Norm_Pop, Fitness);
      Result      : Population_Vector(Norm_Pop'Range);
   begin
      if Avg_Fitness = 0.0 then
         raise Zero_Average_Fitness with "Average fitness is zero; discrete step cannot divide by zero.";
      end if;

      for I in Norm_Pop'Range loop
         Result(I) := Norm_Pop(I) * (Fitness(I) / Avg_Fitness);
      end loop;

      return Normalize(Result);
   end Step_Discrete;

   ----------------------------------------------------------------------------
   -- 2. Step_Continuous
   ----------------------------------------------------------------------------
   function Step_Continuous (
      Population : Population_Vector; 
      Payoff     : Payoff_Matrix; 
      Delta_T    : Float
   ) return Population_Vector is
      Norm_Pop    : Population_Vector := Normalize(Population);
      Fitness     : Population_Vector := Calculate_Fitness(Norm_Pop, Payoff);
      Avg_Fitness : Float := Average_Fitness(Norm_Pop, Fitness);
      Result      : Population_Vector(Norm_Pop'Range);
      Derivative  : Float;
   begin
      for I in Norm_Pop'Range loop
         Derivative := Norm_Pop(I) * (Fitness(I) - Avg_Fitness);
         Result(I)  := Norm_Pop(I) + (Derivative * Delta_T);
         
         -- Prevent extreme float drifts into negative (extinction barrier)
         if Result(I) < 0.0 then
            Result(I) := 0.0;
         end if;
      end loop;

      return Normalize(Result);
   end Step_Continuous;

   ----------------------------------------------------------------------------
   -- 3. Step_Mutator_Continuous
   ----------------------------------------------------------------------------
   function Step_Mutator_Continuous (
      Population      : Population_Vector;
      Payoff          : Payoff_Matrix;
      Mutation_Matrix : Payoff_Matrix;
      Delta_T         : Float
   ) return Population_Vector is
      Norm_Pop    : Population_Vector := Normalize(Population);
      Fitness     : Population_Vector := Calculate_Fitness(Norm_Pop, Payoff);
      Avg_Fitness : Float := Average_Fitness(Norm_Pop, Fitness);
      Result      : Population_Vector(Norm_Pop'Range);
      Mutation_Sum: Float;
   begin
      if Mutation_Matrix'Length(1) /= Norm_Pop'Length or Mutation_Matrix'Length(2) /= Norm_Pop'Length then
         raise Dimension_Mismatch with "Mutation matrix dimensions must match Population vector length.";
      end if;

      for I in Norm_Pop'Range loop
         Mutation_Sum := 0.0;
         for J in Norm_Pop'Range loop
            Mutation_Sum := Mutation_Sum + (Norm_Pop(J) * Fitness(J) * Mutation_Matrix(J, I));
         end loop;

         Result(I) := Norm_Pop(I) + Delta_T * (Mutation_Sum - (Norm_Pop(I) * Avg_Fitness));
         
         if Result(I) < 0.0 then
            Result(I) := 0.0;
         end if;
      end loop;

      return Normalize(Result);
   end Step_Mutator_Continuous;

   ----------------------------------------------------------------------------
   -- 4. Step_Asymmetric_Discrete
   ----------------------------------------------------------------------------
   procedure Step_Asymmetric_Discrete (
      Population_A : in out Population_Vector;
      Population_B : in out Population_Vector;
      Payoff_A     : in     Payoff_Matrix;
      Payoff_B     : in     Payoff_Matrix
   ) is
      Norm_A      : Population_Vector := Normalize(Population_A);
      Norm_B      : Population_Vector := Normalize(Population_B);
      
      Fitness_A   : Population_Vector(Norm_A'Range) := (others => 0.0);
      Fitness_B   : Population_Vector(Norm_B'Range) := (others => 0.0);
      
      Avg_Fit_A   : Float := 0.0;
      Avg_Fit_B   : Float := 0.0;
   begin
      -- A plays against B
      if Payoff_A'Length(1) /= Norm_A'Length or Payoff_A'Length(2) /= Norm_B'Length then
         raise Dimension_Mismatch with "Payoff_A dimensions must match (Pop_A, Pop_B).";
      end if;
      
      -- B plays against A
      if Payoff_B'Length(1) /= Norm_B'Length or Payoff_B'Length(2) /= Norm_A'Length then
         raise Dimension_Mismatch with "Payoff_B dimensions must match (Pop_B, Pop_A).";
      end if;

      -- Compute Fitness for A (A vs B)
      for I in Payoff_A'Range(1) loop
         for J in Payoff_A'Range(2) loop
            Fitness_A(I) := Fitness_A(I) + Payoff_A(I, J) * Norm_B(J);
         end loop;
         Avg_Fit_A := Avg_Fit_A + (Norm_A(I) * Fitness_A(I));
      end loop;

      -- Compute Fitness for B (B vs A)
      for I in Payoff_B'Range(1) loop
         for J in Payoff_B'Range(2) loop
            Fitness_B(I) := Fitness_B(I) + Payoff_B(I, J) * Norm_A(J);
         end loop;
         Avg_Fit_B := Avg_Fit_B + (Norm_B(I) * Fitness_B(I));
      end loop;

      if Avg_Fit_A = 0.0 or Avg_Fit_B = 0.0 then
         raise Zero_Average_Fitness with "Average fitness is zero in asymmetric step.";
      end if;

      -- Update A
      for I in Norm_A'Range loop
         Population_A(I) := Norm_A(I) * (Fitness_A(I) / Avg_Fit_A);
      end loop;
      
      -- Update B
      for I in Norm_B'Range loop
         Population_B(I) := Norm_B(I) * (Fitness_B(I) / Avg_Fit_B);
      end loop;

      Population_A := Normalize(Population_A);
      Population_B := Normalize(Population_B);
   end Step_Asymmetric_Discrete;

end Replicator_Equation;
