with Ada.Text_IO; use Ada.Text_IO;
with Inside_Outside; use Inside_Outside;

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

   function Approx_Eq (A, B : Real) return Boolean is
   begin
      return abs (A - B) < 1.0e-5;
   end Approx_Eq;

   -- Shared Grammar Template across tests for validation
   function Setup_Test_Grammar return Grammar is
      G : Grammar (Num_NT => 2, Num_T => 2);
   begin
      -- Non-terminals: 1 (S), 2 (A)
      -- Terminals: 1 ('a'), 2 ('b')
      G.Start_Symbol := 1;

      -- P(S -> a) = 0.4
      G.Unary (1, 1) := 0.4;
      -- P(S -> A A) = 0.6
      G.Binary (1, 2, 2) := 0.6;

      -- P(A -> a) = 0.3
      G.Unary (2, 1) := 0.3;
      -- P(A -> b) = 0.7
      G.Unary (2, 2) := 0.7;

      return G;
   end Setup_Test_Grammar;

begin
   Put_Line ("--- Inside-Outside Algorithm Test Suite ---");

   -- TEST 1 - Valid Grammar Identification
   Put_Line ("TEST 1 - Valid Grammar Identification");
   declare
      G : constant Grammar := Setup_Test_Grammar;
   begin
      Check ("1.1 Grammar identifies as valid", Is_Valid_Grammar (G));
      Check ("1.2 Unary prob correct", Approx_Eq (G.Unary (1, 1), 0.4));
      Check ("1.3 Binary prob correct", Approx_Eq (G.Binary (1, 2, 2), 0.6));
   end;

   -- TEST 2 - Invalid Grammar Identification
   Put_Line ("TEST 2 - Invalid Grammar Identification");
   declare
      G : Grammar := Setup_Test_Grammar;
   begin
      G.Unary (1, 1) := 0.9; -- Sum is now 1.5 for NT 1
      Check ("2.1 Invalid grammar rejected", not Is_Valid_Grammar (G));
      G.Unary (1, 1) := 0.0; -- Sum is now 0.6 for NT 1
      Check ("2.2 Partial sum grammar rejected", not Is_Valid_Grammar (G));
      G.Unary (1, 1) := 0.4; -- Fix back
      Check ("2.3 Fixed grammar valid", Is_Valid_Grammar (G));
   end;

   -- TEST 3 - Inside Algorithm (Single Element Valid)
   Put_Line ("TEST 3 - Inside Algorithm (Single Element Valid)");
   declare
      G     : constant Grammar := Setup_Test_Grammar;
      O     : constant Observation_Sequence (1 .. 1) := [1]; -- 'a'
      Alpha : constant Dynamic_Matrix := Compute_Inside (G, O);
   begin
      Check ("3.1 Alpha(S, 1, 1) = 0.4", Approx_Eq (Alpha (1, 1, 1), 0.4));
      Check ("3.2 Alpha(A, 1, 1) = 0.3", Approx_Eq (Alpha (2, 1, 1), 0.3));
      Check ("3.3 Sum matches expectation", Approx_Eq (Alpha (1, 1, 1) + Alpha (2, 1, 1), 0.7));
   end;

   -- TEST 4 - Inside Algorithm (Single Element Invalid)
   Put_Line ("TEST 4 - Inside Algorithm (Single Element Invalid)");
   declare
      G     : constant Grammar := Setup_Test_Grammar;
      O     : constant Observation_Sequence (1 .. 1) := [2]; -- 'b'
      Alpha : constant Dynamic_Matrix := Compute_Inside (G, O);
   begin
      Check ("4.1 Alpha(S, 1, 1) = 0.0", Approx_Eq (Alpha (1, 1, 1), 0.0));
      Check ("4.2 Alpha(A, 1, 1) = 0.7", Approx_Eq (Alpha (2, 1, 1), 0.7));
      Check ("4.3 Start symbol probability zero", Approx_Eq (Sequence_Probability (G, O), 0.0));
   end;

   -- TEST 5 - Inside Algorithm (Length 2 Recursive Step)
   Put_Line ("TEST 5 - Inside Algorithm (Length 2 Recursive Step)");
   declare
      G     : constant Grammar := Setup_Test_Grammar;
      O     : constant Observation_Sequence (1 .. 2) := [1, 2]; -- "ab"
      Alpha : constant Dynamic_Matrix := Compute_Inside (G, O);
   begin
      -- Alpha(S, 1, 2) = P(S->AA) * Alpha(A, 1, 1) * Alpha(A, 2, 2) = 0.6 * 0.3 * 0.7 = 0.126
      Check ("5.1 Alpha(S, 1, 2) = 0.126", Approx_Eq (Alpha (1, 1, 2), 0.126));
      Check ("5.2 Alpha(A, 1, 2) = 0.0", Approx_Eq (Alpha (2, 1, 2), 0.0));
      Check ("5.3 Correct shape", Alpha'Length (2) = 2 and Alpha'Length (3) = 2);
   end;

   -- TEST 6 - Outside Algorithm (Base Case Check)
   Put_Line ("TEST 6 - Outside Algorithm (Base Case Check)");
   declare
      G     : constant Grammar := Setup_Test_Grammar;
      O     : constant Observation_Sequence (1 .. 2) := [1, 2];
      Alpha : constant Dynamic_Matrix := Compute_Inside (G, O);
      Beta  : constant Dynamic_Matrix := Compute_Outside (G, O, Alpha);
   begin
      Check ("6.1 Beta(S, 1, 2) = 1.0 (Root constraint)", Approx_Eq (Beta (1, 1, 2), 1.0));
      Check ("6.2 Beta(A, 1, 2) = 0.0", Approx_Eq (Beta (2, 1, 2), 0.0));
      Check ("6.3 Beta dimensions match", Beta'Length (1) = 2);
   end;

   -- TEST 7 - Outside Algorithm (Recursive Step Check)
   Put_Line ("TEST 7 - Outside Algorithm (Recursive Step Check)");
   declare
      G     : constant Grammar := Setup_Test_Grammar;
      O     : constant Observation_Sequence (1 .. 2) := [1, 2];
      Alpha : constant Dynamic_Matrix := Compute_Inside (G, O);
      Beta  : constant Dynamic_Matrix := Compute_Outside (G, O, Alpha);
   begin
      -- Beta(A, 1, 1) = Beta(S, 1, 2) * P(S->AA) * Alpha(A, 2, 2) = 1.0 * 0.6 * 0.7 = 0.42
      -- Beta(A, 2, 2) = Beta(S, 1, 2) * P(S->AA) * Alpha(A, 1, 1) = 1.0 * 0.6 * 0.3 = 0.18
      Check ("7.1 Beta(A, 1, 1) = 0.42", Approx_Eq (Beta (2, 1, 1), 0.42));
      Check ("7.2 Beta(A, 2, 2) = 0.18", Approx_Eq (Beta (2, 2, 2), 0.18));
      Check ("7.3 Beta(S, 1, 1) = 0.0", Approx_Eq (Beta (1, 1, 1), 0.0));
   end;

   -- TEST 8 - Sequence Probability Cohesion
   Put_Line ("TEST 8 - Sequence Probability Cohesion");
   declare
      G        : constant Grammar := Setup_Test_Grammar;
      O        : constant Observation_Sequence (1 .. 2) := [1, 2];
      Alpha    : constant Dynamic_Matrix := Compute_Inside (G, O);
      Beta     : constant Dynamic_Matrix := Compute_Outside (G, O, Alpha);
      Seq_Prob : constant Real := Sequence_Probability (G, O);
      Sum_Span : Real := 0.0;
   begin
      -- The sum over all non-terminals for span (1, 1) of Alpha*Beta should equal P(O)
      Sum_Span := Alpha (1, 1, 1) * Beta (1, 1, 1) + Alpha (2, 1, 1) * Beta (2, 1, 1);
      Check ("8.1 P(O) via helper = 0.126", Approx_Eq (Seq_Prob, 0.126));
      Check ("8.2 P(O) via sum(Alpha * Beta)", Approx_Eq (Sum_Span, Seq_Prob));
      Check ("8.3 Alpha * Beta bounds within logic", Sum_Span > 0.0);
   end;

   -- TEST 9 - EM Step (Binary Rules Update)
   Put_Line ("TEST 9 - EM Step (Binary Rules Update)");
   declare
      G     : constant Grammar := Setup_Test_Grammar;
      O     : constant Observation_Sequence (1 .. 2) := [1, 2];
      New_G : constant Grammar := EM_Step (G, O);
   begin
      -- 'S' only produced 'A A' in this sequence layout. Expect P(S->AA) = 1.0.
      Check ("9.1 P(S -> A A) updated to 1.0", Approx_Eq (New_G.Binary (1, 2, 2), 1.0));
      Check ("9.2 No phantom binary rules S -> S S", Approx_Eq (New_G.Binary (1, 1, 1), 0.0));
      Check ("9.3 No phantom binary rules A -> A A", Approx_Eq (New_G.Binary (2, 2, 2), 0.0));
   end;

   -- TEST 10 - EM Step (Unary Rules Update)
   Put_Line ("TEST 10 - EM Step (Unary Rules Update)");
   declare
      G     : constant Grammar := Setup_Test_Grammar;
      O     : constant Observation_Sequence (1 .. 2) := [1, 2];
      New_G : constant Grammar := EM_Step (G, O);
   begin
      -- 'S' never directly emitted terminal in this sequence, P(S->a) = 0
      Check ("10.1 P(S -> a) updated to 0.0", Approx_Eq (New_G.Unary (1, 1), 0.0));
      -- 'A' emitted 'a' and 'b' equally under expected counts for this sequence.
      Check ("10.2 P(A -> a) updated to 0.5", Approx_Eq (New_G.Unary (2, 1), 0.5));
      Check ("10.3 P(A -> b) updated to 0.5", Approx_Eq (New_G.Unary (2, 2), 0.5));
   end;

   -- TEST 11 - EM Step Constraint Preservation
   Put_Line ("TEST 11 - EM Step Constraint Preservation");
   declare
      G     : constant Grammar := Setup_Test_Grammar;
      O     : constant Observation_Sequence (1 .. 2) := [1, 2];
      New_G : constant Grammar := EM_Step (G, O);
   begin
      Check ("11.1 New grammar remains valid", Is_Valid_Grammar (New_G));
      Check ("11.2 S rules sum to 1.0", Approx_Eq (New_G.Unary (1, 1) + New_G.Binary (1, 2, 2), 1.0));
      Check ("11.3 A rules sum to 1.0", Approx_Eq (New_G.Unary (2, 1) + New_G.Unary (2, 2), 1.0));
   end;

   -- TEST 12 - Impossible Sequence Handling
   Put_Line ("TEST 12 - Impossible Sequence Handling");
   declare
      G     : constant Grammar := Setup_Test_Grammar;
      O     : constant Observation_Sequence (1 .. 1) := [2]; -- 'b' cannot be directly generated by S
   begin
      Check ("12.1 Sequence probability is strictly zero", Sequence_Probability (G, O) = 0.0);
      Check ("12.2 Length matches length 1 bounds", O'Length = 1);
      Check ("12.3 Bounds slide implicitly", O'First = 1);
   end;

   -- TEST 13 - Exception Handling on Zero Probability Sequence
   Put_Line ("TEST 13 - Exception Handling on Zero Probability Sequence");
   declare
      G     : constant Grammar := Setup_Test_Grammar;
      O     : constant Observation_Sequence (1 .. 1) := [2];
      Caught : Boolean := False;
   begin
      begin
         declare
            New_G : constant Grammar := EM_Step (G, O);
            pragma Unreferenced (New_G);
         begin
            null;
         end;
      exception
         when Computation_Error =>
            Caught := True;
         when others =>
            null;
      end;
      Check ("13.1 Exception Computation_Error caught", Caught);
      Check ("13.2 Survived exception handling", True);
      Check ("13.3 Assured EM invariant checks block failure", Caught);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
