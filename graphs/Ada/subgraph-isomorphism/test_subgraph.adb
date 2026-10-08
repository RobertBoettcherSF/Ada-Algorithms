--  test_subgraph.adb
--  Test program for Subgraph Isomorphism package
--
--  This program demonstrates the usage of the subgraph isomorphism algorithms
--  with various test cases including:
--  - Triangle in Square (should find isomorphism)
--  - Path graphs (should find subgraph)
--  - Empty graphs (edge cases)
--  - Enumeration of all mappings
--
--  Author: Robert Boettcher
--  Date: July 29, 2026

with Subgraph_Isomorphism;
with Ada.Text_IO;

procedure Test_Subgraph is
   use Subgraph_Isomorphism;
   use Ada.Text_IO;

   -- Test graphs
   G, H : Graph;

   -- Result variables
   Result : Boolean;
   Mappings : Mapping_List_Type;
   Found_Count : Natural;

begin
   Put_Line("Subgraph Isomorphism Test Program");
   Put_Line("==================================");

   -- Test 1: Triangle in Square
   -- A triangle (3 vertices, 3 edges) should be a subgraph of a square (4 vertices, 4 edges)
   New_Line;
   Put_Line("Test 1: Triangle in Square");

   -- Build square graph G (4 vertices in a cycle)
   Initialize_Graph(G);
   Add_Vertex(G, 1);
   Add_Vertex(G, 2);
   Add_Vertex(G, 3);
   Add_Vertex(G, 4);
   Add_Edge(G, 1, 2);
   Add_Edge(G, 2, 3);
   Add_Edge(G, 3, 4);
   Add_Edge(G, 4, 1);

   -- Build triangle graph H (3 vertices in a cycle)
   Initialize_Graph(H);
   Add_Vertex(H, 1);
   Add_Vertex(H, 2);
   Add_Vertex(H, 3);
   Add_Edge(H, 1, 2);
   Add_Edge(H, 2, 3);
   Add_Edge(H, 3, 1);

   -- Check if triangle is subgraph of square
   Result := Is_Subgraph(G, H, VF2);
   Put_Line("Triangle in Square: " & Boolean'Image(Result));

   -- Test 2: Path Graph
   -- A path of 2 edges should be a subgraph of a path of 3 edges
   New_Line;
   Put_Line("Test 2: Path Graph");

   -- Build path graph G (3 vertices, 2 edges: 1-2-3)
   Initialize_Graph(G);
   Add_Vertex(G, 1);
   Add_Vertex(G, 2);
   Add_Vertex(G, 3);
   Add_Edge(G, 1, 2);
   Add_Edge(G, 2, 3);

   -- Build path graph H (2 vertices, 1 edge: 1-2)
   Initialize_Graph(H);
   Add_Vertex(H, 1);
   Add_Vertex(H, 2);
   Add_Edge(H, 1, 2);

   Result := Is_Subgraph(G, H, VF2);
   Put_Line("Path 2 in Path 3: " & Boolean'Image(Result));

   -- Test 3: Empty Graphs
   -- Edge case: empty graph is a subgraph of any graph
   New_Line;
   Put_Line("Test 3: Empty Graphs");

   Initialize_Graph(G);
   Initialize_Graph(H);
   Result := Is_Subgraph(G, H, VF2);
   Put_Line("Empty H in empty G: " & Boolean'Image(Result));

   -- Test 4: Find All Mappings
   -- Enumerate all possible mappings from a 2-edge path to a 3-vertex path
   New_Line;
   Put_Line("Test 4: Find All Mappings");

   -- Build path graph G (3 vertices, 2 edges: 1-2-3)
   Initialize_Graph(G);
   Add_Vertex(G, 1);
   Add_Vertex(G, 2);
   Add_Vertex(G, 3);
   Add_Edge(G, 1, 2);
   Add_Edge(G, 2, 3);

   -- Build path graph H (2 vertices, 1 edge: 1-2)
   Initialize_Graph(H);
   Add_Vertex(H, 1);
   Add_Vertex(H, 2);
   Add_Edge(H, 1, 2);

   -- Find all mappings (limited to 10)
   Find_All_Mappings(G, H, Mappings, VF2, 10, Found_Count);
   Put_Line("Found " & Natural'Image(Found_Count) & " mappings");

   Put_Line("All tests completed!");
end Test_Subgraph;
