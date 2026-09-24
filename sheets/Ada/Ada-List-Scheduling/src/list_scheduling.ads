with Ada.Containers.Vectors;

package List_Scheduling is

   type Job_ID is new Positive;
   type Machine_ID is new Positive;
   type Time_Type is new Natural;
   
   -- Defines the final scheduled block for a job on a machine
   type Job_Schedule is record
      Job        : Job_ID;
      Machine    : Machine_ID;
      Start_Time : Time_Type;
      End_Time   : Time_Type;
   end record;
   
   package Schedule_Vectors is new Ada.Containers.Vectors (Positive, Job_Schedule);
   subtype Schedule_List is Schedule_Vectors.Vector;

   type Job_Duration_Array is array (Job_ID range <>) of Time_Type;
   type Job_List is array (Positive range <>) of Job_ID;
   
   -- 1. Arbitrary Order List Scheduling (Graham's algorithm)
   -- For independent jobs on homogeneous machines
   function Basic_List_Scheduling
     (Jobs      : Job_List;
      Durations : Job_Duration_Array;
      M         : Machine_ID) return Schedule_List;

   -- 2. LPT (Longest Processing Time First)
   function LPT_Scheduling
     (Durations : Job_Duration_Array;
      M         : Machine_ID) return Schedule_List;

   -- Graph node definition to support dependencies in HLF and HEFT
   package Job_Vectors is new Ada.Containers.Vectors (Positive, Job_ID);
   
   type Dependency_Node is record
      Duration     : Time_Type;
      Predecessors : Job_Vectors.Vector;
      Successors   : Job_Vectors.Vector;
   end record;
   
   type DAG_Array is array (Job_ID range <>) of Dependency_Node;

   -- 3. HLF (Highest Level First) / LP (Longest Path) / CPM
   -- For homogeneous machines executing a Precedence DAG
   function HLF_Scheduling
     (DAG : DAG_Array;
      M   : Machine_ID) return Schedule_List;

   -- 4. Heterogeneous Earliest Finish Time (HEFT)
   -- Execution time depends on the specific job and machine combination
   type Duration_Matrix is array (Job_ID range <>, Machine_ID range <>) of Time_Type;
   
   function HEFT_Scheduling
     (DAG       : DAG_Array;
      Durations : Duration_Matrix;
      M         : Machine_ID) return Schedule_List;

end List_Scheduling;
