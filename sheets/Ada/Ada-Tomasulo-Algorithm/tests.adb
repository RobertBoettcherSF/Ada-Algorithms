-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Tomasulo_Algorithm; use Tomasulo_Algorithm;

procedure Tests is
   State : Machine_State;
   Test_Program_1 : Instruction_Array (1..3) := (
      (ADD, F0, F1, F2),
      (ADD, F3, F0, F4),
      (SUB, F5, F3, F0)
   );
begin
   Put_Line ("Starting Tomasulo V&V Test Suite...");
   Put_Line ("=====================================");

   -- TEST 1 - Initialization
   Put_Line ("TEST 1 - Initialization State");
   Initialize (State);
   Put_Line ("  1.1 Assert PC = 1");
   Assert (State.PC = 1, "PC failed to initialize");
   Put_Line ("  1.2 Assert Cycle = 0");
   Assert (State.Cycle = 0, "Cycle failed to initialize");
   Put_Line ("  1.3 Assert RAT is empty");
   Assert (State.RAT(F0) = None, "RAT not empty");
   Put_Line ("      PASS");

   -- TEST 2 - Basic Issue Logic
   Put_Line ("TEST 2 - Basic Instruction Issue");
   Initialize (State);
   State.Regs(F1) := 10; State.Regs(F2) := 20;
   Step_Cycle (State, Test_Program_1);
   Put_Line ("  2.1 Assert RS allocated for ADD");
   Assert (State.RS(Add1).Busy, "RS not allocated");
   Put_Line ("  2.2 Assert Operands Read");
   Assert (State.RS(Add1).Vj = 10 and State.RS(Add1).Vk = 20, "Operands mismatch");
   Put_Line ("  2.3 Assert RAT Renaming Occurs");
   Assert (State.RAT(F0) = Add1, "Register not renamed");
   Put_Line ("      PASS");

   -- TEST 3 - Data Hazard (RAW) Stalls Execution
   Put_Line ("TEST 3 - Read-After-Write Hazard Detection");
   Step_Cycle (State, Test_Program_1); -- Issues second ADD
   Put_Line ("  3.1 Assert Second instruction queued");
   Assert (State.RS(Add2).Busy, "Second inst not issued");
   Put_Line ("  3.2 Assert Operand wait (Qj set)");
   Assert (State.RS(Add2).Qj = Add1, "RAW hazard not mapped");
   Put_Line ("      PASS");

   -- TEST 4 - Execution Latency (ADD)
   Put_Line ("TEST 4 - Execution Latency Enforcement");
   Step_Cycle (State, Test_Program_1); -- Add1 executes, Add2 waits
   Put_Line ("  4.1 Assert ADD Latency matches specification (2 cycles)");
   Assert (State.RS(Add1).Done = True, "ADD latency incorrect");
   Put_Line ("      PASS");

   -- TEST 5 - CDB Broadcast (Write Result)
   Put_Line ("TEST 5 - Common Data Bus (CDB) Broadcasting");
   Step_Cycle (State, Test_Program_1); -- Add1 writes back to CDB
   Put_Line ("  5.1 Assert RS Add1 is freed");
   Assert (not State.RS(Add1).Busy, "RS not freed after CDB");
   Put_Line ("  5.2 Assert RAT cleared for F0");
   Assert (State.RAT(F0) = None, "RAT not cleared");
   Put_Line ("  5.3 Assert Target Register updated");
   Assert (State.Regs(F0) = 30, "Register writeback failed");
   Put_Line ("      PASS");

   -- TEST 6 - Dependency Forwarding (Dependent RS gets CDB data)
   Put_Line ("TEST 6 - CDB Forwarding to waiting Reservation Stations");
   Put_Line ("  6.1 Assert Add2 grabbed CDB data");
   Assert (State.RS(Add2).Qj = None and State.RS(Add2).Vj = 30, "Forwarding failed");
   Put_Line ("      PASS");

   -- TEST 7 - WAW Hazard Protection (Register Renaming)
   Put_Line ("TEST 7 - Write-After-Write Hazard Mitigation");
   declare
      WAW_Program : Instruction_Array(1..2) := ((ADD, F0, F1, F2), (SUB, F0, F3, F4));
   begin
      Initialize (State);
      Step_Cycle (State, WAW_Program);
      Step_Cycle (State, WAW_Program);
      Put_Line ("  7.1 Assert RAT points to SUB (latest writer)");
      Assert (State.RAT(F0) = Add2, "WAW resolution failed");
      Put_Line ("      PASS");
   end;

   -- TEST 8 - Division by Zero Exception
   Put_Line ("TEST 8 - Execution Faults (Div by Zero)");
   declare
      Div_Zero : Instruction_Array(1..1) := (1 => (DIV, F10, F0, F1));
   begin
      Initialize (State);
      State.Regs(F0) := 10; State.Regs(F1) := 0;
      Step_Cycle (State, Div_Zero);
      for I in 1..40 loop -- Skip Div latency
         begin
            Step_Cycle (State, Div_Zero);
         exception
            when Execution_Error => 
               Put_Line ("  8.1 Assert Execution_Error raised gracefully");
               Put_Line ("      PASS");
               exit;
         end;
      end loop;
   end;

   -- TEST 9 - Structural Hazards (RS Full)
   Put_Line ("TEST 9 - Structural Hazard Handling");
   declare
      Full_RS : Instruction_Array(1..5) := (
         (DIV, F1, F2, F3), -- Blocks F1 for 40 cycles to trap following ADDs
         (ADD, F4, F1, F2), -- Takes Add1, waits for F1
         (ADD, F5, F1, F2), -- Takes Add2, waits for F1
         (ADD, F6, F1, F2), -- Takes Add3, waits for F1
         (ADD, F7, F1, F2)  -- 4th ADD should stall due to structural hazard
      );
   begin
      Initialize(State);
      State.Regs(F3) := 1; -- Avoid division by zero on DIV instruction
      Step_Cycle (State, Full_RS); -- Cycle 1: Issues DIV
      Step_Cycle (State, Full_RS); -- Cycle 2: Issues ADD1
      Step_Cycle (State, Full_RS); -- Cycle 3: Issues ADD2
      Step_Cycle (State, Full_RS); -- Cycle 4: Issues ADD3
      Step_Cycle (State, Full_RS); -- Cycle 5: Attempts 4th ADD, Structural Hazard
      Put_Line ("  9.1 Assert 4th Issue stalled (PC blocked)");
      Assert (State.PC = 5, "Structural hazard not stalling");
      Put_Line ("      PASS");
   end;

   -- TEST 10 - Halt State Detection
   Put_Line ("TEST 10 - Machine Halts on Completion");
   Initialize (State);
   Step_Cycle (State, (1 => (NOP, None_Reg, None_Reg, None_Reg)));
   Put_Line ("  10.1 Assert State.Is_Halted flag is True");
   Assert (State.Is_Halted, "Did not halt on NOP complete");
   Put_Line ("      PASS");

   -- TEST 11 - Empty Input handling
   Put_Line ("TEST 11 - Empty Input");
   declare
      Empty_Array : Instruction_Array(1..0);
   begin
      Initialize(State);
      Step_Cycle (State, Empty_Array);
      Put_Line ("  11.1 Assert Empty array causes halt immediately");
      Assert (State.Is_Halted, "Failed to handle empty array");
      Put_Line ("      PASS");
   end;

   -- TEST 12 - Execution Time verification (MUL Latency)
   Put_Line ("TEST 12 - Variable Execution Latency (MUL)");
   declare
      Mul_Prog : Instruction_Array(1..1) := (1 => (MUL, F1, F2, F3));
   begin
      Initialize(State);
      Step_Cycle (State, Mul_Prog);
      Put_Line ("  12.1 Assert MUL cycles initialized to 10");
      Assert (State.RS(Mult1).Cycles = 10, "MUL Latency mismatch");
      Put_Line ("      PASS");
   end;

   -- TEST 13 - Preemptive Pipeline Flush (Branch Mispredict Variant)
   Put_Line ("TEST 13 - Preemptive Pipeline Flush");
   Initialize(State);
   Step_Cycle(State, Test_Program_1); -- Issue 1 ADD
   Flush_Pipeline (State);
   Put_Line ("  13.1 Assert RS array cleared");
   Assert (not State.RS(Add1).Busy, "RS not cleared on flush");
   Put_Line ("  13.2 Assert RAT cleared");
   Assert (State.RAT(F0) = None, "RAT not flushed");
   Put_Line ("      PASS");

   Put_Line ("=====================================");
   Put_Line ("ALL TESTS EXECUTED SUCCESSFULLY.");
end Tests;
