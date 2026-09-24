--  subgraph_isomorphism.ads
--  Package specification for Subgraph Isomorphism Problem algorithms
--
--  This package implements the Ullmann's backtracking algorithm (1976)
--  and VF2 algorithm (Cordella, 2004) for solving the subgraph isomorphism problem.
--
--  The subgraph isomorphism problem determines whether a graph H is isomorphic
--  to a subgraph of another graph G. This is an NP-complete problem.
--
--  Features:
--  - Ullmann's Algorithm: Classic backtracking approach
--  - VF2 Algorithm: Improved version with better pruning
--  - Support for decision (Boolean result) and enumeration (find all mappings)
--  - Strong typing with fixed-size arrays for performance
--
--  Author: Robert Boettcher
--  Date: July 29, 2026

package Subgraph_Isomorphism is

   -- Maximum number of vertices and mappings supported
   Max_Vertices : constant := 100;
   Max_Mappings : constant := 1000;

   -- Adjacency matrix for graph representation (100x100)
   type Adjacency_Matrix_Type is array (1 .. Max_Vertices, 1 .. Max_Vertices) of Boolean;

   -- Mapping from pattern graph vertices to target graph vertices
   type Vertex_Mapping_Type is array (1 .. Max_Vertices) of Integer;

   -- List of all possible mappings (for enumeration)
   type Mapping_List_Type is array (1 .. Max_Mappings) of Vertex_Mapping_Type;

   -- Graph data structure
   type Graph is record
      Num_Vertices : Integer := 0;  -- Number of vertices in the graph
      Adj_Matrix   : Adjacency_Matrix_Type;  -- Adjacency matrix representation
      Num_Edges    : Integer := 0;  -- Number of edges in the graph
   end record;

   -- Algorithm selection type
   type Algorithm_Type is (Ullmann, VF2);

   -- Exception declarations for error handling
   Graph_Too_Large : exception;  -- Raised when graph exceeds maximum size
   Invalid_Vertex  : exception;  -- Raised for invalid vertex operations
   Invalid_Edge    : exception;  -- Raised for invalid edge operations

   -- Initialize an empty graph
   procedure Initialize_Graph(G : out Graph);

   -- Add a vertex to the graph
   -- V: Vertex index to add (1-based)
   procedure Add_Vertex(G : in out Graph; V : Integer);

   -- Add an edge between two vertices
   -- From, To: Vertex indices to connect
   procedure Add_Edge(G : in out Graph; From, To : Integer);

   -- Check if H is isomorphic to a subgraph of G
   -- Returns: True if subgraph isomorphism exists
   function Is_Subgraph(
      G, H : Graph;
      Algorithm : Algorithm_Type := VF2) return Boolean;

   -- Find all mappings from H to G
   -- G, H: Input graphs
   -- Mappings: Output array of all valid mappings
   -- Algorithm: Which algorithm to use (Ullmann or VF2)
   -- Max_Mappings: Maximum number of mappings to find
   -- Found_Count: Number of mappings actually found
   procedure Find_All_Mappings(
      G, H : Graph;
      Mappings : out Mapping_List_Type;
      Algorithm : Algorithm_Type := VF2;
      Max_Mappings : Positive;
      Found_Count : out Natural);

   -- Check if two graphs are isomorphic (same size and subgraph isomorphism)
   function Are_Isomorphic(
      G, H : Graph;
      Algorithm : Algorithm_Type := VF2) return Boolean;

   -- Print graph information to standard output
   procedure Print_Graph(G : Graph);

end Subgraph_Isomorphism;
