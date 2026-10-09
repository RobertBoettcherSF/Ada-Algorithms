pragma Ada_2022;

--  Clone graph: copy every node reachable from a start node into a new
--  graph with fresh node ids, keeping each node's label and its
--  neighbour slots. The graph is a pool of Capacity nodes; each node has
--  Max_Degree neighbour slots, 0 meaning an empty slot (repeats and
--  self-loops allowed).
package Clone_Graph with SPARK_Mode => On is
   Capacity   : constant := 16;
   Max_Degree : constant := 4;
   subtype Node_Id is Positive range 1 .. Capacity;
   subtype Node_Ref is Natural range 0 .. Capacity;   --  0: no node
   subtype Slot is Positive range 1 .. Max_Degree;
   type Neighbor_Array is array (Slot) of Node_Ref;

   type Node is record
      Label     : Integer := 0;
      Neighbors : Neighbor_Array := [others => 0];
   end record;
   type Graph is array (Node_Id) of Node;

   type Id_Map is array (Node_Id) of Node_Ref;
   type Clone_Result is record
      Size : Node_Ref;   --  copies are nodes 1 .. Size of Copy
      Copy : Graph;
      Map  : Id_Map;     --  Map (N): id of N's copy, 0 if N is not copied
      Orig : Id_Map;     --  Orig (D): the node copied to D, 0 after Size
   end record;

   --  N's neighbour in slot S (0 if the slot is empty).
   function Neighbor (G : Graph; N : Node_Id; S : Slot) return Node_Ref is
     (G (N).Neighbors (S));

   --  R is a clone of the part of G reachable from Start:
   --  * Start is copied to node 1; copies are numbered 1 .. Size, every
   --    copy D is the copy of exactly one node of G, Orig (D);
   --  * a copied node's copy has its label and, slot by slot, the copy of
   --    its neighbour or an empty slot (so the copied set is closed under
   --    neighbours); copy nodes after Size are empty;
   --  * every copied node other than Start is a neighbour of a node with
   --    a smaller copy id, so it is reachable from Start.
   function Is_Clone (G : Graph; Start : Node_Id; R : Clone_Result) return Boolean is
     (R.Map (Start) = 1
      and then R.Size >= 1
      and then
        (for all N in Node_Id =>
           (if R.Map (N) /= 0 then
              R.Map (N) <= R.Size
              and then R.Copy (R.Map (N)).Label = G (N).Label
              and then
                (for all S in Slot =>
                   (if Neighbor (G, N, S) = 0 then Neighbor (R.Copy, R.Map (N), S) = 0
                    else R.Map (Neighbor (G, N, S)) /= 0
                         and then Neighbor (R.Copy, R.Map (N), S) = R.Map (Neighbor (G, N, S))))))
      and then
        (for all A in Node_Id =>
           (for all B in Node_Id =>
              (if A /= B and then R.Map (A) /= 0 then R.Map (A) /= R.Map (B))))
      and then
        (for all D in Node_Id =>
           (if D <= R.Size then R.Orig (D) /= 0 and then R.Map (R.Orig (D)) = D
            else R.Orig (D) = 0))
      and then
        (for all D in R.Size + 1 .. Capacity =>
           R.Copy (D).Label = 0
           and then (for all S in Slot => Neighbor (R.Copy, D, S) = 0))
      and then
        (for all N in Node_Id =>
           (if R.Map (N) /= 0 and then N /= Start then
              (for some P in Node_Id =>
                 R.Map (P) /= 0 and then R.Map (P) < R.Map (N)
                 and then (for some S in Slot => Neighbor (G, P, S) = N)))));

   function Clone (G : Graph; Start : Node_Id) return Clone_Result
   with
     Global => null,
     Post   => Is_Clone (G, Start, Clone'Result);
end Clone_Graph;
