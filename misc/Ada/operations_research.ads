package Operations_Research is
   pragma Pure;

   -- Using a high-precision floating point type for linear programming calculations
   type Value_Type is new Long_Float;

   type Vector_Type is array (Positive range <>) of Value_Type;
   type Matrix_Type is array (Positive range <>, Positive range <>) of Value_Type;

   Unbounded_Problem  : exception;
   Infeasible_Problem : exception;

   -- Standard form maximization:
   -- Maximize Z = Objective * X
   -- Subject to Constraints * X <= Bounds, X >= 0, Bounds >= 0
   procedure Maximize
     (Objective   : in Vector_Type;
      Constraints : in Matrix_Type;
      Bounds      : in Vector_Type;
      Max_Value   : out Value_Type;
      Solution    : out Vector_Type)
     with
       Global => null,
       Pre => Objective'Length > 0 and then
              Constraints'Length (1) > 0 and then
              Constraints'Length (2) = Objective'Length and then
              Bounds'Length = Constraints'Length (1) and then
              Solution'Length = Objective'Length;

   -- Standard form minimization:
   -- Minimize Z = Objective * X
   -- Subject to Constraints * X >= Bounds, X >= 0, Objective >= 0
   -- This solves the primal minimization problem by transforming it into its Dual.
   procedure Minimize
     (Objective   : in Vector_Type;
      Constraints : in Matrix_Type;
      Bounds      : in Vector_Type;
      Min_Value   : out Value_Type;
      Solution    : out Vector_Type)
     with
       Global => null,
       Pre => Objective'Length > 0 and then
              Constraints'Length (1) > 0 and then
              Constraints'Length (2) = Objective'Length and then
              Bounds'Length = Constraints'Length (1) and then
              Solution'Length = Objective'Length;

end Operations_Research;
