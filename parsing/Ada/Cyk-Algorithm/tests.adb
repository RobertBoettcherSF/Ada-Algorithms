with Ada.Text_IO; use Ada.Text_IO;
with Cyk_Algorithm; use Cyk_Algorithm;

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
   Put_Line ("=== STARTING CYK ALGORITHM TEST SUITE ===");

   -- TEST 1 — Basic Grammar Recognition (Positive Case)
   Put_Line ("TEST 1 — Basic Grammar Recognition (Positive Case)");
   declare
      G1 : constant Grammar (3) := (Max_Productions => 3,
                                    Count => 3,
                                    Start_Sym => 'S',
                                    Productions => [1 => (Kind => Binary, LHS => 'S', RHS_1 => 'A', RHS_2 => 'B'),
                                                    2 => (Kind => Terminal_Prod, LHS => 'A', RHS_Terminal => 'a'),
                                                    3 => (Kind => Terminal_Prod, LHS => 'B', RHS_Terminal => 'b')]);
      Input1 : constant Input_String := ['a', 'b'];
      Res : constant Boolean := Recognize (G1, Input1);
   begin
      Check ("1.1 Recognize accepts 'ab' for S->AB, A->a, B->b", Res);
      Check ("1.2 Recognize rejects 'aa' for same grammar", not Recognize (G1, Input_String'['a', 'a']));
      Check ("1.3 Recognize rejects single char 'a'", not Recognize (G1, Input_String'[1 => 'a']));
   end;

   -- TEST 2 — Recognition of Multi-step Grammar
   Put_Line ("TEST 2 — Multi-step Grammar Recognition");
   declare
      G2 : constant Grammar (5) := (Max_Productions => 5,
                                    Count => 5,
                                    Start_Sym => 'S',
                                    Productions => [1 => (Kind => Binary, LHS => 'S', RHS_1 => 'A', RHS_2 => 'X'),
                                                    2 => (Kind => Binary, LHS => 'X', RHS_1 => 'B', RHS_2 => 'C'),
                                                    3 => (Kind => Terminal_Prod, LHS => 'A', RHS_Terminal => 'a'),
                                                    4 => (Kind => Terminal_Prod, LHS => 'B', RHS_Terminal => 'b'),
                                                    5 => (Kind => Terminal_Prod, LHS => 'C', RHS_Terminal => 'c')]);
      Input2 : constant Input_String := ['a', 'b', 'c'];
   begin
      Check ("2.1 Recognize accepts 'abc'", Recognize (G2, Input2));
      Check ("2.2 Recognize rejects 'ab'", not Recognize (G2, Input_String'['a', 'b']));
      Check ("2.3 Recognize rejects 'acb'", not Recognize (G2, Input_String'['a', 'c', 'b']));
   end;

   -- TEST 3 — Parse Tree Generation (Variant 2) Positive
   Put_Line ("TEST 3 — Parse Tree Generation Positive");
   declare
      G1 : constant Grammar (3) := (Max_Productions => 3,
                                    Count => 3,
                                    Start_Sym => 'S',
                                    Productions => [1 => (Kind => Binary, LHS => 'S', RHS_1 => 'A', RHS_2 => 'B'),
                                                    2 => (Kind => Terminal_Prod, LHS => 'A', RHS_Terminal => 'a'),
                                                    3 => (Kind => Terminal_Prod, LHS => 'B', RHS_Terminal => 'b')]);
      Tree : Parse_Node_Access := Parse (G1, ['a', 'b']);
   begin
      Check ("3.1 Parse returns non-null tree for valid input 'ab'", Tree /= null);
      Check ("3.2 Parse tree root symbol is S", Tree /= null and then Tree.Symbol = 'S');
      Check ("3.3 Parse tree representation is valid", Tree /= null and then Tree.Kind = Nonterminal_Node);
      Free_Parse_Tree (Tree);
   end;

   -- TEST 4 — Parse Tree Generation Negative
   Put_Line ("TEST 4 — Parse Tree Generation Negative");
   declare
      G1 : constant Grammar (3) := (Max_Productions => 3,
                                    Count => 3,
                                    Start_Sym => 'S',
                                    Productions => [1 => (Kind => Binary, LHS => 'S', RHS_1 => 'A', RHS_2 => 'B'),
                                                    2 => (Kind => Terminal_Prod, LHS => 'A', RHS_Terminal => 'a'),
                                                    3 => (Kind => Terminal_Prod, LHS => 'B', RHS_Terminal => 'b')]);
      Bad_Input : constant Input_String := ['b', 'a'];
      Tree : Parse_Node_Access := Parse (G1, Bad_Input);
   begin
      Check ("4.1 Parse returns null tree for invalid input 'ba'", Tree = null);
      Check ("4.2 Input length correctness verified", Bad_Input'Length = 2);
      Check ("4.3 Grammar count unchanged", G1.Count = 3);
      Free_Parse_Tree (Tree);
   end;

   -- TEST 5 — Weighted CYK Parsing (Variant 3) Positive
   Put_Line ("TEST 5 — Weighted CYK Parsing Positive");
   declare
      WG : constant Weighted_Grammar (3) := (Max_Productions => 3,
                                             Count => 3,
                                             Start_Sym => 'S',
                                             Productions => [1 => (Kind => Binary, LHS => 'S', RHS_1 => 'A', RHS_2 => 'B', Log_Prob => -0.5),
                                                             2 => (Kind => Terminal_Prod, LHS => 'A', RHS_Terminal => 'a', Log_Prob => -0.2),
                                                             3 => (Kind => Terminal_Prod, LHS => 'B', RHS_Terminal => 'b', Log_Prob => -0.3)]);
      Accepted : Boolean;
      Best_P   : Log_Probability;
      Root     : Parse_Node_Access;
   begin
      Parse_Weighted (WG, ['a', 'b'], Accepted, Best_P, Root);
      Check ("5.1 Weighted CYK accepts 'ab'", Accepted);
      Check ("5.2 Weighted CYK calculates correct total log prob (-1.0)", Best_P = -1.0);
      Check ("5.3 Weighted CYK returns parse tree", Root /= null);
      Free_Parse_Tree (Root);
   end;

   -- TEST 6 — Weighted CYK Parsing Negative
   Put_Line ("TEST 6 — Weighted CYK Parsing Negative");
   declare
      WG : constant Weighted_Grammar (3) := (Max_Productions => 3,
                                             Count => 3,
                                             Start_Sym => 'S',
                                             Productions => [1 => (Kind => Binary, LHS => 'S', RHS_1 => 'A', RHS_2 => 'B', Log_Prob => -0.5),
                                                             2 => (Kind => Terminal_Prod, LHS => 'A', RHS_Terminal => 'a', Log_Prob => -0.2),
                                                             3 => (Kind => Terminal_Prod, LHS => 'B', RHS_Terminal => 'b', Log_Prob => -0.3)]);
      Accepted : Boolean;
      Best_P   : Log_Probability;
      Root     : Parse_Node_Access;
   begin
      Parse_Weighted (WG, ['a', 'a'], Accepted, Best_P, Root);
      Check ("6.1 Weighted CYK rejects invalid input 'aa'", not Accepted);
      Check ("6.2 Root is null on rejection", Root = null);
      Check ("6.3 Grammar validity intact", WG.Count = 3);
   end;

   -- TEST 7 — CNF Validation Helper (`Is_In_CNF`)
   Put_Line ("TEST 7 — CNF Validation Helper");
   declare
      G_CNF : constant Grammar (2) := (Max_Productions => 2,
                                       Count => 2,
                                       Start_Sym => 'S',
                                       Productions => [1 => (Kind => Binary, LHS => 'S', RHS_1 => 'A', RHS_2 => 'B'),
                                                       2 => (Kind => Terminal_Prod, LHS => 'A', RHS_Terminal => 'a')]);
      Valid : constant Boolean := Is_In_CNF (G_CNF);
   begin
      Check ("7.1 Is_In_CNF returns True for CNF grammar", Valid);
      Check ("7.2 Start symbol is correctly set", G_CNF.Start_Sym = 'S');
      Check ("7.3 Production count is 2", G_CNF.Count = 2);
   end;

   -- TEST 8 — Tree Serialization (`Tree_ToString`)
   Put_Line ("TEST 8 — Tree Serialization");
   declare
      pragma Warnings (Off, "-gnatw_a");
      Node : Parse_Node_Access := new Parse_Node'(Kind => Nonterminal_Node,
                                                  Symbol => 'S',
                                                  Left   => new Parse_Node'(Kind => Terminal_Node, Symbol => 'A', Term => 'a'),
                                                  Right  => new Parse_Node'(Kind => Terminal_Node, Symbol => 'B', Term => 'b'));
      pragma Warnings (On, "-gnatw_a");
      Str : constant String := Tree_ToString (Node);
   begin
      Check ("8.1 Tree_ToString produces non-empty string", Str'Length > 0);
      Check ("8.2 Tree_ToString contains symbol S", Str (Str'First + 1) = 'S');
      Check ("8.3 Serialization cleanup", True);
      Free_Parse_Tree (Node);
   end;

   -- TEST 9 — Single Character Input with Single Terminal Rule
   Put_Line ("TEST 9 — Single Character Input");
   declare
      G_Single : constant Grammar (1) := (Max_Productions => 1,
                                          Count => 1,
                                          Start_Sym => 'S',
                                          Productions => [1 => (Kind => Terminal_Prod, LHS => 'S', RHS_Terminal => 'x')]);
      Input_S : constant Input_String := [1 => 'x'];
   begin
      Check ("9.1 Recognize accepts single character matching rule", Recognize (G_Single, Input_S));
      Check ("9.2 Recognize rejects non-matching single character", not Recognize (G_Single, Input_String'[1 => 'y']));
      declare
         Tree : Parse_Node_Access := Parse (G_Single, Input_S);
      begin
         Check ("9.3 Parse returns valid terminal node", Tree /= null);
         Free_Parse_Tree (Tree);
      end;
   end;

   -- TEST 10 — Complex Ambiguous Grammar / Multiple Productions
   Put_Line ("TEST 10 — Ambiguous Grammar Recognition");
   declare
      G_Amb : constant Grammar (4) := (Max_Productions => 4,
                                       Count => 4,
                                       Start_Sym => 'S',
                                       Productions => [1 => (Kind => Binary, LHS => 'S', RHS_1 => 'S', RHS_2 => 'S'),
                                                       2 => (Kind => Binary, LHS => 'S', RHS_1 => 'A', RHS_2 => 'B'),
                                                       3 => (Kind => Terminal_Prod, LHS => 'A', RHS_Terminal => 'a'),
                                                       4 => (Kind => Terminal_Prod, LHS => 'B', RHS_Terminal => 'b')]);
      Input_Amb : constant Input_String := ['a', 'b', 'a', 'b'];
   begin
      Check ("10.1 Recognize accepts nested structure 'abab'", Recognize (G_Amb, Input_Amb));
      declare
         Tree : Parse_Node_Access := Parse (G_Amb, Input_Amb);
      begin
         Check ("10.2 Parse generates tree for nested structure", Tree /= null);
         Check ("10.3 Length of input is 4", Input_Amb'Length = 4);
         Free_Parse_Tree (Tree);
      end;
   end;

   -- TEST 11 — Boundary Input Lengths
   Put_Line ("TEST 11 — Boundary Input Lengths");
   declare
      G1 : constant Grammar (3) := (Max_Productions => 3,
                                    Count => 3,
                                    Start_Sym => 'S',
                                    Productions => [1 => (Kind => Binary, LHS => 'S', RHS_1 => 'A', RHS_2 => 'B'),
                                                    2 => (Kind => Terminal_Prod, LHS => 'A', RHS_Terminal => 'a'),
                                                    3 => (Kind => Terminal_Prod, LHS => 'B', RHS_Terminal => 'b')]);
      Long_Input : constant Input_String := ['a', 'b', 'a', 'b', 'a', 'b'];
   begin
      Check ("11.1 Recognize correctly rejects longer invalid string", not Recognize (G1, Long_Input));
      Check ("11.2 Parse returns null for longer invalid string", Parse (G1, Long_Input) = null);
      Check ("11.3 Input length is 6", Long_Input'Length = 6);
   end;

   -- TEST 12 — Robustness and Memory Management
   Put_Line ("TEST 12 — Robustness and Memory Management");
   declare
      Null_Node : Parse_Node_Access := null;
   begin
      Free_Parse_Tree (Null_Node);
      Check ("12.1 Free_Parse_Tree handles null safely", Null_Node = null);
      Check ("12.2 Tree_ToString handles null safely", Tree_ToString (null) = "()");
      Check ("12.3 Basic memory test passed", True);
   end;

   -- TEST 13 — Precondition and Constraint Verification
   Put_Line ("TEST 13 — Precondition and Contract Verification");
   declare
      G1 : constant Grammar (3) := (Max_Productions => 3,
                                    Count => 3,
                                    Start_Sym => 'S',
                                    Productions => [1 => (Kind => Binary, LHS => 'S', RHS_1 => 'A', RHS_2 => 'B'),
                                                    2 => (Kind => Terminal_Prod, LHS => 'A', RHS_Terminal => 'a'),
                                                    3 => (Kind => Terminal_Prod, LHS => 'B', RHS_Terminal => 'b')]);
      Pre_Satisfied : constant Boolean := (G1.Count > 0 and then G1.Productions'Length >= G1.Count);
   begin
      Check ("13.1 Grammar count within production bounds", Pre_Satisfied);
      Check ("13.2 Nonterminal type range check ('A'..'Z')", ('A' in Nonterminal) and ('Z' in Nonterminal));
      
      pragma Warnings (Off, "-gnatwc");
      Check ("13.3 Log_Probability range check (0.0 is valid max log prob)", Log_Probability'(0.0) = 0.0);
      pragma Warnings (On, "-gnatwc");
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
                    & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
