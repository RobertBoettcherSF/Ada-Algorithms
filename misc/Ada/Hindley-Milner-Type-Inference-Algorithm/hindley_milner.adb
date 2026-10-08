with Ada.Strings.Fixed;

package body Hindley_Milner is

   use Ada.Strings.Unbounded;

   --  String Conversion Helpers
   function U (S : String) return Unbounded_String renames To_Unbounded_String;
   function S (U_Str : Unbounded_String) return String renames To_String;

   -----------------------------------------------------------------------------
   --  Constructors
   -----------------------------------------------------------------------------
   function Make_Type_Var (Name : String) return Type_Access is
   begin
      return new Type_Node'(Kind => Kind_Var, Var_Name => U (Name));
   end Make_Type_Var;

   function Make_Type_Base (Name : String) return Type_Access is
   begin
      return new Type_Node'(Kind => Kind_Base, Base_Name => U (Name));
   end Make_Type_Base;

   function Make_Type_Arrow (Left, Right : Type_Access) return Type_Access is
   begin
      return new Type_Node'(Kind => Kind_Arrow, Left => Left, Right => Right);
   end Make_Type_Arrow;

   function Make_Expr_Var (Name : String) return Expr_Access is
   begin
      return new Expr_Node'(Kind => Kind_Var, Name => U (Name));
   end Make_Expr_Var;

   function Make_Expr_App (Func, Arg : Expr_Access) return Expr_Access is
   begin
      return new Expr_Node'(Kind => Kind_App, Func => Func, Arg => Arg);
   end Make_Expr_App;

   function Make_Expr_Abs (Param : String; Body_Expr : Expr_Access) return Expr_Access is
   begin
      return new Expr_Node'(Kind => Kind_Abs, Param => U (Param), Body_Expr => Body_Expr);
   end Make_Expr_Abs;

   function Make_Expr_Let (Bound_Var : String; Value_Expr, Let_Body : Expr_Access) return Expr_Access is
   begin
      return new Expr_Node'(Kind => Kind_Let, Bound_Var => U (Bound_Var), Value_Expr => Value_Expr, Let_Body => Let_Body);
   end Make_Expr_Let;

   -----------------------------------------------------------------------------
   --  Free Type Variables (FTV)
   -----------------------------------------------------------------------------
   function FTV_Type (T : Type_Access) return String_Sets.Set is
      Res : String_Sets.Set;
   begin
      case T.Kind is
         when Kind_Var =>
            Res.Insert (S (T.Var_Name));
         when Kind_Base =>
            null;
         when Kind_Arrow =>
            Res.Union (FTV_Type (T.Left));
            Res.Union (FTV_Type (T.Right));
      end case;
      return Res;
   end FTV_Type;

   function FTV_Env (Env : Environment) return String_Sets.Set is
      Res : String_Sets.Set;
   begin
      for C in Env.Iterate loop
         declare
            Sch : constant Scheme := Env_Maps.Element (C);
            Sch_FTV : String_Sets.Set := FTV_Type (Sch.T);
         begin
            Sch_FTV.Difference (Sch.Bound_Vars);
            Res.Union (Sch_FTV);
         end;
      end loop;
      return Res;
   end FTV_Env;

   -----------------------------------------------------------------------------
   --  Substitutions
   -----------------------------------------------------------------------------
   function Apply_Subst_Type (Sub : Substitution; T : Type_Access) return Type_Access is
   begin
      case T.Kind is
         when Kind_Var =>
            if Sub.Contains (S (T.Var_Name)) then
               return Sub.Element (S (T.Var_Name));
            else
               return T;
            end if;
         when Kind_Base =>
            return T;
         when Kind_Arrow =>
            return Make_Type_Arrow
              (Apply_Subst_Type (Sub, T.Left),
               Apply_Subst_Type (Sub, T.Right));
      end case;
   end Apply_Subst_Type;

   function Apply_Subst_Env (Sub : Substitution; Env : Environment) return Environment is
      Res : Environment;
   begin
      for C in Env.Iterate loop
         declare
            K : constant String := Env_Maps.Key (C);
            Sch : constant Scheme := Env_Maps.Element (C);
            Clean_Sub : Substitution := Sub;
         begin
            --  Remove bound variables from the substitution to prevent capture
            for B_Var of Sch.Bound_Vars loop
               Clean_Sub.Exclude (B_Var);
            end loop;
            Res.Insert (K, Scheme'(Sch.Bound_Vars, Apply_Subst_Type (Clean_Sub, Sch.T)));
         end;
      end loop;
      return Res;
   end Apply_Subst_Env;

   function Compose_Subst (S_After, S_Before : Substitution) return Substitution is
      Res : Substitution := S_After;
   begin
      --  For Compose(S_After, S_Before), mathematically S_After o S_Before:
      --  First apply S_Before, then S_After.
      for C in S_Before.Iterate loop
         declare
            K : constant String := Subst_Maps.Key (C);
            V : constant Type_Access := Subst_Maps.Element (C);
            V_Sub : constant Type_Access := Apply_Subst_Type (S_After, V);
         begin
            if Res.Contains (K) then
               Res.Include (K, V_Sub);
            else
               Res.Insert (K, V_Sub);
            end if;
         end;
      end loop;
      return Res;
   end Compose_Subst;

   -----------------------------------------------------------------------------
   --  Unification
   -----------------------------------------------------------------------------
   function Bind (Name : String; T : Type_Access) return Substitution is
      Res : Substitution;
   begin
      if T.Kind = Kind_Var and then S (T.Var_Name) = Name then
         return Res; -- Empty substitution
      end if;
      
      --  Occurs Check
      if FTV_Type (T).Contains (Name) then
         raise Unification_Error;
      end if;
      
      Res.Insert (Name, T);
      return Res;
   end Bind;

   function Unify (T1, T2 : Type_Access) return Substitution is
   begin
      --  Fast identity check
      if T1 = T2 then
         return Subst_Maps.Empty_Map;
      end if;

      if T1.Kind = Kind_Var then
         return Bind (S (T1.Var_Name), T2);
      elsif T2.Kind = Kind_Var then
         return Bind (S (T2.Var_Name), T1);
      elsif T1.Kind = Kind_Base and then T2.Kind = Kind_Base then
         if S (T1.Base_Name) = S (T2.Base_Name) then
            return Subst_Maps.Empty_Map;
         else
            raise Unification_Error;
         end if;
      elsif T1.Kind = Kind_Arrow and then T2.Kind = Kind_Arrow then
         declare
            S1 : constant Substitution := Unify (T1.Left, T2.Left);
            S2 : constant Substitution := Unify 
              (Apply_Subst_Type (S1, T1.Right), 
               Apply_Subst_Type (S1, T2.Right));
         begin
            return Compose_Subst (S2, S1);
         end;
      else
         raise Unification_Error;
      end if;
   end Unify;

   -----------------------------------------------------------------------------
   --  Generalize, Instantiate and Fresh Variables
   -----------------------------------------------------------------------------
   function Fresh_Var (State : in out Infer_State) return Type_Access is
      use Ada.Strings;
      use Ada.Strings.Fixed;
      Img : constant String := Trim (Natural'Image (State.Next_ID), Left);
      Name : constant String := "t" & Img;
   begin
      State.Next_ID := State.Next_ID + 1;
      return Make_Type_Var (Name);
   end Fresh_Var;

   function Instantiate (Sch : Scheme; State : in out Infer_State) return Type_Access is
      Sub : Substitution;
   begin
      for Var_Name of Sch.Bound_Vars loop
         Sub.Insert (Var_Name, Fresh_Var (State));
      end loop;
      return Apply_Subst_Type (Sub, Sch.T);
   end Instantiate;

   function Generalize (Env : Environment; T : Type_Access) return Scheme is
      Env_FTV : constant String_Sets.Set := FTV_Env (Env);
      T_FTV   : constant String_Sets.Set := FTV_Type (T);
      Bound   : String_Sets.Set := T_FTV;
   begin
      Bound.Difference (Env_FTV);
      return Scheme'(Bound_Vars => Bound, T => T);
   end Generalize;

   -----------------------------------------------------------------------------
   --  Algorithm W (Core Step)
   -----------------------------------------------------------------------------
   function Algorithm_W_Step
     (Env   : Environment;
      Expr  : Expr_Access;
      State : in out Infer_State;
      Poly  : Boolean) return Infer_Result
   is
      Empty_Sub : Substitution;
   begin
      case Expr.Kind is
         when Kind_Var =>
            if not Env.Contains (S (Expr.Name)) then
               raise Unbound_Variable_Error;
            end if;
            declare
               Sch : constant Scheme := Env.Element (S (Expr.Name));
               T   : constant Type_Access := Instantiate (Sch, State);
            begin
               return (Empty_Sub, T);
            end;
            
         when Kind_App =>
            declare
               Res1   : constant Infer_Result := Algorithm_W_Step (Env, Expr.Func, State, Poly);
               Env1   : constant Environment := Apply_Subst_Env (Res1.Sub, Env);
               Res2   : constant Infer_Result := Algorithm_W_Step (Env1, Expr.Arg, State, Poly);
               Tv     : constant Type_Access := Fresh_Var (State);
               T1_Sub : constant Type_Access := Apply_Subst_Type (Res2.Sub, Res1.T);
               S3     : constant Substitution := Unify (T1_Sub, Make_Type_Arrow (Res2.T, Tv));
            begin
               return (Compose_Subst (S3, Compose_Subst (Res2.Sub, Res1.Sub)),
                       Apply_Subst_Type (S3, Tv));
            end;
            
         when Kind_Abs =>
            declare
               Tv : constant Type_Access := Fresh_Var (State);
               New_Env : Environment := Env;
               Empty_Set : String_Sets.Set;
            begin
               New_Env.Include (S (Expr.Param), Scheme'(Empty_Set, Tv));
               declare
                  Res1 : constant Infer_Result := Algorithm_W_Step (New_Env, Expr.Body_Expr, State, Poly);
               begin
                  return (Res1.Sub, Make_Type_Arrow (Apply_Subst_Type (Res1.Sub, Tv), Res1.T));
               end;
            end;
            
         when Kind_Let =>
            declare
               Res1    : constant Infer_Result := Algorithm_W_Step (Env, Expr.Value_Expr, State, Poly);
               Env1    : constant Environment := Apply_Subst_Env (Res1.Sub, Env);
               Sch     : Scheme;
               New_Env : Environment := Env1;
            begin
               if Poly then
                  Sch := Generalize (Env1, Res1.T);
               else
                  Sch := Scheme'(String_Sets.Empty_Set, Res1.T);
               end if;
               
               New_Env.Include (S (Expr.Bound_Var), Sch);
               declare
                  Res2 : constant Infer_Result := Algorithm_W_Step (New_Env, Expr.Let_Body, State, Poly);
               begin
                  return (Compose_Subst (Res2.Sub, Res1.Sub), Res2.T);
               end;
            end;
      end case;
   end Algorithm_W_Step;

   -----------------------------------------------------------------------------
   --  Wrappers
   -----------------------------------------------------------------------------
   function Infer_Type
     (Env   : Environment;
      Expr  : Expr_Access;
      State : in out Infer_State) return Type_Access
   is
      Res : constant Infer_Result := Algorithm_W_Step (Env, Expr, State, True);
   begin
      return Apply_Subst_Type (Res.Sub, Res.T);
   end Infer_Type;

   function Infer_Type_Monomorphic
     (Env   : Environment;
      Expr  : Expr_Access;
      State : in out Infer_State) return Type_Access
   is
      Res : constant Infer_Result := Algorithm_W_Step (Env, Expr, State, False);
   begin
      return Apply_Subst_Type (Res.Sub, Res.T);
   end Infer_Type_Monomorphic;

   -----------------------------------------------------------------------------
   --  Formatting
   -----------------------------------------------------------------------------
   function Type_To_String (T : Type_Access) return String is
   begin
      case T.Kind is
         when Kind_Var =>
            return S (T.Var_Name);
         when Kind_Base =>
            return S (T.Base_Name);
         when Kind_Arrow =>
            return "(" & Type_To_String (T.Left) & " -> " & Type_To_String (T.Right) & ")";
      end case;
   end Type_To_String;

end Hindley_Milner;
