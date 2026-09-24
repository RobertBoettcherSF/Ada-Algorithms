package Description_Logic is
   pragma Pure;

   -- Domain configuration limits
   Max_Individuals : constant := 32;
   Max_Concepts    : constant := 32;
   Max_Roles       : constant := 32;
   Max_Nodes       : constant := 128;

   -- Strong typing for domain elements
   subtype Individual_ID is Integer range 1 .. Max_Individuals;
   subtype Concept_ID    is Integer range 1 .. Max_Concepts;
   subtype Role_ID       is Integer range 1 .. Max_Roles;
   subtype Node_ID       is Integer range 1 .. Max_Nodes;
   subtype Node_Count    is Integer range 0 .. Max_Nodes;
   subtype Domain_Size   is Integer range 0 .. Max_Individuals;

   -- Sets and Relations for Model Checking
   type Individual_Set is array (Individual_ID) of Boolean;
   type Role_Relation is array (Individual_ID, Individual_ID) of Boolean;

   type Concept_Map is array (Concept_ID) of Individual_Set;
   type Role_Map is array (Role_ID) of Role_Relation;

   -- A finite interpretation (model) mapping syntax to semantics
   type Interpretation is record
      Size     : Domain_Size := 0; -- The active domain size
      Concepts : Concept_Map := (others => (others => False));
      Roles    : Role_Map    := (others => (others => (others => False)));
   end record;

   -- ALC (Attributive Concept Language with Complements) constructs
   type Node_Kind is (Top, Bottom, Atomic, Intersection, Union,
                      Negation, Universal, Existential);

   type Concept_Node (Kind : Node_Kind := Top) is record
      case Kind is
         when Top | Bottom =>
            null;
         when Atomic =>
            Concept : Concept_ID := 1;
         when Intersection | Union =>
            Left, Right : Node_ID := 1;
         when Negation =>
            Operand : Node_ID := 1;
         when Universal | Existential =>
            Role   : Role_ID := 1;
            Target : Node_ID := 1;
      end case;
   end record;

   type Node_Array is array (Node_ID) of Concept_Node;

   -- Abstract Syntax Tree for Concept Expressions (Arena allocated)
   type Concept_Expression is record
      Nodes : Node_Array := (others => (Kind => Top));
      Last  : Node_Count := 0;
   end record;

   Expression_Full : exception;
   Invalid_Node    : exception;

   -- =========================================================================
   -- ALC Expression Builders
   -- =========================================================================
   
   function Add_Top (Expr : in out Concept_Expression) return Node_ID
     with Global => null;
     
   function Add_Bottom (Expr : in out Concept_Expression) return Node_ID
     with Global => null;
     
   function Add_Atomic (Expr : in out Concept_Expression; C : Concept_ID) return Node_ID
     with Global => null;
     
   function Add_Intersection (Expr : in out Concept_Expression; L, R : Node_ID) return Node_ID
     with Global => null;
     
   function Add_Union (Expr : in out Concept_Expression; L, R : Node_ID) return Node_ID
     with Global => null;
     
   function Add_Negation (Expr : in out Concept_Expression; Op : Node_ID) return Node_ID
     with Global => null;
     
   function Add_Universal (Expr : in out Concept_Expression; R : Role_ID; T : Node_ID) return Node_ID
     with Global => null;
     
   function Add_Existential (Expr : in out Concept_Expression; R : Role_ID; T : Node_ID) return Node_ID
     with Global => null;

   -- =========================================================================
   -- Semantic Evaluation (Model Checking)
   -- =========================================================================
   
   -- Evaluates the set of individuals belonging to the concept in the interpretation
   function Evaluate (I : Interpretation; Expr : Concept_Expression; N : Node_ID) return Individual_Set
     with Global => null;

   -- =========================================================================
   -- TBox Reasoning Tasks (Terminological Box)
   -- =========================================================================
   
   -- Checks if Sub subsumes Super (Sub is a subset of Super) in interpretation I
   function Satisfies_Subsumption (I : Interpretation; Expr : Concept_Expression; Sub, Super : Node_ID) return Boolean
     with Global => null;
     
   -- Checks if concept C is equivalent to concept D in interpretation I
   function Satisfies_Equivalence (I : Interpretation; Expr : Concept_Expression; C, D : Node_ID) return Boolean
     with Global => null;
     
   -- Checks if concept C and D are disjoint (intersection is empty)
   function Satisfies_Disjointness (I : Interpretation; Expr : Concept_Expression; C, D : Node_ID) return Boolean
     with Global => null;

   -- =========================================================================
   -- ABox Reasoning Tasks (Assertional Box)
   -- =========================================================================
   
   -- Checks if individual Indiv belongs to concept C
   function Satisfies_Concept_Assertion (I : Interpretation; Expr : Concept_Expression; Indiv : Individual_ID; C : Node_ID) return Boolean
     with Global => null;
     
   -- Checks if role R links Indiv1 to Indiv2
   function Satisfies_Role_Assertion (I : Interpretation; Indiv1, Indiv2 : Individual_ID; R : Role_ID) return Boolean
     with Global => null;

end Description_Logic;
