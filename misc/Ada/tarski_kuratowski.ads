-- tarski_kuratowski.ads
-- Specification for the Tarski-Kuratowski Algorithm
-- Computes the upper bound for the complexity of a formula in the 
-- Arithmetical or Analytical hierarchy by analyzing its quantifier prefix.

package Tarski_Kuratowski is

   -- Represents the type of logical quantifier
   type Quantifier_Type is (Existential, Universal);

   -- Represents the domain of the quantifier (Type 0 = Number, Type 1 = Function/Set)
   type Variable_Order is (First_Order, Second_Order);

   -- A single quantifier in the prenex normal form prefix
   type Quantifier is record
      Q_Type : Quantifier_Type;
      V_Order : Variable_Order;
   end record;

   -- A sequence of quantifiers (the prefix of a formula in Prenex Normal Form)
   type Quantifier_Prefix is array (Positive range <>) of Quantifier;

   -- The resulting complexity classes (Σ, Π, Δ)
   -- Renamed with Class_ prefix to avoid Ada's reserved word "delta"
   type Complexity_Class is (Class_Sigma, Class_Pi, Class_Delta);

   -- The calculated upper bound complexity
   type Complexity_Bound is record
      Class   : Complexity_Class;
      Level   : Natural;
      V_Order : Variable_Order;
   end record;

   -- Exception raised when a prefix violates the constraints of a specific hierarchy
   Invalid_Hierarchy_Prefix : exception;

   -- Algorithm Variants

   -- 1. Arithmetical Hierarchy (Type 0): Evaluates prefixes with ONLY First_Order quantifiers.
   -- Raises Invalid_Hierarchy_Prefix if a Second_Order quantifier is encountered.
   function Evaluate_Arithmetical (Prefix : Quantifier_Prefix) return Complexity_Bound;

   -- 2. Analytical Hierarchy (Type 1): Evaluates prefixes containing Second_Order quantifiers.
   -- First_Order quantifiers are absorbed and do not increase the analytical level.
   function Evaluate_Analytical (Prefix : Quantifier_Prefix) return Complexity_Bound;

   -- 3. Dynamic Bound Resolver: Automatically determines if the prefix belongs to the 
   -- Arithmetical or Analytical hierarchy and routes it to the appropriate variant.
   function Get_Upper_Bound (Prefix : Quantifier_Prefix) return Complexity_Bound;

end Tarski_Kuratowski;
