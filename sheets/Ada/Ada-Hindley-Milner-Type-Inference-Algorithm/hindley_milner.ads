with Ada.Strings.Unbounded;
with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Containers.Indefinite_Ordered_Sets;

--  Hindley-Milner Type Inference (Algorithm W)
--  Implements polymorphic type inference including both standard (poly) 
--  and monomorphic let-binding variants.
package Hindley_Milner is

   package String_Sets is new Ada.Containers.Indefinite_Ordered_Sets
     (Element_Type => String);

   type Type_Kind is (Kind_Var, Kind_Base, Kind_Arrow);
   
   type Type_Node;
   type Type_Access is access all Type_Node;
   
   type Type_Node (Kind : Type_Kind) is record
      case Kind is
         when Kind_Var =>
            Var_Name : Ada.Strings.Unbounded.Unbounded_String;
         when Kind_Base =>
            Base_Name : Ada.Strings.Unbounded.Unbounded_String;
         when Kind_Arrow =>
            Left, Right : Type_Access;
      end case;
   end record;

   type Scheme is record
      Bound_Vars : String_Sets.Set;
      T          : Type_Access;
   end record;

   type Expr_Kind is (Kind_Var, Kind_App, Kind_Abs, Kind_Let);
   
   type Expr_Node;
   type Expr_Access is access all Expr_Node;
   
   type Expr_Node (Kind : Expr_Kind) is record
      case Kind is
         when Kind_Var =>
            Name : Ada.Strings.Unbounded.Unbounded_String;
         when Kind_App =>
            Func, Arg : Expr_Access;
         when Kind_Abs =>
            Param : Ada.Strings.Unbounded.Unbounded_String;
            Body_Expr : Expr_Access;
         when Kind_Let =>
            Bound_Var : Ada.Strings.Unbounded.Unbounded_String;
            Value_Expr, Let_Body : Expr_Access;
      end case;
   end record;

   package Subst_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type => String, Element_Type => Type_Access);
   subtype Substitution is Subst_Maps.Map;

   package Env_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type => String, Element_Type => Scheme);
   subtype Environment is Env_Maps.Map;

   type Infer_State is record
      Next_ID : Natural := 0;
   end record;
   
   type Infer_Result is record
      Sub : Substitution;
      T   : Type_Access;
   end record;

   --  Exceptions
   Unification_Error      : exception;
   Unbound_Variable_Error : exception;

   --  Constructors for AST and Types
   function Make_Type_Var (Name : String) return Type_Access
     with Pre => Name'Length > 0, Post => Make_Type_Var'Result /= null;
     
   function Make_Type_Base (Name : String) return Type_Access
     with Pre => Name'Length > 0, Post => Make_Type_Base'Result /= null;
     
   function Make_Type_Arrow (Left, Right : Type_Access) return Type_Access
     with Pre => Left /= null and then Right /= null,
          Post => Make_Type_Arrow'Result /= null;

   function Make_Expr_Var (Name : String) return Expr_Access
     with Pre => Name'Length > 0, Post => Make_Expr_Var'Result /= null;
     
   function Make_Expr_App (Func, Arg : Expr_Access) return Expr_Access
     with Pre => Func /= null and then Arg /= null,
          Post => Make_Expr_App'Result /= null;
          
   function Make_Expr_Abs (Param : String; Body_Expr : Expr_Access) return Expr_Access
     with Pre => Param'Length > 0 and then Body_Expr /= null,
          Post => Make_Expr_Abs'Result /= null;
          
   function Make_Expr_Let (Bound_Var : String; Value_Expr, Let_Body : Expr_Access) return Expr_Access
     with Pre => Bound_Var'Length > 0 and then Value_Expr /= null and then Let_Body /= null,
          Post => Make_Expr_Let'Result /= null;

   --  Core Algorithm Subprograms (Variants)
   --  Variant 1: Standard Polymorphic Let
   function Infer_Type
     (Env   : Environment;
      Expr  : Expr_Access;
      State : in out Infer_State) return Type_Access
     with Pre => Expr /= null;

   --  Variant 2: Monomorphic Let (No Generalization)
   function Infer_Type_Monomorphic
     (Env   : Environment;
      Expr  : Expr_Access;
      State : in out Infer_State) return Type_Access
     with Pre => Expr /= null;

   --  Helper functions exposed for deep testing and validation
   function Unify (T1, T2 : Type_Access) return Substitution
     with Pre => T1 /= null and then T2 /= null;
     
   function Apply_Subst_Type (Sub : Substitution; T : Type_Access) return Type_Access
     with Pre => T /= null, Post => Apply_Subst_Type'Result /= null;
     
   function Apply_Subst_Env (Sub : Substitution; Env : Environment) return Environment;
   
   function Compose_Subst (S_After, S_Before : Substitution) return Substitution;
   
   function FTV_Type (T : Type_Access) return String_Sets.Set
     with Pre => T /= null;
     
   function FTV_Env (Env : Environment) return String_Sets.Set;

   --  Formatting
   function Type_To_String (T : Type_Access) return String
     with Pre => T /= null;

private
   function Algorithm_W_Step
     (Env   : Environment;
      Expr  : Expr_Access;
      State : in out Infer_State;
      Poly  : Boolean) return Infer_Result;

end Hindley_Milner;
