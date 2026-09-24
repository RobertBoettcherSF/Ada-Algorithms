pragma Ada_2022;
pragma Unevaluated_Use_Of_Old (Allow);

--  Bounded job table (sequential model of the pool's protected Table).
--  Free-slot stack keeps Allocate/Complete Level-2 provable.
package Job_Table
  with SPARK_Mode => On
is
   Max_Jobs : constant := 16;

   type Job_Id is range 0 .. Max_Jobs;
   subtype Valid_Job_Id is Job_Id range 1 .. Job_Id'Last;

   type Job_Kind is (Nop, Increment_Counter, Ping_Channel);

   type Job_Request is record
      Kind : Job_Kind := Nop;
      Arg  : Integer  := 0;
   end record;

   type Table is private;

   function Free_Slots (T : Table) return Natural
     with Global => null,
          Post   => Free_Slots'Result <= Max_Jobs;

   function Busy_Count (T : Table) return Natural
     with Global => null,
          Post   => Busy_Count'Result <= Max_Jobs
            and then Free_Slots (T) + Busy_Count'Result = Max_Jobs;

   function Is_Live (T : Table; Id : Valid_Job_Id) return Boolean
     with Global => null;

   function Is_Complete (T : Table; Id : Valid_Job_Id) return Boolean
     with Global => null;

   procedure Clear (T : out Table)
     with Global => null,
          Post   => Free_Slots (T) = Max_Jobs and then Busy_Count (T) = 0;

   procedure Allocate
     (T       : in out Table;
      Request : Job_Request;
      Id      : out Job_Id)
     with Global => null,
          Pre    => Request.Kind /= Nop and then Free_Slots (T) > 0,
          Post   => Id in Valid_Job_Id
            and then Free_Slots (T) = Free_Slots (T)'Old - 1
            and then Busy_Count (T) = Busy_Count (T)'Old + 1
            and then Is_Live (T, Id);

   procedure Complete (T : in out Table; Id : Valid_Job_Id)
     with Global => null,
          Pre    => Is_Live (T, Id)
            and then Busy_Count (T) > 0
            and then Free_Slots (T) < Max_Jobs,
          Post   => Free_Slots (T) = Free_Slots (T)'Old + 1
            and then Busy_Count (T) = Busy_Count (T)'Old - 1
            and then not Is_Live (T, Id)
            and then Is_Complete (T, Id);

   procedure Acknowledge (T : in out Table; Id : Valid_Job_Id)
     with Global => null,
          Pre    => Is_Complete (T, Id),
          Post   => not Is_Complete (T, Id);

private
   subtype Stack_Index is Natural range 0 .. Max_Jobs;
   type Id_Stack is array (1 .. Max_Jobs) of Valid_Job_Id;
   type Live_Flags is array (Valid_Job_Id) of Boolean;
   type Done_Flags is array (Valid_Job_Id) of Boolean;
   type Request_Array is array (Valid_Job_Id) of Job_Request;

   type Table is record
      Stack      : Id_Stack := [for I in 1 .. Max_Jobs => Valid_Job_Id (I)];
      Top        : Stack_Index := Max_Jobs;  --  number of free ids on stack
      Live       : Live_Flags := [others => False];
      Completed  : Done_Flags := [others => False];
      Requests   : Request_Array := [others => (Kind => Nop, Arg => 0)];
   end record
     with Type_Invariant => Top <= Max_Jobs;

   function Free_Slots (T : Table) return Natural is (T.Top);
   function Busy_Count (T : Table) return Natural is (Max_Jobs - T.Top);
   function Is_Live (T : Table; Id : Valid_Job_Id) return Boolean is
     (T.Live (Id));
   function Is_Complete (T : Table; Id : Valid_Job_Id) return Boolean is
     (T.Completed (Id));
end Job_Table;
