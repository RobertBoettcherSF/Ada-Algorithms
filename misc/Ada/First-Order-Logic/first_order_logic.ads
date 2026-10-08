package First_Order_Logic is

   --  First-Order Logic (FOL) AST and Semantics Implementation.
   --  This package provides a framework for creating and evaluating FOL 
   --  terms and formulas based on a finite universe of discourse (Domain_Element).

   --  Domain elements for semantic evaluation. 
   --  We use a small finite domain to make quantifier evaluation computable.
   type Domain_Element is range 1 .. 3;

   --  Variables are restricted to a single lowercase character for simplicity.
   subtype Variable_Name is Character range 'a' .. 'z';

   --  Assignments map free variables to domain elements during evaluation.
   type Assignment is array (Variable_Name) of Domain_Element;

   --  Abstract interpretation type. Users must extend this to define the 
   --  meaning of specific constants, functions, and predicates.
   type Interpretation is abstract tagged null record;

   function Eval_Constant 
     (I    : Interpretation; 
      Name : Character) return Domain_Element is abstract;
      
   --  Second argument of a function or predicate symbol. A unary symbol
   --  gets Present = False: there is no placeholder value to read (reading
   --  Value of an absent argument raises Constraint_Error).
   type Optional_Element (Present : Boolean := False) is record
      case Present is
         when True  => Value : Domain_Element;
         when False => null;
      end case;
   end record;
   No_Element : constant Optional_Element := (Present => False);

   function Eval_Function 
     (I    : Interpretation; 
      Name : Character; 
      Arg1 : Domain_Element;
      Arg2 : Optional_Element) return Domain_Element is abstract;
      
   function Eval_Predicate 
     (I    : Interpretation; 
      Name : Character; 
      Arg1 : Domain_Element;
      Arg2 : Optional_Element) return Boolean is abstract;

   -----------------------------------------------------------------------------
   --  Terms (Variables, Constants, Functions)
   -----------------------------------------------------------------------------
   type Term_Kind is (Is_Variable, Is_Constant, Is_Function);
   type Term (Kind : Term_Kind);
   type Term_Access is access Term;

   type Term (Kind : Term_Kind) is record
      Name : Character;
      case Kind is
         when Is_Variable | Is_Constant => 
            null;
         when Is_Function =>
            Arg1 : Term_Access;
            Arg2 : Term_Access; -- Can be null for unary functions
      end case;
   end record;

   --  Constructors for Terms
   function Make_Variable (Name : Variable_Name) return Term_Access;
   function Make_Constant (Name : Character) return Term_Access;
   function Make_Function (Name : Character; Arg1 : not null Term_Access; Arg2 : Term_Access := null) return Term_Access;

   -----------------------------------------------------------------------------
   --  Formulas (Predicates, Equality, Connectives, Quantifiers)
   -----------------------------------------------------------------------------
   type Formula_Kind is 
     (Is_Predicate, Is_Equality, Is_Not, Is_And, Is_Or, 
      Is_Implies, Is_Iff, Is_Forall, Is_Exists);
      
   type Formula (Kind : Formula_Kind);
   type Formula_Access is access Formula;

   type Formula (Kind : Formula_Kind) is record
      case Kind is
         when Is_Predicate =>
            Pred_Name : Character;
            Term1     : Term_Access;
            Term2     : Term_Access; -- Can be null for unary predicates
         when Is_Equality =>
            Eq_Term1, Eq_Term2 : Term_Access;
         when Is_Not =>
            Sub_Formula : Formula_Access;
         when Is_And | Is_Or | Is_Implies | Is_Iff =>
            Left, Right : Formula_Access;
         when Is_Forall | Is_Exists =>
            Var_Name     : Variable_Name;
            Body_Formula : Formula_Access;
      end case;
   end record;

   --  Constructors for Formulas
   function Make_Predicate (Name : Character; Term1 : not null Term_Access; Term2 : Term_Access := null) return Formula_Access;
   function Make_Equality (Term1, Term2 : not null Term_Access) return Formula_Access;
   function Make_Not (F : not null Formula_Access) return Formula_Access;
   function Make_And (Left, Right : not null Formula_Access) return Formula_Access;
   function Make_Or (Left, Right : not null Formula_Access) return Formula_Access;
   function Make_Implies (Left, Right : not null Formula_Access) return Formula_Access;
   function Make_Iff (Left, Right : not null Formula_Access) return Formula_Access;
   function Make_Forall (Var : Variable_Name; Body_Formula : not null Formula_Access) return Formula_Access;
   function Make_Exists (Var : Variable_Name; Body_Formula : not null Formula_Access) return Formula_Access;

   -----------------------------------------------------------------------------
   --  Core First-Order Logic Algorithms
   -----------------------------------------------------------------------------

   --  Evaluates a term to a domain element within a specific interpretation and assignment
   function Evaluate_Term
     (T      : Term_Access;
      Interp : Interpretation'Class;
      Env    : Assignment) return Domain_Element
     with Pre => T /= null;

   --  Evaluates a formula to a truth value (Semantics of FOL)
   function Evaluate_Formula
     (F      : Formula_Access;
      Interp : Interpretation'Class;
      Env    : Assignment) return Boolean
     with Pre => F /= null;

   --  Checks if a variable occurs free (unbound by a quantifier) in a formula
   function Is_Free_Variable (F : Formula_Access; Var : Variable_Name) return Boolean
     with Pre => F /= null;

   --  Checks if a formula is in Prenex Normal Form (all quantifiers at the outermost level)
   function Is_Prenex_Normal_Form (F : Formula_Access) return Boolean
     with Pre => F /= null;

   --  Checks if a formula contains any quantifiers
   function Has_Quantifier (F : Formula_Access) return Boolean;

   --  Substitutes all free occurrences of Var in T with a deep copy of Replacement
   function Substitute_Term (T : Term_Access; Var : Variable_Name; Replacement : Term_Access) return Term_Access
     with Pre => T /= null and Replacement /= null;

   --  Substitutes all free occurrences of Var in F with Replacement,
   --  avoiding capture: a quantifier whose variable occurs in Replacement
   --  (and above a free occurrence of Var) has its variable renamed to one
   --  used neither in F nor in Replacement. Raises Constraint_Error if all
   --  26 variable names are in use.
   function Substitute_Formula (F : Formula_Access; Var : Variable_Name; Replacement : Term_Access) return Formula_Access
     with Pre => F /= null and Replacement /= null;

end First_Order_Logic;
