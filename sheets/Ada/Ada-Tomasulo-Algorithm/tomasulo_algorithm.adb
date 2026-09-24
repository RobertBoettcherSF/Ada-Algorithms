-- tomasulo_algorithm.adb
package body Tomasulo_Algorithm is

   procedure Initialize (State : out Machine_State) is
   begin
      State.PC := 1;
      State.Cycle := 0;
      State.Is_Halted := False;
      State.RAT := (others => None);
      State.Regs := (others => 0);
      for I in State.RS'Range loop
         State.RS (I).Busy := False;
      end loop;
   end Initialize;

   procedure Flush_Pipeline (State : in out Machine_State) is
   begin
      -- Preemptive Variant: Emulates branch misprediction recovery
      State.RAT := (others => None);
      for I in State.RS'Range loop
         State.RS (I).Busy := False;
      end loop;
   end Flush_Pipeline;

   -- Helper Function for Execution Latency
   function Get_Latency (Op : Opcode_Type) return Integer is
   begin
      case Op is
         when ADD | SUB => return 2;
         when MUL => return 10;
         when DIV => return 40;
         when others => return 1;
      end case;
   end Get_Latency;

   procedure Step_Cycle (State : in out Machine_State; Insts : Instruction_Array) is
      CDB_Valid : Boolean := False;
      CDB_Value : Integer := 0;
      CDB_Tag   : RS_Name := None;
   begin
      State.Cycle := State.Cycle + 1;

      -- 1. WRITE RESULT (CDB Broadcast)
      for I in State.RS'Range loop
         if State.RS(I).Busy and then State.RS(I).Done and then not CDB_Valid then
            CDB_Valid := True;
            CDB_Value := State.RS(I).Result;
            CDB_Tag   := I;
            State.RS(I).Busy := False; -- Free RS
            State.RS(I).Done := False;
         end if;
      end loop;

      if CDB_Valid then
         -- Broadcast to Reservation Stations
         for I in State.RS'Range loop
            if State.RS(I).Busy then
               if State.RS(I).Qj = CDB_Tag then
                  State.RS(I).Vj := CDB_Value;
                  State.RS(I).Qj := None;
               end if;
               if State.RS(I).Qk = CDB_Tag then
                  State.RS(I).Vk := CDB_Value;
                  State.RS(I).Qk := None;
               end if;
            end if;
         end loop;

         -- Broadcast to Register File (RAT)
         for R in State.RAT'Range loop
            if State.RAT(R) = CDB_Tag then
               State.Regs(R) := CDB_Value;
               State.RAT(R) := None;
            end if;
         end loop;
      end if;

      -- 2. EXECUTE
      for I in State.RS'Range loop
         if State.RS(I).Busy and then not State.RS(I).Done then
            if State.RS(I).Qj = None and then State.RS(I).Qk = None then
               if State.RS(I).Cycles > 0 then
                  State.RS(I).Cycles := State.RS(I).Cycles - 1;
               end if;

               if State.RS(I).Cycles = 0 then
                  case State.RS(I).Op is
                     when ADD => State.RS(I).Result := State.RS(I).Vj + State.RS(I).Vk;
                     when SUB => State.RS(I).Result := State.RS(I).Vj - State.RS(I).Vk;
                     when MUL => State.RS(I).Result := State.RS(I).Vj * State.RS(I).Vk;
                     when DIV =>
                        if State.RS(I).Vk = 0 then
                           raise Execution_Error with "Division by Zero";
                        end if;
                        State.RS(I).Result := State.RS(I).Vj / State.RS(I).Vk;
                     when others => null;
                  end case;
                  State.RS(I).Done := True;
               end if;
            end if;
         end if;
      end loop;

      -- 3. ISSUE
      if State.PC <= Insts'Last then
         declare
            Inst : Instruction := Insts (State.PC);
            Allocated_RS : RS_Name := None;
         begin
            if Inst.Op = NOP then
               State.PC := State.PC + 1;
            else
               -- Find Free RS
               for I in State.RS'Range loop
                  if not State.RS(I).Busy then
                     if (Inst.Op = ADD or Inst.Op = SUB) and (I = Add1 or I = Add2 or I = Add3) then
                        Allocated_RS := I;
                        exit;
                     elsif (Inst.Op = MUL or Inst.Op = DIV) and (I = Mult1 or I = Mult2) then
                        Allocated_RS := I;
                        exit;
                     end if;
                  end if;
               end loop;

               if Allocated_RS /= None then
                  State.RS(Allocated_RS).Busy := True;
                  State.RS(Allocated_RS).Op := Inst.Op;
                  State.RS(Allocated_RS).Done := False;
                  State.RS(Allocated_RS).Cycles := Get_Latency(Inst.Op);

                  -- Read Src1
                  if Inst.Src1 /= None_Reg then
                     if State.RAT(Inst.Src1) /= None then
                        State.RS(Allocated_RS).Qj := State.RAT(Inst.Src1);
                     else
                        State.RS(Allocated_RS).Vj := State.Regs(Inst.Src1);
                        State.RS(Allocated_RS).Qj := None;
                     end if;
                  end if;

                  -- Read Src2
                  if Inst.Src2 /= None_Reg then
                     if State.RAT(Inst.Src2) /= None then
                        State.RS(Allocated_RS).Qk := State.RAT(Inst.Src2);
                     else
                        State.RS(Allocated_RS).Vk := State.Regs(Inst.Src2);
                        State.RS(Allocated_RS).Qk := None;
                     end if;
                  end if;

                  -- Rename Target (RAT)
                  if Inst.Dest /= None_Reg then
                     State.RAT(Inst.Dest) := Allocated_RS;
                  end if;

                  State.PC := State.PC + 1;
               else
                  -- Structural Hazard: Cannot issue, wait for next cycle
                  null; 
               end if;
            end if;
         end;
      end if;

      -- Determine Halt Condition
      State.Is_Halted := (State.PC > Insts'Last);
      for I in State.RS'Range loop
         if State.RS(I).Busy then
            State.Is_Halted := False;
         end if;
      end loop;
   end Step_Cycle;

end Tomasulo_Algorithm;
