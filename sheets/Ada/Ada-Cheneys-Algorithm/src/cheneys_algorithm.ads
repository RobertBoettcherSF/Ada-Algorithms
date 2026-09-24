package Cheneys_Algorithm is

   -- Strong typing for memory references
   type Reference is new Natural;
   Null_Reference : constant Reference := 0;

   -- Configurable Heap bounds
   Max_Heap_Size : constant Reference := 1000;

   -- Exception raised when allocation exceeds available Semi-Space
   Out_Of_Memory : exception;

   -- The core data structure representing an object/node in memory.
   -- Includes a Forwarded flag and New_Addr for Cheney's algorithm tracking.
   type Node is record
      Forwarded : Boolean := False;
      New_Addr  : Reference := Null_Reference;
      Data      : Integer := 0;
      Ref_1     : Reference := Null_Reference;
      Ref_2     : Reference := Null_Reference;
   end record;

   type Heap_Array is array (Reference range 1 .. Max_Heap_Size) of Node;

   -- A Semi-Space tracks the raw memory array and its current Allocation/Free pointer
   type Semi_Space is record
      Memory : Heap_Array;
      Free   : Reference := 1;
   end record;

   type Space_ID is (Space_A, Space_B);
   type Memory_Spaces is array (Space_ID) of Semi_Space;

   -- The Garbage Collector State tracks the active (From) and inactive (To) spaces
   type GC_State is record
      Spaces  : Memory_Spaces;
      From_ID : Space_ID := Space_A;
      To_ID   : Space_ID := Space_B;
   end record;

   -- Array of root references that start the GC traversal
   type Root_Set is array (Positive range <>) of Reference;

   -- Core Operations
   procedure Initialize (State : out GC_State);
   
   -- Allocates a new node in the active Semi-Space
   function Allocate (State : in out GC_State; 
                      Data  : Integer; 
                      Ref_1 : Reference := Null_Reference; 
                      Ref_2 : Reference := Null_Reference) return Reference;
                      
   -- Performs Cheney's Stop-and-Copy Garbage Collection using BFS
   procedure Collect (State : in out GC_State; Roots : in out Root_Set);

   -- State observation helpers (primarily for validation & testing)
   function Get_Node (State : GC_State; Ref : Reference) return Node;
   function Get_Free_Pointer (State : GC_State) return Reference;
   function Get_From_Space_ID (State : GC_State) return Space_ID;

private
   -- Helper variant: Copies a single node during GC, handling cyclic forwarding
   function Copy_Node (State : in out GC_State; Ref : Reference) return Reference;
end Cheneys_Algorithm;
