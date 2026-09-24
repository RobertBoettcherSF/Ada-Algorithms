--  bankers_algorithm.ads
--  
--  Ada implementation of the Banker's Algorithm for deadlock avoidance
--  Based on: https://en.wikipedia.org/wiki/Banker's_algorithm
--  
--  This package provides a complete implementation of the Banker's Algorithm
--  including all variants mentioned in the Wikipedia article.
--  
--  Author: Vibe Code (Mistral AI)
--  Date: 2024

package Bankers_Algorithm is

   --  ====================================================================
   --  EXCEPTIONS
   --  ====================================================================

   Request_Exceeds_Available : exception;
   Unsafe_State_Exception : exception;
   Max_Exceeded_Exception : exception;
   Index_Out_Of_Range : exception;
   No_Resources_Exception : exception;
   No_Processes_Exception : exception;

   --  ====================================================================
   --  TYPES
   --  ====================================================================

   --  Type for resource counts (allows negative for need calculations)
   type Resource_Count is range Integer'First .. Integer'Last;

   --  Vector type for available resources (using Positive for 1-based indexing)
   type Resource_Vector is array (Positive range <>) of Resource_Count;

   --  Matrix type for allocation and maximum needs
   type Resource_Matrix is array (Positive range <>, Positive range <>) of Resource_Count;

   --  Type to represent the system state
   type System_State (Num_Processes : Positive; Num_Resources : Positive) is
      record
         Available   : Resource_Vector (1 .. Num_Resources);
         Allocation  : Resource_Matrix (1 .. Num_Processes, 1 .. Num_Resources);
         Max_Need    : Resource_Matrix (1 .. Num_Processes, 1 .. Num_Resources);
      end record;

   --  Type to represent a resource request
   type Resource_Request (Num_Resources : Positive) is
      record
         Process    : Positive;
         Resources  : Resource_Vector (1 .. Num_Resources);
      end record;

   --  Type to represent the result of a safety check
   type Safety_Result is (Safe, Unsafe);

   --  Type for algorithm variant selection
   type Algorithm_Variant is (Non_Preemptive, Preemptive, Static, Dynamic);

   --  Type for process sequence
   type Process_Sequence is array (Positive range <>) of Positive;

   --  ====================================================================
   --  BASIC OPERATIONS
   --  ====================================================================

   function Initialize_System (
      Num_Processes  : Positive;
      Num_Resources  : Positive;
      Total_Resources : Resource_Vector)
      return System_State;

   function Calculate_Need (State : System_State) return Resource_Matrix;

   --  ====================================================================
   --  SAFETY CHECK ALGORITHM
   --  ====================================================================

   function Is_Safe (State : System_State) return Safety_Result;

   function Find_Safe_Sequence (
      State    : System_State;
      Sequence : out Process_Sequence) 
      return Boolean;

   --  ====================================================================
   --  RESOURCE REQUEST HANDLING
   --  ====================================================================

   function Handle_Request_Non_Preemptive (
      State   : in out System_State;
      Request : Resource_Request) 
      return Boolean;

   function Handle_Request_Preemptive (
      State   : in out System_State;
      Request : Resource_Request) 
      return Boolean;

   --  ====================================================================
   --  STATIC VARIANT
   --  ====================================================================

   function Initialize_Static_System (
      Num_Processes  : Positive;
      Num_Resources  : Positive;
      Total_Resources : Resource_Vector;
      Max_Needs      : Resource_Matrix) 
      return System_State;

   function Handle_Static_Request (
      State   : in out System_State;
      Request : Resource_Request) 
      return Boolean;

   --  ====================================================================
   --  DYNAMIC VARIANT
   --  ====================================================================

   function Add_Process (
      State            : in out System_State;
      Max_Need         : Resource_Vector;
      Initial_Allocation : Resource_Vector) 
      return Positive;

   function Remove_Process (
      State   : in out System_State;
      Process : Positive) 
      return Resource_Vector;

   function Handle_Dynamic_Request (
      State   : in out System_State;
      Request : Resource_Request) 
      return Boolean;

   --  ====================================================================
   --  UTILITY FUNCTIONS
   --  ====================================================================

   function Is_Request_Valid (
      State   : System_State;
      Request : Resource_Request) 
      return Boolean;

   function Is_State_Valid (State : System_State) return Boolean;

   function Get_Total_Resources (State : System_State) return Resource_Vector;

   function Get_Process_Need (
      State   : System_State;
      Process : Positive) 
      return Resource_Vector;

   function Can_Process_Finish (
      State   : System_State;
      Process : Positive) 
      return Boolean;

   --  ====================================================================
   --  ALGORITHM SELECTOR
   --  ====================================================================

   function Handle_Request (
      State   : in out System_State;
      Request : Resource_Request;
      Variant : Algorithm_Variant := Non_Preemptive) 
      return Boolean;

end Bankers_Algorithm;
