-- round_robin.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Containers.Doubly_Linked_Lists;

procedure Round_Robin is

   -- Basic Types
   type Process_ID is new Positive;

   -- Process Control Block containing metadata for all variants
   type Process_Info is record
      ID             : Process_ID;
      Arrival_Time   : Natural  := 0;
      Burst_Time     : Natural  := 0;
      Remaining_Time : Natural  := 0;
      
      -- For Weighted Round Robin
      Weight         : Positive := 1;
      
      -- For Deficit Round Robin (Packet Scheduling Simulation)
      Deficit        : Natural  := 0;
      Atomic_Chunk   : Positive := 1; 
   end record;

   -- Instantiate a standard Doubly Linked List to act as our Ready Queue
   package Process_Lists is new Ada.Containers.Doubly_Linked_Lists (Process_Info);
   subtype Process_Queue is Process_Lists.List;

   -----------------------------------------------------------
   -- Helper: Load Simulation Data
   -----------------------------------------------------------
   procedure Load_Mock_Processes (Queue : in out Process_Queue) is
   begin
      Queue.Clear;
      Queue.Append ((ID => 1, Arrival_Time => 0, Burst_Time => 10, Remaining_Time => 10, Weight => 1, Deficit => 0, Atomic_Chunk => 2));
      Queue.Append ((ID => 2, Arrival_Time => 0, Burst_Time => 5,  Remaining_Time => 5,  Weight => 2, Deficit => 0, Atomic_Chunk => 1));
      Queue.Append ((ID => 3, Arrival_Time => 0, Burst_Time => 8,  Remaining_Time => 8,  Weight => 1, Deficit => 0, Atomic_Chunk => 4));
   end Load_Mock_Processes;

   -----------------------------------------------------------
   -- Variant 1: Standard Round-Robin
   -----------------------------------------------------------
   procedure Execute_Standard_RR (Queue : in out Process_Queue; Time_Quantum : Positive) is
      Current_Time : Natural := 0;
      Proc         : Process_Info;
   begin
      Put_Line ("=== Starting Standard Round Robin ===");
      Put_Line ("Fixed Time Quantum: " & Positive'Image(Time_Quantum));

      while not Queue.Is_Empty loop
         Proc := Queue.First_Element;
         Queue.Delete_First;

         if Proc.Remaining_Time > Time_Quantum then
            Current_Time := Current_Time + Time_Quantum;
            Proc.Remaining_Time := Proc.Remaining_Time - Time_Quantum;
            Put_Line ("Time" & Natural'Image(Current_Time) & 
                      ": Process" & Process_ID'Image(Proc.ID) & 
                      " ran for" & Positive'Image(Time_Quantum) & 
                      ". Remainder:" & Natural'Image(Proc.Remaining_Time));
            
            -- Preempt and send to back of queue
            Queue.Append (Proc);
         else
            Current_Time := Current_Time + Proc.Remaining_Time;
            Put_Line ("Time" & Natural'Image(Current_Time) & 
                      ": Process" & Process_ID'Image(Proc.ID) & " FINISHED.");
            Proc.Remaining_Time := 0;
         end if;
      end loop;
      Put_Line ("=== Standard RR Complete ===" & ASCII.LF);
   end Execute_Standard_RR;

   -----------------------------------------------------------
   -- Variant 2: Weighted Round-Robin (WRR)
   -----------------------------------------------------------
   procedure Execute_Weighted_RR (Queue : in out Process_Queue; Base_Quantum : Positive) is
      Current_Time   : Natural := 0;
      Proc           : Process_Info;
      Actual_Quantum : Positive;
   begin
      Put_Line ("=== Starting Weighted Round Robin ===");
      Put_Line ("Base Time Quantum: " & Positive'Image(Base_Quantum));

      while not Queue.Is_Empty loop
         Proc := Queue.First_Element;
         Queue.Delete_First;

         -- Scale the quantum by the process weight
         Actual_Quantum := Base_Quantum * Proc.Weight;

         if Proc.Remaining_Time > Actual_Quantum then
            Current_Time := Current_Time + Actual_Quantum;
            Proc.Remaining_Time := Proc.Remaining_Time - Actual_Quantum;
            Put_Line ("Time" & Natural'Image(Current_Time) & 
                      ": Process" & Process_ID'Image(Proc.ID) & 
                      " [Weight:" & Positive'Image(Proc.Weight) & "]" &
                      " ran for" & Positive'Image(Actual_Quantum) & 
                      ". Remainder:" & Natural'Image(Proc.Remaining_Time));
            Queue.Append (Proc);
         else
            Current_Time := Current_Time + Proc.Remaining_Time;
            Put_Line ("Time" & Natural'Image(Current_Time) & 
                      ": Process" & Process_ID'Image(Proc.ID) & 
                      " [Weight:" & Positive'Image(Proc.Weight) & "] FINISHED.");
            Proc.Remaining_Time := 0;
         end if;
      end loop;
      Put_Line ("=== Weighted RR Complete ===" & ASCII.LF);
   end Execute_Weighted_RR;

   -----------------------------------------------------------
   -- Variant 3: Deficit Round-Robin (DRR)
   -----------------------------------------------------------
   procedure Execute_Deficit_RR (Queue : in out Process_Queue; Quantum : Positive) is
      Current_Time : Natural := 0;
      Proc         : Process_Info;
      Executed     : Natural;
   begin
      Put_Line ("=== Starting Deficit Round Robin ===");
      Put_Line ("Quantum Added Per Round: " & Positive'Image(Quantum));

      while not Queue.Is_Empty loop
         Proc := Queue.First_Element;
         Queue.Delete_First;

         -- Accumulate deficit (saving up transmission allowance)
         Proc.Deficit := Proc.Deficit + Quantum;

         if Proc.Remaining_Time <= Proc.Deficit then
            Current_Time := Current_Time + Proc.Remaining_Time;
            Proc.Deficit := Proc.Deficit - Proc.Remaining_Time;
            Put_Line ("Time" & Natural'Image(Current_Time) & 
                      ": Process" & Process_ID'Image(Proc.ID) & " FINISHED.");
         else
            -- Ensure execution happens in increments of the indivisible atomic chunk (packet sizes)
            if Proc.Atomic_Chunk > Proc.Deficit then
               Executed := 0;
            else
               Executed := (Proc.Deficit / Proc.Atomic_Chunk) * Proc.Atomic_Chunk;
            end if;

            if Executed > 0 then
               Current_Time := Current_Time + Executed;
               Proc.Remaining_Time := Proc.Remaining_Time - Executed;
               Proc.Deficit := Proc.Deficit - Executed;
               Put_Line ("Time" & Natural'Image(Current_Time) & 
                         ": Process" & Process_ID'Image(Proc.ID) & 
                         " ran for" & Natural'Image(Executed) & 
                         " units. Remainder:" & Natural'Image(Proc.Remaining_Time) & 
                         ", Deficit left:" & Natural'Image(Proc.Deficit));
            else
               Put_Line ("Time" & Natural'Image(Current_Time) & 
                         ": Process" & Process_ID'Image(Proc.ID) & 
                         " skipped. Deficit (" & Natural'Image(Proc.Deficit) & 
                         ") < Atomic Chunk (" & Positive'Image(Proc.Atomic_Chunk) & ").");
            end if;
            
            Queue.Append (Proc);
         end if;
      end loop;
      Put_Line ("=== Deficit RR Complete ===" & ASCII.LF);
   end Execute_Deficit_RR;

   -- Working Queue Instance
   Q : Process_Queue;

begin
   -- 1. Execute standard variant simulation
   Load_Mock_Processes (Q);
   Execute_Standard_RR (Q, Time_Quantum => 3);

   -- 2. Execute weighted variant simulation
   Load_Mock_Processes (Q);
   Execute_Weighted_RR (Q, Base_Quantum => 2);

   -- 3. Execute deficit variant simulation
   Load_Mock_Processes (Q);
   Execute_Deficit_RR (Q, Quantum => 3);

end Round_Robin;
