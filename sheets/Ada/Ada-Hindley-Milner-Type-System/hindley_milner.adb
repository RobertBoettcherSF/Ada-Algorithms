package body Hindley_Milner is

   function Make_Var_Type (Id : Var_Id) return Type_Ref is
   begin
      return new Type_Node'(Kind => Kind_Var, Id => Id);
   end Make_Var_Type;

   function Make_Const_Type (Name : String) return Type_Ref is
   begin
      return new Type_Node'(Kind => Kind_Const, Name => To_Unbounded_String (Name));
   end Make_Const_Type;

   function Make_Arrow_Type (Left, Right : Type_Ref) return Type_Ref is
   begin
      return new Type_Node'(Kind => Kind_Arrow, Left => Left, Right => Right);
   end Make_Arrow_Type;

   function Make_Var_Expr (Name : String) return Expr_Ref is
   begin
      return new Expr_Node'(Kind => Expr_Var, Var_Name => To_Unbounded_String (Name));
   end Make_Var_Expr;

   function Make_App_Expr (Func, Arg : Expr_Ref) return Expr_Ref is
   begin
      return new Expr_Node'(Kind => Expr_App, Func => Func, Arg => Arg);
   end Make_App_Expr;

   function Make_Abs_Expr (Param : String; Body_Expr : Expr_Ref) return Expr_Ref is
   begin
      return new Expr_Node'(Kind => Expr_Abs, Param_Name => To_Unbounded_String (Param), Body_Expr => Body_Expr);
   end Make_Abs_Expr;

   function Make_Let_Expr (Var_Name : String; Value, Body_Expr : Expr_Ref) return Expr_Ref is
   begin
      return new Expr_Node'(Kind => Expr_Let, Let_Var => To_Unbounded_String (Var_Name), Let_Value => Value, Let_Body => Body_Expr);
   end Make_Let_Expr;

   function Fresh_Var (Ctx : in out Context) return Type_Ref is
      T : constant Type_Ref := Make_Var_Type (Ctx.Next_Id);
   begin
      Ctx.Next_Id := Ctx.Next_Id + 1;
      return T;
   end Fresh_Var;

   function Types_Equal (L, R : Type_Ref) return Boolean is
   begin
      if L = null and R = null then return True; end if;
      if L = null or R = null then return False; end if;
      if L.Kind /= R.Kind then return False; end if;

      case L.Kind is
         when Kind_Var =>
            return L.Id = R.Id;
         when Kind_Const =>
            return L.Name = R.Name;
         when Kind_Arrow =>
            return Types_Equal (L.Left, R.Left) and then Types_Equal (L.Right, R.Right);
      end case;
   end Types_Equal;

   function Free_Type_Vars (T : Type_Ref) return Var_Sets.Set is
      Result : Var_Sets.Set;
   begin
      if T = null then return Result; end if;
      case T.Kind is
         when Kind_Var =>
            Result.Insert (T.Id);
         when Kind_Const =>
            null;
         when Kind_Arrow =>
            Result.Union (Free_Type_Vars (T.Left));
            Result.Union (Free_Type_Vars (T.Right));
      end case;
      return Result;
   end Free_Type_Vars;

   function Free_Type_Vars (P : Poly_Type) return Var_Sets.Set is
      Result : Var_Sets.Set := Free_Type_Vars (P.T);
   begin
      Result.Difference (P.Bound);
      return Result;
   end Free_Type_Vars;

   function Free_Type_Vars (Env : Environment) return Var_Sets.Set is
      Result : Var_Sets.Set;
   begin
      for Cursor in Env.Iterate loop
         Result.Union (Free_Type_Vars (Env_Maps.Element (Cursor)));
      end loop;
      return Result;
   end Free_Type_Vars;

   function Apply (S : Substitution; T : Type_Ref) return Type_Ref is
   begin
      if T = null then return null; end if;
      case T.Kind is
         when Kind_Var =>
            if S.Contains (T.Id) then
               return S.Element (T.Id);
            else
               return T;
            end if;
         when Kind_Const =>
            return T;
         when Kind_Arrow =>
            return Make_Arrow_Type (Apply (S, T.Left), Apply (S, T.Right));
      end case;
   end Apply;

   function Apply (S : Substitution; P : Poly_Type) return Poly_Type is
      Subst_No_Bound : Substitution := S;
   begin
      for Id of P.Bound loop
         if Subst_No_Bound.Contains (Id) then
            Subst_No_Bound.Delete (Id);
         end if;
      end loop;
      return (Bound => P.Bound, T => Apply (Subst_No_Bound, P.T));
   end Apply;

   function Apply (S : Substitution; Env : Environment) return Environment is
      Result : Environment;
   begin
      for Cursor in Env.Iterate loop
         Result.Include (Env_Maps.Key (Cursor), Apply (S, Env_Maps.Element (Cursor)));
      end loop;
      return Result;
   end Apply;

   function Compose (S1, S2 : Substitution) return Substitution is
      Result : Substitution;
   begin
      for Cursor in S2.Iterate loop
         Result.Include (Subst_Maps.Key (Cursor), Apply (S1, Subst_Maps.Element (Cursor)));
      end loop;
      for Cursor in S1.Iterate loop
         if not Result.Contains (Subst_Maps.Key (Cursor)) then
            Result.Include (Subst_Maps.Key (Cursor), Subst_Maps.Element (Cursor));
         end if;
      end loop;
      return Result;
   end Compose;

   function Instantiate (Ctx : in out Context; P : Poly_Type) return Type_Ref is
      S : Substitution;
   begin
      for Id of P.Bound loop
         S.Include (Id, Fresh_Var (Ctx));
      end loop;
      return Apply (S, P.T);
   end Instantiate;

   function Generalize (Env : Environment; T : Type_Ref) return Poly_Type is
      Env_Ftv : constant Var_Sets.Set := Free_Type_Vars (Env);
      T_Ftv   : constant Var_Sets.Set := Free_Type_Vars (T);
      Bound   : Var_Sets.Set := T_Ftv;
   begin
      Bound.Difference (Env_Ftv);
      return (Bound => Bound, T => T);
   end Generalize;

   function Bind (Id : Var_Id; T : Type_Ref) return Substitution is
      Result : Substitution;
   begin
      if T.Kind = Kind_Var and then T.Id = Id then
         return Result;
      elsif Free_Type_Vars (T).Contains (Id) then
         raise Unification_Error with "Occurs check failed for variable " & Var_Id'Image (Id);
      else
         Result.Include (Id, T);
         return Result;
      end if;
   end Bind;

   function Unify (T1, T2 : Type_Ref) return Substitution is
   begin
      if T1.Kind = Kind_Arrow and then T2.Kind = Kind_Arrow then
         declare
            Subst1 : constant Substitution := Unify (T1.Left, T2.Left);
            Subst2 : constant Substitution := Unify (Apply (Subst1, T1.Right), Apply (Subst1, T2.Right));
         begin
            return Compose (Subst2, Subst1);
         end;
      elsif T1.Kind = Kind_Var then
         return Bind (T1.Id, T2);
      elsif T2.Kind = Kind_Var then
         return Bind (T2.Id, T1);
      elsif T1.Kind = Kind_Const and then T2.Kind = Kind_Const and then T1.Name = T2.Name then
         return Subst_Maps.Empty_Map;
      else
         raise Unification_Error with "Type mismatch: " & To_String (T1) & " vs " & To_String (T2);
      end if;
   end Unify;

   function To_String (T : Type_Ref) return String is
      function Trim (S : String) return String is
      begin
         if S'Length > 0 and then S (S'First) = ' ' then
            return S (S'First + 1 .. S'Last);
         else
            return S;
         end if;
      end Trim;
   begin
      if T = null then return "null"; end if;
      case T.Kind is
         when Kind_Var =>
            return "a" & Trim (Var_Id'Image (T.Id));
         when Kind_Const =>
            return To_String (T.Name);
         when Kind_Arrow =>
            return "(" & To_String (T.Left) & " -> " & To_String (T.Right) & ")";
      end case;
   end To_String;

   function Algorithm_W (Ctx : in out Context; Env : Environment; E : Expr_Ref) return Inference_Result is
   begin
      case E.Kind is
         when Expr_Var =>
            if not Env.Contains (E.Var_Name) then
               raise Unbound_Variable_Error with To_String (E.Var_Name);
            end if;
            declare
               P : constant Poly_Type := Env.Element (E.Var_Name);
               T : constant Type_Ref  := Instantiate (Ctx, P);
            begin
               return (Subst => Subst_Maps.Empty_Map, T => T);
            end;

         when Expr_App =>
            declare
               Res1   : constant Inference_Result := Algorithm_W (Ctx, Env, E.Func);
               Env1   : constant Environment      := Apply (Res1.Subst, Env);
               Res2   : constant Inference_Result := Algorithm_W (Ctx, Env1, E.Arg);
               T_Var  : constant Type_Ref         := Fresh_Var (Ctx);
               Arrow  : constant Type_Ref         := Make_Arrow_Type (Res2.T, T_Var);
               Subst3 : constant Substitution     := Unify (Apply (Res2.Subst, Res1.T), Arrow);
            begin
               return (Subst => Compose (Subst3, Compose (Res2.Subst, Res1.Subst)),
                       T     => Apply (Subst3, T_Var));
            end;

         when Expr_Abs =>
            declare
               T_Var : constant Type_Ref  := Fresh_Var (Ctx);
               P     : constant Poly_Type := (Bound => Var_Sets.Empty_Set, T => T_Var);
               Env1  : Environment        := Env;
            begin
               Env1.Include (E.Param_Name, P);
               declare
                  Res1 : constant Inference_Result := Algorithm_W (Ctx, Env1, E.Body_Expr);
               begin
                  return (Subst => Res1.Subst,
                          T     => Make_Arrow_Type (Apply (Res1.Subst, T_Var), Res1.T));
               end;
            end;

         when Expr_Let =>
            declare
               Res1 : constant Inference_Result := Algorithm_W (Ctx, Env, E.Let_Value);
               Env1 : constant Environment      := Apply (Res1.Subst, Env);
               P    : constant Poly_Type        := Generalize (Env1, Res1.T);
               Env2 : Environment               := Env1;
            begin
               Env2.Include (E.Let_Var, P);
               declare
                  Res2 : constant Inference_Result := Algorithm_W (Ctx, Env2, E.Let_Body);
               begin
                  return (Subst => Compose (Res2.Subst, Res1.Subst),
                          T     => Res2.T);
               end;
            end;
      end case;
   end Algorithm_W;

   function Algorithm_M (Ctx : in out Context; Env : Environment; E : Expr_Ref; Expected : Type_Ref) return Substitution is
   begin
      case E.Kind is
         when Expr_Var =>
            if not Env.Contains (E.Var_Name) then
               raise Unbound_Variable_Error with To_String (E.Var_Name);
            end if;
            declare
               P : constant Poly_Type := Env.Element (E.Var_Name);
               T : constant Type_Ref  := Instantiate (Ctx, P);
            begin
               return Unify (T, Expected);
            end;

         when Expr_App =>
            declare
               Beta   : constant Type_Ref     := Fresh_Var (Ctx);
               Arrow  : constant Type_Ref     := Make_Arrow_Type (Beta, Expected);
               Subst1 : constant Substitution := Algorithm_M (Ctx, Env, E.Func, Arrow);
               Env1   : constant Environment  := Apply (Subst1, Env);
               Subst2 : constant Substitution := Algorithm_M (Ctx, Env1, E.Arg, Apply (Subst1, Beta));
            begin
               return Compose (Subst2, Subst1);
            end;

         when Expr_Abs =>
            declare
               Beta1  : constant Type_Ref     := Fresh_Var (Ctx);
               Beta2  : constant Type_Ref     := Fresh_Var (Ctx);
               Arrow  : constant Type_Ref     := Make_Arrow_Type (Beta1, Beta2);
               Subst1 : constant Substitution := Unify (Arrow, Expected);
               Env1   : Environment           := Apply (Subst1, Env);
               P      : constant Poly_Type    := (Bound => Var_Sets.Empty_Set, T => Apply (Subst1, Beta1));
            begin
               Env1.Include (E.Param_Name, P);
               declare
                  Subst2 : constant Substitution := Algorithm_M (Ctx, Env1, E.Body_Expr, Apply (Subst1, Beta2));
               begin
                  return Compose (Subst2, Subst1);
               end;
            end;

         when Expr_Let =>
            declare
               Beta   : constant Type_Ref     := Fresh_Var (Ctx);
               Subst1 : constant Substitution := Algorithm_M (Ctx, Env, E.Let_Value, Beta);
               Env1   : constant Environment  := Apply (Subst1, Env);
               T1     : constant Type_Ref     := Apply (Subst1, Beta);
               P      : constant Poly_Type    := Generalize (Env1, T1);
               Env2   : Environment           := Env1;
            begin
               Env2.Include (E.Let_Var, P);
               declare
                  Subst2 : constant Substitution := Algorithm_M (Ctx, Env2, E.Let_Body, Apply (Subst1, Expected));
               begin
                  return Compose (Subst2, Subst1);
               end;
            end;
      end case;
   end Algorithm_M;

end Hindley_Milner;
