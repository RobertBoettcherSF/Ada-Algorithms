-- vqe.adb
with Ada.Numerics.Float_Random;
with Ada.Exceptions;
with Ada.Numerics.Generic_Elementary_Functions;

package body VQE is

   -- Instantiate elementary functions for our custom Float_Type 
   package Math is new Ada.Numerics.Generic_Elementary_Functions (Float_Type);
   use Math;

   -- =========================================================================
   -- Expectation_Value
   -- Simulates the quantum measurement <psi | H | psi>. 
   -- Since this is classical Ada, we mock the quantum landscape with 
   -- n-dimensional paraboloids where the optimal parameters depend on the ansatz.
   -- =========================================================================
   function Expectation_Value
     (H      : Hamiltonian;
      Ansatz : Ansatz_Type;
      Params : Vector) return Float_Type
   is
      Energy : Float_Type := H.Base_Energy;
      Target : Float_Type;
   begin
      -- Edge Case: Empty parameter list
      if Params'Length = 0 then
         raise Dimension_Error with "Parameter vector cannot be empty";
      end if;

      for I in Params'Range loop
         -- Implement variants: different Ansätze lead to different quantum state landscapes
         case Ansatz is
            when Hardware_Efficient => 
               Target := 1.0; -- Mock target parameters
            when Unitary_Coupled_Cluster =>
               if I mod 2 = 0 then 
                  Target := -0.5; 
               else 
                  Target := 0.5; 
               end if;
            when QAOA => 
               Target := 3.1415926535; -- Pi
         end case;
         
         -- Sum of squared differences simulates the energy landscape converging
         Energy := Energy + ((Params(I) - Target) ** 2) * Float_Type(H.Complexity);
      end loop;
      
      return Energy;
   end Expectation_Value;

   -- =========================================================================
   -- Calculate_Gradient (Finite Differences)
   -- Used for Gradient Descent variant
   -- =========================================================================
   function Calculate_Gradient
     (H      : Hamiltonian;
      Ansatz : Ansatz_Type;
      Params : Vector) return Vector
   is
      Grad  : Vector(Params'Range);
      Eps   : constant Float_Type := 1.0e-4;
      P_Fwd : Vector(Params'Range) := Params;
      P_Bwd : Vector(Params'Range) := Params;
   begin
      for I in Params'Range loop
         P_Fwd(I) := Params(I) + Eps;
         P_Bwd(I) := Params(I) - Eps;
         
         Grad(I) := (Expectation_Value(H, Ansatz, P_Fwd) - 
                     Expectation_Value(H, Ansatz, P_Bwd)) / (2.0 * Eps);
                     
         -- Reset for next dimension
         P_Fwd(I) := Params(I);
         P_Bwd(I) := Params(I);
      end loop;
      return Grad;
   end Calculate_Gradient;

   -- =========================================================================
   -- Calculate_SPSA_Gradient
   -- Simultaneous Perturbation Stochastic Approximation (Gradient-free variant)
   -- =========================================================================
   function Calculate_SPSA_Gradient
     (H      : Hamiltonian;
      Ansatz : Ansatz_Type;
      Params : Vector) return Vector
   is
      Gen          : Ada.Numerics.Float_Random.Generator;
      Grad         : Vector(Params'Range);
      Perturbation : Vector(Params'Range);
      C            : constant Float_Type := 0.01; -- Perturbation magnitude
      P_Fwd        : Vector(Params'Range);
      P_Bwd        : Vector(Params'Range);
      E_Fwd, E_Bwd : Float_Type;
   begin
      Ada.Numerics.Float_Random.Reset(Gen);
      
      -- Generate random Bernoulli distribution perturbations (-1 or 1)
      for I in Params'Range loop
         if Ada.Numerics.Float_Random.Random(Gen) > 0.5 then
            Perturbation(I) := 1.0;
         else
            Perturbation(I) := -1.0;
         end if;
         
         P_Fwd(I) := Params(I) + C * Perturbation(I);
         P_Bwd(I) := Params(I) - C * Perturbation(I);
      end loop;
      
      E_Fwd := Expectation_Value(H, Ansatz, P_Fwd);
      E_Bwd := Expectation_Value(H, Ansatz, P_Bwd);
      
      for I in Params'Range loop
         Grad(I) := (E_Fwd - E_Bwd) / (2.0 * C * Perturbation(I));
      end loop;
      
      return Grad;
   end Calculate_SPSA_Gradient;

   -- =========================================================================
   -- Optimize
   -- Classical outer loop of the Variational Quantum Eigensolver
   -- =========================================================================
   function Optimize
     (H             : Hamiltonian;
      Ansatz        : Ansatz_Type;
      Opt_Method    : Optimizer_Type;
      Initial_Guess : Vector;
      Learning_Rate : Float_Type := 0.05;
      Tolerance     : Float_Type := 1.0e-5;
      Max_Iter      : Positive   := 1000) return Vector
   is
      Current_Params : Vector(Initial_Guess'Range) := Initial_Guess;
      Prev_Energy    : Float_Type := Float_Type'Last;
      Current_Energy : Float_Type;
      Gradient       : Vector(Initial_Guess'Range);
      Effective_LR   : Float_Type;
   begin
      if Initial_Guess'Length = 0 then
         raise Dimension_Error with "Initial guess vector cannot be empty";
      end if;

      for Iter in 1 .. Max_Iter loop
         Current_Energy := Expectation_Value(H, Ansatz, Current_Params);
         
         -- Convergence check: 
         -- SPSA is heavily stochastic. Exiting on a single step where Delta E < Tolerance 
         -- can cause premature termination if the random gradient vector happens to cancel out.
         -- Therefore, we only permit early tolerance exits for deterministic Gradient_Descent.
         if Opt_Method = Gradient_Descent and then abs(Prev_Energy - Current_Energy) < Tolerance then
            return Current_Params;
         end if;
         Prev_Energy := Current_Energy;

         -- Get Gradient based on variant
         case Opt_Method is
            when Gradient_Descent =>
               Gradient := Calculate_Gradient(H, Ansatz, Current_Params);
               Effective_LR := Learning_Rate;
            when SPSA =>
               Gradient := Calculate_SPSA_Gradient(H, Ansatz, Current_Params);
               -- SPSA requires a decaying learning rate to force stochastic convergence
               Effective_LR := Learning_Rate / Math.Sqrt(Float_Type(Iter));
         end case;
         
         -- Parameter update
         for I in Current_Params'Range loop
            Current_Params(I) := Current_Params(I) - Effective_LR * Gradient(I);
         end loop;
      end loop;
      
      -- If loop completes without hitting tolerance, we return best effort
      return Current_Params;
   end Optimize;

end VQE;
