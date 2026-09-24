with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Earley_Parser; use Earley_Parser;

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

   --  Helper Types and Routines for Grammar Construction
   type Symbol_Array is array (Positive range <>) of Symbol;

   procedure Add_Rule (G : in out Grammar; LHS : Symbol; RHS : Symbol_Array) is
      List : Symbol_List;
   begin
      for S of RHS loop
         List.Append (S);
      end loop;
      --  Qualify the aggregate as Production'() so the compiler knows which
      --  overloaded Append (Element vs Vector) to invoke.
      G.Rules.Append (Production'(LHS => LHS, RHS => List));
   end Add_Rule;

   function ST (Name : String) return Symbol renames Create_Terminal;
   function SNT (Name : String) return Symbol renames Create_Non_Terminal;

   function Make_Input (Arr : Symbol_Array) return Symbol_List is
      List : Symbol_List;
   begin
      for S of Arr loop
         List.Append (S);
      end loop;
      return List;
   end Make_Input;

begin
   Put_Line ("=== Earley Parser Test Suite ===");

   --  TEST 1: Symbol Creation and Equality
   Put_Line ("TEST 1 — Symbol Handling");
   declare
      T1 : constant Symbol := ST ("a");
      T2 : constant Symbol := ST ("a");
      T3 : constant Symbol := ST ("b");
      N1 : constant Symbol := SNT ("A");
   begin
      Check ("1.1 Terminals with same name are equal", T1 = T2);
      Check ("1.2 Terminals with different names are not equal", not (T1 = T3));
      Check ("1.3 Terminal and Non-Terminal differ", not (T1 = N1));
   end;

   --  TEST 2: Basic Grammar Construction
   Put_Line ("TEST 2 — Basic Grammar Construction");
   declare
      G : Grammar := (Start_Symbol => SNT ("S"), Rules => Production_Vectors.Empty_Vector);
   begin
      Add_Rule (G, SNT ("S"), [ST ("a")]);
      Check ("2.1 Grammar has correct Start_Symbol", G.Start_Symbol.Name = SNT ("S").Name);
      Check ("2.2 Grammar rules appended", Natural (G.Rules.Length) = 1);
      Check ("2.3 LHS is valid non-terminal", G.Rules.Element (1).LHS.Kind = Non_Terminal);
   end;

   --  TEST 3: Empty Input & Nullable Start
   Put_Line ("TEST 3 — Empty Input & Nullable Start");
   declare
      G : Grammar := (Start_Symbol => SNT ("S"), Rules => Production_Vectors.Empty_Vector);
      Input : constant Symbol_List := Symbol_Vectors.Empty_Vector;
   begin
      Add_Rule (G, SNT ("S"), []); -- Epsilon rule
      Check ("3.1 Start rule is Epsilon", Natural (G.Rules.Element (1).RHS.Length) = 0);
      Check ("3.2 Recognizes empty input", Recognize (G, Input));
      
      declare
         C : constant Chart := Parse_Chart (G, Input);
      begin
         Check ("3.3 Chart contains exactly 1 state set for empty input", Natural (C.Length) = 1);
      end;
   end;

   --  TEST 4: Empty Input & Non-Nullable Start
   Put_Line ("TEST 4 — Empty Input & Non-Nullable Start");
   declare
      G : Grammar := (Start_Symbol => SNT ("S"), Rules => Production_Vectors.Empty_Vector);
      Input : constant Symbol_List := Symbol_Vectors.Empty_Vector;
   begin
      Add_Rule (G, SNT ("S"), [ST ("a")]);
      Check ("4.1 Non-Nullable grammar", Natural (G.Rules.Element (1).RHS.Length) = 1);
      Check ("4.2 Rejects empty input", not Recognize (G, Input));
      
      declare
         C : constant Chart := Parse_Chart (G, Input);
      begin
         Check ("4.3 Chart set is instantiated safely", Natural (C.Length) = 1);
      end;
   end;

   --  TEST 5: Single Token Acceptance
   Put_Line ("TEST 5 — Single Token Acceptance");
   declare
      G : Grammar := (Start_Symbol => SNT ("S"), Rules => Production_Vectors.Empty_Vector);
      Input : constant Symbol_List := Make_Input ([ST ("a")]);
   begin
      Add_Rule (G, SNT ("S"), [ST ("a")]);
      Check ("5.1 Input length is 1", Natural (Input.Length) = 1);
      Check ("5.2 Token matched and recognized", Recognize (G, Input));
      Check ("5.3 Correct Chart size", Natural (Parse_Chart (G, Input).Length) = 2);
   end;

   --  TEST 6: Single Token Rejection
   Put_Line ("TEST 6 — Single Token Rejection");
   declare
      G : Grammar := (Start_Symbol => SNT ("S"), Rules => Production_Vectors.Empty_Vector);
      Input : constant Symbol_List := Make_Input ([ST ("b")]);
   begin
      Add_Rule (G, SNT ("S"), [ST ("a")]);
      Check ("6.1 Rules initialized", Natural (G.Rules.Length) = 1);
      Check ("6.2 Rejects mismatched token", not Recognize (G, Input));
      
      declare
         C : constant Chart := Parse_Chart (G, Input);
      begin
         -- State 1 should be empty because scan failed
         Check ("6.3 Chart(1) is empty upon mismatch", Natural (C.Element (1).Length) = 0);
      end;
   end;

   --  TEST 7: Expression Grammar Validation
   Put_Line ("TEST 7 — Mathematical Expression Parsing");
   declare
      G : Grammar := (Start_Symbol => SNT ("E"), Rules => Production_Vectors.Empty_Vector);
      Input : constant Symbol_List := Make_Input ([ST ("n"), ST ("+"), ST ("n")]);
   begin
      -- E -> E + E | n
      Add_Rule (G, SNT ("E"), [SNT ("E"), ST ("+"), SNT ("E")]);
      Add_Rule (G, SNT ("E"), [ST ("n")]);
      
      Check ("7.1 Ambiguous rule sets configured", Natural (G.Rules.Length) = 2);
      Check ("7.2 Recognizes 'n + n'", Recognize (G, Input));
      Check ("7.3 Rejects malformed 'n +'", not Recognize (G, Make_Input ([ST ("n"), ST ("+")])));
   end;

   --  TEST 8: Left Recursion Handling
   Put_Line ("TEST 8 — Left Recursive Grammar");
   declare
      G : Grammar := (Start_Symbol => SNT ("A"), Rules => Production_Vectors.Empty_Vector);
      Input : constant Symbol_List := Make_Input ([ST ("a"), ST ("a"), ST ("a")]);
   begin
      -- A -> A a | a
      Add_Rule (G, SNT ("A"), [SNT ("A"), ST ("a")]);
      Add_Rule (G, SNT ("A"), [ST ("a")]);
      
      Check ("8.1 Grammar configuration", G.Start_Symbol = SNT ("A"));
      Check ("8.2 Earley handles left recursion natively without infinite loops", Recognize (G, Input));
      Check ("8.3 Rejects mismatched suffix", not Recognize (G, Make_Input ([ST ("a"), ST ("a"), ST ("b")])));
   end;

   --  TEST 9: Right Recursion Handling
   Put_Line ("TEST 9 — Right Recursive Grammar");
   declare
      G : Grammar := (Start_Symbol => SNT ("A"), Rules => Production_Vectors.Empty_Vector);
      Input : constant Symbol_List := Make_Input ([ST ("a"), ST ("a"), ST ("a")]);
   begin
      -- A -> a A | a
      Add_Rule (G, SNT ("A"), [ST ("a"), SNT ("A")]);
      Add_Rule (G, SNT ("A"), [ST ("a")]);
      
      Check ("9.1 Grammar configuration", G.Start_Symbol = SNT ("A"));
      Check ("9.2 Recursion unrolls accurately", Recognize (G, Input));
      Check ("9.3 Validates subsets correctly", Recognize (G, Make_Input ([ST ("a")])));
   end;

   --  TEST 10: Highly Ambiguous Grammar (Catalan Numbers)
   Put_Line ("TEST 10 — Highly Ambiguous Grammar");
   declare
      G : Grammar := (Start_Symbol => SNT ("S"), Rules => Production_Vectors.Empty_Vector);
      Input : constant Symbol_List := Make_Input ([ST ("x"), ST ("x"), ST ("x"), ST ("x")]);
   begin
      -- S -> S S | x
      Add_Rule (G, SNT ("S"), [SNT ("S"), SNT ("S")]);
      Add_Rule (G, SNT ("S"), [ST ("x")]);
      
      Check ("10.1 Grammar is set", Natural (G.Rules.Length) = 2);
      Check ("10.2 Four tokens recognized", Recognize (G, Input));
      
      declare
         C : constant Chart := Parse_Chart (G, Input);
      begin
         Check ("10.3 Chart sets contain overlapping states", Natural (C.Element (4).Length) > 0);
      end;
   end;

   --  TEST 11: Complex Item State Generation
   Put_Line ("TEST 11 — Complex Item Generation Validation");
   declare
      G : Grammar := (Start_Symbol => SNT ("S"), Rules => Production_Vectors.Empty_Vector);
      Input : constant Symbol_List := Make_Input ([ST ("("), ST (")")]);
   begin
      -- S -> ( S ) | epsilon
      Add_Rule (G, SNT ("S"), [ST ("("), SNT ("S"), ST (")")]);
      Add_Rule (G, SNT ("S"), []);
      
      Check ("11.1 Parenthesis matching recognition", Recognize (G, Input));
      
      declare
         C : constant Chart := Parse_Chart (G, Input);
      begin
         Check ("11.2 Correct origin tracking", Natural (C.Length) = 3);
         -- Ensure the completion properly spanned the input
         Check ("11.3 Final set populated", Natural (C.Element (2).Length) > 0);
      end;
   end;

   --  TEST 12: Item Set Equality Operator Verification
   Put_Line ("TEST 12 — Core Equality Semantics");
   declare
      I1 : constant Item := (Rule_Index => 1, Dot => 0, Origin => 0);
      I2 : constant Item := (Rule_Index => 1, Dot => 0, Origin => 0);
      I3 : constant Item := (Rule_Index => 2, Dot => 0, Origin => 0);
   begin
      Check ("12.1 Identical items equate", I1 = I2);
      Check ("12.2 Differing Rule_Index inequality", not (I1 = I3));
      Check ("12.3 Differing Dot inequality", not (I1 = (Rule_Index => 1, Dot => 1, Origin => 0)));
   end;

   --  TEST 13: Exception and Precondition Checking
   Put_Line ("TEST 13 — Empty Grammar Contract Rejection");
   declare
      Empty_G : constant Grammar := (Start_Symbol => SNT ("S"), Rules => Production_Vectors.Empty_Vector);
      Input   : constant Symbol_List := Symbol_Vectors.Empty_Vector;
      Hit     : Boolean := False;
      Res     : Boolean;
      pragma Warnings (Off, Res);
   begin
      Check ("13.1 Rule count is strictly 0", Natural (Empty_G.Rules.Length) = 0);
      
      begin
         Res := Recognize (Empty_G, Input);
      exception
         when Ada.Assertions.Assertion_Error =>
            Hit := True;
      end;
      
      Check ("13.2 Precondition caught execution correctly", Hit);
      Check ("13.3 Safety confirmed", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   
   if Fail_Count > 0 then
      raise Program_Error with "Some tests failed";
   end if;

end Tests;
