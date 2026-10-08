--------------------------------------------------------------------------------
-- Package Alopex (ISO/IEC 8652:2023 Ada)
-- Implements the ALOPEX (Algorithms of Pattern Extraction) optimization algorithm,
-- a correlation-based stochastic optimization method proposed by Tzanakou & Harth (1974).
--------------------------------------------------------------------------------

package Alopex is

   -- Domain types with strong typing
   type Weight_Type is digits 12;
   type Cost_Type is digits 12;
   type Learning_Rate_Type is digits 12;
   type Temperature_Type is digits 12 range 0.0 .. Cost_Type'Last;

   type Weight_Vector is array (Positive range <>) of Weight_Type;

   -- Exceptions
   Invalid_Parameter_Error : exception;
   Empty_Vector_Error      : exception;
   Convergence_Error       : exception;

   -----------------------------------------------------------------------------
   -- Subprogram 1: Optimize (General ALOPEX optimization)
   -- Minimizes or maximizes the objective function depending on the sign of Learning_Rate.
   -- Learning_Rate < 0 minimizes, Learning_Rate > 0 maximizes.
   -----------------------------------------------------------------------------
   procedure Optimize
     (Initial_Weights : in Weight_Vector;
      Objective       : not null access function (W : Weight_Vector) return Cost_Type;
      Max_Iterations  : in Positive;
      Learning_Rate   : in Learning_Rate_Type;
      Temperature     : in Temperature_Type;
      Final_Weights   : out Weight_Vector;
      Best_Cost       : out Cost_Type;
      Iterations_Run  : out Natural)
     with Pre  => Initial_Weights'Length > 0 and then Max_Iterations > 0,
          Post => Final_Weights'Length = Initial_Weights'Length
                  and then Iterations_Run <= Max_Iterations
                  and then Iterations_Run > 0;

   -----------------------------------------------------------------------------
   -- Subprogram 2: Minimize (Specialized Minimization Variant)
   -- Guaranteed minimization variant (forces negative learning rate internally).
   -----------------------------------------------------------------------------
   procedure Minimize
     (Initial_Weights : in Weight_Vector;
      Objective       : not null access function (W : Weight_Vector) return Cost_Type;
      Max_Iterations  : in Positive;
      Learning_Rate   : in Learning_Rate_Type; -- Positive magnitude, applied as negative
      Temperature     : in Temperature_Type;
      Final_Weights   : out Weight_Vector;
      Best_Cost       : out Cost_Type;
      Iterations_Run  : out Natural)
     with Pre  => Initial_Weights'Length > 0
                  and then Max_Iterations > 0
                  and then Learning_Rate > 0.0,
          Post => Final_Weights'Length = Initial_Weights'Length
                  and then Iterations_Run <= Max_Iterations;

   -----------------------------------------------------------------------------
   -- Subprogram 3: Maximize (Specialized Maximization Variant)
   -- Guaranteed maximization variant (forces positive learning rate internally).
   -----------------------------------------------------------------------------
   procedure Maximize
     (Initial_Weights : in Weight_Vector;
      Objective       : not null access function (W : Weight_Vector) return Cost_Type;
      Max_Iterations  : in Positive;
      Learning_Rate   : in Learning_Rate_Type; -- Positive magnitude
      Temperature     : in Temperature_Type;
      Final_Weights   : out Weight_Vector;
      Best_Cost       : out Cost_Type;
      Iterations_Run  : out Natural)
     with Pre  => Initial_Weights'Length > 0
                  and then Max_Iterations > 0
                  and then Learning_Rate > 0.0,
          Post => Final_Weights'Length = Initial_Weights'Length
                  and then Iterations_Run <= Max_Iterations;

   -----------------------------------------------------------------------------
   -- Subprogram 4: Optimize_Adaptive (Annealing / Temperature Schedule Variant)
   -- ALOPEX with simulated annealing style temperature decay over iterations.
   -----------------------------------------------------------------------------
   procedure Optimize_Adaptive
     (Initial_Weights   : in Weight_Vector;
      Objective         : not null access function (W : Weight_Vector) return Cost_Type;
      Max_Iterations    : in Positive;
      Learning_Rate     : in Learning_Rate_Type;
      Initial_Temp      : in Temperature_Type;
      Cooling_Rate      : in Temperature_Type; -- e.g. 0.95 .. 0.99
      Is_Minimization   : in Boolean;
      Final_Weights     : out Weight_Vector;
      Best_Cost         : out Cost_Type;
      Iterations_Run    : out Natural)
     with Pre  => Initial_Weights'Length > 0
                  and then Max_Iterations > 0
                  and then Cooling_Rate > 0.0
                  and then Cooling_Rate <= 1.0,
          Post => Final_Weights'Length = Initial_Weights'Length
                  and then Iterations_Run <= Max_Iterations;

   -----------------------------------------------------------------------------
   -- Helper function: Vector Euclidean Norm (useful for testing & analysis)
   -----------------------------------------------------------------------------
   function Euclidean_Norm (V : Weight_Vector) return Weight_Type;

end Alopex;
