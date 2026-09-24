with Ada.Text_IO; use Ada.Text_IO;
with LALR_Parser; use LALR_Parser;

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

   --  =========================================================================
   --  Test Setup: A miniature grammar and LALR parse table
   --  Grammar:
   --  1: S -> E
   --  2: E -> E PLUS ID
   --  3: E -> ID
   --  =========================================================================
   ID_Tok   : constant Terminal_ID := 1;
   PLUS_Tok : constant Terminal_ID := 2;
   S_Sym    : constant Non_Terminal_ID := 5001;
   E_Sym    : constant Non_Terminal_ID := 5002;

   Grammar_Rules : constant Rule_Array (1 .. 3) := [
      1 => (LHS => S_Sym, RHS_Length => 1),
      2 => (LHS => E_Sym, RHS_Length => 3),
      3 => (LHS => E_Sym, RHS_Length => 1)
   ];

   Act_Table : constant Action_Table (0 .. 4, 0 .. 2) := [
      0 => [1 => (Kind => Action_Shift, Next_State => 2), others => (Kind => Action_Error)],
      1 => [0 => (Kind => Action_Accept), 2 => (Kind => Action_Shift, Next_State => 3), others => (Kind => Action_Error)],
      2 => [0 => (Kind => Action_Reduce, Rule => 3), 2 => (Kind => Action_Reduce, Rule => 3), others => (Kind => Action_Error)],
      3 => [1 => (Kind => Action_Shift, Next_State => 4), others => (Kind => Action_Error)],
      4 => [0 => (Kind => Action_Reduce, Rule => 2), 2 => (Kind => Action_Reduce, Rule => 2), others => (Kind => Action_Error)]
   ];

   Goto_Tab : constant Goto_Table (0 .. 4, 5001 .. 5002) := [
      0      => [5002 => 1, others => Invalid_State],
      others => [others => Invalid_State]
   ];

begin
   --  TEST 1 — Valid Basic Parsings
   Put_Line ("TEST 1 — Valid Parsings");
   Check ("1.1 Base token single ID", Parse (Act_Table, Goto_Tab, Grammar_Rules, [1 => ID_Tok, 2 => EOF_Symbol], 0));
   Check ("1.2 Complex ID PLUS ID", Parse (Act_Table, Goto_Tab, Grammar_Rules, [1 => ID_Tok, 2 => PLUS_Tok, 3 => ID_Tok, 4 => EOF_Symbol], 0));
   Check ("1.3 Complex ID PLUS ID PLUS ID", Parse (Act_Table, Goto_Tab, Grammar_Rules, [1 => ID_Tok, 2 => PLUS_Tok, 3 => ID_Tok, 4 => PLUS_Tok, 5 => ID_Tok, 6 => EOF_Symbol], 0));

   --  TEST 2 — Syntax Errors triggering normal Action_Error returns
   Put_Line ("TEST 2 — Invalid Tokens (Syntax Error)");
   Check ("2.1 Unrecognized start sequence", not Parse (Act_Table, Goto_Tab, Grammar_Rules, [1 => PLUS_Tok, 2 => EOF_Symbol], 0));
   Check ("2.2 Sequential invalid tokens", not Parse (Act_Table, Goto_Tab, Grammar_Rules, [1 => ID_Tok, 2 => ID_Tok, 3 => EOF_Symbol], 0));
   Check ("2.3 Immediate EOF token", not Parse (Act_Table, Goto_Tab, Grammar_Rules, [1 => EOF_Symbol], 0));

   --  TEST 3 — LALR State Merging (All states distinct)
   Put_Line ("TEST 3 — LALR State Merging: Distinct Cores");
   declare
      LR1 : constant LR1_State_Array (1 .. 3) := [1 => (Core_ID => 10), 2 => (Core_ID => 11), 3 => (Core_ID => 12)];
      Map : constant LALR_Map := Generate_LALR_Mapping (LR1);
   begin
      Check ("3.1 Mapped ID 0", Map (1) = 0);
      Check ("3.2 Mapped ID 1", Map (2) = 1);
      Check ("3.3 Mapped ID 2", Map (3) = 2);
   end;

   --  TEST 4 — LALR State Merging (All states identical)
   Put_Line ("TEST 4 — LALR State Merging: Identical Cores");
   declare
      LR1 : constant LR1_State_Array (1 .. 3) := [others => (Core_ID => 10)];
      Map : constant LALR_Map := Generate_LALR_Mapping (LR1);
   begin
      Check ("4.1 First maps to 0", Map (1) = 0);
      Check ("4.2 Second collapses to 0", Map (2) = 0);
      Check ("4.3 Third collapses to 0", Map (3) = 0);
   end;

   --  TEST 5 — LALR State Merging (Mixed typical parsing)
   Put_Line ("TEST 5 — LALR State Merging: Typical Interleaved Merging");
   declare
      LR1 : constant LR1_State_Array (0 .. 4) := [0 => (Core_ID => 10), 1 => (Core_ID => 11), 2 => (Core_ID => 10), 3 => (Core_ID => 12), 4 => (Core_ID => 11)];
      Map : constant LALR_Map := Generate_LALR_Mapping (LR1);
   begin
      Check ("5.1 Initial mapped to 0", Map (0) = 0);
      Check ("5.2 Distinct mapped to 1", Map (1) = 1);
      Check ("5.3 Merged back to 0", Map (2) = 0);
      Check ("5.4 Distinct mapped to 2", Map (3) = 2);
      Check ("5.5 Merged back to 1", Map (4) = 1);
   end;

   --  TEST 6 — Invalid Parse Tables Handling (Bounds Checking)
   Put_Line ("TEST 6 — Robustness: Table Out of Bounds Lookups");
   declare
      Got_Err1, Got_Err2, Got_Err3 : Boolean := False;
   begin
      begin
         if Parse (Act_Table, Goto_Tab, Grammar_Rules, [1 => 3, 2 => EOF_Symbol], 0) then null; end if;
      exception when Invalid_Table_Error => Got_Err1 := True; end;
      Check ("6.1 Unknown Token raises Invalid_Table_Error", Got_Err1);

      declare
         Bad_Act : Action_Table := Act_Table;
      begin
         Bad_Act (2, 0) := (Kind => Action_Reduce, Rule => 999);
         begin
            if Parse (Bad_Act, Goto_Tab, Grammar_Rules, [1 => ID_Tok, 2 => EOF_Symbol], 0) then null; end if;
         exception when Invalid_Table_Error => Got_Err2 := True; end;
      end;
      Check ("6.2 Out of bounds Rule ID raises Invalid_Table_Error", Got_Err2);

      declare
         Bad_Goto : constant Goto_Table (0 .. 4, 5001 .. 5001) := [others => [others => Invalid_State]];
      begin
         begin
            if Parse (Act_Table, Bad_Goto, Grammar_Rules, [1 => ID_Tok, 2 => EOF_Symbol], 0) then null; end if;
         exception when Invalid_Table_Error => Got_Err3 := True; end;
      end;
      Check ("6.3 Out of bounds Goto target raises Invalid_Table_Error", Got_Err3);
   end;

   --  TEST 7 — Invalid Goto Transitions
   Put_Line ("TEST 7 — Invalid Goto Evaluation");
   declare
      Bad_Goto : Goto_Table := Goto_Tab;
      Got_Err1, Got_Err2 : Boolean := False;
   begin
      Bad_Goto (0, 5002) := Invalid_State;
      
      begin
         if Parse (Act_Table, Bad_Goto, Grammar_Rules, [1 => ID_Tok, 2 => EOF_Symbol], 0) then null; end if;
      exception when Parse_Error => Got_Err1 := True; end;
      Check ("7.1 Missing essential Goto raises Parse_Error", Got_Err1);

      begin
         if Parse (Act_Table, Bad_Goto, Grammar_Rules, [1 => ID_Tok, 2 => PLUS_Tok, 3 => ID_Tok, 4 => EOF_Symbol], 0) then null; end if;
      exception when Parse_Error => Got_Err2 := True; end;
      Check ("7.2 Missing essential Goto during long parse fails safely", Got_Err2);

      Check ("7.3 Valid token failing Goto doesn't prevent basic Action errors", not Parse (Act_Table, Goto_Tab, Grammar_Rules, [1 => PLUS_Tok, 2 => EOF_Symbol], 0));
   end;

   --  TEST 8 — Stack Management Violations
   Put_Line ("TEST 8 — Stack Underflow Validations");
   declare
      Bad_Rules : constant Rule_Array (1 .. 3) := [
         1 => (LHS => S_Sym, RHS_Length => 5), 
         2 => (LHS => E_Sym, RHS_Length => 5), 
         3 => (LHS => E_Sym, RHS_Length => 5)
      ];
      Got_Err1, Got_Err2, Got_Err3 : Boolean := False;
   begin
      begin
         if Parse (Act_Table, Goto_Tab, Bad_Rules, [1 => ID_Tok, 2 => EOF_Symbol], 0) then null; end if;
      exception when Parse_Error => Got_Err1 := True; end;
      Check ("8.1 Excess RHS size causes stack underflow exception", Got_Err1);

      begin
         if Parse (Act_Table, Goto_Tab, Bad_Rules, [1 => ID_Tok, 2 => PLUS_Tok, 3 => ID_Tok, 4 => EOF_Symbol], 0) then null; end if;
      exception when Parse_Error => Got_Err2 := True; end;
      Check ("8.2 Recursive rule underflow protected", Got_Err2);

      begin
         if Parse (Act_Table, Goto_Tab, Grammar_Rules, [1 => EOF_Symbol], 2) then null; end if;
      exception when Parse_Error => Got_Err3 := True; end;
      Check ("8.3 Starting midway through invalid context underflows safely", Got_Err3);
   end;

   --  TEST 9 — Input Stream Constraints Handling
   Put_Line ("TEST 9 — Input Array Preconditions");
   declare
      Got_Err1, Got_Err2, Got_Err3 : Boolean := False;
   begin
      declare
         Empty_Toks : constant Token_Array (1 .. 0) := [others => EOF_Symbol];
      begin
         begin
            if Parse (Act_Table, Goto_Tab, Grammar_Rules, Empty_Toks, 0) then null; end if;
         exception when Parse_Error => Got_Err1 := True; end;
      end;
      Check ("9.1 Null token array raised Parse_Error properly", Got_Err1);

      declare
         No_EOF : constant Token_Array (1 .. 1) := [1 => ID_Tok];
      begin
         begin
            if Parse (Act_Table, Goto_Tab, Grammar_Rules, No_EOF, 0) then null; end if;
         exception when Parse_Error => Got_Err2 := True; end;
      end;
      Check ("9.2 Missing EOF trailing token raises Parse_Error", Got_Err2);

      declare
         No_EOF_Long : constant Token_Array (1 .. 3) := [1 => ID_Tok, 2 => PLUS_Tok, 3 => ID_Tok];
      begin
         begin
            if Parse (Act_Table, Goto_Tab, Grammar_Rules, No_EOF_Long, 0) then null; end if;
         exception when Parse_Error => Got_Err3 := True; end;
      end;
      Check ("9.3 Long sequence without EOF raises Parse_Error", Got_Err3);
   end;

   --  TEST 10 — State Merging Array Boundary Edge Cases
   Put_Line ("TEST 10 — LALR Mapping Bounds Isolation");
   declare
      Single : constant LR1_State_Array (10 .. 10) := [10 => (Core_ID => 99)];
      Map_Single : constant LALR_Map := Generate_LALR_Mapping (Single);
      Empty : constant LR1_State_Array (1 .. 0) := [others => (Core_ID => 1)];
      Map_Empty : constant LALR_Map := Generate_LALR_Mapping (Empty);
      Offset : constant LR1_State_Array (5 .. 6) := [5 => (Core_ID => 2), 6 => (Core_ID => 3)];
      Map_Offset : constant LALR_Map := Generate_LALR_Mapping (Offset);
   begin
      Check ("10.1 Length=1 array maps safely", Map_Single (10) = 0);
      Check ("10.2 Empty arrays returned seamlessly", Map_Empty'Length = 0);
      Check ("10.3 Arbitrary lower bound offsets handled", Map_Offset (5) = 0 and Map_Offset (6) = 1);
   end;

   --  TEST 11 — Complex Expression Parsing
   Put_Line ("TEST 11 — Deeper Parsing Loops");
   declare
      Toks : Token_Array (1 .. 22);
      Got_Err : Boolean := False;
   begin
      for I in 1 .. 10 loop
         Toks (I * 2 - 1) := ID_Tok;
         Toks (I * 2)     := PLUS_Tok;
      end loop;
      Toks (21) := ID_Tok;
      Toks (22) := EOF_Symbol;

      Check ("11.1 Extremely long recursive structure validates", Parse (Act_Table, Goto_Tab, Grammar_Rules, Toks, 0));
      
      Toks (21) := PLUS_Tok;
      Check ("11.2 Dangling operators denied cleanly", not Parse (Act_Table, Goto_Tab, Grammar_Rules, Toks, 0));
      
      Toks (21) := ID_Tok;
      Toks (22) := ID_Tok; 
      begin
         if Parse (Act_Table, Goto_Tab, Grammar_Rules, Toks, 0) then null; end if;
      exception when Parse_Error => Got_Err := True; end;
      Check ("11.3 Invalid trailing characters without EOF triggers Error", Got_Err);
   end;

   --  TEST 12 — Mapping Type Limits and High Boundaries
   Put_Line ("TEST 12 — Mapping High Limits");
   declare
      Max_St : constant State_ID := 10_000;
      Extreme : constant LR1_State_Array (Max_St - 2 .. Max_St) := [
         Max_St - 2 => (Core_ID => 1),
         Max_St - 1 => (Core_ID => 2),
         Max_St     => (Core_ID => 1)
      ];
      Map : constant LALR_Map := Generate_LALR_Mapping (Extreme);
   begin
      Check ("12.1 Limit boundary element A maps", Map (Max_St - 2) = 0);
      Check ("12.2 Limit boundary element B distinct", Map (Max_St - 1) = 1);
      Check ("12.3 Limit boundary wrap merges", Map (Max_St) = 0);
   end;

   --  TEST 13 — Massive State Merging Scalability
   Put_Line ("TEST 13 — Large Scale State Mapping");
   declare
      Massive : LR1_State_Array (1 .. 1_000);
   begin
      for I in Massive'Range loop
         Massive (I).Core_ID := Item_Core_ID (I mod 5);
      end loop;
      
      declare
         Map : constant LALR_Map := Generate_LALR_Mapping (Massive);
      begin
         Check ("13.1 Modulo identities form 5 LALR states", Map (1) = 0 and Map (2) = 1 and Map (3) = 2 and Map (4) = 3 and Map (5) = 4);
         Check ("13.2 Repeating patterns map back smoothly", Map (6) = Map (1));
         Check ("13.3 Maximum extreme resolves dynamically", Map (1_000) = Map (5));
      end;
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
