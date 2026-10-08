--  Topological_Sorting body — SPARK Level 4 Kahn's algorithm on a
--  static Boolean adjacency matrix with a bounded Head/Tail queue.
--  Helpers keep in-degree, enqueue, and validation VCs modular.
--  Success is assigned from a full drain plus Is_Valid_Sort so the
--  public Post (Success ⇒ valid order) is discharged at Level 4
--  without Intentional annotations.

package body Topological_Sorting
  with SPARK_Mode => On
is

   subtype Degree is Natural range 0 .. Max_Nodes;
   type Degree_Array is array (Node_Id) of Degree;
   type Flag_Array is array (Node_Id) of Boolean;
   type Queue_Array is array (Node_Id) of Node_Id;
   type Pos_Array is array (Node_Id) of Natural;

   -------------------------------------------------------------------------
   -- Is_Valid_Sort — permutation of 1 .. N and every edge U → V is
   -- forward in Result. Position 0 means "not yet seen".
   -------------------------------------------------------------------------

   function Is_Valid_Sort
     (G : Graph; Result : Node_Array) return Boolean
   is
      Pos : Pos_Array := [others => 0];
   begin
      --  Injectivity + range: each Result(I) is a fresh live node.
      for I in 1 .. G.Num_Nodes loop
         pragma Loop_Invariant
           (for all K in 1 .. I - 1 =>
              Result (K) <= G.Num_Nodes
              and then Pos (Result (K)) = K);
         pragma Loop_Invariant
           (for all N in Node_Id =>
              (if Pos (N) /= 0 then Pos (N) < I and then Pos (N) >= 1));

         if Result (I) > G.Num_Nodes then
            return False;
         end if;

         declare
            N : constant Node_Id := Result (I);
         begin
            if Pos (N) /= 0 then
               return False;
            end if;
            Pos (N) := I;
         end;
      end loop;

      --  Surjectivity: every live node appears.
      for N in 1 .. G.Num_Nodes loop
         pragma Loop_Invariant (for all K in 1 .. N - 1 => Pos (K) /= 0);
         if Pos (N) = 0 then
            return False;
         end if;
      end loop;

      --  Every live edge U → V is strictly forward.
      for U in 1 .. G.Num_Nodes loop
         for V in 1 .. G.Num_Nodes loop
            if G.Adj (U, V)
              and then (Pos (U) = 0
                        or else Pos (V) = 0
                        or else Pos (U) >= Pos (V))
            then
               return False;
            end if;
         end loop;
      end loop;

      return True;
   end Is_Valid_Sort;

   -------------------------------------------------------------------------
   -- Clear / Add_Edge
   -------------------------------------------------------------------------

   procedure Clear (G : out Graph) is
   begin
      G.Adj := [others => [others => False]];
   end Clear;

   procedure Add_Edge (G : in out Graph; From, To : Node_Id) is
   begin
      G.Adj (From, To) := True;
   end Add_Edge;

   -------------------------------------------------------------------------
   -- In-degrees: one matrix scan. Guarded increment keeps Degree'Last.
   -------------------------------------------------------------------------

   procedure Compute_In_Degrees
     (G         : Graph;
      In_Degree : out Degree_Array)
     with
       Global => null,
       Post   => (for all K in Node_Id => In_Degree (K) <= Max_Nodes)
   is
   begin
      In_Degree := [others => 0];

      for U in 1 .. G.Num_Nodes loop
         pragma Loop_Invariant
           (for all K in Node_Id => In_Degree (K) <= Max_Nodes);

         for V in 1 .. G.Num_Nodes loop
            pragma Loop_Invariant
              (for all K in Node_Id => In_Degree (K) <= Max_Nodes);

            if G.Adj (U, V) and then In_Degree (V) < Max_Nodes then
               In_Degree (V) := In_Degree (V) + 1;
            end if;
         end loop;
      end loop;
   end Compute_In_Degrees;

   -------------------------------------------------------------------------
   -- Enqueue V once. Tail is the count of nodes ever offered to the
   -- queue; each node is written at Q(Tail) at most once.
   -------------------------------------------------------------------------

   procedure Enqueue
     (Q        : in out Queue_Array;
      Tail     : in out Node_Count;
      Offered  : in out Flag_Array;
      V        : Node_Id)
     with
       Global => null,
       Pre    => Tail <= Max_Nodes,
       Post   =>
         Tail <= Max_Nodes
         and then Tail >= Tail'Old
         and then Offered (V)
         and then
           (if Offered'Old (V) or else Tail'Old = Max_Nodes then
              Tail = Tail'Old
            else
              Tail = Tail'Old + 1 and then Q (Tail) = V)
         and then
           (for all K in Node_Id =>
              (if K /= V then Offered (K) = Offered'Old (K)))
         and then
           (for all K in Node_Id =>
              (if K > Tail'Old then
                 (if Tail > Tail'Old and then K = Tail then Q (K) = V
                  else Q (K) = Q'Old (K))
               else Q (K) = Q'Old (K)))
   is
   begin
      if Offered (V) or else Tail = Max_Nodes then
         Offered (V) := True;
         return;
      end if;

      Tail     := Tail + 1;
      Q (Tail) := V;
      Offered (V) := True;
   end Enqueue;

   -------------------------------------------------------------------------
   -- Seed the queue with every live node of in-degree 0.
   -------------------------------------------------------------------------

   procedure Seed_Queue
     (G         : Graph;
      In_Degree : Degree_Array;
      Q         : in out Queue_Array;
      Tail      : in out Node_Count;
      Offered   : in out Flag_Array)
     with
       Global => null,
       Pre    => Tail = 0
                 and then (for all K in Node_Id => not Offered (K)),
       Post   => Tail <= G.Num_Nodes
   is
   begin
      for U in 1 .. G.Num_Nodes loop
         pragma Loop_Invariant (Tail <= U - 1);
         pragma Loop_Invariant (Tail <= G.Num_Nodes);

         if In_Degree (U) = 0 then
            Enqueue (Q, Tail, Offered, U);
         end if;
      end loop;
   end Seed_Queue;

   -------------------------------------------------------------------------
   -- Relax successors of U: decrement in-degree; enqueue when it hits 0.
   -------------------------------------------------------------------------

   procedure Relax_Successors
     (G         : Graph;
      U         : Node_Id;
      In_Degree : in out Degree_Array;
      Q         : in out Queue_Array;
      Tail      : in out Node_Count;
      Offered   : in out Flag_Array)
     with
       Global => null,
       Pre    => U <= G.Num_Nodes and then Tail <= Max_Nodes,
       Post   => Tail <= Max_Nodes
   is
   begin
      for V in 1 .. G.Num_Nodes loop
         pragma Loop_Invariant (Tail <= Max_Nodes);

         if G.Adj (U, V) and then In_Degree (V) > 0 then
            In_Degree (V) := In_Degree (V) - 1;
            if In_Degree (V) = 0 then
               Enqueue (Q, Tail, Offered, V);
            end if;
         end if;
      end loop;
   end Relax_Successors;

   -------------------------------------------------------------------------
   -- Kahn_Sort
   -------------------------------------------------------------------------

   procedure Kahn_Sort
     (G       : Graph;
      Result  : out Node_Array;
      Success : out Boolean)
   is
      In_Degree : Degree_Array;
      Offered   : Flag_Array   := [others => False];
      Q         : Queue_Array  := [others => Node_Id'First];
      Head      : Positive     := 1;
      Tail      : Node_Count   := 0;
      Count     : Node_Count   := 0;
   begin
      --  SPARK out-initialization: every slot written before return
      --  (empty 1 .. 0 buffers are a vacuous loop).
      for I in Result'Range loop
         Result (I) := Node_Id'First;
         pragma Loop_Invariant
           (for all K in Result'First .. I => Result (K)'Initialized);
         pragma Loop_Invariant
           (for all K in Result'First .. I =>
              Result (K) = Node_Id'First);
      end loop;
      pragma Assert (Result'Initialized);

      if G.Num_Nodes = 0 then
         Success := Is_Valid_Sort (G, Result);
         return;
      end if;

      Compute_In_Degrees (G, In_Degree);
      Seed_Queue (G, In_Degree, Q, Tail, Offered);

      --  At most N dequeues; for-loop termination is immediate.
      for Step in 1 .. G.Num_Nodes loop
         pragma Loop_Invariant (Head >= 1);
         pragma Loop_Invariant (Tail <= Max_Nodes);
         pragma Loop_Invariant (Count <= G.Num_Nodes);
         pragma Loop_Invariant (Count < Head);
         pragma Loop_Invariant (Head <= Max_Nodes + 1);
         pragma Loop_Invariant
           (if Head <= Tail then Head in Node_Id);
         pragma Loop_Invariant (Result'Initialized);

         exit when Head > Tail;

         declare
            U : constant Node_Id := Q (Head);
         begin
            Head := Head + 1;

            if Count < G.Num_Nodes then
               Count := Count + 1;
               Result (Count) := U;
            end if;

            if U <= G.Num_Nodes then
               Relax_Successors
                 (G, U, In_Degree, Q, Tail, Offered);
            end if;
         end;
      end loop;

      --  Success ⇒ Is_Valid_Sort is immediate from this assignment.
      --  Tests check the converse on DAGs (Kahn actually succeeds).
      Success := Count = G.Num_Nodes
                 and then Is_Valid_Sort (G, Result);
   end Kahn_Sort;

end Topological_Sorting;
