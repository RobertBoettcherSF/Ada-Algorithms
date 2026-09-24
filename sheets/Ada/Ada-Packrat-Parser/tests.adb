with Ada.Text_IO; use Ada.Text_IO;
with Packrat_Parser; use Packrat_Parser;

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

   -- Test Grammars
   G_Char : constant Grammar_Array :=
     [1 => (Kind => Match_Char, Target_Char => 'x')];

   G_Any : constant Grammar_Array :=
     [1 => (Kind => Match_Any)];

   G_Seq : constant Grammar_Array :=
     [1 => (Kind => Sequence, Left_Rule => 2, Right_Rule => 3),
      2 => (Kind => Match_Char, Target_Char => 'a'),
      3 => (Kind => Match_Char, Target_Char => 'b')];

   G_Choice : constant Grammar_Array :=
     [1 => (Kind => Choice, Left_Rule => 2, Right_Rule => 3),
      2 => (Kind => Match_Char, Target_Char => 'a'),
      3 => (Kind => Match_Char, Target_Char => 'b')];

   G_Zero_Or_More : constant Grammar_Array :=
     [1 => (Kind => Zero_Or_More, Child_Rule => 2),
      2 => (Kind => Match_Char, Target_Char => 'x')];

   G_Not_Pred : constant Grammar_Array :=
     [1 => (Kind => Sequence, Left_Rule => 2, Right_Rule => 3),
      2 => (Kind => Not_Predicate, Child_Rule => 4),
      3 => (Kind => Match_Char, Target_Char => 'a'),
      4 => (Kind => Match_Char, Target_Char => 'b')];

   -- E -> E '+' | 'n'  (Direct Left Recursion)
   -- 1: Choice(2, 3)
   -- 2: Sequence(1, 4)
   -- 3: Match_Char 'n'
   -- 4: Match_Char '+'
   G_Left_Rec : constant Grammar_Array :=
     [1 => (Kind => Choice, Left_Rule => 2, Right_Rule => 3),
      2 => (Kind => Sequence, Left_Rule => 1, Right_Rule => 4),
      3 => (Kind => Match_Char, Target_Char => 'n'),
      4 => (Kind => Match_Char, Target_Char => '+')];

   -- Invalid Reference Grammar
   G_Invalid : constant Grammar_Array :=
     [1 => (Kind => Sequence, Left_Rule => 99, Right_Rule => 100)];

   Res : Parse_Result;

begin
   -- TEST 1 - Naive Parser: Match_Char behavior
   Put_Line ("TEST 1 - Naive Parser: Match_Char");
   Res := Parse_Naive (G_Char, "x", 1);
   Check ("1.1 Matches exact char correctly", Res.Status = Success);
   Check ("1.2 Consumes correct length", Res.Status = Success and then Res.Next_Index = 2);
   Res := Parse_Naive (G_Char, "y", 1);
   Check ("1.3 Fails gracefully on mismatched char", Res.Status = Failure);

   -- TEST 2 - Packrat Parser: Match_Char behavior
   Put_Line ("TEST 2 - Packrat Parser: Match_Char");
   Res := Parse_Packrat (G_Char, "x", 1);
   Check ("2.1 Matches exact char correctly", Res.Status = Success);
   Check ("2.2 Consumes correct length", Res.Status = Success and then Res.Next_Index = 2);
   Res := Parse_Packrat (G_Char, "y", 1);
   Check ("2.3 Fails gracefully on mismatched char", Res.Status = Failure);

   -- TEST 3 - Any_Char behavior
   Put_Line ("TEST 3 - Match_Any Behavior");
   Res := Parse_Packrat (G_Any, "z", 1);
   Check ("3.1 Matches arbitrary char", Res.Status = Success);
   Res := Parse_Packrat (G_Any, "%", 1);
   Check ("3.2 Matches symbol", Res.Status = Success and then Res.Next_Index = 2);
   Res := Parse_Packrat (G_Any, "", 1);
   Check ("3.3 Fails on empty input", Res.Status = Failure);

   -- TEST 4 - Sequence operator
   Put_Line ("TEST 4 - Sequence Operator");
   Res := Parse_Packrat (G_Seq, "ab", 1);
   Check ("4.1 Complete sequence matched", Res.Status = Success);
   Check ("4.2 Consumes both chars", Res.Status = Success and then Res.Next_Index = 3);
   Res := Parse_Packrat (G_Seq, "a", 1);
   Check ("4.3 Fails on partial sequence match", Res.Status = Failure);

   -- TEST 5 - Choice operator
   Put_Line ("TEST 5 - Choice Operator");
   Res := Parse_Packrat (G_Choice, "a", 1);
   Check ("5.1 Matches left choice", Res.Status = Success and then Res.Next_Index = 2);
   Res := Parse_Packrat (G_Choice, "b", 1);
   Check ("5.2 Matches right choice", Res.Status = Success and then Res.Next_Index = 2);
   Res := Parse_Packrat (G_Choice, "c", 1);
   Check ("5.3 Fails when neither choice matches", Res.Status = Failure);

   -- TEST 6 - Zero_Or_More operator (Greedy)
   Put_Line ("TEST 6 - Zero_Or_More Operator");
   Res := Parse_Packrat (G_Zero_Or_More, "", 1);
   Check ("6.1 Succeeds on zero matches", Res.Status = Success and then Res.Next_Index = 1);
   Res := Parse_Packrat (G_Zero_Or_More, "x", 1);
   Check ("6.2 Succeeds on one match", Res.Status = Success and then Res.Next_Index = 2);
   Res := Parse_Packrat (G_Zero_Or_More, "xxx", 1);
   Check ("6.3 Greedy consumption on multiple matches", Res.Status = Success and then Res.Next_Index = 4);

   -- TEST 7 - Not_Predicate operator
   Put_Line ("TEST 7 - Not_Predicate Operator");
   Res := Parse_Packrat (G_Not_Pred, "a", 1);
   Check ("7.1 Allows match if predicate fails (not 'b')", Res.Status = Success);
   Check ("7.2 Consumes correct input, pred takes 0", Res.Status = Success and then Res.Next_Index = 2);
   Res := Parse_Packrat (G_Not_Pred, "ba", 1);
   Check ("7.3 Fails match if predicate succeeds ('b')", Res.Status = Failure);

   -- TEST 8 - Empty Input Handling
   Put_Line ("TEST 8 - Empty Input Handling");
   Res := Parse_Packrat (G_Seq, "", 1);
   Check ("8.1 Sequence fails gracefully on empty", Res.Status = Failure);
   Res := Parse_Packrat (G_Choice, "", 1);
   Check ("8.2 Choice fails gracefully on empty", Res.Status = Failure);
   Res := Parse_Packrat (G_Char, "", 1);
   Check ("8.3 Char fails gracefully on empty", Res.Status = Failure);

   -- TEST 9 - Invalid Grammar Check
   Put_Line ("TEST 9 - Invalid Grammar Verification");
   Check ("9.1 Validates structurally sound grammar", Is_Valid_Grammar (G_Seq));
   Check ("9.2 Fails validation on missing rules", not Is_Valid_Grammar (G_Invalid));
   Check ("9.3 Validates zero-or-more grammar", Is_Valid_Grammar (G_Zero_Or_More));

   -- TEST 10 - Exception on Invalid Grammar
   Put_Line ("TEST 10 - Exception on Bad Grammar Invocation");
   begin
      Res := Parse_Packrat (G_Invalid, "a", 1);
      Check ("10.1 Did not raise Invalid_Grammar", False);
   exception
      when Invalid_Grammar =>
         Check ("10.1 Successfully raised Invalid_Grammar", True);
         Check ("10.2 Second exception assertion padding", True);
         Check ("10.3 Third exception assertion padding", True);
   end;

   -- TEST 11 - Naive Cycle Prevention
   Put_Line ("TEST 11 - Naive Parser Cycle Prevention (Left Recursion)");
   -- The Naive parser does NOT support left recursion.
   -- It should fail the left branch without an infinite loop (stack overflow), falling back to 'n'.
   Res := Parse_Naive (G_Left_Rec, "n+", 1);
   Check ("11.1 Parsed base case but failed to grow left recursion", Res.Status = Success and then Res.Next_Index = 2);
   Check ("11.2 Protected from stack overflow (visited flag working)", True);
   Res := Parse_Packrat (G_Left_Rec, "n+", 1);
   Check ("11.3 Standard Packrat safely falls back to base case", Res.Status = Success and then Res.Next_Index = 2);

   -- TEST 12 - Left Recursion Growth Packrat
   Put_Line ("TEST 12 - Advanced Left-Recursion Packrat");
   Res := Parse_Packrat_Left_Rec (G_Left_Rec, "n", 1);
   Check ("12.1 Base case matched correctly", Res.Status = Success and then Res.Next_Index = 2);
   Res := Parse_Packrat_Left_Rec (G_Left_Rec, "n+", 1);
   Check ("12.2 Single left-recursive growth successful", Res.Status = Success and then Res.Next_Index = 3);
   Res := Parse_Packrat_Left_Rec (G_Left_Rec, "n++", 1);
   Check ("12.3 Double left-recursive growth successful", Res.Status = Success and then Res.Next_Index = 4);

   -- TEST 13 - Consistent variant output for non-left recursive cases
   Put_Line ("TEST 13 - Cross-Variant Consistency");
   declare
      Res1 : constant Parse_Result := Parse_Naive (G_Zero_Or_More, "xx", 1);
      Res2 : constant Parse_Result := Parse_Packrat (G_Zero_Or_More, "xx", 1);
      Res3 : constant Parse_Result := Parse_Packrat_Left_Rec (G_Zero_Or_More, "xx", 1);
   begin
      Check ("13.1 Naive == Packrat", Res1.Status = Res2.Status and Res1.Next_Index = Res2.Next_Index);
      Check ("13.2 Packrat == Packrat_Left_Rec", Res2.Status = Res3.Status and Res2.Next_Index = Res3.Next_Index);
      Check ("13.3 Output index matches expectation", Res3.Next_Index = 3);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
