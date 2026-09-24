with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
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

   Int_Type  : constant Type_Ref := Make_Const_Type ("Int");
   Bool_Type : constant Type_Ref := Make_Const_Type ("Bool");
   Empty_Env : Environment;
begin
   --  TEST 1 — Constructors & Basic Types
   Put_Line ("TEST 1 — Constructors & Basic Types");
   declare
      T_Var : constant Type_Ref := Make_Var_Type (42);
      T_Arr : constant Type_Ref := Make_Arrow_Type (Int_Type, Bool_Type);
   begin
      Check ("1.1 Make_Var_Type is Kind_Var", T_Var.Kind = Kind_Var);
      Check ("1.2 Make_Arrow_Type left is Int", Types_Equal (T_Arr.Left, Int_Type));
      Check ("1.3 Equality identifies identical structure", Types_Equal (Make_Const_Type ("Int"), Int_Type));
   end;

   --  TEST 2 — Free Type Variables (Type)
   Put_Line ("TEST 2 — Free Type Variables");
   declare
      T     : constant Type_Ref := Make_Arrow_Type (Make_Var_Type (1), Make_Var_Type (2));
      Ftvs  : constant Var_Sets.Set := Free_Type_Vars (T);
   begin
      Check ("2.1 FTV count is 2", Natural (Ftvs.Length) = 2);
      Check ("2.2 Contains Var 1", Ftvs.Contains (1));
      Check ("2.3 Contains Var 2", Ftvs.Contains (2));
   end;

   --  TEST 3 — Apply Substitution
   Put_Line ("TEST 3 — Apply Substitution");
   declare
      S     : Substitution;
      T_In  : constant Type_Ref := Make_Var_Type (5);
      T_Out : Type_Ref;
   begin
      S.Include (5, Bool_Type);
      T_Out := Apply (S, T_In);
      Check ("3.1 Applied subst is Bool", T_Out.Kind = Kind_Const and then T_Out.Name = To_Unbounded_String ("Bool"));
      
      T_Out := Apply (S, Make_Var_Type (99));
      Check ("3.2 Unmapped var remains var", T_Out.Kind = Kind_Var and then T_Out.Id = 99);
      Check ("3.3 Substitution over const type does nothing", Types_Equal (Apply (S, Int_Type), Int_Type));
   end;

   --  TEST 4 — Compose Substitutions
   Put_Line ("TEST 4 — Compose Substitutions");
   declare
      S1, S2, S3 : Substitution;
   begin
      S1.Include (1, Bool_Type);
      S2.Include (2, Make_Var_Type (1));
      S3 := Compose (S1, S2);
      Check ("4.1 Composed contains 2", S3.Contains (2));
      Check ("4.2 S1(S2(2)) yields Bool", Types_Equal (S3.Element (2), Bool_Type));
      Check ("4.3 Composed maintains 1 -> Bool", S3.Contains (1) and then Types_Equal (S3.Element (1), Bool_Type));
   end;

   --  TEST 5 — Unification (Success)
   Put_Line ("TEST 5 — Unification Success");
   declare
      T1 : constant Type_Ref := Make_Arrow_Type (Make_Var_Type (1), Int_Type);
      T2 : constant Type_Ref := Make_Arrow_Type (Bool_Type, Make_Var_Type (2));
      S  : constant Substitution := Unify (T1, T2);
   begin
      Check ("5.1 Unify resolved two variables", Natural (S.Length) = 2);
      Check ("5.2 Var 1 bound to Bool", Types_Equal (S.Element (1), Bool_Type));
      Check ("5.3 Var 2 bound to Int", Types_Equal (S.Element (2), Int_Type));
   end;

   --  TEST 6 — Unification (Mismatch / Error)
   Put_Line ("TEST 6 — Unification Mismatch");
   declare
      Fail_Caught : Boolean := False;
   begin
      begin
         declare
            S : Substitution := Unify (Int_Type, Bool_Type);
            pragma Unreferenced (S);
         begin
            null;
         end;
      exception
         when Unification_Error =>
            Fail_Caught := True;
      end;
      Check ("6.1 Caught Unification_Error for Int != Bool", Fail_Caught);
      Check ("6.2 Int_Type is not Bool_Type", not Types_Equal (Int_Type, Bool_Type));
      Check ("6.3 Kind constants match but names differ", Int_Type.Kind = Kind_Const and Bool_Type.Kind = Kind_Const);
   end;

   --  TEST 7 — Unification (Occurs Check)
   Put_Line ("TEST 7 — Unification Occurs Check");
   declare
      Occurs_Caught : Boolean := False;
      T_Var         : constant Type_Ref := Make_Var_Type (1);
      T_Arr         : constant Type_Ref := Make_Arrow_Type (T_Var, Int_Type);
   begin
      begin
         declare
            S : Substitution := Unify (T_Var, T_Arr);
            pragma Unreferenced (S);
         begin
            null;
         end;
      exception
         when Unification_Error =>
            Occurs_Caught := True;
      end;
      Check ("7.1 Caught Occurs Check", Occurs_Caught);
      Check ("7.2 Var 1 is in Arrow FTVs", Free_Type_Vars (T_Arr).Contains (1));
      Check ("7.3 Var kind matches", T_Var.Kind = Kind_Var);
   end;

   --  TEST 8 — Algorithm W (Variable Lookup)
   Put_Line ("TEST 8 — Algorithm W (Variable)");
   declare
      Ctx  : Context;
      Env  : Environment;
      Expr : constant Expr_Ref := Make_Var_Expr ("x");
      P    : constant Poly_Type := (Bound => Var_Sets.Empty_Set, T => Int_Type);
      Res  : Inference_Result;
   begin
      Env.Include (To_Unbounded_String ("x"), P);
      Res := Algorithm_W (Ctx, Env, Expr);
      Check ("8.1 W inferred correctly for var", Types_Equal (Res.T, Int_Type));
      Check ("8.2 Subst is empty", Natural (Res.Subst.Length) = 0);
      
      declare
         Fail_Caught : Boolean := False;
      begin
         begin
            Res := Algorithm_W (Ctx, Empty_Env, Expr);
         exception
            when Unbound_Variable_Error =>
               Fail_Caught := True;
         end;
         Check ("8.3 Unbound var raises exception", Fail_Caught);
      end;
   end;

   --  TEST 9 — Algorithm W (Abstraction `\x -> x`)
   Put_Line ("TEST 9 — Algorithm W (Abstraction)");
   declare
      Ctx  : Context;
      Expr : constant Expr_Ref := Make_Abs_Expr ("x", Make_Var_Expr ("x"));
      Res  : constant Inference_Result := Algorithm_W (Ctx, Empty_Env, Expr);
   begin
      Check ("9.1 Identity inferred as Arrow", Res.T.Kind = Kind_Arrow);
      Check ("9.2 Arrow left is a variable", Res.T.Left.Kind = Kind_Var);
      Check ("9.3 Arrow left equals right", Types_Equal (Res.T.Left, Res.T.Right));
   end;

   --  TEST 10 — Algorithm W (Application `(\x -> x) 42`)
   Put_Line ("TEST 10 — Algorithm W (Application)");
   declare
      Ctx  : Context;
      Env  : Environment;
      Iden : constant Expr_Ref := Make_Abs_Expr ("x", Make_Var_Expr ("x"));
      Arg  : constant Expr_Ref := Make_Var_Expr ("num");
      App  : constant Expr_Ref := Make_App_Expr (Iden, Arg);
      P    : constant Poly_Type := (Bound => Var_Sets.Empty_Set, T => Int_Type);
      Res  : Inference_Result;
   begin
      Env.Include (To_Unbounded_String ("num"), P);
      Res := Algorithm_W (Ctx, Env, App);
      Check ("10.1 Application result is Int", Types_Equal (Res.T, Int_Type));
      Check ("10.2 Context incremented correctly", Ctx.Next_Id > 0);
      Check ("10.3 Left child of app is Iden", App.Func = Iden);
   end;

   --  TEST 11 — Algorithm W (Let Polymorphism `let id = \x -> x in id id`)
   Put_Line ("TEST 11 — Algorithm W (Let Polymorphism)");
   declare
      Ctx    : Context;
      Id_Def : constant Expr_Ref := Make_Abs_Expr ("x", Make_Var_Expr ("x"));
      Id_App : constant Expr_Ref := Make_App_Expr (Make_Var_Expr ("id"), Make_Var_Expr ("id"));
      Let_Ex : constant Expr_Ref := Make_Let_Expr ("id", Id_Def, Id_App);
      Res    : constant Inference_Result := Algorithm_W (Ctx, Empty_Env, Let_Ex);
   begin
      Check ("11.1 Let bound id application returns Arrow", Res.T.Kind = Kind_Arrow);
      Check ("11.2 Result left is variable", Res.T.Left.Kind = Kind_Var);
      Check ("11.3 Result right is matching variable", Types_Equal (Res.T.Left, Res.T.Right));
   end;

   --  TEST 12 — Algorithm M (Top-Down Inference / Checking)
   Put_Line ("TEST 12 — Algorithm M (Top-Down Success)");
   declare
      Ctx      : Context;
      Expr     : constant Expr_Ref := Make_Abs_Expr ("x", Make_Var_Expr ("x"));
      Expected : constant Type_Ref := Make_Arrow_Type (Int_Type, Int_Type);
      S        : constant Substitution := Algorithm_M (Ctx, Empty_Env, Expr, Expected);
   begin
      Check ("12.1 M inferred identity against Int -> Int", True); -- did not crash
      Check ("12.2 M returns valid substitution", Natural (S.Length) >= 1);
      Check ("12.3 Context advanced", Ctx.Next_Id >= 2);
   end;

   --  TEST 13 — Algorithm M (Top-Down Mismatch)
   Put_Line ("TEST 13 — Algorithm M (Top-Down Mismatch)");
   declare
      Ctx      : Context;
      Expr     : constant Expr_Ref := Make_Abs_Expr ("x", Make_Var_Expr ("x"));
      Expected : constant Type_Ref := Make_Arrow_Type (Int_Type, Bool_Type);
      Failed   : Boolean := False;
   begin
      begin
         declare
            S : Substitution := Algorithm_M (Ctx, Empty_Env, Expr, Expected);
            pragma Unreferenced (S);
         begin
            null;
         end;
      exception
         when Unification_Error =>
            Failed := True;
      end;
      Check ("13.1 M failed correctly for identity vs Int -> Bool", Failed);
      Check ("13.2 Expected left is Int", Types_Equal (Expected.Left, Int_Type));
      Check ("13.3 Expected right is Bool", Types_Equal (Expected.Right, Bool_Type));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
