-- push_relabel.ads
-- Specification for the Push-Relabel Maximum Flow Algorithm.
-- Supports three variants: Generic, FIFO, and Highest-Label selection.
-- Note: "Preemptive/Non-preemptive" variants apply to CPU scheduling algorithms (e.g., SJN), 
-- whereas Push-Relabel variants are based on active node selection strategies. 

package Push_Relabel is

   -- Strong typing for algorithm-specific data
   type Node_Id is new Positive;
   type Capacity_Type is new Natural;
   type Flow_Type is new Natural;
   
   -- Graph represented as an adjacency matrix of capacities.
   -- Residual capacities will be calculated dynamically.
   type Adjacency_Matrix is array (Node_Id range <>, Node_Id range <>) of Capacity_Type;

   -- Exceptions for edge cases and invalid inputs
   Invalid_Node_Error : exception;
   Source_Sink_Error  : exception;
   Empty_Graph_Error  : exception;

   -- 1. Generic Push-Relabel
   -- Selects any active node arbitrarily. 
   -- Time Complexity: O(V^2 E)
   function Generic_Max_Flow (
      Graph  : Adjacency_Matrix;
      Source : Node_Id;
      Sink   : Node_Id
   ) return Flow_Type;

   -- 2. FIFO Push-Relabel
   -- Maintains a queue of active nodes for fair processing.
   -- Time Complexity: O(V^3)
   function FIFO_Max_Flow (
      Graph  : Adjacency_Matrix;
      Source : Node_Id;
      Sink   : Node_Id
   ) return Flow_Type;

   -- 3. Highest-Label Push-Relabel
   -- Always selects the active node with the highest distance label (height).
   -- Time Complexity: O(V^2 sqrt(E))
   function Highest_Label_Max_Flow (
      Graph  : Adjacency_Matrix;
      Source : Node_Id;
      Sink   : Node_Id
   ) return Flow_Type;

end Push_Relabel;
