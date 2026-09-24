with Ada.Text_IO; use Ada.Text_IO;
with First_Order_Logic; use First_Order_Logic;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS - " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL - " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Concrete Interpretation for testing
   type Test_Interp is new Interpretation with null record;
   
   -- Suppress benign unused warnings for formal parameters required by the interface
   pragma Warnings (Off, "-gnatwu");
   overriding function Eval_Constant (I : Test_Interp; Name : Character) return Domain_Element is
      (case Name is
         when 'c' => 2,
         when 'd' => 3,
         when others => 1);

   overriding function Eval_Function (I : Test_Interp; Name : Character; Arg1, Arg2 : Domain_Element) return Domain_Element is
      (case Name is
         when 'f' => (if Arg1 = 3 then 1 else Arg1 + 1), -- Unary: increments mod 3
         when 'g' => ((Arg1 + Arg2) mod 3) + 1,          -- Binary function
         when others => Arg1);

   overriding function Eval_Predicate (I : Test_Interp; Name : Character; Arg1, Arg2 : Domain_Element) return Boolean is
      (case Name is
         when 'P' => Arg1 = 2,           -- Unary: True if Arg1 == 2
         when 'G' => Arg1 > Arg2,        -- Binary: Greater than
         when others => False);
   pragma Warnings (On, "-gnatwu");

   Interp : Test_Interp;
   Env    : Assignment := [others => 1]; -- Default environment (all vars = 1)

   T_x : constant Term_Access := Make_Variable ('x');
   T_y : constant Term_Access := Make_Variable ('y');
   T_c : constant Term_Access := Make_Constant ('c');

begin
   Put_Line ("Starting First-Order Logic Tests...");

   -- TEST 1: Term Evaluation
   Put_Line ("TEST 1 - Term Evaluation");
   Env ('x') := 1;
   Check ("1.1 Evaluate Constant 'c' -> 2", Evaluate_Term (T_c, Interp, Env) = 2);
   Check ("1.2 Evaluate Variable 'x' -> 1", Evaluate_Term (T_x, Interp, Env) = 1);
   Check ("1.3 Evaluate Unary Func f(c) -> 3", Evaluate_Term (Make_Function ('f', T_c), Interp, Env) = 3);
   Check ("1.4 Evaluate Binary Func g(c, x) -> 1", 
      Evaluate_Term (Make_Function ('g', T_c, T_x), Interp, Env) = 1); -- (2+1)%3+1 = 1

   -- TEST 2: Basic Formula Evaluation (Propositional Logic)
   Put_Line ("TEST 2 - Basic Formula Evaluation");
   declare
      F_True : constant Formula_Access := Make_Predicate ('P', T_c); -- P(2) is True
      F_False : constant Formula_Access := Make_Predicate ('P', T_x); -- P(1) is False
   begin
      Check ("2.1 Evaluate True Predicate", Evaluate_Formula (F_True, Interp, Env));
      Check ("2.2 Evaluate False Predicate", not Evaluate_Formula (F_False, Interp, Env));
      Check ("2.3 Evaluate AND", not Evaluate_Formula (Make_And (F_True, F_False), Interp, Env));
      Check ("2.4 Evaluate OR", Evaluate_Formula (Make_Or (F_True, F_False), Interp, Env));
      Check ("2.5 Evaluate NOT", Evaluate_Formula (Make_Not (F_False), Interp, Env));
   end;

   -- TEST 3: Equality and Binary Predicates
   Put_Line ("TEST 3 - Equality & Predicates");
   Env ('x') := 3;
   declare
      -- c = 2, f(x) where x=3 is f(3)=1
      F_Eq1 : constant Formula_Access := Make_Equality (T_c, Make_Function ('f', T_x));
      -- G(c, f(x)) i.e., 2 > 1
      F_G   : constant Formula_Access := Make_Predicate ('G', T_c, Make_Function ('f', T_x)); 
   begin
      Check ("3.1 Evaluate Equality (False)", not Evaluate_Formula (F_Eq1, Interp, Env));
      Check ("3.2 Evaluate Equality (True)", Evaluate_Formula (Make_Equality (T_c, T_c), Interp, Env));
      Check ("3.3 Evaluate Binary Predicate", Evaluate_Formula (F_G, Interp, Env));
   end;

   -- TEST 4: Quantifiers (Exists)
   Put_Line ("TEST 4 - Existential Quantifier");
   declare
      -- Exists x . P(x) (True, since P(2) is True)
      F_Exists : constant Formula_Access := Make_Exists ('x', Make_Predicate ('P', T_x));
      -- Exists x . G(x, d) where d=3. Is there an x > 3? No, domain is 1..3
      F_None   : constant Formula_Access := Make_Exists ('x', Make_Predicate ('G', T_x, Make_Constant ('d')));
   begin
      Check ("4.1 Exists matching element", Evaluate_Formula (F_Exists, Interp, Env));
      Check ("4.2 Exists no matching element", not Evaluate_Formula (F_None, Interp, Env));
      Check ("4.3 Nested Exists", Evaluate_Formula (Make_Exists ('y', F_Exists), Interp, Env));
   end;

   -- TEST 5: Quantifiers (Forall)
   Put_Line ("TEST 5 - Universal Quantifier");
   declare
      -- Forall x . P(x) (False, P(1) is False)
      F_Forall : constant Formula_Access := Make_Forall ('x', Make_Predicate ('P', T_x));
      -- Forall x . x = x (True)
      F_Id     : constant Formula_Access := Make_Forall ('x', Make_Equality (T_x, T_x));
   begin
      Check ("5.1 Forall with a failure", not Evaluate_Formula (F_Forall, Interp, Env));
      Check ("5.2 Forall identity (tautology)", Evaluate_Formula (F_Id, Interp, Env));
      Check ("5.3 Unused bound var", Evaluate_Formula (Make_Forall ('z', F_Id), Interp, Env));
   end;

   -- TEST 6: Free Variables (Simple)
   Put_Line ("TEST 6 - Free Variables (Simple)");
   declare
      F : constant Formula_Access := Make_Predicate ('G', T_x, T_y);
   begin
      Check ("6.1 x is free", Is_Free_Variable (F, 'x'));
      Check ("6.2 y is free", Is_Free_Variable (F, 'y'));
      Check ("6.3 z is not free", not Is_Free_Variable (F, 'z'));
   end;

   -- TEST 7: Free Variables (Quantified)
   Put_Line ("TEST 7 - Free Variables (Quantified)");
   declare
      F1 : constant Formula_Access := Make_Forall ('x', Make_Predicate ('G', T_x, T_y));
      F2 : constant Formula_Access := Make_And (Make_Predicate ('P', T_x), F1);
   begin
      Check ("7.1 x is bound", not Is_Free_Variable (F1, 'x'));
      Check ("7.2 y remains free", Is_Free_Variable (F1, 'y'));
      Check ("7.3 x is free in other branch of AND", Is_Free_Variable (F2, 'x'));
   end;

   -- TEST 8: Prenex Normal Form Checking
   Put_Line ("TEST 8 - Prenex Normal Form");
   declare
      F_PNF     : constant Formula_Access := Make_Forall ('x', Make_Exists ('y', Make_Predicate ('G', T_x, T_y)));
      F_Not_PNF : constant Formula_Access := Make_And (F_PNF, Make_Predicate ('P', T_x));
   begin
      Check ("8.1 Strictly quantifiers first", Is_Prenex_Normal_Form (F_PNF));
      Check ("8.2 Quantifier inside AND is not PNF", not Is_Prenex_Normal_Form (F_Not_PNF));
      Check ("8.3 Simple predicate is PNF", Is_Prenex_Normal_Form (Make_Predicate ('P', T_x)));
   end;

   -- TEST 9: Term Substitution
   Put_Line ("TEST 9 - Term Substitution");
   declare
      T1 : constant Term_Access := Make_Function ('f', T_x);
      T2 : constant Term_Access := Substitute_Term (T1, 'x', T_c);
   begin
      Env ('x') := 1;
      Check ("9.1 Orig term evaluates correctly", Evaluate_Term (T1, Interp, Env) = 2); -- f(1)=2
      Check ("9.2 Substituted term evaluates correctly", Evaluate_Term (T2, Interp, Env) = 3); -- f(c)=3
      Check ("9.3 Substitution misses unbound var", 
         Substitute_Term (T1, 'y', T_c).Arg1.Kind = Is_Variable);
   end;

   -- TEST 10: Formula Substitution
   Put_Line ("TEST 10 - Formula Substitution");
   declare
      F_Sub1 : constant Formula_Access := Substitute_Formula (Make_Predicate ('P', T_x), 'x', T_c);
      -- Substitute into Forall x . P(x) -> Should shadow and not substitute
      F_Sub2 : constant Formula_Access := Substitute_Formula (Make_Forall ('x', Make_Predicate ('P', T_x)), 'x', T_c);
   begin
      Env ('x') := 1;
      Check ("10.1 Direct sub applies", Evaluate_Formula (F_Sub1, Interp, Env)); -- P(c) is True
      Check ("10.2 Shadowed sub blocked", not Evaluate_Formula (F_Sub2, Interp, Env)); -- Forall x.P(x) is False
      Check ("10.3 Shadowed structural check", F_Sub2.Body_Formula.Term1.Kind = Is_Variable);
   end;

   -- TEST 11: Deep AST Evaluation
   Put_Line ("TEST 11 - Deep AST Connectives (Implies/Iff)");
   declare
      F_True : constant Formula_Access := Make_Predicate ('P', T_c);
      F_False : constant Formula_Access := Make_Predicate ('P', T_x);
   begin
      Check ("11.1 Implies (F->T = T)", Evaluate_Formula (Make_Implies (F_False, F_True), Interp, Env));
      Check ("11.2 Implies (T->F = F)", not Evaluate_Formula (Make_Implies (F_True, F_False), Interp, Env));
      Check ("11.3 Iff (F<->F = T)", Evaluate_Formula (Make_Iff (F_False, F_False), Interp, Env));
   end;

   -- TEST 12: Vacuous Truth and Tautologies
   Put_Line ("TEST 12 - Vacuous Truth");
   declare
      -- Forall x . (Not (x=x) -> P(x)) == True
      F_Vacuous : constant Formula_Access := 
         Make_Forall ('x', Make_Implies (Make_Not (Make_Equality (T_x, T_x)), Make_Predicate ('P', T_x)));
   begin
      Check ("12.1 Vacuous Truth", Evaluate_Formula (F_Vacuous, Interp, Env));
      Check ("12.2 Tautology with Or", Evaluate_Formula (
         Make_Forall ('x', Make_Or (Make_Predicate ('P', T_x), Make_Not (Make_Predicate ('P', T_x)))), Interp, Env));
      Check ("12.3 Double Negation", Evaluate_Formula (
         Make_Not (Make_Not (Make_Predicate ('P', T_c))), Interp, Env));
   end;

   -- TEST 13: Edge Cases / Precondition Violations
   Put_Line ("TEST 13 - Edge Cases and Robustness");
   
   begin
      declare
         Bad : constant Formula_Access := Make_Not (null);
         pragma Unreferenced (Bad);
      begin
         Check ("13.1 Precondition catches null in Make_Not", False);
      end;
   exception
      when others => 
         Check ("13.1 Precondition catches null in Make_Not", True);
   end;
   
   begin
      declare
         Bad : constant Term_Access := Make_Function ('f', null);
         pragma Unreferenced (Bad);
      begin
         Check ("13.2 Precondition catches null in Make_Function", False);
      end;
   exception
      when others => 
         Check ("13.2 Precondition catches null in Make_Function", True);
   end;

   Check ("13.3 Has_Quantifier on null", not Has_Quantifier (null));

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
