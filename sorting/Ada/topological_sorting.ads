-- topological_sorting.ads
-- Specification for Topological Sorting algorithms.
-- Implements variants from Wikipedia: Kahn's Algorithm and DFS Algorithm.

with Ada.Containers.Vectors;

package Topological_Sorting is

   -- Strong typing for Graph elements
   type Node_ID is new Positive;
   type Node_Array is array (Positive range <>) of Node_ID;

   -- Adjacency list representation using vectors
   package Node_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Node_ID);

   type Adjacency_List is array (Positive range <>) of Node_Vectors.Vector;

   -- Directed Graph structure
   -- Using discriminants to allow dynamic graph sizing
   type Graph (Num_Nodes : Natural) is record
      Edges : Adjacency_List (1 .. Num_Nodes);
   end record;

   -- Custom Exceptions
   Invalid_Graph : exception;

   -- Helper subprograms
   -- Adds a directed edge from 'From' node to 'To' node.
   procedure Add_Edge (G : in out Graph; From, To : Node_ID);

   -- Validates if a given result array is a valid topological sort of G
   function Is_Valid_Sort (G : in Graph; Result : in Node_Array) return Boolean;

   -- Variant 1: Kahn's algorithm (Iterative / Indegree based)
   -- Non-preemptive style, relies on static snapshot of the graph.
   procedure Kahn_Sort 
     (G       : in Graph; 
      Result  : out Node_Array; 
      Success : out Boolean);

   -- Variant 2: Depth-First Search (DFS) based algorithm (Recursive)
   -- Explores paths recursively and pushes to array upon returning.
   procedure DFS_Sort 
     (G       : in Graph; 
      Result  : out Node_Array; 
      Success : out Boolean);

end Topological_Sorting;
