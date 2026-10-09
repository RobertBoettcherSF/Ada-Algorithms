pragma SPARK_Mode (On);
pragma Ada_2022;

--  Topological sort of a directed graph on the vertices 1 .. N (adjacency
--  matrix, Edges (U, V) = an edge U -> V), N up to 200 (the matrix is
--  40 KB).
package Topological_Sort_Lite with SPARK_Mode => On is
   Capacity : constant := 200;
   subtype Vertex is Positive range 1 .. Capacity;
   type Graph is array (Vertex, Vertex) of Boolean;
   type Order_Array is array (Vertex) of Vertex;
   type Vertex_Set is array (Vertex) of Boolean;

   --  Order (1 .. N) lists the vertices 1 .. N, each once, and every edge
   --  among them points forward (so a self-loop makes every order invalid).
   function Valid_Order (Edges : Graph; Order : Order_Array; N : Vertex) return Boolean is
     ((for all I in 1 .. N => Order (I) <= N)
      and then (for all J in 1 .. N => (for all I in 1 .. J - 1 => Order (I) /= Order (J)))
      and then (for all J in 1 .. N => (for all I in 1 .. J => not Edges (Order (J), Order (I)))));

   function Is_Valid_Order
     (Edges : Graph; Order : Order_Array; N : Vertex) return Boolean
     with Global => null,
          Post   => Is_Valid_Order'Result = Valid_Order (Edges, Order, N);

   --  Every vertex of Left (a non-empty subset of 1 .. N) has an incoming
   --  edge from Left: a cycle certificate (the first vertex of Left in any
   --  order would have a predecessor placed after it, so no valid order).
   function Cycle_Certificate (Edges : Graph; N : Vertex; Left : Vertex_Set) return Boolean is
     ((for some V in 1 .. N => Left (V))
      and then (for all V in 1 .. N =>
                  (if Left (V) then (for some U in 1 .. N => Left (U) and then Edges (U, V)))));

   --  Cycle (1 .. Len) is a cycle: distinct vertices of 1 .. N, each with
   --  an edge to the next and the last with an edge back to the first.
   function Is_Cycle (Edges : Graph; N : Vertex; Cycle : Order_Array; Len : Natural) return Boolean is
     (Len in 1 .. N
      and then (for all I in 1 .. Len => Cycle (I) <= N)
      and then (for all J in 1 .. Len => (for all I in 1 .. J - 1 => Cycle (I) /= Cycle (J)))
      and then (for all I in 1 .. Len - 1 => Edges (Cycle (I), Cycle (I + 1)))
      and then Edges (Cycle (Len), Cycle (1)));

   --  Repeatedly take the smallest remaining vertex with no incoming edge
   --  from the remaining ones. Ok and a valid Order, or not Ok, Left is a
   --  cycle certificate and Cycle (1 .. Cycle_Len) a cycle inside it (found
   --  by walking back along incoming edges inside Left until a vertex
   --  repeats).
   procedure Topo_Sort
     (Edges : Graph; N : Vertex; Order : out Order_Array; Ok : out Boolean; Left : out Vertex_Set;
      Cycle : out Order_Array; Cycle_Len : out Natural)
     with Global => null,
          Post   => (if Ok then Valid_Order (Edges, Order, N)
                     else Cycle_Certificate (Edges, N, Left)
                          and then Is_Cycle (Edges, N, Cycle, Cycle_Len)
                          and then (for all I in 1 .. Cycle_Len => Left (Cycle (I))));
end Topological_Sort_Lite;
