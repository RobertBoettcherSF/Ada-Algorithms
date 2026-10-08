--  Topological_Sorting — Ada/SPARK Level 4 educational package for
--  Kahn's algorithm (indegree + queue) on a bounded directed graph.
--  A topological order of a DAG is a linear arrangement of vertices
--  such that every directed edge u → v has u before v. Cycles are
--  reported via Success : out Boolean (no exceptions).
--
--  SPARK port of Ada-Topological-Sort: hard Max_Nodes bound, static
--  Boolean adjacency matrix (no Ada.Containers), static Kahn queue,
--  In_Bounds / Is_Valid_Sort contracts replace Invalid_Graph.
--  Non-SPARK sibling uses Vectors adjacency lists, exceptions, and a
--  recursive DFS variant; this port keeps Kahn only (DFS recursion
--  does not prove as cleanly at Level 4) and nodes 1 .. N.
--
--  Reference: https://en.wikipedia.org/wiki/Topological_sorting

package Topological_Sorting
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps matrix / queue VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on |V|. Smaller than an unbounded sibling graph so
   --  Level 4 can discharge index / arithmetic VCs on the static matrix.
   Max_Nodes : constant Positive := 32;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live nodes are 1 .. N with N ≤ Max_Nodes. Empty graphs use N = 0.
   subtype Node_Count is Natural range 0 .. Max_Nodes;
   subtype Node_Id is Positive range 1 .. Max_Nodes;

   type Node_Array is array (Positive range <>) of Node_Id;

   --  Static dense adjacency: Adj (U, V) = True iff there is an edge
   --  U → V. Multi-edges collapse (Boolean). Live cells are 1 .. N.
   type Adj_Matrix is array (Node_Id, Node_Id) of Boolean;

   type Graph (Num_Nodes : Node_Count) is record
      Adj : Adj_Matrix := [others => [others => False]];
   end record;

   ---------------------------------------------------------------------------
   -- Shape guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (Result : Node_Array) return Boolean is
     (Result'First = 1 and then Result'Last in Node_Count)
   with Global => null;
   --  Shape guard for a 1-based order buffer of length 0 .. Max_Nodes.

   function Result_Shape
     (G : Graph; Result : Node_Array) return Boolean is
     (Result'First = 1 and then Result'Last = G.Num_Nodes)
   with Global => null;
   --  Kahn writes a dense 1-based order of length N (empty: Last = 0).

   function Has_Edge
     (G : Graph; From, To : Node_Id) return Boolean is
     (From <= G.Num_Nodes
      and then To <= G.Num_Nodes
      and then G.Adj (From, To))
   with Global => null;
   --  True iff From → To is present among the live N × N cells.

   ---------------------------------------------------------------------------
   -- Graph mutators
   ---------------------------------------------------------------------------

   procedure Clear (G : out Graph)
     with
       Global => null,
       Post   =>
         (for all I in Node_Id =>
            (for all J in Node_Id => not G.Adj (I, J)));
   --  Drop every edge. Num_Nodes (discriminant) is unchanged.

   procedure Add_Edge (G : in out Graph; From, To : Node_Id)
     with
       Global => null,
       Pre    => From <= G.Num_Nodes and then To <= G.Num_Nodes,
       Post   =>
         G.Adj (From, To)
         and then
           (for all I in Node_Id =>
              (for all J in Node_Id =>
                 (if I /= From or else J /= To then
                    G.Adj (I, J) = G'Old.Adj (I, J))));
   --  Insert directed edge From → To. Idempotent (Boolean matrix).
   --  Self-loops are allowed and make the graph cyclic.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Kahn / Wikipedia)
   ---------------------------------------------------------------------------
   --  1. In_Degree(v) ← |{u : Adj(u,v)}|.
   --  2. Enqueue every v with In_Degree(v) = 0.
   --  3. While the queue is not empty: dequeue u, append u to Result,
   --     and for each edge u → v decrement In_Degree(v); if it hits 0,
   --     enqueue v. Each node is enqueued at most once.
   --  4. Success iff |Result| = N (otherwise a cycle remains).
   --  Static queue: array 1 .. Max_Nodes plus Head / Tail.
   --  Matrix scan is Θ(N²); no heap, no Ada.Containers.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Validation / sort
   ---------------------------------------------------------------------------

   function Is_Valid_Sort
     (G : Graph; Result : Node_Array) return Boolean
     with
       Global => null,
       Pre    => Result_Shape (G, Result);
   --  True iff Result is a permutation of 1 .. N and every live edge
   --  U → V has Position(U) < Position(V). Vacuous for N = 0.
   --  Used by tests and, when Success, as Kahn_Sort's postcondition
   --  (discharged by evaluating the predicate after a full drain).

   pragma Warnings (Off, "referenced before it has a value");
   procedure Kahn_Sort
     (G       : Graph;
      Result  : out Node_Array;
      Success : out Boolean)
     with
       Global                 => null,
       Relaxed_Initialization => Result,
       Pre                    =>
         Result'First = 1 and then Result'Last = G.Num_Nodes,
       Post                   =>
         Result'Initialized
         and then Result'First = 1
         and then Result'Last = G.Num_Nodes
         and then (if Success then Is_Valid_Sort (G, Result) else True);
   --  Kahn's algorithm. Success is True iff the graph is a DAG and
   --  Result is a valid topological order. On a cycle Success is False
   --  and Result is a (possibly partial) prefix — not a valid sort.
   --  Full permutation + edge-order is Is_Valid_Sort; SPARK proves
   --  that Success implies that predicate. Tests check that every
   --  acyclic case actually returns Success (the algorithm works)
   --  and that cyclic cases return Failure.

   pragma Warnings (On, "referenced before it has a value");

end Topological_Sorting;
