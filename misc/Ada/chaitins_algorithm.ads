package Chaitins_Algorithm
  with Pure
is
   --  Maximum number of nodes supported by the graph to avoid dynamic allocation.
   Maximum_Nodes : constant := 64;

   type Node_ID is range 1 .. Maximum_Nodes;
   type Node_Count is range 0 .. Maximum_Nodes;
   type Register_Count is range 1 .. Maximum_Nodes;

   --  Color assignment. A value of 0 indicates that a node was spilled.
   type Color_ID is range 0 .. Maximum_Nodes;
   Spilled_Color : constant Color_ID := 0;

   type Node_Set is array (Node_ID) of Boolean
     with Default_Component_Value => False;
   Empty_Node_Set : constant Node_Set := [others => False];

   type Allocation_Map is array (Node_ID) of Color_ID
     with Default_Component_Value => Spilled_Color;
   Empty_Allocation : constant Allocation_Map := [others => Spilled_Color];

   type Adjacency_Matrix is array (Node_ID, Node_ID) of Boolean
     with Default_Component_Value => False;

   type Degree_Array is array (Node_ID) of Node_Count
     with Default_Component_Value => 0;

   --  Represents an interference graph for register allocation.
   type Interference_Graph is record
      Active_Node_Count : Node_Count := 0;
      Nodes             : Node_Set := Empty_Node_Set;
      Edges             : Adjacency_Matrix := [others => [others => False]];
      Degrees           : Degree_Array := [others => 0];
   end record;

   Graph_Error : exception;

   --  Initializes a graph with a specific number of active nodes (1 .. Nodes).
   procedure Initialize_Graph (Graph : out Interference_Graph; Nodes : Node_Count)
     with Global => null,
          Post   => Graph.Active_Node_Count = Nodes;

   --  Adds a bidirectional interference edge between two active nodes.
   --  Raises Graph_Error if either U or V is not currently active.
   procedure Add_Edge (Graph : in out Interference_Graph; U, V : Node_ID)
     with Global => null,
          Pre    => U /= V,
          Post   => Graph.Edges (U, V) and Graph.Edges (V, U);

   --  Allocates registers using the basic Chaitin algorithm.
   --  Nodes that cannot be colored (degree >= K at simplification) are spilled
   --  immediately and will not receive a color.
   procedure Basic_Chaitin_Allocate (
      Graph      : in  Interference_Graph;
      K          : in  Register_Count;
      Allocation : out Allocation_Map;
      Spilled    : out Node_Set
   ) with Global => null;

   --  Allocates registers using the Chaitin-Briggs optimistic extension.
   --  Nodes with degree >= K are pushed onto the stack anyway and given a
   --  chance to be colored during the selection phase.
   procedure Chaitin_Briggs_Allocate (
      Graph      : in  Interference_Graph;
      K          : in  Register_Count;
      Allocation : out Allocation_Map;
      Spilled    : out Node_Set
   ) with Global => null;

end Chaitins_Algorithm;
