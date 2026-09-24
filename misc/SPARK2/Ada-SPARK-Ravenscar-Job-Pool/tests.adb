pragma Ada_2022;

with Ada.Text_IO;
with Bounded_Buffer;
with Channel;
with Channel.Sync;
with Demo_Jobs;
with Job_Pool;
with Job_Table;

procedure Tests is
   use Ada.Text_IO;
   Failed : Natural := 0;
   Passed : Natural := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      if Cond then
         Passed := Passed + 1;
         Put_Line ("PASS " & Name);
      else
         Failed := Failed + 1;
         Put_Line ("FAIL " & Name);
      end if;
   end Check;

   --  1) Sequential bounded buffer / channel Put-Get contracts
   procedure Test_Bounded_Buffer is
      B : Bounded_Buffer.Buffer;
      E : Bounded_Buffer.Element;
   begin
      Bounded_Buffer.Clear (B);
      Check (Bounded_Buffer.Is_Empty (B), "buffer empty after clear");
      for I in 1 .. Bounded_Buffer.Capacity loop
         Bounded_Buffer.Put (B, Bounded_Buffer.Element (I));
      end loop;
      Check (Bounded_Buffer.Is_Full (B), "buffer full after Capacity puts");
      Check (Bounded_Buffer.Length (B) = Bounded_Buffer.Capacity,
             "buffer length = Capacity");
      Bounded_Buffer.Get (B, E);
      Check (Integer (E) = 1, "buffer FIFO first element");
      Check (Bounded_Buffer.Length (B) = Bounded_Buffer.Capacity - 1,
             "buffer length after get");
   end Test_Bounded_Buffer;

   procedure Test_Channel_Sequential is
      B : Channel.Buffer;
      V : Integer;
   begin
      Channel.Clear (B);
      Channel.Put (B, 42);
      Channel.Get (B, V);
      Check (V = 42, "channel sequential round-trip");
      Check (Channel.Is_Empty (B), "channel empty after get");
   end Test_Channel_Sequential;

   procedure Test_Channel_PO is
      V : Integer;
   begin
      Channel.Sync.PO.Reset;
      Channel.Sync.PO.Enqueue (7);
      Channel.Sync.PO.Enqueue (8);
      Check (Channel.Sync.PO.Length = 2, "channel PO length 2");
      Channel.Sync.PO.Dequeue (V);
      Check (V = 7, "channel PO FIFO");
      Channel.Sync.PO.Dequeue (V);
      Check (V = 8, "channel PO second");
   end Test_Channel_PO;

   procedure Test_Job_Table is
      T  : Job_Table.Table;
      Id : Job_Table.Job_Id;
   begin
      Job_Table.Clear (T);
      Check (Job_Table.Free_Slots (T) = Job_Table.Max_Jobs, "job table full free");
      Job_Table.Allocate
        (T, (Kind => Job_Table.Increment_Counter, Arg => 1), Id);
      Check (Id in Job_Table.Valid_Job_Id, "job table allocate id");
      Check (Job_Table.Busy_Count (T) = 1, "job table busy 1");
      Job_Table.Complete (T, Id);
      Check (Job_Table.Is_Complete (T, Id), "job table complete flag");
      Check (Job_Table.Free_Slots (T) = Job_Table.Max_Jobs, "job table reclaimed");
      Job_Table.Acknowledge (T, Id);
      Check (not Job_Table.Is_Complete (T, Id), "job table ack clears");
   end Test_Job_Table;

   --  2) Spawn Increment_Counter jobs and Await
   procedure Test_Spawn_Increment is
      Id : Job_Pool.Valid_Job_Id;
   begin
      Demo_Jobs.Reset;
      for I in 1 .. 10 loop
         Job_Pool.Spawn
           ((Kind => Job_Pool.Increment_Counter, Arg => 1), Id);
         Job_Pool.Await (Id);
      end loop;
      Check (Demo_Jobs.Counter_Value = 10, "10 increments via Await");
   end Test_Spawn_Increment;

   --  3) Parallel Spawn + Sync
   procedure Test_Spawn_Sync is
      Id : Job_Pool.Valid_Job_Id;
   begin
      Demo_Jobs.Reset;
      for I in 1 .. 8 loop
         Job_Pool.Spawn
           ((Kind => Job_Pool.Increment_Counter, Arg => 3), Id);
      end loop;
      Job_Pool.Sync;
      Check (Demo_Jobs.Counter_Value = 24, "8*3 increments via Sync");
      Check (Job_Pool.Free_Slots = Job_Pool.Max_Jobs, "all slots free after Sync");
   end Test_Spawn_Sync;

   --  4) Ping_Channel job through the pool
   procedure Test_Ping_Jobs is
      Id : Job_Pool.Valid_Job_Id;
   begin
      Demo_Jobs.Reset;
      Job_Pool.Spawn ((Kind => Job_Pool.Ping_Channel, Arg => 99), Id);
      Job_Pool.Await (Id);
      Check (Demo_Jobs.Last_Ping = 99, "ping channel via worker");
   end Test_Ping_Jobs;

   --  5) Mixed workload
   procedure Test_Mixed is
      Id1, Id2, Id3 : Job_Pool.Valid_Job_Id;
   begin
      Demo_Jobs.Reset;
      Job_Pool.Spawn ((Kind => Job_Pool.Increment_Counter, Arg => 5), Id1);
      Job_Pool.Spawn ((Kind => Job_Pool.Ping_Channel, Arg => 11), Id2);
      Job_Pool.Spawn ((Kind => Job_Pool.Increment_Counter, Arg => 7), Id3);
      Job_Pool.Sync;
      Check (Demo_Jobs.Counter_Value = 12, "mixed counter");
      Check (Demo_Jobs.Last_Ping = 11, "mixed ping");
   end Test_Mixed;

   --  6) Shutdown workers cleanly
   procedure Test_Shutdown is
   begin
      Job_Pool.Shutdown;
      Check (Job_Pool.Is_Shutdown, "shutdown flag set");
   end Test_Shutdown;

begin
   Put_Line ("Ada-SPARK-Ravenscar-Job-Pool tests");
   Test_Bounded_Buffer;
   Test_Channel_Sequential;
   Test_Channel_PO;
   Test_Job_Table;
   Test_Spawn_Increment;
   Test_Spawn_Sync;
   Test_Ping_Jobs;
   Test_Mixed;
   Test_Shutdown;

   Put_Line ("----");
   Put_Line ("Passed:" & Passed'Image & " Failed:" & Failed'Image);
   if Failed > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
