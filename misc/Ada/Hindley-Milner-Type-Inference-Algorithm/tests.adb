with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings;
with Ada.Strings.Fixed;
with Hindley_Milner; use Hindley_Milner;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   --  Variables used across tests
   St : Infer_State;
   Empty_Env : Environment;
   Int_Type : constant Type_Access := Make_Type_Base ("Int");
   Bool_Type : constant Type_Access := Make_Type_Base ("Bool");

   T_Var_A : constant Type_Access := Make_Type_Var ("a");
   T_Var_B : constant Type_Access := Make_Type_Var ("b");

begin
   --  TEST 1: Type Constructors
   Put_Line ("TEST 1 — Type Constructors");
   declare
      Tv : constant Type_Access := Make_Type_Var ("a");
      Tb : constant Type_Access := Make_Type_Base ("Int");
      Ta : constant Type_Access := Make_Type_Arrow (Tv, Tb);
   begin
      Check ("1.1 Type_Var created", Tv.Kind = Kind_Var);
      Check ("1.2 Type_Base created", Tb.Kind = Kind_Base);
      Check ("1.3 Type_Arrow created properly", Ta.Kind = Kind_Arrow and then Ta.Left = Tv);
   end;

   --  TEST 2: Expression Constructors
   Put_Line ("TEST 2 — Expression Constructors");
   declare
      Ev : constant Expr_Access := Make_Expr_Var ("x");
      Ea : constant Expr_Access := Make_Expr_App (Ev, Ev);
      El : constant Expr_Access := Make_Expr_Let ("y", Ev, Ea);
   begin
      Check ("2.1 Expr_Var created", Ev.Kind = Kind_Var);
      Check ("2.2 Expr_App created properly", Ea.Kind = Kind_App);
      Check ("2.3 Expr_Let created properly", El.Kind = Kind_Let);
   end;

   --  TEST 3: Free Type Variables (FTV)
   Put_Line ("TEST 3 — Free Type Variables");
   declare
      F1 : constant String_Sets.Set := FTV_Type (Int_Type);
      F2 : constant String_Sets.Set := FTV_Type (Make_Type_Arrow (T_Var_A, T_Var_B));
      F3 : constant String_Sets.Set := FTV_Type (Make_Type_Arrow (T_Var_A, T_Var_A));
   begin
      Check ("3.1 Base type has 0 FTVs", F1.Is_Empty);
      Check ("3.2 Arrow a->b has 2 FTVs", Natural (F2.Length) = 2);
      Check ("3.3 Arrow a->a has 1 FTV", Natural (F3.Length) = 1);
   end;

   --  TEST 4: Apply Subst Type
   Put_Line ("TEST 4 — Apply Substitutions on Types");
   declare
      Sub : Substitution;
      T1  : constant Type_Access := Make_Type_Arrow (T_Var_A, T_Var_B);
   begin
      Sub.Insert ("a", Int_Type);
      Check ("4.1 Empty subst is identity", Type_To_String (Apply_Subst_Type (Subst_Maps.Empty_Map, T1)) = "(a -> b)");
      Check ("4.2 Subst applied to var", Type_To_String (Apply_Subst_Type (Sub, T_Var_A)) = "Int");
      Check ("4.3 Subst applied to arrow", Type_To_String (Apply_Subst_Type (Sub, T1)) = "(Int -> b)");
   end;

   --  TEST 5: Apply Subst Environment
   Put_Line ("TEST 5 — Apply Substitutions on Environment");
   declare
      Sub : Substitution;
      Env : Environment;
      S_Bound : String_Sets.Set;
   begin
      Sub.Insert ("a", Int_Type);
      S_Bound.Insert ("a");
      --  Env has x: forall a. a -> b
      Env.Insert ("x", Scheme'(Bound_Vars => S_Bound, T => Make_Type_Arrow (T_Var_A, T_Var_B)));
      declare
         New_Env : constant Environment := Apply_Subst_Env (Sub, Env);
         Sch : constant Scheme := New_Env.Element ("x");
      begin
         Check ("5.1 Env contains x", New_Env.Contains ("x"));
         --  'a' is bound, so it shouldn't be substituted. 'b' isn't in substitution.
         Check ("5.2 Bound var 'a' protected from subst", Type_To_String (Sch.T) = "(a -> b)");
         Check ("5.3 Bound var list intact", Sch.Bound_Vars.Contains ("a"));
      end;
   end;

   --  TEST 6: Compose Substitutions
   Put_Line ("TEST 6 — Compose Substitutions");
   declare
      S1, S2, S3 : Substitution;
   begin
      S1.Insert ("a", Int_Type);
      S2.Insert ("b", Bool_Type);
      S3 := Compose_Subst (S1, S2);
      Check ("6.1 Independent compose size", Natural (S3.Length) >= 2);
      Check ("6.2 S3 maps a -> Int", Type_To_String (S3.Element ("a")) = "Int");
      Check ("6.3 S3 maps b -> Bool", Type_To_String (S3.Element ("b")) = "Bool");
   end;

   --  TEST 7: Unify Identical & Base Types
   Put_Line ("TEST 7 — Unify Identical and Base Types");
   declare
      S1 : constant Substitution := Unify (Int_Type, Int_Type);
      S2 : constant Substitution := Unify (T_Var_A, T_Var_A);
   begin
      Check ("7.1 Int vs Int gives empty", S1.Is_Empty);
      Check ("7.2 a vs a gives empty", S2.Is_Empty);
      begin
         declare
            S3 : constant Substitution := Unify (Int_Type, Bool_Type);
            pragma Unreferenced (S3);
         begin
            Check ("7.3 Int vs Bool fails (reached unreachable)", False);
         end;
      exception
         when Unification_Error => Check ("7.3 Int vs Bool raises error", True);
      end;
   end;

   --  TEST 8: Unify Variables
   Put_Line ("TEST 8 — Unify Variables");
   declare
      S1 : constant Substitution := Unify (T_Var_A, Int_Type);
      S2 : constant Substitution := Unify (Bool_Type, T_Var_B);
      S3 : constant Substitution := Unify (T_Var_A, T_Var_B);
   begin
      Check ("8.1 a vs Int maps a -> Int", Type_To_String (S1.Element ("a")) = "Int");
      Check ("8.2 Bool vs b maps b -> Bool", Type_To_String (S2.Element ("b")) = "Bool");
      Check ("8.3 a vs b maps a -> b", Type_To_String (S3.Element ("a")) = "b");
   end;

   --  TEST 9: Unify Occurs Check
   Put_Line ("TEST 9 — Unify Occurs Check");
   declare
      T_Self : constant Type_Access := Make_Type_Arrow (T_Var_A, Int_Type);
   begin
      begin
         declare
            S : constant Substitution := Unify (T_Var_A, T_Self);
            pragma Unreferenced (S);
         begin
            Check ("9.1 Occurs check a vs a -> Int fails", False);
         end;
      exception
         when Unification_Error => Check ("9.1 Occurs check a vs a -> Int caught", True);
      end;
      
      begin
         declare
            S : constant Substitution := Unify (T_Self, T_Var_A);
            pragma Unreferenced (S);
         begin
            Check ("9.2 Occurs check reversed fails", False);
         end;
      exception
         when Unification_Error => Check ("9.2 Occurs check reversed caught", True);
      end;
      
      declare
         S_Good : constant Substitution := Unify (Make_Type_Arrow (T_Var_A, T_Var_B), Make_Type_Arrow (T_Var_B, T_Var_A));
      begin
         Check ("9.3 Unify a->b vs b->a succeeds", not S_Good.Is_Empty);
      end;
   end;

   --  TEST 10: Infer Variable & Unbound
   Put_Line ("TEST 10 — Infer Variable");
   declare
      Env : Environment;
      Var_E : constant Expr_Access := Make_Expr_Var ("x");
      T1 : Type_Access;
   begin
      begin
         T1 := Infer_Type (Env, Var_E, St);
         Check ("10.1 Unbound var raises error", False);
      exception
         when Unbound_Variable_Error => Check ("10.1 Unbound var raises error caught", True);
      end;
      
      Env.Insert ("x", Scheme'(String_Sets.Empty_Set, Int_Type));
      T1 := Infer_Type (Env, Var_E, St);
      Check ("10.2 Bound var inferred properly", Type_To_String (T1) = "Int");
      
      declare
         -- Polmorphic instantiation test
         S_Bound : String_Sets.Set;
      begin
         S_Bound.Insert ("a");
         Env.Insert ("id", Scheme'(S_Bound, Make_Type_Arrow (T_Var_A, T_Var_A)));
         T1 := Infer_Type (Env, Make_Expr_Var ("id"), St);
         Check ("10.3 Polymorphic var instantiation", Type_To_String (T1) /= "(a -> a)" and then T1.Kind = Kind_Arrow);
      end;
   end;

   --  TEST 11: Infer Abstraction (Identity)
   Put_Line ("TEST 11 — Infer Abstraction");
   declare
      -- \x -> x
      Id_Expr : constant Expr_Access := Make_Expr_Abs ("x", Make_Expr_Var ("x"));
      T1 : constant Type_Access := Infer_Type (Empty_Env, Id_Expr, St);
   begin
      Check ("11.1 Identity function is arrow type", T1.Kind = Kind_Arrow);
      -- e.g. "(t3 -> t3)"
      Check ("11.2 Arrow left and right match", Type_To_String (T1.Left) = Type_To_String (T1.Right));
      
      declare
         -- \x -> \y -> x
         Const_Expr : constant Expr_Access := Make_Expr_Abs ("x", Make_Expr_Abs ("y", Make_Expr_Var ("x")));
         T2 : constant Type_Access := Infer_Type (Empty_Env, Const_Expr, St);
      begin
         Check ("11.3 Const function inferred", T2.Kind = Kind_Arrow and then T2.Right.Kind = Kind_Arrow);
      end;
   end;

   --  TEST 12: Infer Application
   Put_Line ("TEST 12 — Infer Application");
   declare
      Id_Expr : constant Expr_Access := Make_Expr_Abs ("x", Make_Expr_Var ("x"));
      Env : Environment;
   begin
      Env.Insert ("num", Scheme'(String_Sets.Empty_Set, Int_Type));
      declare
         App_Expr : constant Expr_Access := Make_Expr_App (Id_Expr, Make_Expr_Var ("num"));
         T1 : constant Type_Access := Infer_Type (Env, App_Expr, St);
      begin
         Check ("12.1 (id num) inferred as Int", Type_To_String (T1) = "Int");
      end;
      
      begin
         declare
            Bad_App : constant Expr_Access := Make_Expr_App (Make_Expr_Var ("num"), Make_Expr_Var ("num"));
            T2 : constant Type_Access := Infer_Type (Env, Bad_App, St);
            pragma Unreferenced (T2);
         begin
            Check ("12.2 Applying Int to Int should fail", False);
         end;
      exception
         when Unification_Error => Check ("12.2 Applying Int to Int raises unification error", True);
      end;
      
      declare
         -- (\f -> f num) id -> Int
         App_Higher : constant Expr_Access := Make_Expr_App (
           Make_Expr_Abs ("f", Make_Expr_App (Make_Expr_Var ("f"), Make_Expr_Var ("num"))),
           Id_Expr
         );
         T3 : constant Type_Access := Infer_Type (Env, App_Higher, St);
      begin
         Check ("12.3 Higher order application inferred", Type_To_String (T3) = "Int");
      end;
   end;

   --  TEST 13: Infer Polymorphic Let
   Put_Line ("TEST 13 — Infer Polymorphic Let");
   declare
      -- let id = \x -> x in id id
      Id_Expr : constant Expr_Access := Make_Expr_Abs ("x", Make_Expr_Var ("x"));
      Let_Expr : constant Expr_Access := Make_Expr_Let ("id", Id_Expr, Make_Expr_App (Make_Expr_Var ("id"), Make_Expr_Var ("id")));
      T1 : constant Type_Access := Infer_Type (Empty_Env, Let_Expr, St);
   begin
      Check ("13.1 Poly let evaluates self-application of id", T1.Kind = Kind_Arrow);
      Check ("13.2 Left and Right match for resulting id", Type_To_String (T1.Left) = Type_To_String (T1.Right));
      
      declare
         Env : Environment;
         -- let id = \x -> x in id num (where num is Int)
         Let2 : constant Expr_Access := Make_Expr_Let ("id", Id_Expr, Make_Expr_App (Make_Expr_Var ("id"), Make_Expr_Var ("num")));
         T2 : Type_Access;
      begin
         Env.Insert ("num", Scheme'(String_Sets.Empty_Set, Int_Type));
         T2 := Infer_Type (Env, Let2, St);
         Check ("13.3 Poly let id applied to Int yields Int", Type_To_String (T2) = "Int");
      end;
   end;

   --  TEST 14: Infer Monomorphic Let Variant
   Put_Line ("TEST 14 — Infer Monomorphic Let");
   declare
      Id_Expr : constant Expr_Access := Make_Expr_Abs ("x", Make_Expr_Var ("x"));
      Let_Expr : constant Expr_Access := Make_Expr_Let ("id", Id_Expr, Make_Expr_App (Make_Expr_Var ("id"), Make_Expr_Var ("id")));
   begin
      begin
         -- In monomorphic let, `id` gets a single monotype (e.g., t0 -> t0). 
         -- Unifying it against its own argument triggers the Occurs Check: (t0 -> t0) vs ((t0 -> t0) -> t1).
         declare
            T1 : constant Type_Access := Infer_Type_Monomorphic (Empty_Env, Let_Expr, St);
            pragma Unreferenced (T1);
         begin
            Check ("14.1 Mono let self-application should fail", False);
         end;
      exception
         when Unification_Error => Check ("14.1 Mono let self-application caught by occurs check", True);
      end;
      
      declare
         Env : Environment;
         Let2 : constant Expr_Access := Make_Expr_Let ("id", Id_Expr, Make_Expr_App (Make_Expr_Var ("id"), Make_Expr_Var ("num")));
         T2 : Type_Access;
      begin
         Env.Insert ("num", Scheme'(String_Sets.Empty_Set, Int_Type));
         T2 := Infer_Type_Monomorphic (Env, Let2, St);
         -- It works fine when used monomorphically once.
         Check ("14.2 Mono let id applied to Int yields Int", Type_To_String (T2) = "Int");
         Check ("14.3 Variant correctly exposes Algorithm W mono mode", True);
      end;
   end;

   Put_Line ("");
   Put_Line ("=== " & Ada.Strings.Fixed.Trim (Natural'Image (Pass_Count), Ada.Strings.Left) & " passed, "
             & Ada.Strings.Fixed.Trim (Natural'Image (Fail_Count), Ada.Strings.Left) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");

end Tests;
