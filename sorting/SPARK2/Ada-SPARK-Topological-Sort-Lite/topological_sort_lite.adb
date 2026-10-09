pragma SPARK_Mode (On);
pragma Ada_2022;

package body Topological_Sort_Lite with SPARK_Mode => On is
   function Is_Valid_Order
     (Edges : Graph; Order : Order_Array; N : Vertex) return Boolean is
      Seen : Vertex_Set := [others => False];
   begin
      for I in 1 .. N loop
         pragma Loop_Invariant (for all K in 1 .. I - 1 => Order (K) <= N);
         pragma Loop_Invariant
           (for all J in 1 .. I - 1 => (for all K in 1 .. J - 1 => Order (K) /= Order (J)));
         pragma Loop_Invariant (for all K in 1 .. I - 1 => Seen (Order (K)));
         pragma Loop_Invariant
           (for all V in Vertex => (if Seen (V) then (for some K in 1 .. I - 1 => Order (K) = V)));
         if Order (I) > N or else Seen (Order (I)) then
            return False;
         end if;
         Seen (Order (I)) := True;
      end loop;
      for J in 1 .. N loop
         pragma Loop_Invariant
           (for all L in 1 .. J - 1 => (for all K in 1 .. L => not Edges (Order (L), Order (K))));
         for I in 1 .. J loop
            pragma Loop_Invariant (for all K in 1 .. I - 1 => not Edges (Order (J), Order (K)));
            if Edges (Order (J), Order (I)) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Valid_Order;

   --  Number of vertices of S in 1 .. M (proof only).
   function Count_Of (S : Vertex_Set; M : Natural) return Natural is
     (if M = 0 then 0 else Count_Of (S, M - 1) + (if S (M) then 1 else 0))
     with Ghost, Pre => M <= Capacity, Post => Count_Of'Result <= M,
          Subprogram_Variant => (Decreases => M);

   --  A positive count has a member.
   procedure Lemma_Member (S : Vertex_Set; M : Natural)
     with Ghost, Pre => M <= Capacity and then Count_Of (S, M) > 0,
          Post => (for some V in 1 .. M => S (V)),
          Subprogram_Variant => (Decreases => M)
   is
   begin
      if not S (M) then
         Lemma_Member (S, M - 1);
      end if;
   end Lemma_Member;

   --  Removing member P lowers every count from P on by one.
   procedure Lemma_Remove (S, T : Vertex_Set; P : Vertex; M : Natural)
     with Ghost,
          Pre  => M <= Capacity and then S (P) and then not T (P)
                  and then (for all V in Vertex => (if V /= P then T (V) = S (V))),
          Post => Count_Of (T, M) = Count_Of (S, M) - (if P <= M then 1 else 0),
          Subprogram_Variant => (Decreases => M)
   is
   begin
      if M > 0 then
         Lemma_Remove (S, T, P, M - 1);
      end if;
   end Lemma_Remove;

   --  No member in 1 .. M counts 0.
   procedure Lemma_None (S : Vertex_Set; M : Natural)
     with Ghost, Pre => M <= Capacity and then (for all V in 1 .. M => not S (V)),
          Post => Count_Of (S, M) = 0,
          Subprogram_Variant => (Decreases => M)
   is
   begin
      if M > 0 then
         Lemma_None (S, M - 1);
      end if;
   end Lemma_None;

   --  An empty set plus one member P <= N counts 1.
   procedure Lemma_Zero_Plus (S : Vertex_Set; P : Vertex; M : Natural)
     with Ghost,
          Pre  => M <= Capacity and then P <= M and then S (P)
                  and then (for all V in Vertex => (if V /= P then not S (V))),
          Post => Count_Of (S, M) = 1,
          Subprogram_Variant => (Decreases => M)
   is
   begin
      if M > P then
         Lemma_Zero_Plus (S, P, M - 1);
      elsif M = P then
         Lemma_None (S, M - 1);
      end if;
   end Lemma_Zero_Plus;

   --  The set 1 .. N has N members.
   procedure Lemma_Full (S : Vertex_Set; N : Vertex; M : Natural)
     with Ghost,
          Pre  => M <= N and then (for all V in Vertex => S (V) = (V <= N)),
          Post => Count_Of (S, M) = M,
          Subprogram_Variant => (Decreases => M)
   is
   begin
      if M > 0 then
         Lemma_Full (S, N, M - 1);
      end if;
   end Lemma_Full;

   --  A full count means every vertex is a member.
   procedure Lemma_All (S : Vertex_Set; M : Natural)
     with Ghost, Pre => M <= Capacity and then Count_Of (S, M) = M,
          Post => (for all V in 1 .. M => S (V)),
          Subprogram_Variant => (Decreases => M)
   is
   begin
      if M > 0 then
         Lemma_All (S, M - 1);
      end if;
   end Lemma_All;

   --  Walk back along incoming edges inside Left until a vertex repeats; the
   --  repeated stretch, reversed, is the cycle.
   procedure Find_Cycle
     (Edges : Graph; N : Vertex; Left : Vertex_Set; Cycle : out Order_Array; Len : out Natural)
     with Pre  => Cycle_Certificate (Edges, N, Left),
          Post => Is_Cycle (Edges, N, Cycle, Len) and then (for all I in 1 .. Len => Left (Cycle (I)))
   is
      P    : Order_Array := [others => 1];      --  the walk; P (K + 1) -> P (K) is an edge
      Mark : Order_Array := [others => 1];      --  Mark (V) = position of V in P, when Marked (V)
      Marked : Vertex_Set := [others => False];
      M    : Vertex := 1;
      Start : Natural := 0;
      U    : Natural;
   begin
      for V in 1 .. N loop
         pragma Loop_Invariant (Start = 0 and then (for all W in 1 .. V - 1 => not Left (W)));
         if Left (V) then
            Start := V;
            exit;
         end if;
      end loop;
      pragma Assert (Start /= 0);
      P (1) := Start;
      Mark (Start) := 1;
      Marked (Start) := True;
      Lemma_Zero_Plus (Marked, Start, N);
      loop
         pragma Loop_Invariant (M <= N and then Count_Of (Marked, N) = M);
         pragma Loop_Invariant (for all V in Vertex => (if Marked (V) then V <= N));
         pragma Loop_Invariant
           (for all K in 1 .. M => P (K) <= N and then Left (P (K)) and then Marked (P (K))
                                   and then Mark (P (K)) = K);
         pragma Loop_Invariant
           (for all V in Vertex => (if Marked (V) then Mark (V) <= M and then P (Mark (V)) = V));
         pragma Loop_Invariant (for all K in 1 .. M - 1 => Edges (P (K + 1), P (K)));
         pragma Loop_Variant (Increases => M);
         --  an incoming edge of P (M) from Left
         U := 0;
         for W in 1 .. N loop
            pragma Loop_Invariant (U = 0);
            pragma Loop_Invariant (for all X in 1 .. W - 1 => not (Left (X) and then Edges (X, P (M))));
            if Left (W) and then Edges (W, P (M)) then
               U := W;
               exit;
            end if;
         end loop;
         pragma Assert (U /= 0);
         exit when Marked (U);
         if M = N then
            Lemma_All (Marked, N);
         end if;
         declare
            Before : constant Vertex_Set := Marked with Ghost;
         begin
            M := M + 1;
            P (M) := U;
            Mark (U) := M;
            Marked (U) := True;
            Lemma_Remove (Marked, Before, U, N);
         end;
      end loop;
      --  P (Mark (U)) = U and U -> P (M): the cycle is P (M), P (M - 1), .., P (Mark (U))
      Len := M - Mark (U) + 1;
      Cycle := [others => 1];
      for I in 1 .. Len loop
         pragma Loop_Invariant (for all J in 1 .. I - 1 => Cycle (J) = P (M - J + 1));
         Cycle (I) := P (M - I + 1);
      end loop;
   end Find_Cycle;

   procedure Topo_Sort
     (Edges : Graph; N : Vertex; Order : out Order_Array; Ok : out Boolean; Left : out Vertex_Set;
      Cycle : out Order_Array; Cycle_Len : out Natural)
   is
      Pick : Natural;
   begin
      Order := [others => 1];
      Cycle := [others => 1];
      Cycle_Len := 0;
      Left  := [for V in Vertex => V <= N];
      Lemma_Full (Left, N, N);
      for K in 1 .. N loop
         pragma Loop_Invariant (Count_Of (Left, N) = N - (K - 1));
         --  Order (1 .. K - 1) are the vertices taken, the rest of 1 .. N is Left.
         pragma Loop_Invariant (for all V in Vertex => (if Left (V) then V <= N));
         pragma Loop_Invariant (for all I in 1 .. K - 1 => Order (I) <= N and then not Left (Order (I)));
         pragma Loop_Invariant
           (for all J in 1 .. K - 1 => (for all I in 1 .. J - 1 => Order (I) /= Order (J)));
         pragma Loop_Invariant
           (for all V in 1 .. N => Left (V) or else (for some I in 1 .. K - 1 => Order (I) = V));
         --  a taken vertex had no edge from anything taken later or still left
         pragma Loop_Invariant
           (for all J in 1 .. K - 1 => (for all I in 1 .. J => not Edges (Order (J), Order (I))));
         pragma Loop_Invariant
           (for all I in 1 .. K - 1 => (for all U in 1 .. N => (if Left (U) then not Edges (U, Order (I)))));
         Pick := 0;
         for V in 1 .. N loop
            pragma Loop_Invariant (Pick = 0);
            pragma Loop_Invariant
              (for all W in 1 .. V - 1 =>
                 (if Left (W) then (for some U in 1 .. N => Left (U) and then Edges (U, W))));
            if Left (V) and then (for all U in 1 .. N => not (Left (U) and then Edges (U, V))) then
               Pick := V;
               exit;
            end if;
         end loop;
         if Pick = 0 then
            Lemma_Member (Left, N);
            Ok := False;
            Find_Cycle (Edges, N, Left, Cycle, Cycle_Len);
            return;
         end if;
         pragma Assert (for all I in 1 .. K - 1 => Order (I) /= Pick);
         pragma Assert (for all I in 1 .. K - 1 => not Edges (Pick, Order (I)));
         pragma Assert (not Edges (Pick, Pick));
         declare
            Before : constant Vertex_Set := Left with Ghost;
         begin
            Order (K) := Pick;
            Left (Pick) := False;
            Lemma_Remove (Before, Left, Pick, N);
         end;
      end loop;
      Ok := True;
   end Topo_Sort;
end Topological_Sort_Lite;
