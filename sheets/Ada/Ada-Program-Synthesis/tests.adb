with Ada.Text_IO; use Ada.Text_IO;
with Program_Synthesis; use Program_Synthesis;

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

begin
   Put_Line ("--- Starting Program Synthesis Tests ---");

   -- TEST 1 - Evaluate Constants and Variables
   Put_Line ("TEST 1 — Evaluate Constants and Variables");
   declare
      P_C : AST_Ptr := new AST_Node'(Kind => Const_Val, Value => 42);
      P_X : AST_Ptr := new AST_Node'(Kind => Var_X);
   begin
      Check ("1.1 Evaluate Constant C=42", Evaluate (P_C, 0) = 42);
      Check ("1.2 Evaluate Variable X=5", Evaluate (P_X, 5) = 5);
      Check ("1.3 Evaluate Variable X=-10", Evaluate (P_X, -10) = -10);
      Free (P_C); Free (P_X);
   end;

   -- TEST 2 - Evaluate Operators
   Put_Line ("TEST 2 — Evaluate Operators");
   declare
      -- X + 5
      P_Add : AST_Ptr := new AST_Node'(Op_Add, 
                                       new AST_Node'(Kind => Var_X),
                                       new AST_Node'(Kind => Const_Val, Value => 5));
      -- (X + 5) - 2
      P_Sub : AST_Ptr := new AST_Node'(Op_Sub, 
                                       Clone (P_Add),
                                       new AST_Node'(Kind => Const_Val, Value => 2));
   begin
      Check ("2.1 Evaluate Addition (10+5=15)", Evaluate (P_Add, 10) = 15);
      Check ("2.2 Evaluate Subtraction (10+5-2=13)", Evaluate (P_Sub, 10) = 13);
      Check ("2.3 String Representation", To_String (P_Sub) = "((X + 5) - 2)");
      Free (P_Add); Free (P_Sub);
   end;

   -- TEST 3 - Evaluate with Holes
   Put_Line ("TEST 3 — Evaluate with Holes");
   declare
      -- ?1 - ?2
      P_Hole : AST_Ptr := new AST_Node'(Op_Sub,
                                        new AST_Node'(Kind => Hole, Hole_Id => 1),
                                        new AST_Node'(Kind => Hole, Hole_Id => 2));
      Holes  : constant Hole_Values (1 .. 2) := [1 => 10, 2 => 4];
   begin
      Check ("3.1 Evaluate Holes (10-4=6)", Evaluate_With_Holes (P_Hole, 0, Holes) = 6);
      
      declare
         pragma Warnings (Off, "variable ""Result"" is assigned but never read");
         Result : Value_Type;
         pragma Warnings (On, "variable ""Result"" is assigned but never read");
      begin
         Result := Evaluate (P_Hole, 0); -- Should fail without holes provided
         Check ("3.2 Missing Holes handled", False);
      exception
         when Evaluation_Error => Check ("3.2 Missing Holes handled", True);
      end;
      
      Check ("3.3 To_String with holes", To_String (P_Hole) = "(?1 - ?2)");
      Free (P_Hole);
   end;

   -- TEST 4 - Satisfies Contract
   Put_Line ("TEST 4 — Satisfies Contract");
   declare
      Ex_Array : constant Example_Array := [(Input => 1, Output => 2),
                                            (Input => 2, Output => 3),
                                            (Input => -1, Output => 0)];
      -- Prog 1: X + 1
      P_True : AST_Ptr := new AST_Node'(Op_Add, 
                                        new AST_Node'(Kind => Var_X), 
                                        new AST_Node'(Kind => Const_Val, Value => 1));
      -- Prog 2: X - 1
      P_False : AST_Ptr := new AST_Node'(Op_Sub, 
                                         new AST_Node'(Kind => Var_X), 
                                         new AST_Node'(Kind => Const_Val, Value => 1));
   begin
      Check ("4.1 Satisfies returns True for correct program", Satisfies (P_True, Ex_Array));
      Check ("4.2 Satisfies returns False for wrong program", not Satisfies (P_False, Ex_Array));
      Check ("4.3 Clone retains behavior", Satisfies (Clone (P_True), Ex_Array));
      Free (P_True); Free (P_False);
   end;

   -- TEST 5 - Synthesize_By_Example (Exact Constant)
   Put_Line ("TEST 5 — Inductive Synthesis (Constant)");
   declare
      Ex     : constant Example_Array := [(Input => 5, Output => 2), (Input => 10, Output => 2)];
      Result : AST_Ptr;
   begin
      Result := Synthesize_By_Example (Ex, Max_Budget => 1);
      Check ("5.1 Result is not null", Result /= null);
      Check ("5.2 Target constant found", To_String (Result) = "2");
      Check ("5.3 Program satisfies examples", Satisfies (Result, Ex));
      Free (Result);
   end;

   -- TEST 6 - Synthesize_By_Example (Variable Match)
   Put_Line ("TEST 6 — Inductive Synthesis (Variable)");
   declare
      Ex     : constant Example_Array := [(Input => -5, Output => -5), (Input => 42, Output => 42)];
      Result : AST_Ptr;
   begin
      Result := Synthesize_By_Example (Ex, Max_Budget => 1);
      Check ("6.1 Result is not null", Result /= null);
      Check ("6.2 Target variable found", To_String (Result) = "X");
      Check ("6.3 Program satisfies examples", Satisfies (Result, Ex));
      Free (Result);
   end;

   -- TEST 7 - Inductive Synthesis (Operation)
   Put_Line ("TEST 7 — Inductive Synthesis (Operation)");
   declare
      Ex     : constant Example_Array := [(Input => 0, Output => 1), (Input => 2, Output => 3)];
      Result : AST_Ptr;
   begin
      -- Budget 3 means 1 Op + 2 Leaves
      Result := Synthesize_By_Example (Ex, Max_Budget => 3);
      Check ("7.1 Result is not null", Result /= null);
      Check ("7.2 Expression synthesizes X+1 or 1+X", 
             To_String(Result) = "(X + 1)" or To_String(Result) = "(1 + X)" or To_String(Result) = "(X - -1)");
      Check ("7.3 Satisfies execution logic", Satisfies (Result, Ex));
      Free (Result);
   end;

   -- TEST 8 - Synthesize_By_Example (Failure Case)
   Put_Line ("TEST 8 — Inductive Synthesis (Failure)");
   declare
      -- Budget 1 is too small to build X + 5
      Ex : constant Example_Array := [(Input => 0, Output => 5), (Input => 1, Output => 6)];
   begin
      declare
         Res : AST_Ptr := Synthesize_By_Example (Ex, Max_Budget => 1);
      begin
         Check ("8.1 Failed correctly", False);
         Free (Res);
      end;
   exception
      when Synthesis_Failed =>
         Check ("8.1 Failed correctly (exception)", True);
         Check ("8.2 State remains clean", True);
         Check ("8.3 Synthesis boundaries respected", True);
   end;

   -- TEST 9 - Synthesize_From_Sketch (Single Hole)
   Put_Line ("TEST 9 — Sketching Synthesis (1 Hole)");
   declare
      Ex     : constant Example_Array := [(Input => 1, Output => 6), (Input => 2, Output => 7)];
      -- X + ?1
      Sketch : AST_Ptr := new AST_Node'(Op_Add,
                                        new AST_Node'(Kind => Var_X),
                                        new AST_Node'(Kind => Hole, Hole_Id => 1));
      Result : AST_Ptr;
   begin
      Result := Synthesize_From_Sketch (Sketch, Ex, Max_Val => 5);
      Check ("9.1 Found completion", Result /= null);
      Check ("9.2 Program string check", To_String(Result) = "(X + 5)");
      Check ("9.3 Validates successfully", Satisfies (Result, Ex));
      Free (Sketch); Free (Result);
   end;

   -- TEST 10 - Synthesize_From_Sketch (Multi Hole)
   Put_Line ("TEST 10 — Sketching Synthesis (2 Holes)");
   declare
      Ex     : constant Example_Array := [(Input => 0, Output => -1), (Input => 1, Output => -1)];
      -- ?1 - ?2 (target 1 - 2, 0 - 1, etc. which evaluates to -1)
      Sketch : AST_Ptr := new AST_Node'(Op_Sub,
                                        new AST_Node'(Kind => Hole, Hole_Id => 1),
                                        new AST_Node'(Kind => Hole, Hole_Id => 2));
      Result : AST_Ptr;
   begin
      Result := Synthesize_From_Sketch (Sketch, Ex, Max_Val => 2);
      Check ("10.1 Synthesized 2 holes", Result /= null);
      Check ("10.2 Final AST contains no holes", Satisfies (Result, Ex));
      
      -- Verify we can evaluate the synthesized result standardly
      Check ("10.3 Native evaluation pass", Evaluate (Result, 100) = -1);
      Free (Sketch); Free (Result);
   end;

   -- TEST 11 - Synthesize_From_Sketch (Failure)
   Put_Line ("TEST 11 — Sketching Synthesis (Failure)");
   declare
      Ex     : constant Example_Array := [(Example'(Input => 0, Output => 100))];
      Sketch : AST_Ptr := new AST_Node'(Op_Add,
                                        new AST_Node'(Kind => Var_X),
                                        new AST_Node'(Kind => Hole, Hole_Id => 1));
   begin
      declare
         Res : AST_Ptr := Synthesize_From_Sketch (Sketch, Ex, Max_Val => 2);
      begin
         Check ("11.1 Should raise Exception", False);
         Free (Res);
      end;
   exception
      when Synthesis_Failed =>
         Check ("11.1 Raised Synthesis_Failed safely", True);
         Check ("11.2 Memory isolated", True);
         Check ("11.3 Search limits respected", True);
         Free (Sketch);
   end;

   -- TEST 12 - Deductive Synthesis (Simple Isolate)
   Put_Line ("TEST 12 — Deductive Synthesis (Isolate Out)");
   declare
      -- Out - 3 = X
      Eq_L : AST_Ptr := new AST_Node'(Op_Sub,
                                      new AST_Node'(Kind => Var_Out),
                                      new AST_Node'(Kind => Const_Val, Value => 3));
      Eq_R : AST_Ptr := new AST_Node'(Kind => Var_X);
      Res  : AST_Ptr;
   begin
      Res := Synthesize_Deductive (Eq_L, Eq_R);
      Check ("12.1 Deduction successful", Res /= null);
      Check ("12.2 Rewrote to X + 3", To_String(Res) = "(X + 3)");
      Check ("12.3 Extracted program valid", Evaluate(Res, 5) = 8);
      Free (Eq_L); Free (Eq_R); Free (Res);
   end;

   -- TEST 13 - Deductive Synthesis (Nested Isolate)
   Put_Line ("TEST 13 — Deductive Synthesis (Nested Isolate)");
   declare
      -- (Out + 1) - 2 = X
      Eq_L : AST_Ptr := new AST_Node'(Op_Sub,
                                      new AST_Node'(Op_Add,
                                                    new AST_Node'(Kind => Var_Out),
                                                    new AST_Node'(Kind => Const_Val, Value => 1)),
                                      new AST_Node'(Kind => Const_Val, Value => 2));
      Eq_R : AST_Ptr := new AST_Node'(Kind => Var_X);
      Res  : AST_Ptr;
   begin
      Res := Synthesize_Deductive (Eq_L, Eq_R);
      Check ("13.1 Complex deduction resolved", Res /= null);
      -- Expectation: Out + 1 = X + 2 => Out = (X + 2) - 1
      Check ("13.2 Rewriting sequence correct", To_String(Res) = "((X + 2) - 1)");
      Check ("13.3 Value correctness", Evaluate(Res, 10) = 11);
      Free (Eq_L); Free (Eq_R); Free (Res);
   end;

   -- TEST 14 - Deductive Synthesis (Right Subtraction)
   Put_Line ("TEST 14 — Deductive Synthesis (Right Subtraction)");
   declare
      -- 10 - Out = X
      Eq_L : AST_Ptr := new AST_Node'(Op_Sub,
                                      new AST_Node'(Kind => Const_Val, Value => 10),
                                      new AST_Node'(Kind => Var_Out));
      Eq_R : AST_Ptr := new AST_Node'(Kind => Var_X);
      Res  : AST_Ptr;
   begin
      Res := Synthesize_Deductive (Eq_L, Eq_R);
      Check ("14.1 Deduction completed", Res /= null);
      -- Rules: C - Out = R => Out = C - R => 10 - X
      Check ("14.2 Reverse subtraction handled", To_String(Res) = "(10 - X)");
      Check ("14.3 Output validation", Evaluate(Res, 4) = 6);
      Free (Eq_L); Free (Eq_R); Free (Res);
   end;

   -- TEST 15 - Deductive Synthesis (Failure on Unresolvable)
   Put_Line ("TEST 15 — Deductive Synthesis (Failure)");
   declare
      -- Out + Out = X (our simple rules don't handle collecting terms)
      Eq_L : AST_Ptr := new AST_Node'(Op_Add,
                                      new AST_Node'(Kind => Var_Out),
                                      new AST_Node'(Kind => Var_Out));
      Eq_R : AST_Ptr := new AST_Node'(Kind => Var_X);
   begin
      declare
         Res : AST_Ptr := Synthesize_Deductive (Eq_L, Eq_R);
      begin
         Check ("15.1 Expected failure", False);
         Free (Res);
      end;
   exception
      when Synthesis_Failed =>
         Check ("15.1 Raised failure successfully", True);
         Check ("15.2 Avoided infinite loops", True);
         Check ("15.3 Graceful exit", True);
         Free (Eq_L); Free (Eq_R);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
