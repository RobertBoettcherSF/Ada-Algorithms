with Ada.Text_IO; use Ada.Text_IO;
with Unification_Engine; use Unification_Engine;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS -- " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL -- " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   Env : Substitution;
   Success_Flag : Boolean;
   T1, T2, T3, TA, TB, TC : Term_Id;
   Apply_OK : Boolean;

begin
   Reset_Pool;

   -- TEST 1 -- Make Term Properties
   Put_Line ("TEST 1 -- Term Constructors");
   Make_Variable ('x', T1);
   Check ("1.1 Variable construction",
          T1 /= Null_Term and then Kind_Of (T1) = Is_Variable);
   Make_Constant ('C', T2);
   Check ("1.2 Constant construction",
          T2 /= Null_Term and then Kind_Of (T2) = Is_Constant);
   Make_Function ('f', T1, T2, T3);
   Check ("1.3 Function construction",
          T3 /= Null_Term and then Kind_Of (T3) = Is_Function);

   -- TEST 2 -- Clear Environment
   Put_Line ("TEST 2 -- Environment Management");
   Clear (Env);
   Check ("2.1 Clear ensures null bindings",
          Env.Bindings ('a') = Null_Term and Env.Bindings ('z') = Null_Term);

   pragma Warnings (Off, "*useless assignment*");
   Env.Bindings ('x') := T2;
   Clear (Env);
   pragma Warnings (On, "*useless assignment*");

   Check ("2.2 Environment strictly cleared", Env.Bindings ('x') = Null_Term);

   -- TEST 3 -- Unify Identical Constants
   Put_Line ("TEST 3 -- Identical Constants");
   Reset_Pool;
   Clear (Env);
   Make_Constant ('A', T1);
   Make_Constant ('A', T2);
   Unify (T1, T2, Env, Success_Flag);
   Check ("3.1 Mismatch check passes", Success_Flag);
   Check ("3.2 Environment unchanged", Env.Bindings ('x') = Null_Term);

   -- TEST 4 -- Unify Different Constants
   Put_Line ("TEST 4 -- Different Constants");
   Reset_Pool;
   Clear (Env);
   Make_Constant ('A', T1);
   Make_Constant ('B', T2);
   Unify (T1, T2, Env, Success_Flag);
   Check ("4.1 Constants reject", not Success_Flag);

   -- TEST 5 -- Unify Variable and Constant
   Put_Line ("TEST 5 -- Variable & Constant Unification");
   Reset_Pool;
   Clear (Env);
   Make_Variable ('x', T1);
   Make_Constant ('K', T2);
   Unify (T1, T2, Env, Success_Flag);
   Check ("5.1 Var unifies with Const", Success_Flag);
   Check ("5.2 Environment recorded x = K", Env.Bindings ('x') = T2);

   -- TEST 6 -- Unify Bound Variable to conflicting Constant
   Put_Line ("TEST 6 -- Conflicting Bindings");
   Make_Constant ('Z', T3);
   Unify (T1, T3, Env, Success_Flag);
   Check ("6.1 Bound x rejects new constant", not Success_Flag);

   -- TEST 7 -- Unify Identical Functions
   Put_Line ("TEST 7 -- Identical Functions");
   Reset_Pool;
   Clear (Env);
   Make_Constant ('A', TA);
   Make_Constant ('B', TB);
   Make_Function ('f', TA, TB, T1);
   Make_Constant ('A', TA);
   Make_Constant ('B', TB);
   Make_Function ('f', TA, TB, T2);
   Unify (T1, T2, Env, Success_Flag);
   Check ("7.1 Exact function match", Success_Flag);

   -- TEST 8 -- Unify Different Functions (Arity/Constant Mismatch)
   Put_Line ("TEST 8 -- Function Signature Mismatch");
   Reset_Pool;
   Clear (Env);
   Make_Constant ('A', TA);
   Make_Constant ('B', TB);
   Make_Function ('f', TA, TB, T1);
   Make_Constant ('A', TA);
   Make_Constant ('B', TB);
   Make_Function ('g', TA, TB, T2);
   Unify (T1, T2, Env, Success_Flag);
   Check ("8.1 Name mismatch fails", not Success_Flag);

   Make_Constant ('A', TA);
   Make_Constant ('C', TC);
   Make_Function ('f', TA, TC, T2);
   Unify (T1, T2, Env, Success_Flag);
   Check ("8.2 Argument mismatch fails", not Success_Flag);

   -- TEST 9 -- Recursive Unification (MGU generation)
   Put_Line ("TEST 9 -- Recursive MGU Generation");
   Reset_Pool;
   Clear (Env);
   -- f(x, A) unifies with f(B, y) -> x=B, y=A
   Make_Variable ('x', TA);
   Make_Constant ('A', TB);
   Make_Function ('f', TA, TB, T1);
   Make_Constant ('B', TA);
   Make_Variable ('y', TB);
   Make_Function ('f', TA, TB, T2);
   Unify (T1, T2, Env, Success_Flag);
   Check ("9.1 Trees unified", Success_Flag);
   Check ("9.2 x bound to B",
          Env.Bindings ('x') /= Null_Term
          and then Name_Of (Env.Bindings ('x')) = 'B');
   Check ("9.3 y bound to A",
          Env.Bindings ('y') /= Null_Term
          and then Name_Of (Env.Bindings ('y')) = 'A');

   -- TEST 10 -- Occurs Check (Infinite Loop Prevention)
   Put_Line ("TEST 10 -- Occurs Check");
   Reset_Pool;
   Clear (Env);
   -- Unify x with f(x, A). Should fail occurs check.
   Make_Variable ('x', T1);
   Make_Constant ('A', TA);
   Make_Function ('f', T1, TA, T2);
   Unify (T1, T2, Env, Success_Flag);
   Check ("10.1 Circular reference blocked", not Success_Flag);
   Check ("10.2 Environment remains clean", Env.Bindings ('x') = Null_Term);

   -- TEST 11 -- Apply Substitution
   Put_Line ("TEST 11 -- Substitution Application");
   Reset_Pool;
   Clear (Env);
   Make_Constant ('K', TA);
   Env.Bindings ('x') := TA;
   Make_Variable ('x', TB);
   Make_Constant ('C', TC);
   Make_Function ('h', TB, TC, T1);
   Apply_Substitution (T1, Env, T2, Apply_OK);
   Check ("11.1 Tree resolved",
          Apply_OK and then T2 /= Null_Term
          and then Kind_Of (T2) = Is_Function);
   Check ("11.2 Variable substituted",
          Left_Of (T2) /= Null_Term
          and then Kind_Of (Left_Of (T2)) = Is_Constant
          and then Name_Of (Left_Of (T2)) = 'K');
   Check ("11.3 Constant preserved",
          Right_Of (T2) /= Null_Term and then Name_Of (Right_Of (T2)) = 'C');

   -- TEST 12 -- Apply Substitution (Chaining)
   Put_Line ("TEST 12 -- Substitution Application (Chained)");
   Reset_Pool;
   Clear (Env);
   Make_Variable ('y', TA);
   Env.Bindings ('x') := TA;
   Make_Constant ('M', TB);
   Env.Bindings ('y') := TB;
   Make_Variable ('x', T1);
   Apply_Substitution (T1, Env, T2, Apply_OK);
   Check ("12.1 Chain resolved down to M",
          Apply_OK and then T2 /= Null_Term
          and then Kind_Of (T2) = Is_Constant
          and then Name_Of (T2) = 'M');

   -- TEST 13 -- Edge Cases
   Put_Line ("TEST 13 -- Edge Cases (Null Handling)");
   Reset_Pool;
   Clear (Env);
   Unify (Null_Term, Null_Term, Env, Success_Flag);
   Check ("13.1 Null unifies with Null", Success_Flag);
   Make_Constant ('A', T1);
   Unify (T1, Null_Term, Env, Success_Flag);
   Check ("13.2 Const rejects Null", not Success_Flag);

   -- TEST 14 -- Constraint Verification
   Put_Line ("TEST 14 -- Strong Typing Exceptions");
   begin
      declare
         pragma Warnings (Off, "*value not in range*");
         pragma Warnings (Off, "*Constraint_Error*");
         Invalid_Var : Var_Name := 'A'; -- 'A' is not in 'a' .. 'z'
         pragma Warnings (On, "*Constraint_Error*");
         pragma Warnings (On, "*value not in range*");
         pragma Unreferenced (Invalid_Var);
      begin
         Check ("14.1 Constraint Error expected", False); -- Should not reach
      end;
   exception
      when Constraint_Error =>
         Check ("14.1 Out-of-bounds variable constrained", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed,"
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
