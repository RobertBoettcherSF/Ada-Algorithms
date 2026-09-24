with Ada.Containers.Vectors;

package Uniform_Cost_Search is

   -- Strong typing for algorithm-specific data
   type Node_Id is new Natural;
   Invalid_Node : constant Node_Id := 0;

   type Cost_Type is new Natural;
   -- Use half of Last to prevent overflow during addition (Cost + Edge.Cost)
   Unreachable : constant Cost_Type := Cost_Type'Last / 2;

   -- Edge representation
   type Edge is record
      Target : Node_Id;
      Cost   : Cost_Type;
   end record;

   -- Packages for handling dynamic graph adjacency lists and paths
   package Edge_Vectors is new Ada.Containers.Vectors (Positive, Edge);
   package Path_Vectors is new Ada.Containers.Vectors (Positive, Node_Id);

   -- The main Graph type
   type Graph is tagged private;

   -- Modifiers and Inspectors
   procedure Add_Edge (G : in out Graph; From, To : Node_Id; Cost : Cost_Type);
   procedure Add_Node (G : in out Graph; Node : Node_Id);
   function Contains_Node (G : Graph; Node : Node_Id) return Boolean;

   -- Result Structure
   type Search_Result is record
      Found : Boolean := False;
      Cost  : Cost_Type := Unreachable;
      Path  : Path_Vectors.Vector;
   end record;

   -- Algorithm Variants
   -- Variant 1: Graph Search (Uses 'Explored' set, standard UCS)
   function UCS_Graph_Search (G : Graph; Start, Goal : Node_Id) return Search_Result;

   -- Variant 2: Tree Search (No 'Explored' set, prone to cycles, depth/expansion limited)
   function UCS_Tree_Search (G : Graph; Start, Goal : Node_Id; Max_Expansions : Natural := 10000) return Search_Result;

   -- Exceptions
   Graph_Error : exception;
   Search_Limit_Exceeded : exception;

private
   
   -- We map each node to its outgoing edges using a Vector mapping
   -- For simplicity, we use an array bounded by an assumed max nodes
   Max_Nodes_Limit : constant := 10_000;
   type Adjacency_Array is array (Node_Id range 1 .. Node_Id (Max_Nodes_Limit)) of Edge_Vectors.Vector;
   type Node_Presence_Array is array (Node_Id range 1 .. Node_Id (Max_Nodes_Limit)) of Boolean;

   type Graph is tagged record
      Edges    : Adjacency_Array;
      Presence : Node_Presence_Array := (others => False);
   end record;

end Uniform_Cost_Search;
