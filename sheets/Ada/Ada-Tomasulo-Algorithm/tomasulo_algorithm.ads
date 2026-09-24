-- tomasulo_algorithm.ads
-- Tomasulo's Algorithm for Dynamic Instruction Scheduling
package Tomasulo_Algorithm is

   -- Core Types (Strong Typing)
   type Opcode_Type is (NOP, ADD, SUB, MUL, DIV);
   type Register_Type is (F0, F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15, None_Reg);
   type RS_Name is (None, Add1, Add2, Add3, Mult1, Mult2);

   -- Exception for Structural Hazards / Invalid Data
   Structural_Hazard : exception;
   Execution_Error   : exception;

   type Instruction is record
      Op   : Opcode_Type := NOP;
      Dest : Register_Type := None_Reg;
      Src1 : Register_Type := None_Reg;
      Src2 : Register_Type := None_Reg;
   end record;

   type Instruction_Array is array (Positive range <>) of Instruction;

   -- Reservation Station (RS) Structure
   type Reservation_Station is record
      Busy   : Boolean := False;
      Op     : Opcode_Type := NOP;
      Vj     : Integer := 0;      -- Value of Source 1
      Vk     : Integer := 0;      -- Value of Source 2
      Qj     : RS_Name := None;   -- RS producing Source 1
      Qk     : RS_Name := None;   -- RS producing Source 2
      A      : Integer := 0;      -- Address/Immediate
      Result : Integer := 0;      -- Executed Result
      Cycles : Integer := 0;      -- Remaining cycles for execution
      Done   : Boolean := False;  -- Finished execution, awaiting CDB
   end record;

   type RS_Array is array (RS_Name range Add1 .. Mult2) of Reservation_Station;
   type RAT_Array is array (Register_Type range F0 .. F15) of RS_Name;
   type Reg_Array is array (Register_Type range F0 .. F15) of Integer;

   -- Machine State
   type Machine_State is record
      PC         : Positive := 1;
      Cycle      : Natural := 0;
      RS         : RS_Array;
      RAT        : RAT_Array := (others => None);
      Regs       : Reg_Array := (others => 0);
      Is_Halted  : Boolean := False;
   end record;

   -- Operations
   procedure Initialize (State : out Machine_State);
   
   -- Core Variants: Standard (Dynamic) vs Flush (Preemptive Branch Mispredict)
   procedure Step_Cycle (State : in out Machine_State; Insts : Instruction_Array);
   procedure Flush_Pipeline (State : in out Machine_State); -- Preemptive behavior variant

end Tomasulo_Algorithm;
