--  Garbage_Collection.ads
--  Specification for simulated memory management and garbage collection algorithms.
--  Variants implemented:
--  1. Mark-and-Sweep (Tracing)
--  2. Reference Counting
--  3. Generational Collection (Minor/Major cycles)

package Garbage_Collection is

   --  Custom types for strong typing
   Max_Nodes : constant := 100;
   Max_Refs  : constant := 5;

   type Node_ID is new Integer range 0 .. Max_Nodes;
   Null_Node : constant Node_ID := 0;

   --  Exceptions
   Out_Of_Memory_Error : exception;
   Invalid_Node_Error  : exception;
   Max_Edges_Error     : exception;

   --  Algorithm mode selector for edge operations
   type GC_Algorithm is (Tracing, Ref_Counting);

   --  System Initialization
   procedure Initialize;

   --  Memory Allocation
   function Allocate return Node_ID;

   --  Root Set Management (Simulating the stack/global references)
   procedure Add_Root (ID : Node_ID);
   procedure Remove_Root (ID : Node_ID);

   --  Graph Management (Simulating object references)
   --  If Algo = Ref_Counting, Add_Edge/Remove_Edge will update counts and free immediately if 0.
   procedure Add_Edge (From, To : Node_ID; Algo : GC_Algorithm := Tracing);
   procedure Remove_Edge (From, To : Node_ID; Algo : GC_Algorithm := Tracing);

   --  Garbage Collection Variants
   procedure Run_Mark_And_Sweep;
   procedure Run_Minor_Collection; -- Generational variant (Age 0 only)

   --  Helper/Inspection Functions
   function Is_Allocated (ID : Node_ID) return Boolean;
   function Get_Allocated_Count return Natural;
   function Get_Ref_Count (ID : Node_ID) return Natural;
   function Get_Age (ID : Node_ID) return Natural;

private

   type Edge_Array is array (1 .. Max_Refs) of Node_ID;

   type Node_Record is record
      Is_Active : Boolean := False;
      Marked    : Boolean := False;
      Age       : Natural := 0;      -- For generational collection
      Ref_Count : Natural := 0;      -- For reference counting
      Edges     : Edge_Array := (others => Null_Node);
   end record;

   type Heap_Array is array (Node_ID range 1 .. Max_Nodes) of Node_Record;
   
   type Root_Array is array (1 .. Max_Nodes) of Node_ID;

   Heap        : Heap_Array;
   Roots       : Root_Array := (others => Null_Node);
   Root_Count  : Natural := 0;

   --  Internal helpers
   procedure Free_Node (ID : Node_ID; Algo : GC_Algorithm);
   procedure Mark_Node (ID : Node_ID);

end Garbage_Collection;
