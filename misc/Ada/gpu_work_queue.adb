pragma SPARK_Mode (On);

package body GPU_Work_Queue is

   function Create return Queue is
   begin
      return (Slots => [others => Compute],
              Head  => 0,
              Tail  => 0,
              Count => 0);
   end Create;

   procedure Reset (Q : out Queue) is
   begin
      Q := Create;
   end Reset;

   procedure Submit
     (Q    : in out Queue;
      Kind : Job_Kind;
      Ok   : out Boolean)
   is
   begin
      if Q.Count = Capacity then
         Ok := False;
         return;
      end if;
      Q.Slots (Q.Tail) := Kind;
      Q.Tail := (Q.Tail + 1) rem Capacity;
      Q.Count := Q.Count + 1;
      Ok := True;
   end Submit;

   procedure Try_Pop
     (Q    : in out Queue;
      Kind : out Job_Kind;
      Ok   : out Boolean)
   is
   begin
      if Q.Count = 0 then
         Kind := Compute;
         Ok := False;
         return;
      end if;
      Kind := Q.Slots (Q.Head);
      Q.Head := (Q.Head + 1) rem Capacity;
      Q.Count := Q.Count - 1;
      Ok := True;
   end Try_Pop;

   procedure Complete
     (Q  : in out Queue;
      Ok : out Boolean)
   is
      Discard : Job_Kind;
   begin
      Try_Pop (Q, Discard, Ok);
   end Complete;

end GPU_Work_Queue;
