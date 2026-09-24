with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Ordered_Maps;
with Ada.Containers.Ordered_Sets;

package Hindley_Milner is

   --  Strong typing for type variables to avoid confusing with general integers.
   type Var_Id is new Natural;

   --  Ordered set of type variables (used for Free Type Variables and Polytype bound vars)
   package Var_Sets is new Ada.Containers.Ordered_Sets (Element_Type => Var_Id);

   --  Kinds of types in the Hindley-Milner system
   type Type_Kind is (Kind_Var, Kind_Const, Kind_Arrow);

   type Type_Node;
   type Type_Ref is access all Type_Node;

   type Type_Node (Kind : Type_Kind) is record
      case Kind is
         when Kind_Var =>
            Id : Var_Id;
         when Kind_Const =>
            Name : Unbounded_String;
         when Kind_Arrow =>
            Left, Right : Type_Ref;
      end case;
   end record;

   --  Kinds of expressions in the lambda calculus + let bindings
   type Expr_Kind is (Expr_Var, Expr_App, Expr_Abs, Expr_Let);
   
   type Expr_Node;
   type Expr_Ref is access all Expr_Node;

   type Expr_Node (Kind : Expr_Kind) is record
      case Kind is
         when Expr_Var =>
            Var_Name : Unbounded_String;
         when Expr_App =>
            Func, Arg : Expr_Ref;
         when Expr_Abs =>
            Param_Name : Unbounded_String;
            Body_Expr  : Expr_Ref;
         when Expr_Let =>
            Let_Var   : Unbounded_String;
            Let_Value : Expr_Ref;
            Let_Body  : Expr_Ref;
      end case;
   end record;

   --  Polytypes (Type Schemes) represented as Forall Bound . T
   type Poly_Type is record
      Bound : Var_Sets.Set;
      T     : Type_Ref;
   end record;

   --  Substitution mapping type variables to types
   package Subst_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type     => Var_Id,
      Element_Type => Type_Ref);

   subtype Substitution is Subst_Maps.Map;

   --  Environment mapping term variables to polytypes
   package Env_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type     => Unbounded_String,
      Element_Type => Poly_Type,
      "<"          => Ada.Strings.Unbounded."<");

   subtype Environment is Env_Maps.Map;

   --  Stateful context to generate fresh type variables
   type Context is tagged record
      Next_Id : Var_Id := 0;
   end record;

   Unification_Error      : exception;
   Unbound_Variable_Error : exception;

   --  AST Constructors
   function Make_Var_Type (Id : Var_Id) return Type_Ref
     with Post => Make_Var_Type'Result /= null;

   function Make_Const_Type (Name : String) return Type_Ref
     with Post => Make_Const_Type'Result /= null;

   function Make_Arrow_Type (Left, Right : Type_Ref) return Type_Ref
     with Pre => Left /= null and Right /= null,
          Post => Make_Arrow_Type'Result /= null;

   function Make_Var_Expr (Name : String) return Expr_Ref
     with Post => Make_Var_Expr'Result /= null;

   function Make_App_Expr (Func, Arg : Expr_Ref) return Expr_Ref
     with Pre => Func /= null and Arg /= null,
          Post => Make_App_Expr'Result /= null;

   function Make_Abs_Expr (Param : String; Body_Expr : Expr_Ref) return Expr_Ref
     with Pre => Body_Expr /= null,
          Post => Make_Abs_Expr'Result /= null;

   function Make_Let_Expr (Var_Name : String; Value, Body_Expr : Expr_Ref) return Expr_Ref
     with Pre => Value /= null and Body_Expr /= null,
          Post => Make_Let_Expr'Result /= null;

   --  Core Operations
   function Fresh_Var (Ctx : in out Context) return Type_Ref
     with Post => Fresh_Var'Result /= null;

   function Types_Equal (L, R : Type_Ref) return Boolean;

   function Free_Type_Vars (T : Type_Ref) return Var_Sets.Set;
   function Free_Type_Vars (P : Poly_Type) return Var_Sets.Set;
   function Free_Type_Vars (Env : Environment) return Var_Sets.Set;

   function Apply (S : Substitution; T : Type_Ref) return Type_Ref;
   function Apply (S : Substitution; P : Poly_Type) return Poly_Type;
   function Apply (S : Substitution; Env : Environment) return Environment;

   function Compose (S1, S2 : Substitution) return Substitution;

   function Instantiate (Ctx : in out Context; P : Poly_Type) return Type_Ref
     with Post => Instantiate'Result /= null;

   function Generalize (Env : Environment; T : Type_Ref) return Poly_Type
     with Pre => T /= null;

   function Unify (T1, T2 : Type_Ref) return Substitution
     with Pre => T1 /= null and T2 /= null;

   function To_String (T : Type_Ref) return String;

   type Inference_Result is record
      Subst : Substitution;
      T     : Type_Ref;
   end record;

   --  Variant 1: Algorithm W (Bottom-Up Inference)
   function Algorithm_W (Ctx : in out Context; Env : Environment; E : Expr_Ref) return Inference_Result
     with Pre => E /= null;

   --  Variant 2: Algorithm M (Top-Down Inference / Type Checking)
   function Algorithm_M (Ctx : in out Context; Env : Environment; E : Expr_Ref; Expected : Type_Ref) return Substitution
     with Pre => E /= null and Expected /= null;

end Hindley_Milner;
