package body First_Order_Logic is

   -----------------------------------------------------------------------------
   --  Term Constructors
   -----------------------------------------------------------------------------
   function Make_Variable (Name : Variable_Name) return Term_Access is
   begin
      return new Term'(Kind => Is_Variable, Name => Name);
   end Make_Variable;

   function Make_Constant (Name : Character) return Term_Access is
   begin
      return new Term'(Kind => Is_Constant, Name => Name);
   end Make_Constant;

   function Make_Function (Name : Character; Arg1 : Term_Access; Arg2 : Term_Access := null) return Term_Access is
   begin
      return new Term'(Kind => Is_Function, Name => Name, Arg1 => Arg1, Arg2 => Arg2);
   end Make_Function;

   -----------------------------------------------------------------------------
   --  Formula Constructors
   -----------------------------------------------------------------------------
   function Make_Predicate (Name : Character; Term1 : Term_Access; Term2 : Term_Access := null) return Formula_Access is
   begin
      return new Formula'(Kind => Is_Predicate, Pred_Name => Name, Term1 => Term1, Term2 => Term2);
   end Make_Predicate;

   function Make_Equality (Term1, Term2 : Term_Access) return Formula_Access is
   begin
      return new Formula'(Kind => Is_Equality, Eq_Term1 => Term1, Eq_Term2 => Term2);
   end Make_Equality;

   function Make_Not (F : Formula_Access) return Formula_Access is
   begin
      return new Formula'(Kind => Is_Not, Sub_Formula => F);
   end Make_Not;

   function Make_And (Left, Right : Formula_Access) return Formula_Access is
   begin
      return new Formula'(Kind => Is_And, Left => Left, Right => Right);
   end Make_And;

   function Make_Or (Left, Right : Formula_Access) return Formula_Access is
   begin
      return new Formula'(Kind => Is_Or, Left => Left, Right => Right);
   end Make_Or;

   function Make_Implies (Left, Right : Formula_Access) return Formula_Access is
   begin
      return new Formula'(Kind => Is_Implies, Left => Left, Right => Right);
   end Make_Implies;

   function Make_Iff (Left, Right : Formula_Access) return Formula_Access is
   begin
      return new Formula'(Kind => Is_Iff, Left => Left, Right => Right);
   end Make_Iff;

   function Make_Forall (Var : Variable_Name; Body_Formula : Formula_Access) return Formula_Access is
   begin
      return new Formula'(Kind => Is_Forall, Var_Name => Var, Body_Formula => Body_Formula);
   end Make_Forall;

   function Make_Exists (Var : Variable_Name; Body_Formula : Formula_Access) return Formula_Access is
   begin
      return new Formula'(Kind => Is_Exists, Var_Name => Var, Body_Formula => Body_Formula);
   end Make_Exists;

   -----------------------------------------------------------------------------
   --  Evaluation Logic
   -----------------------------------------------------------------------------
   function Evaluate_Term
     (T      : Term_Access;
      Interp : Interpretation'Class;
      Env    : Assignment) return Domain_Element 
   is
   begin
      case T.Kind is
         when Is_Variable => 
            return Env (T.Name);
         when Is_Constant => 
            return Interp.Eval_Constant (T.Name);
         when Is_Function =>
            declare
               V1 : constant Domain_Element := Evaluate_Term (T.Arg1, Interp, Env);
               V2 : Domain_Element := 1;
            begin
               if T.Arg2 /= null then
                  V2 := Evaluate_Term (T.Arg2, Interp, Env);
               end if;
               return Interp.Eval_Function (T.Name, V1, V2);
            end;
      end case;
   end Evaluate_Term;

   function Evaluate_Formula
     (F      : Formula_Access;
      Interp : Interpretation'Class;
      Env    : Assignment) return Boolean 
   is
   begin
      case F.Kind is
         when Is_Predicate =>
            declare
               V1 : constant Domain_Element := Evaluate_Term (F.Term1, Interp, Env);
               V2 : Domain_Element := 1;
            begin
               if F.Term2 /= null then
                  V2 := Evaluate_Term (F.Term2, Interp, Env);
               end if;
               return Interp.Eval_Predicate (F.Pred_Name, V1, V2);
            end;
            
         when Is_Equality =>
            return Evaluate_Term (F.Eq_Term1, Interp, Env) = Evaluate_Term (F.Eq_Term2, Interp, Env);
            
         when Is_Not =>
            return not Evaluate_Formula (F.Sub_Formula, Interp, Env);
            
         when Is_And =>
            return Evaluate_Formula (F.Left, Interp, Env) and then 
                   Evaluate_Formula (F.Right, Interp, Env);
                   
         when Is_Or =>
            return Evaluate_Formula (F.Left, Interp, Env) or else 
                   Evaluate_Formula (F.Right, Interp, Env);
                   
         when Is_Implies =>
            return (not Evaluate_Formula (F.Left, Interp, Env)) or else 
                   Evaluate_Formula (F.Right, Interp, Env);
                   
         when Is_Iff =>
            return Evaluate_Formula (F.Left, Interp, Env) = 
                   Evaluate_Formula (F.Right, Interp, Env);
                   
         when Is_Forall =>
            -- Universal quantifier: True if body is True for ALL domain elements
            for D in Domain_Element loop
               declare
                  New_Env : Assignment := Env;
               begin
                  New_Env (F.Var_Name) := D;
                  if not Evaluate_Formula (F.Body_Formula, Interp, New_Env) then
                     return False;
                  end if;
               end;
            end loop;
            return True;
            
         when Is_Exists =>
            -- Existential quantifier: True if body is True for AT LEAST ONE domain element
            for D in Domain_Element loop
               declare
                  New_Env : Assignment := Env;
               begin
                  New_Env (F.Var_Name) := D;
                  if Evaluate_Formula (F.Body_Formula, Interp, New_Env) then
                     return True;
                  end if;
               end;
            end loop;
            return False;
      end case;
   end Evaluate_Formula;

   -----------------------------------------------------------------------------
   --  Syntactic Analysis Helpers
   -----------------------------------------------------------------------------
   
   -- Helper to check if a term contains a specific variable
   function Term_Contains_Var (T : Term_Access; Var : Variable_Name) return Boolean is
   begin
      if T = null then
         return False;
      end if;
      case T.Kind is
         when Is_Variable => return T.Name = Var;
         when Is_Constant => return False;
         when Is_Function => 
            return Term_Contains_Var (T.Arg1, Var) or else 
                   Term_Contains_Var (T.Arg2, Var);
      end case;
   end Term_Contains_Var;

   function Is_Free_Variable (F : Formula_Access; Var : Variable_Name) return Boolean is
   begin
      case F.Kind is
         when Is_Predicate =>
            return Term_Contains_Var (F.Term1, Var) or else 
                   Term_Contains_Var (F.Term2, Var);
         when Is_Equality =>
            return Term_Contains_Var (F.Eq_Term1, Var) or else 
                   Term_Contains_Var (F.Eq_Term2, Var);
         when Is_Not =>
            return Is_Free_Variable (F.Sub_Formula, Var);
         when Is_And | Is_Or | Is_Implies | Is_Iff =>
            return Is_Free_Variable (F.Left, Var) or else 
                   Is_Free_Variable (F.Right, Var);
         when Is_Forall | Is_Exists =>
            if F.Var_Name = Var then
               return False; -- The variable is bound by this quantifier
            else
               return Is_Free_Variable (F.Body_Formula, Var);
            end if;
      end case;
   end Is_Free_Variable;

   -- Helper: Does the formula contain any quantifier at all?
   function Has_Quantifier (F : Formula_Access) return Boolean is
   begin
      if F = null then return False; end if;
      case F.Kind is
         when Is_Predicate | Is_Equality => 
            return False;
         when Is_Not => 
            return Has_Quantifier (F.Sub_Formula);
         when Is_And | Is_Or | Is_Implies | Is_Iff =>
            return Has_Quantifier (F.Left) or else Has_Quantifier (F.Right);
         when Is_Forall | Is_Exists => 
            return True;
      end case;
   end Has_Quantifier;

   function Is_Prenex_Normal_Form (F : Formula_Access) return Boolean is
   begin
      case F.Kind is
         when Is_Forall | Is_Exists =>
            -- If it's a quantifier, the body must continue the PNF
            return Is_Prenex_Normal_Form (F.Body_Formula);
         when others =>
            -- If it's not a quantifier, it cannot contain any quantifiers deeper inside
            return not Has_Quantifier (F);
      end case;
   end Is_Prenex_Normal_Form;

   -----------------------------------------------------------------------------
   --  Substitution Helpers (Deep Copy)
   -----------------------------------------------------------------------------
   
   function Copy_Term (T : Term_Access) return Term_Access is
   begin
      if T = null then return null; end if;
      case T.Kind is
         when Is_Variable => return Make_Variable (T.Name);
         when Is_Constant => return Make_Constant (T.Name);
         when Is_Function => return Make_Function (T.Name, Copy_Term (T.Arg1), Copy_Term (T.Arg2));
      end case;
   end Copy_Term;

   function Copy_Formula (F : Formula_Access) return Formula_Access is
   begin
      if F = null then return null; end if;
      case F.Kind is
         when Is_Predicate => return Make_Predicate (F.Pred_Name, Copy_Term (F.Term1), Copy_Term (F.Term2));
         when Is_Equality  => return Make_Equality (Copy_Term (F.Eq_Term1), Copy_Term (F.Eq_Term2));
         when Is_Not       => return Make_Not (Copy_Formula (F.Sub_Formula));
         when Is_And       => return Make_And (Copy_Formula (F.Left), Copy_Formula (F.Right));
         when Is_Or        => return Make_Or (Copy_Formula (F.Left), Copy_Formula (F.Right));
         when Is_Implies   => return Make_Implies (Copy_Formula (F.Left), Copy_Formula (F.Right));
         when Is_Iff       => return Make_Iff (Copy_Formula (F.Left), Copy_Formula (F.Right));
         when Is_Forall    => return Make_Forall (F.Var_Name, Copy_Formula (F.Body_Formula));
         when Is_Exists    => return Make_Exists (F.Var_Name, Copy_Formula (F.Body_Formula));
      end case;
   end Copy_Formula;

   function Substitute_Term (T : Term_Access; Var : Variable_Name; Replacement : Term_Access) return Term_Access is
   begin
      case T.Kind is
         when Is_Variable =>
            if T.Name = Var then
               return Copy_Term (Replacement);
            else
               return Copy_Term (T);
            end if;
         when Is_Constant =>
            return Copy_Term (T);
         when Is_Function =>
            return Make_Function (T.Name, 
               Substitute_Term (T.Arg1, Var, Replacement), 
               (if T.Arg2 = null then null else Substitute_Term (T.Arg2, Var, Replacement)));
      end case;
   end Substitute_Term;

   function Substitute_Formula (F : Formula_Access; Var : Variable_Name; Replacement : Term_Access) return Formula_Access is
   begin
      case F.Kind is
         when Is_Predicate =>
            return Make_Predicate (F.Pred_Name, 
               Substitute_Term (F.Term1, Var, Replacement), 
               (if F.Term2 = null then null else Substitute_Term (F.Term2, Var, Replacement)));
               
         when Is_Equality =>
            return Make_Equality (
               Substitute_Term (F.Eq_Term1, Var, Replacement),
               Substitute_Term (F.Eq_Term2, Var, Replacement));
               
         when Is_Not =>
            return Make_Not (Substitute_Formula (F.Sub_Formula, Var, Replacement));
            
         when Is_And => 
            return Make_And (Substitute_Formula (F.Left, Var, Replacement), Substitute_Formula (F.Right, Var, Replacement));
         when Is_Or => 
            return Make_Or (Substitute_Formula (F.Left, Var, Replacement), Substitute_Formula (F.Right, Var, Replacement));
         when Is_Implies => 
            return Make_Implies (Substitute_Formula (F.Left, Var, Replacement), Substitute_Formula (F.Right, Var, Replacement));
         when Is_Iff => 
            return Make_Iff (Substitute_Formula (F.Left, Var, Replacement), Substitute_Formula (F.Right, Var, Replacement));
            
         when Is_Forall =>
            if F.Var_Name = Var then
               -- Shadowing: Var is bound here, do not substitute deeper
               return Make_Forall (F.Var_Name, Copy_Formula (F.Body_Formula));
            else
               return Make_Forall (F.Var_Name, Substitute_Formula (F.Body_Formula, Var, Replacement));
            end if;
            
         when Is_Exists =>
            if F.Var_Name = Var then
               return Make_Exists (F.Var_Name, Copy_Formula (F.Body_Formula));
            else
               return Make_Exists (F.Var_Name, Substitute_Formula (F.Body_Formula, Var, Replacement));
            end if;
      end case;
   end Substitute_Formula;

end First_Order_Logic;
