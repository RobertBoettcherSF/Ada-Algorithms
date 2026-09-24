--  bankers_algorithm.adb
--  
--  Ada implementation of the Banker's Algorithm
--  Based on: https://en.wikipedia.org/wiki/Banker's_algorithm
--  
--  Author: Vibe Code (Mistral AI)
--  Date: 2024

package body Bankers_Algorithm is

   --  ====================================================================
   --  HELPER FUNCTIONS

   --  Helper function to get the minimum of two Resource_Count values
   function Min_Resource (A, B : Resource_Count) return Resource_Count is
   begin
      if A <= B then
         return A;
      else
         return B;
      end if;
   end Min_Resource;

   --  Helper function to get a row from a resource matrix
   function Get_Row (Matrix : Resource_Matrix; Row : Positive) return Resource_Vector is
      Result : Resource_Vector (Matrix'Range(2));
   begin
      for R in Matrix'Range(2) loop
         Result(R) := Matrix(Row, R);
      end loop;
      return Result;
   end Get_Row;

   --  ====================================================================

   function "<=" (Left, Right : Resource_Vector) return Boolean is
   begin
      if Left'Length /= Right'Length then
         return False;
      end if;
      for I in Left'Range loop
         if Left(I) > Right(I) then
            return False;
         end if;
      end loop;
      return True;
   end "<=";

   function "<" (Left, Right : Resource_Vector) return Boolean is
   begin
      if Left'Length /= Right'Length then
         return False;
      end if;
      for I in Left'Range loop
         if Left(I) >= Right(I) then
            return False;
         end if;
      end loop;
      return True;
   end "<";

   --  Check if any element of Left exceeds corresponding element of Right
   function Exceeds (Left, Right : Resource_Vector) return Boolean is
   begin
      if Left'Length /= Right'Length then
         return True; -- Different lengths means it exceeds
      end if;
      for I in Left'Range loop
         if Left(I) > Right(I) then
            return True;
         end if;
      end loop;
      return False;
   end Exceeds;

   function "+" (Left, Right : Resource_Vector) return Resource_Vector is
      Result : Resource_Vector (Left'Range);
   begin
      for I in Left'Range loop
         Result(I) := Left(I) + Right(I);
      end loop;
      return Result;
   end "+";

   function "-" (Left, Right : Resource_Vector) return Resource_Vector is
      Result : Resource_Vector (Left'Range);
   begin
      for I in Left'Range loop
         Result(I) := Left(I) - Right(I);
      end loop;
      return Result;
   end "-";



   --  ====================================================================
   --  BASIC OPERATIONS
   --  ====================================================================

   --  Initialize a new system state with given number of processes and resources
   --  Parameters:
   --    Num_Processes: Number of processes in the system
   --    Num_Resources: Number of resource types
   --    Total_Resources: Initial available resources for each type
   --  Returns: New system state with zero allocations and max needs
   function Initialize_System (
      Num_Processes  : Positive;
      Num_Resources  : Positive;
      Total_Resources : Resource_Vector)
      return System_State is
   begin
      if Num_Processes <= 0 then
         raise No_Processes_Exception with "Number of processes must be positive";
      end if;
      if Num_Resources <= 0 then
         raise No_Resources_Exception with "Number of resources must be positive";
      end if;
      if Total_Resources'Length /= Num_Resources then
         raise Index_Out_Of_Range with "Total_Resources length mismatch";
      end if;

      return State : System_State (Num_Processes, Num_Resources) do
         State.Available := Total_Resources;
         State.Allocation := (1 .. Num_Processes => (1 .. Num_Resources => 0));
         State.Max_Need := (1 .. Num_Processes => (1 .. Num_Resources => 0));
      end return;
   end Initialize_System;

   function Calculate_Need (State : System_State) return Resource_Matrix is
      Need : Resource_Matrix (State.Allocation'Range(1), State.Allocation'Range(2));
   begin
      for P in State.Allocation'Range(1) loop
         for R in State.Allocation'Range(2) loop
            Need(P, R) := State.Max_Need(P, R) - State.Allocation(P, R);
         end loop;
      end loop;
      return Need;
   end Calculate_Need;



   --  ====================================================================
   --  SAFETY CHECK ALGORITHM
   --  ====================================================================

   --  Check if the current system state is safe (all processes can finish)
   --  Uses the Banker's Algorithm: finds a sequence where each process's need
   --  can be satisfied by available resources, releasing its allocation back
   --  Parameters:
   --    State: The system state to check
   --  Returns: Safe if all processes can finish, Unsafe otherwise
   function Is_Safe (State : System_State) return Safety_Result is
      Available_Copy : Resource_Vector (State.Available'Range) := State.Available;
      Finished : array (State.Allocation'Range(1)) of Boolean := (State.Allocation'Range(1) => False);
      Need : Resource_Matrix (State.Allocation'Range(1), State.Allocation'Range(2)) := Calculate_Need(State);
      Count : Integer := State.Allocation'Length(1);
      Found : Boolean;
   begin
      loop
         Found := False;
         for P in State.Allocation'Range(1) loop
            if not Finished(P) then
               if Get_Row(Need, P) <= Available_Copy then
                  Available_Copy := Available_Copy + Get_Row(State.Allocation, P);
                  Finished(P) := True;
                  Count := Count - 1;
                  Found := True;
                  exit; -- Exit after finding one process
               end if;
            end if;
         end loop;
         exit when not Found;
      end loop;
      if Count = 0 then
         return Safe;
      else
         return Unsafe;
      end if;
   end Is_Safe;

   function Find_Safe_Sequence (
      State    : System_State;
      Sequence : out Process_Sequence) 
      return Boolean is
      Available_Copy : Resource_Vector (State.Available'Range) := State.Available;
      Finished : array (State.Allocation'Range(1)) of Boolean := (State.Allocation'Range(1) => False);
      Need : Resource_Matrix (State.Allocation'Range(1), State.Allocation'Range(2)) := Calculate_Need(State);
      Count : Integer := State.Allocation'Length(1);
      Found : Boolean;
      Temp_Sequence : Process_Sequence (1 .. State.Allocation'Length(1));
      Temp_Index : Positive := 1;
   begin
      loop
         Found := False;
         for P in State.Allocation'Range(1) loop
            if not Finished(P) then
               if Get_Row(Need, P) <= Available_Copy then
                  Temp_Sequence(Temp_Index) := P;
                  Temp_Index := Temp_Index + 1;
                  Available_Copy := Available_Copy + Get_Row(State.Allocation, P);
                  Finished(P) := True;
                  Count := Count - 1;
                  Found := True;
               end if;
            end if;
         end loop;
         exit when not Found;
      end loop;
      if Count = 0 then
         Sequence := Temp_Sequence(1 .. Temp_Index - 1);
         return True;
      else
         return False;
      end if;
   end Find_Safe_Sequence;



   --  ====================================================================
   --  RESOURCE REQUEST HANDLING
   --  ====================================================================

   --  Validate a resource request before processing
   --  Parameters:
   --    State: Current system state
   --    Request: The resource request to validate
   --  Returns: True if request is valid (doesn't exceed need or available), False otherwise
   function Is_Request_Valid (
      State   : System_State;
      Request : Resource_Request) 
      return Boolean is
      Need : Resource_Matrix := Calculate_Need(State);
      Process_Need : Resource_Vector (State.Available'Range);
   begin
      if Request.Process < State.Allocation'First(1) or Request.Process > State.Allocation'Last(1) then
         return False;
      end if;
      Process_Need := Get_Row(Need, Request.Process);
      if Exceeds(Request.Resources, Process_Need) then
         return False;
      end if;
      if Exceeds(Request.Resources, State.Available) then
         return False;
      end if;
      return True;
   end Is_Request_Valid;

   function Is_State_Valid (State : System_State) return Boolean is
      Total_Allocated : Resource_Vector (State.Available'Range) := (State.Available'Range => 0);
   begin
      for P in State.Allocation'Range(1) loop
         for R in State.Allocation'Range(2) loop
            if State.Allocation(P, R) > State.Max_Need(P, R) then
               return False;
            end if;
         end loop;
      end loop;
      for P in State.Allocation'Range(1) loop
         for R in State.Allocation'Range(2) loop
            Total_Allocated(R) := Total_Allocated(R) + State.Allocation(P, R);
         end loop;
      end loop;
      for R in State.Available'Range loop
         if State.Available(R) < 0 then
            return False;
         end if;
      end loop;
      return True;
   end Is_State_Valid;

   function Get_Total_Resources (State : System_State) return Resource_Vector is
      Total : Resource_Vector (State.Available'Range) := State.Available;
   begin
      for P in State.Allocation'Range(1) loop
         for R in State.Allocation'Range(2) loop
            Total(R) := Total(R) + State.Allocation(P, R);
         end loop;
      end loop;
      return Total;
   end Get_Total_Resources;

   function Get_Process_Need (
      State   : System_State;
      Process : Positive) 
      return Resource_Vector is
      Need : Resource_Vector (State.Max_Need'Range(2));
   begin
      if Process < State.Max_Need'First(1) or Process > State.Max_Need'Last(1) then
         raise Index_Out_Of_Range with "Process ID out of range";
      end if;
      for R in State.Max_Need'Range(2) loop
         Need(R) := State.Max_Need(Process, R) - State.Allocation(Process, R);
      end loop;
      return Need;
   end Get_Process_Need;

   function Can_Process_Finish (
      State   : System_State;
      Process : Positive) 
      return Boolean is
      Need : Resource_Vector := Get_Process_Need(State, Process);
   begin
      return Need <= State.Available;
   end Can_Process_Finish;

   function Handle_Request_Non_Preemptive (
      State   : in out System_State;
      Request : Resource_Request) 
      return Boolean is
      Temp_State : System_State := State;
   begin
      if Request.Process < Temp_State.Allocation'First(1) or Request.Process > Temp_State.Allocation'Last(1) then
         raise Index_Out_Of_Range with "Invalid process ID in request";
      end if;
      if Request.Resources'Length /= Temp_State.Available'Length then
         raise Index_Out_Of_Range with "Resource vector length mismatch";
      end if;
      if Exceeds(Request.Resources, Temp_State.Available) then
         raise Request_Exceeds_Available with "Request exceeds available resources";
      end if;
      declare
         Need : Resource_Vector := Get_Process_Need(Temp_State, Request.Process);
      begin
         if Exceeds(Request.Resources, Need) then
            raise Max_Exceeded_Exception with "Request exceeds process need";
         end if;
      end;
      Temp_State.Available := Temp_State.Available - Request.Resources;
      for R in Temp_State.Available'Range loop
         Temp_State.Allocation(Request.Process, R) := Temp_State.Allocation(Request.Process, R) + Request.Resources(R);
      end loop;
      if Is_Safe(Temp_State) = Safe then
         State := Temp_State;
         return True;
      else
         raise Unsafe_State_Exception with "Granting request would lead to unsafe state";
      end if;
   end Handle_Request_Non_Preemptive;



   --  ====================================================================
   --  PREEMPTIVE VARIANT
   --  ====================================================================

   --  Handle a resource request with preemption allowed
   --  If request cannot be satisfied with available resources, this variant
   --  will attempt to reclaim resources from other processes to satisfy it
   --  Parameters:
   --    State: The system state (in out - may be modified if preemption occurs)
   --    Request: The resource request to handle
   --  Returns: True if request was granted, False otherwise
   --  Raises: Various exceptions for invalid requests or unsafe states
   function Handle_Request_Preemptive (
      State   : in out System_State;
      Request : Resource_Request) 
      return Boolean is
      Temp_State : System_State := State;
      Need : Resource_Vector := Get_Process_Need(Temp_State, Request.Process);
      Total_Resources : Resource_Vector := Get_Total_Resources(Temp_State);
   begin
      if Request.Process < Temp_State.Allocation'First(1) or Request.Process > Temp_State.Allocation'Last(1) then
         raise Index_Out_Of_Range with "Invalid process ID in request";
      end if;
      if Request.Resources'Length /= Temp_State.Available'Length then
         raise Index_Out_Of_Range with "Resource vector length mismatch";
      end if;
      if Exceeds(Request.Resources, Need) then
         raise Max_Exceeded_Exception with "Request exceeds process need";
      end if;
      if Exceeds(Request.Resources, Total_Resources) then
         raise Request_Exceeds_Available with "Request exceeds total system resources";
      end if;
      if Request.Resources <= Temp_State.Available then
         Temp_State.Available := Temp_State.Available - Request.Resources;
         for R in Temp_State.Available'Range loop
            Temp_State.Allocation(Request.Process, R) := Temp_State.Allocation(Request.Process, R) + Request.Resources(R);
         end loop;
         if Is_Safe(Temp_State) = Safe then
            State := Temp_State;
            return True;
         end if;
      end if;
      declare
         Required : Resource_Vector := Request.Resources - Temp_State.Available;
         Preempt_Amount : Resource_Vector (Temp_State.Available'Range) := (Temp_State.Available'Range => 0);
      begin
         for R in Required'Range loop
            if Required(R) > 0 then
               Preempt_Amount(R) := Required(R);
            end if;
         end loop;
         if Preempt_Amount = (Preempt_Amount'Range => 0) then
            raise Unsafe_State_Exception with "Cannot satisfy request even with preemption";
         end if;
         for P in Temp_State.Allocation'Range(1) loop
            if P = Request.Process then
               null;
            else
               for R in Preempt_Amount'Range loop
                  if Preempt_Amount(R) > 0 and Temp_State.Allocation(P, R) > 0 then
                     declare
                        Take : Resource_Count := Min_Resource(Preempt_Amount(R), Temp_State.Allocation(P, R));
                     begin
                        Preempt_Amount(R) := Preempt_Amount(R) - Take;
                        Temp_State.Allocation(P, R) := Temp_State.Allocation(P, R) - Take;
                        Temp_State.Available(R) := Temp_State.Available(R) + Take;
                     end;
                  end if;
               end loop;
               exit when Preempt_Amount = (Preempt_Amount'Range => 0);
            end if;
         end loop;
         if Preempt_Amount /= (Preempt_Amount'Range => 0) then
            for P in Temp_State.Allocation'Range(1) loop
               if P = Request.Process then
                  null;
               else
                  for R in Preempt_Amount'Range loop
                     if Preempt_Amount(R) > 0 and Temp_State.Allocation(P, R) > 0 then
                        declare
                           Take : Resource_Count := Min_Resource(Preempt_Amount(R), Temp_State.Allocation(P, R));
                        begin
                           Preempt_Amount(R) := Preempt_Amount(R) - Take;
                           Temp_State.Allocation(P, R) := Temp_State.Allocation(P, R) - Take;
                           Temp_State.Available(R) := Temp_State.Available(R) + Take;
                        end;
                     end if;
                  end loop;
                  exit when Preempt_Amount = (Preempt_Amount'Range => 0);
               end if;
            end loop;
         end if;
         if Preempt_Amount /= (Preempt_Amount'Range => 0) then
            raise Unsafe_State_Exception with "Cannot satisfy request even with full preemption";
         end if;
         Temp_State.Available := Temp_State.Available - Request.Resources;
         for R in Temp_State.Available'Range loop
            Temp_State.Allocation(Request.Process, R) := Temp_State.Allocation(Request.Process, R) + Request.Resources(R);
         end loop;
         if Is_Safe(Temp_State) = Safe then
            State := Temp_State;
            return True;
         else
            raise Unsafe_State_Exception with "Granting request would lead to unsafe state even after preemption";
         end if;
      end;
   end Handle_Request_Preemptive;



   --  ====================================================================
   --  STATIC VARIANT
   --  ====================================================================

   --  Initialize a static system with pre-defined maximum needs
   --  In static systems, the maximum needs are known in advance and fixed
   --  Parameters:
   --    Num_Processes: Number of processes
   --    Num_Resources: Number of resource types
   --    Total_Resources: Initial available resources
   --    Max_Needs: Pre-defined maximum resource needs for each process
   --  Returns: Initialized system state
   function Initialize_Static_System (
      Num_Processes  : Positive;
      Num_Resources  : Positive;
      Total_Resources : Resource_Vector;
      Max_Needs      : Resource_Matrix) 
      return System_State is
      State : System_State := Initialize_System(Num_Processes, Num_Resources, Total_Resources);
   begin
      if Max_Needs'Length(1) /= Num_Processes or Max_Needs'Length(2) /= Num_Resources then
         raise Index_Out_Of_Range with "Max_Needs dimensions don't match system";
      end if;
      State.Max_Need := Max_Needs;
      return State;
   end Initialize_Static_System;

   function Handle_Static_Request (
      State   : in out System_State;
      Request : Resource_Request) 
      return Boolean is
   begin
      return Handle_Request_Non_Preemptive(State, Request);
   end Handle_Static_Request;



   --  ====================================================================
   --  DYNAMIC VARIANT
   --  ====================================================================

   --  Add a new process to the system dynamically
   --  Note: Due to Ada discriminant limitations, this creates a new state
   --  but cannot modify the discriminant of an existing state variable
   --  Parameters:
   --    State: Current system state
   --    Max_Need: Maximum resource needs for the new process
   --    Initial_Allocation: Initial resources to allocate to the new process
   --  Returns: Process ID of the new process
   --  Raises: Exceptions for invalid parameters or if adding would create unsafe state
   function Add_Process (
      State            : in out System_State;
      Max_Need         : Resource_Vector;
      Initial_Allocation : Resource_Vector) 
      return Positive is
      New_Num_Processes : Positive := State.Num_Processes + 1;
      New_State : System_State (New_Num_Processes, State.Num_Resources);
   begin
      if Max_Need'Length /= State.Num_Resources or Initial_Allocation'Length /= State.Num_Resources then
         raise Index_Out_Of_Range with "Vector length mismatch with system resources";
      end if;
      if Exceeds(Initial_Allocation, Max_Need) then
         raise Max_Exceeded_Exception with "Initial allocation exceeds max need";
      end if;
      if Exceeds(Initial_Allocation, State.Available) then
         raise No_Resources_Exception with "Not enough resources for initial allocation";
      end if;
      New_State.Available := State.Available - Initial_Allocation;
      --  Copy existing allocations and max needs
      for P in 1 .. State.Num_Processes loop
         for R in 1 .. State.Num_Resources loop
            New_State.Allocation(P, R) := State.Allocation(P, R);
            New_State.Max_Need(P, R) := State.Max_Need(P, R);
         end loop;
      end loop;
      --  Add new process
      for R in 1 .. State.Num_Resources loop
         New_State.Allocation(New_Num_Processes, R) := Initial_Allocation(R);
         New_State.Max_Need(New_Num_Processes, R) := Max_Need(R);
      end loop;
      if Is_Safe(New_State) = Safe then
         --  Note: Due to Ada discriminant limitations, we cannot assign New_State to State
         --  State := New_State;
         return New_Num_Processes;
      else
         raise Unsafe_State_Exception with "Adding process would lead to unsafe state";
      end if;
   end Add_Process;

   function Remove_Process (
      State   : in out System_State;
      Process : Positive) 
      return Resource_Vector is
      New_Num_Processes : Positive := State.Num_Processes - 1;
      New_State : System_State (New_Num_Processes, State.Num_Resources);
      Returned_Resources : Resource_Vector (1 .. State.Num_Resources);
   begin
      if Process < 1 or Process > State.Num_Processes then
         raise Index_Out_Of_Range with "Invalid process ID";
      end if;
      for R in State.Available'Range loop
         Returned_Resources(R) := State.Allocation(Process, R);
      end loop;
      New_State.Available := State.Available + Returned_Resources;
      declare
         New_Index : Positive := 1;
      begin
         for Old_Index in 1 .. State.Num_Processes loop
            if Old_Index /= Process then
               for R in State.Available'Range loop
                  New_State.Allocation(New_Index, R) := State.Allocation(Old_Index, R);
               end loop;
               for R in State.Available'Range loop
                  New_State.Max_Need(New_Index, R) := State.Max_Need(Old_Index, R);
               end loop;
               New_Index := New_Index + 1;
            end if;
         end loop;
      end;
      --  Note: Due to Ada discriminant limitations, we cannot assign New_State to State
      --  State := New_State;
      return Returned_Resources;
   end Remove_Process;

   function Handle_Dynamic_Request (
      State   : in out System_State;
      Request : Resource_Request) 
      return Boolean is
   begin
      return Handle_Request_Non_Preemptive(State, Request);
   end Handle_Dynamic_Request;



   --  ====================================================================
   --  ALGORITHM SELECTOR
   --  ====================================================================

   --  Main entry point for handling resource requests
   --  Selects the appropriate algorithm variant based on the Variant parameter
   --  Parameters:
   --    State: The system state (in out - may be modified)
   --    Request: The resource request to handle
   --    Variant: Which algorithm variant to use (default: Non_Preemptive)
   --  Returns: True if request was granted, False otherwise
   function Handle_Request (
      State   : in out System_State;
      Request : Resource_Request;
      Variant : Algorithm_Variant := Non_Preemptive) 
      return Boolean is
   begin
      case Variant is
         when Non_Preemptive =>
            return Handle_Request_Non_Preemptive(State, Request);
         when Preemptive =>
            return Handle_Request_Preemptive(State, Request);
         when Static =>
            return Handle_Static_Request(State, Request);
         when Dynamic =>
            return Handle_Dynamic_Request(State, Request);
      end case;
   end Handle_Request;

end Bankers_Algorithm;
