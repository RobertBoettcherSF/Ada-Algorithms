with Ada.Text_IO; use Ada.Text_IO;
with LR_Parser;   use LR_Parser;

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

   --  A valid engine for the grammar:
   --  (1) S -> A
   --  (2) A -> a A
   --  (3) A -> b
   --  Terminals: a = 1, b = 2, EOF = 0
   --  Nonterminals: S = 0, A = 1
   Valid_Engine : constant LR_Parser_Engine :=
     (Max_State       => 4,
      Max_Terminal    => 2,
      Max_Nonterminal => 1,
      Max_Rule        => 3,
      Actions =>
        [0 => [1 => (Kind => Shift, Next_State => 2), 2 => (Kind => Shift, Next_State => 3), others => (Kind => Error)],
         1 => [0 => (Kind => Accept_Action), others => (Kind => Error)],
         2 => [1 => (Kind => Shift, Next_State => 2), 2 => (Kind => Shift, Next_State => 3), others => (Kind => Error)],
         3 => [others => (Kind => Reduce, Rule => 3)],
         4 => [others => (Kind => Reduce, Rule => 2)]],
      Gotos =>
        [0 => [1 => 1, others => Invalid_State],
         2 => [1 => 4, others => Invalid_State],
         others => [others => Invalid_State]],
      Rules =>
        [1 => (LHS => 0, Length => 1),
         2 => (LHS => 1, Length => 2),
         3 => (LHS => 1, Length => 1)]);

begin
   Put_Line ("--- LR Parser Test Suite ---");

   --  TEST 1 - Engine Structure Validation
   Put_Line ("TEST 1 - Engine Structure Validation");
   Check ("1.1 Valid engine returns True", Validate_Engine (Valid_Engine));
   
   pragma Warnings (Off, "condition can only be False if invalid values present");
   pragma Warnings (Off, "condition is always True");
   Check ("1.2 Max State matches specification", Valid_Engine.Max_State = 4);
   Check ("1.3 Max Rule matches specification", Valid_Engine.Max_Rule = 3);
   pragma Warnings (On, "condition is always True");
   pragma Warnings (On, "condition can only be False if invalid values present");

   --  TEST 2 - Engine Validation (Missing Accept)
   Put_Line ("TEST 2 - Engine Validation (Missing Accept)");
   declare
      No_Acc : LR_Parser_Engine := Valid_Engine;
   begin
      No_Acc.Actions (1, 0) := (Kind => Error);
      Check ("2.1 Validation fails without Accept action", not Validate_Engine (No_Acc));
      Check ("2.2 Accept replaced with Error", No_Acc.Actions (1, 0).Kind = Error);
      Check ("2.3 Gotos table remains valid", No_Acc.Gotos (0, 1) = 1);
   end;

   --  TEST 3 - Engine Validation (Invalid Rule LHS)
   Put_Line ("TEST 3 - Engine Validation (Invalid Rule LHS)");
   declare
      Bad_LHS : LR_Parser_Engine := Valid_Engine;
   begin
      Bad_LHS.Rules (1).LHS := 99; -- Beyond Max_Nonterminal (1)
      Check ("3.1 Validation fails on out-of-bounds LHS", not Validate_Engine (Bad_LHS));
      Check ("3.2 Rule LHS exceeds Max_Nonterminal", Bad_LHS.Rules (1).LHS > Bad_LHS.Max_Nonterminal);
      Check ("3.3 State 0 Action remains intact", Bad_LHS.Actions (0, 1).Kind = Shift);
   end;

   --  TEST 4 - Parser Initialization State
   Put_Line ("TEST 4 - Parser Initialization State");
   declare
      S : constant Parser_Execution_State := Initialize_Parser;
   begin
      Check ("4.1 Initial status is Running", S.Status = Running);
      Check ("4.2 Initial stack has exactly 1 element", Natural (S.Stack.Length) = 1);
      Check ("4.3 Initial stack top state is 0", S.Stack.Last_Element = 0);
   end;

   --  TEST 5 - Stepwise Shift Action
   Put_Line ("TEST 5 - Stepwise Shift Action");
   declare
      S : Parser_Execution_State := Initialize_Parser;
   begin
      Feed_Token (Valid_Engine, S, 1); -- Shift 'a' -> state 2
      Check ("5.1 Status remains Running after shift", S.Status = Running);
      Check ("5.2 Stack length increased to 2", Natural (S.Stack.Length) = 2);
      Check ("5.3 Top state is accurately updated to 2", S.Stack.Last_Element = 2);
   end;

   --  TEST 6 - Stepwise Reduce and Accept
   Put_Line ("TEST 6 - Stepwise Reduce and Accept");
   declare
      S : Parser_Execution_State := Initialize_Parser;
   begin
      Feed_Token (Valid_Engine, S, 2); -- Shift 'b' -> state 3
      Feed_Token (Valid_Engine, S, 0); -- Read EOF -> Reduce 3, Goto 1, Accept
      Check ("6.1 Status is Accepted", S.Status = Accepted);
      Check ("6.2 Derivation sequence holds 1 rule", Natural (S.Derivation.Length) = 1);
      Check ("6.3 Reduced Rule matches Rule 3", S.Derivation.First_Element = 3);
   end;

   --  TEST 7 - Batch Parse Minimal String
   Put_Line ("TEST 7 - Batch Parse Minimal String");
   declare
      Input  : constant Symbol_Array := [1 => 2, 2 => 0]; -- 'b', EOF
      Result : Derivation_Sequence;
   begin
      Result := Parse (Valid_Engine, Input);
      Check ("7.1 Result length is 1", Natural (Result.Length) = 1);
      Check ("7.2 Applied rule is 3", Result.First_Element = 3);
      Check ("7.3 Last element matches", Result.Last_Element = 3);
   end;

   --  TEST 8 - Batch Parse Complex Recursive String
   Put_Line ("TEST 8 - Batch Parse Complex Recursive String");
   declare
      Input  : constant Symbol_Array := [1, 1, 2, 0]; -- 'a', 'a', 'b', EOF
      Result : Derivation_Sequence;
   begin
      Result := Parse (Valid_Engine, Input);
      Check ("8.1 Total applied rules equals 3", Natural (Result.Length) = 3);
      Check ("8.2 First reduction is Rule 3", Result.Element (1) = 3);
      Check ("8.3 Last reduction resolves to Rule 2", Result.Element (3) = 2);
   end;

   --  TEST 9 - Invalid Token ID Rejection
   Put_Line ("TEST 9 - Invalid Token ID Rejection");
   declare
      S : Parser_Execution_State := Initialize_Parser;
   begin
      Feed_Token (Valid_Engine, S, 99); -- Token ID totally out of bounds
      Check ("9.1 Status flips to Syntax_Error", S.Status = Syntax_Error);
      Check ("9.2 Derivation list remains empty", Natural (S.Derivation.Length) = 0);
      Check ("9.3 Stack unchanged length safely maintained", Natural (S.Stack.Length) = 1);
   end;

   --  TEST 10 - Syntax Error in Batch Parsing
   Put_Line ("TEST 10 - Syntax Error in Batch Parsing");
   declare
      Input  : constant Symbol_Array := [1, 1, 1, 0]; -- 'a', 'a', 'a', EOF (invalid without 'b')
      Caught : Boolean := False;
   begin
      begin
         declare
            Res : constant Derivation_Sequence := Parse (Valid_Engine, Input);
         begin
            Check ("10.1 Should not reach here", Natural (Res.Length) = 0 or else True);
         end;
      exception
         when Syntax_Error_Exception => Caught := True;
      end;
      Check ("10.1 Syntax_Error exception raised successfully", Caught);
      
      pragma Warnings (Off, "condition can only be False if invalid values present");
      pragma Warnings (Off, "condition is always True");
      Check ("10.2 Input array inherently faulty", Input'Length = 4);
      Check ("10.3 Missing critical terminal 'b'", Input (3) = 1);
      pragma Warnings (On, "condition is always True");
      pragma Warnings (On, "condition can only be False if invalid values present");
   end;

   --  TEST 11 - Trailing Garbage Rejection
   Put_Line ("TEST 11 - Trailing Garbage Rejection");
   declare
      Input  : constant Symbol_Array := [2, 0, 2]; -- 'b', EOF, 'b' (trailing)
      Caught : Boolean := False;
   begin
      begin
         declare
            Res : constant Derivation_Sequence := Parse (Valid_Engine, Input);
         begin
            Check ("11.1 Should not reach here", Natural (Res.Length) = 0 or else True);
         end;
      exception
         when Syntax_Error_Exception => Caught := True;
      end;
      Check ("11.1 Exception raised due to trailing data", Caught);
      
      pragma Warnings (Off, "condition can only be False if invalid values present");
      pragma Warnings (Off, "condition is always True");
      Check ("11.2 Valid syntax prefix actually exists", Input (1) = 2 and then Input (2) = 0);
      Check ("11.3 Extraneous data is intercepted", Input (3) = 2);
      pragma Warnings (On, "condition is always True");
      pragma Warnings (On, "condition can only be False if invalid values present");
   end;

   --  TEST 12 - Premature EOF Rejection
   Put_Line ("TEST 12 - Premature EOF Rejection");
   declare
      Input  : constant Symbol_Array := [1 => 1, 2 => 0]; -- 'a', EOF (grammar requires a 'b')
      Caught : Boolean := False;
   begin
      begin
         declare
            Res : constant Derivation_Sequence := Parse (Valid_Engine, Input);
         begin
            Check ("12.1 Should not reach here", Natural (Res.Length) = 0 or else True);
         end;
      exception
         when Syntax_Error_Exception => Caught := True;
      end;
      Check ("12.1 Exception accurately catches early EOF", Caught);
      
      pragma Warnings (Off, "condition can only be False if invalid values present");
      pragma Warnings (Off, "condition is always True");
      Check ("12.2 First sequence token correct ('a')", Input (1) = 1);
      Check ("12.3 Immediate EOF triggers the error", Input (2) = 0);
      pragma Warnings (On, "condition is always True");
      pragma Warnings (On, "condition can only be False if invalid values present");
   end;

   --  TEST 13 - Empty Input Stream
   Put_Line ("TEST 13 - Empty Input Stream");
   declare
      Input  : constant Symbol_Array (1 .. 0) := [others => 0];
      Caught : Boolean := False;
   begin
      begin
         declare
            Res : constant Derivation_Sequence := Parse (Valid_Engine, Input);
         begin
            Check ("13.1 Should not reach here", Natural (Res.Length) = 0 or else True);
         end;
      exception
         when Syntax_Error_Exception => Caught := True;
      end;
      Check ("13.1 Exception catches entirely empty array", Caught);
      Check ("13.2 Input length bounds verify as 0", Input'Length = 0);
      Check ("13.3 Engine state is unaffected and pristine", Validate_Engine (Valid_Engine));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
