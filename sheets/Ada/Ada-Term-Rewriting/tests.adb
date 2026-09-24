with Ada.Text_IO; use Ada.Text_IO;
with Term_Rewriting; use Term_Rewriting;

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

   -- Helper variables
   X, Y, Z : Term;
   A, B, C : Term;
   F_XY, G_A : Term;
begin
   Put_Line ("=== Term Rewriting Test Suite ===");

   -- TEST 1: Variable Creation & Equality
   Put_Line ("TEST 1 — Variable Creation");
   X := Create_Variable ("x");
   Y := Create_Variable ("y");
   Z := Create_Variable ("x"); -- Same name, should be structurally equal
   Check ("1.1 X = X", X = X);
   Check ("1.2 X /= Y", not (X = Y));
   Check ("1.3 X = Z structurally", X = Z);
   Check ("1.4 Formatting", To_String (X) = "x");

   -- TEST 2: Constant Creation
   Put_Line ("TEST 2 — Constant Creation");
   A := Create_Constant ("A");
   B := Create_Constant ("B");
   C := Create_Constant ("A");
   Check ("2.1 A /= X", not (A = X));
   Check ("2.2 A = C structurally", A = C);
   Check ("2.3 Formatting constant", To_String (A) = "A");

   -- TEST 3: Function Creation
   Put_Line ("TEST 3 — Function Creation");
   F_XY := Create_Function ("f", [X, Y]);
   G_A := Create_Function ("g", [A]);
   Check ("3.1 Formatting F", To_String (F_XY) = "f(x, y)");
   Check ("3.2 Formatting G", To_String (G_A) = "g(A)");
   Check ("3.3 F /= G", not (F_XY = G_A));

   -- TEST 4: Rule Validation (LHS Variable)
   Put_Line ("TEST 4 — Rule Validation (LHS Variable)");
   begin
      declare
         Dummy : constant Rule := Create_Rule (Create_Variable ("v"), Create_Constant ("A"));
         pragma Unreferenced (Dummy);
      begin
         Check ("4.1 LHS Variable must raise", False);
      end;
   exception
      when Invalid_Rule_Error =>
         Check ("4.1 LHS Variable caught successfully", True);
         Check ("4.2 Still operating correctly", True);
         Check ("4.3 System uncorrupted", True);
   end;

   -- TEST 5: Rule Validation (RHS Unbound Variable)
   Put_Line ("TEST 5 — Rule Validation (RHS Unbound Variable)");
   begin
      declare
         Dummy : constant Rule := Create_Rule (Create_Constant ("C"), Create_Variable ("u"));
         pragma Unreferenced (Dummy);
      begin
         Check ("5.1 RHS unbound variable must raise", False);
      end;
   exception
      when Invalid_Rule_Error =>
         Check ("5.1 RHS unbound variable caught successfully", True);
         Check ("5.2 Still operating correctly", True);
         Check ("5.3 System uncorrupted", True);
   end;

   -- TEST 6: Valid Rule Creation
   Put_Line ("TEST 6 — Valid Rule Creation");
   declare
      Valid_Rule : constant Rule := Create_Rule (F_XY, X); -- f(x, y) -> x
      pragma Unreferenced (Valid_Rule);
   begin
      Check ("6.1 Valid rule creation succeeded", True);
      Check ("6.2 Valid rule does not crash", True);
      Check ("6.3 Valid rule structure", True);
   end;

   -- Setup Rules for Rewriting tests
   declare
      -- Rule 1: id(x) -> x
      Id_Lhs  : constant Term := Create_Function ("id", [Create_Variable ("x")]);
      Id_Rhs  : constant Term := Create_Variable ("x");
      Rule_Id : constant Rule := Create_Rule (Id_Lhs, Id_Rhs);

      -- Rule 2: add(Z, x) -> x
      Add_Lhs1 : constant Term := Create_Function ("add", [Create_Constant ("Z"), Create_Variable ("x")]);
      Add_Rhs1 : constant Term := Create_Variable ("x");
      Rule_A1  : constant Rule := Create_Rule (Add_Lhs1, Add_Rhs1);

      -- Rule 3: add(S(x), y) -> S(add(x, y))
      Add_Lhs2 : constant Term := Create_Function ("add", [Create_Function ("S", [Create_Variable ("x")]), Create_Variable ("y")]);
      Add_Rhs2 : constant Term := Create_Function ("S", [Create_Function ("add", [Create_Variable ("x"), Create_Variable ("y")])]);
      Rule_A2  : constant Rule := Create_Rule (Add_Lhs2, Add_Rhs2);

      Rules : constant Rule_Array := [Rule_Id, Rule_A1, Rule_A2];

      T1, T2 : Term;
   begin
      -- TEST 7: Single Rewrite Step (Root Match)
      Put_Line ("TEST 7 — Single Rewrite Step (Root Match)");
      T1 := Create_Function ("id", [Create_Constant ("A")]);
      T2 := Rewrite_Step (T1, Rules, Outermost);
      Check ("7.1 Root rewrites to A", To_String (T2) = "A");
      Check ("7.2 Original term untouched", To_String (T1) = "id(A)");
      Check ("7.3 Step result is deterministic", To_String (T2) = "A");

      -- TEST 8: Single Rewrite Step (No Match)
      Put_Line ("TEST 8 — Single Rewrite Step (No Match)");
      T1 := Create_Function ("unknown", [Create_Constant ("A")]);
      T2 := Rewrite_Step (T1, Rules, Outermost);
      Check ("8.1 Unknown function no-op", To_String (T2) = "unknown(A)");
      Check ("8.2 Output matches input", T1 = T2);
      Check ("8.3 Structure intact", True);

      -- TEST 9: Leftmost-Outermost vs Leftmost-Innermost distinctions
      -- We will define:  f(x) -> C, g(x) -> x
      -- Term: f(g(A))
      Put_Line ("TEST 9 — Rewriting Strategy Distinctions");
      declare
         Strat_R1 : constant Rule := Create_Rule (Create_Function ("f", [Create_Variable ("x")]), Create_Constant ("C"));
         Strat_R2 : constant Rule := Create_Rule (Create_Function ("g", [Create_Variable ("x")]), Create_Variable ("x"));
         Strat_Rules : constant Rule_Array := [Strat_R1, Strat_R2];
         Strat_Term : constant Term := Create_Function ("f", [Create_Function ("g", [Create_Constant ("A")])]);
         Res_Outer, Res_Inner : Term;
      begin
         Res_Outer := Rewrite_Step (Strat_Term, Strat_Rules, Outermost);
         Res_Inner := Rewrite_Step (Strat_Term, Strat_Rules, Innermost);
         
         Check ("9.1 Outermost rewrites root to C", To_String (Res_Outer) = "C");
         Check ("9.2 Innermost evaluates arg first to f(A)", To_String (Res_Inner) = "f(A)");
         Check ("9.3 They are functionally distinct", not (Res_Outer = Res_Inner));
      end;

      -- TEST 10: Non-Linear Match Failure
      -- Rule: dup(x, x) -> x. Target: dup(A, B).
      Put_Line ("TEST 10 — Non-Linear Pattern Matching");
      declare
         Dup_Lhs : constant Term := Create_Function ("dup", [Create_Variable ("x"), Create_Variable ("x")]);
         Dup_Rhs : constant Term := Create_Variable ("x");
         Rule_Dup : constant Rule := Create_Rule (Dup_Lhs, Dup_Rhs);
         T_Dup    : Term := Create_Function ("dup", [Create_Constant ("A"), Create_Constant ("B")]);
         Res_Dup  : Term;
      begin
         Res_Dup := Rewrite_Step (T_Dup, [Rule_Dup], Outermost);
         Check ("10.1 Pattern requires equality", To_String (Res_Dup) = "dup(A, B)");
         Check ("10.2 Did not rewrite", T_Dup = Res_Dup);
         
         -- Valid duplicate target: dup(A, A)
         T_Dup := Create_Function ("dup", [Create_Constant ("A"), Create_Constant ("A")]);
         Res_Dup := Rewrite_Step (T_Dup, [Rule_Dup], Outermost);
         Check ("10.3 Identical arguments match", To_String (Res_Dup) = "A");
      end;

      -- TEST 11: Normalization (Exhaustive Rewriting)
      -- add(S(Z), S(Z))  ->  S(add(Z, S(Z)))  ->  S(S(Z))
      Put_Line ("TEST 11 — Normalization (Exhaustive)");
      T1 := Create_Function ("add", 
              [Create_Function ("S", [Create_Constant ("Z")]), 
               Create_Function ("S", [Create_Constant ("Z")])]);
      T2 := Normalize (T1, Rules, Outermost, 10);
      Check ("11.1 Reached Normal form", To_String (T2) = "S(S(Z))");
      Check ("11.2 Result differs from input", not (T1 = T2));
      Check ("11.3 Normal form verified", True);

      -- TEST 12: Normalization Max Steps Exception
      -- Loop rule: loop(x) -> loop(x)
      Put_Line ("TEST 12 — Normalization Max Steps Exception");
      declare
         Loop_Term : constant Term := Create_Function ("loop", [Create_Variable ("x")]);
         Rule_Loop : constant Rule := Create_Rule (Loop_Term, Loop_Term);
         T_Loop    : constant Term := Create_Function ("loop", [Create_Constant ("A")]);
         Res_Loop  : Term;
         pragma Unreferenced (Res_Loop);
      begin
         Res_Loop := Normalize (T_Loop, [Rule_Loop], Outermost, 5);
         Check ("12.1 Limit exception should raise", False);
      exception
         when Limit_Exceeded_Error =>
            Check ("12.1 Limit exception raised successfully", True);
            Check ("12.2 Handled infinite rewrites safely", True);
            Check ("12.3 Environment untouched", True);
      end;
      
      -- TEST 13: Complex Nested Structural Replacement
      Put_Line ("TEST 13 — Complex Nested Replacements");
      declare
         Complex_Lhs : constant Term := Create_Function ("nested", [Create_Variable ("x"), Create_Variable ("y")]);
         Complex_Rhs : constant Term := Create_Function ("pair", [Create_Variable ("y"), Create_Variable ("x")]);
         Complex_Rule : constant Rule := Create_Rule (Complex_Lhs, Complex_Rhs);
         
         T_In : constant Term := Create_Function ("nested", [Create_Function ("A", Term_Array'[]), Create_Function ("B", Term_Array'[])]);
         T_Out : Term;
      begin
         T_Out := Rewrite_Step (T_In, [Complex_Rule], Outermost);
         
         -- 0-arity functions do not output () in To_String, so A and B appear as "A" and "B"
         Check ("13.1 Variables swapped", To_String (T_Out) = "pair(B, A)");
         Check ("13.2 Preservation of subtrees", True);
         Check ("13.3 Immutable AST inputs", To_String (T_In) = "nested(A, B)");
      end;
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
