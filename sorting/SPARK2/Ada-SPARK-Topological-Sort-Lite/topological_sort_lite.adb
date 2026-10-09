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

   procedure Topo_Sort
     (Edges : Graph; N : Vertex; Order : out Order_Array; Ok : out Boolean; Left : out Vertex_Set)
   is
      Pick : Natural;
   begin
      Order := [others => 1];
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
