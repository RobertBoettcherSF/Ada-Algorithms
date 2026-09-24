pragma Ada_2022;

with Demo_Jobs;

package body Job_Pool
  with SPARK_Mode => Off
is
   --  Body SPARK Off: protected queue + Ada tasking carriers.
   --  Spec stays SPARK On; Ravenscar pattern preserved in the design.

   type Job_State is (Unused, Queued, Running);

   type Job_Slot is record
      State     : Job_State := Unused;
      Request   : Job_Request;
      Completed : Boolean := False;
   end record;

   type Job_Table_Array is array (Valid_Job_Id) of Job_Slot;

   subtype Q_Index is Natural range 0 .. Max_Jobs - 1;
   type Q_Data is array (Q_Index) of Job_Id;

   ----------------------------------------------------------------------
   --  Ready queue: Offer / Take (Take blocks; shutdown yields No_Job)
   ----------------------------------------------------------------------

   protected Ready_Queue is
      entry Take (Id : out Job_Id);
      procedure Offer (Id : Valid_Job_Id);
      procedure Request_Shutdown;
      function Pending return Natural;
      function Shutting_Down return Boolean;
   private
      Data  : Q_Data := [others => 0];
      Head  : Q_Index := 0;
      Tail  : Q_Index := 0;
      Count : Natural range 0 .. Max_Jobs := 0;
      Stop  : Boolean := False;
   end Ready_Queue;

   protected body Ready_Queue is
      entry Take (Id : out Job_Id) when Count > 0 or else Stop is
      begin
         if Count = 0 then
            Id := 0;
         else
            Id := Data (Head);
            Head := (Head + 1) mod Max_Jobs;
            Count := Count - 1;
         end if;
      end Take;

      procedure Offer (Id : Valid_Job_Id) is
      begin
         pragma Assert (Count < Max_Jobs);
         Data (Tail) := Id;
         Tail := (Tail + 1) mod Max_Jobs;
         Count := Count + 1;
      end Offer;

      procedure Request_Shutdown is
      begin
         Stop := True;
      end Request_Shutdown;

      function Pending return Natural is (Count);

      function Shutting_Down return Boolean is (Stop);
   end Ready_Queue;

   ----------------------------------------------------------------------
   --  Job table + Future barriers (Wait_Done / Wait_Idle)
   ----------------------------------------------------------------------

   protected Table is
      procedure Allocate (Request : Job_Request; Id : out Job_Id);
      procedure Mark_Running (Id : Valid_Job_Id);
      procedure Mark_Done (Id : Valid_Job_Id);
      entry Wait_Done (Valid_Job_Id);
      entry Wait_Idle;
      function Slots_Free return Natural;
      function Get_Request (Id : Valid_Job_Id) return Job_Request;
   private
      Jobs : Job_Table_Array :=
        [others =>
           (State => Unused, Request => (Kind => Nop, Arg => 0), Completed => False)];
      Free : Natural range 0 .. Max_Jobs := Max_Jobs;
      Busy : Natural range 0 .. Max_Jobs := 0;
   end Table;

   protected body Table is
      procedure Allocate (Request : Job_Request; Id : out Job_Id) is
      begin
         Id := 0;
         if Free = 0 then
            return;
         end if;
         for J in Valid_Job_Id loop
            if Jobs (J).State = Unused then
               Jobs (J) :=
                 (State => Queued,
                  Request => Request,
                  Completed => False);
               Free := Free - 1;
               Busy := Busy + 1;
               Id := J;
               return;
            end if;
         end loop;
      end Allocate;

      procedure Mark_Running (Id : Valid_Job_Id) is
      begin
         Jobs (Id).State := Running;
      end Mark_Running;

      procedure Mark_Done (Id : Valid_Job_Id) is
      begin
         --  Reclaim slot immediately; Completed latches for Await.
         Jobs (Id).State := Unused;
         Jobs (Id).Completed := True;
         if Free < Max_Jobs then
            Free := Free + 1;
         end if;
         if Busy > 0 then
            Busy := Busy - 1;
         end if;
      end Mark_Done;

      entry Wait_Done (for J in Valid_Job_Id)
        when Jobs (J).Completed
      is
      begin
         Jobs (J).Completed := False;
      end Wait_Done;

      entry Wait_Idle when Busy = 0 is
      begin
         null;
      end Wait_Idle;

      function Slots_Free return Natural is (Free);

      function Get_Request (Id : Valid_Job_Id) return Job_Request is
        (Jobs (Id).Request);
   end Table;

   ----------------------------------------------------------------------
   --  Carrier workers (fixed set, library elaboration)
   ----------------------------------------------------------------------

   task type Worker;

   procedure Execute_One (Stop : out Boolean) is
      Id  : Job_Id;
      Req : Job_Request;
   begin
      Ready_Queue.Take (Id);
      if Id = 0 then
         Stop := True;
         return;
      end if;
      Stop := False;
      Table.Mark_Running (Id);
      Req := Table.Get_Request (Id);
      case Req.Kind is
         when Nop =>
            null;
         when Increment_Counter =>
            Demo_Jobs.Increment_Counter (Req.Arg);
         when Ping_Channel =>
            Demo_Jobs.Ping_Channel (Req.Arg);
      end case;
      Table.Mark_Done (Id);
   end Execute_One;

   task body Worker is
      Stop : Boolean := False;
   begin
      while not Stop loop
         Execute_One (Stop);
      end loop;
   end Worker;

   Workers : array (1 .. Worker_Count) of Worker;
   --  Created at library elaboration — fixed task set (Ravenscar-shaped).

   ----------------------------------------------------------------------
   --  Public API
   ----------------------------------------------------------------------

   function Free_Slots return Natural is
   begin
      return Table.Slots_Free;
   end Free_Slots;

   procedure Spawn (Request : Job_Request; Id : out Valid_Job_Id) is
      Raw : Job_Id;
   begin
      pragma Assert (not Ready_Queue.Shutting_Down);
      Table.Allocate (Request, Raw);
      pragma Assert (Raw in Valid_Job_Id);
      Id := Valid_Job_Id (Raw);
      Ready_Queue.Offer (Id);
   end Spawn;

   procedure Await (Id : Valid_Job_Id) is
   begin
      Table.Wait_Done (Id);  --  entry family index
   end Await;

   procedure Sync is
   begin
      Table.Wait_Idle;
   end Sync;

   procedure Shutdown is
   begin
      Table.Wait_Idle;
      Ready_Queue.Request_Shutdown;
   end Shutdown;

   function Is_Shutdown return Boolean is
   begin
      return Ready_Queue.Shutting_Down;
   end Is_Shutdown;

end Job_Pool;
