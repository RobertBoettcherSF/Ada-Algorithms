pragma Ada_2022;
package body Clone_Graph with SPARK_Mode => On is

   --  Number of copied nodes among 1 .. Upto.
   function Count (Map : Id_Map; Upto : Node_Ref) return Node_Ref is
     (if Upto = 0 then 0
      else Count (Map, Upto - 1) + (if Map (Upto) /= 0 then 1 else 0))
   with
     Ghost,
     Post               => Count'Result <= Upto,
     Subprogram_Variant => (Decreases => Upto);

   --  Copying one more node adds one to the count.
   procedure Lemma_Count_Add (A, B : Id_Map; X : Node_Id)
   with
     Ghost,
     Pre  => A (X) = 0 and then B (X) /= 0
       and then (for all N in Node_Id => (if N /= X then B (N) = A (N))),
     Post => Count (B, Capacity) = Count (A, Capacity) + 1
   is
   begin
      for U in Node_Id loop
         pragma Loop_Invariant
           (Count (B, U) = Count (A, U) + (if X <= U then 1 else 0));
      end loop;
   end Lemma_Count_Add;

   --  Nothing copied: count 0.
   procedure Lemma_Count_Zero (Map : Id_Map)
   with
     Ghost,
     Pre  => (for all N in Node_Id => Map (N) = 0),
     Post => Count (Map, Capacity) = 0
   is
   begin
      for U in Node_Id loop
         pragma Loop_Invariant (Count (Map, U) = 0);
      end loop;
   end Lemma_Count_Zero;

   --  If only nodes up to Lim are copied and X <= Lim is not, fewer than
   --  Lim nodes are copied.
   procedure Lemma_Count_Room (Map : Id_Map; X : Node_Id; Lim : Node_Id)
   with
     Ghost,
     Pre  => Map (X) = 0 and then X <= Lim
       and then (for all N in Node_Id => (if Map (N) /= 0 then N <= Lim)),
     Post => Count (Map, Capacity) < Lim
   is
   begin
      for U in Node_Id loop
         pragma Loop_Invariant
           (Count (Map, U) <= (if U <= Lim then U else Lim) - (if X <= U then 1 else 0));
      end loop;
   end Lemma_Count_Room;

   type Slot_Map is array (Node_Id) of Slot with Ghost;

   --  The discovery records give each copied node other than Start a
   --  neighbour-of witness with a smaller copy id.
   procedure Lemma_Reachable
     (G : Graph; Start : Node_Id; Map, Inv, Parent : Id_Map; Via : Slot_Map;
      Size : Node_Ref)
   with
     Ghost,
     Pre  => Map (Start) = 1
       and then
         (for all N in Node_Id =>
            (if Map (N) /= 0 then Map (N) <= Size and then Inv (Map (N)) = N))
       and then
         (for all D in 1 .. Size => Inv (D) /= 0 and then Map (Inv (D)) = D)
       and then
         (for all D in 2 .. Size =>
            Parent (D) in 1 .. D - 1
            and then Neighbor (G, Inv (Parent (D)), Via (D)) = Inv (D)),
     Post =>
       (for all N in Node_Id =>
          (if Map (N) /= 0 and then N /= Start then
             (for some P in Node_Id =>
                Map (P) /= 0 and then Map (P) < Map (N)
                and then (for some S in Slot => Neighbor (G, P, S) = N))))
   is
   begin
      for N in Node_Id loop
         if Map (N) /= 0 and then N /= Start then
            declare
               D : constant Node_Id := Map (N);
               P : constant Node_Id := Inv (Parent (D));
               S : constant Slot := Via (D);
            begin
               pragma Assert (D >= 2);
               pragma Assert (Map (P) = Parent (D) and then Map (P) < D);
               pragma Assert (Neighbor (G, P, S) = N);
            end;
         end if;
         pragma Loop_Invariant
           (for all M in 1 .. N =>
              (if Map (M) /= 0 and then M /= Start then
                 (for some P in Node_Id =>
                    Map (P) /= 0 and then Map (P) < Map (M)
                    and then (for some S in Slot => Neighbor (G, P, S) = M))));
      end loop;
   end Lemma_Reachable;

   function Clone (G : Graph; Start : Node_Id) return Clone_Result is
      Copy : Graph;                       --  every node empty
      Size : Node_Ref := 1;               --  copies so far
      Map  : Id_Map := [others => 0];     --  node of G -> copy id
      Inv  : Id_Map := [others => 0];     --  copy id -> node of G
      Head : Node_Id := 1;                --  next copy to fill in
      U    : Node_Id;
      V    : Node_Ref;
      --  Ghost: copy D (> 1) was found in slot Via (D) of copy Parent (D).
      Old_Map : Id_Map with Ghost;
      Parent  : Id_Map := [others => 0] with Ghost;
      Via     : Slot_Map := [others => 1] with Ghost;
   begin
      Lemma_Count_Zero (Map);
      Lemma_Count_Add (Map, [Map with delta Start => 1], Start);
      Map (Start) := 1;
      Inv (1) := Start;
      --  Breadth-first: copies are numbered in discovery order, so the
      --  queue is the copies Head .. Size not filled in yet.
      loop
         pragma Loop_Invariant (Head <= Size);
         pragma Loop_Invariant (Map (Start) = 1 and then Inv (1) = Start);
         pragma Loop_Invariant (Count (Map, Capacity) = Size);
         pragma Loop_Invariant
           (for all N in Node_Id =>
              (if Map (N) /= 0 then Map (N) <= Size and then Inv (Map (N)) = N));
         pragma Loop_Invariant
           (for all D in Node_Id =>
              (if D <= Size then Inv (D) /= 0 and then Map (Inv (D)) = D
               else Inv (D) = 0));
         --  Filled-in copies.
         pragma Loop_Invariant
           (for all D in 1 .. Head - 1 =>
              Copy (D).Label = G (Inv (D)).Label
              and then
                (for all S in Slot =>
                   (if Neighbor (G, Inv (D), S) = 0 then Neighbor (Copy, D, S) = 0
                    else Map (Neighbor (G, Inv (D), S)) /= 0
                         and then Neighbor (Copy, D, S) = Map (Neighbor (G, Inv (D), S)))));
         --  Copies not filled in yet are still empty.
         pragma Loop_Invariant
           (for all D in Head .. Capacity =>
              Copy (D).Label = 0 and then (for all S in Slot => Neighbor (Copy, D, S) = 0));
         --  Each copy after the first was found from an earlier one.
         pragma Loop_Invariant
           (for all D in 2 .. Size =>
              Parent (D) in 1 .. D - 1
              and then Neighbor (G, Inv (Parent (D)), Via (D)) = Inv (D));
         pragma Loop_Variant (Increases => Head);

         U := Inv (Head);
         Copy (Head).Label := G (U).Label;
         for S in Slot loop
            V := G (U).Neighbors (S);
            if V /= 0 then
               if Map (V) = 0 then
                  --  First time V is seen: give it the next copy id.
                  Lemma_Count_Room (Map, V, Capacity);
                  Size := Size + 1;
                  Old_Map := Map;
                  Map (V) := Size;
                  Lemma_Count_Add (Old_Map, Map, V);
                  Inv (Size) := V;
                  Parent (Size) := Head;
                  Via (Size) := S;
               end if;
               Copy (Head).Neighbors (S) := Map (V);
            end if;
            pragma Loop_Invariant (Head <= Size);
            pragma Loop_Invariant (Map (Start) = 1 and then Inv (1) = Start);
            pragma Loop_Invariant (Count (Map, Capacity) = Size);
            pragma Loop_Invariant
              (for all N in Node_Id =>
                 (if Map (N) /= 0 then Map (N) <= Size and then Inv (Map (N)) = N));
            pragma Loop_Invariant
              (for all D in Node_Id =>
                 (if D <= Size then Inv (D) /= 0 and then Map (Inv (D)) = D
                  else Inv (D) = 0));
            pragma Loop_Invariant (Inv (Head) = U);
            pragma Loop_Invariant
              (for all D in 1 .. Head - 1 =>
                 Copy (D).Label = G (Inv (D)).Label
                 and then
                   (for all T in Slot =>
                      (if Neighbor (G, Inv (D), T) = 0 then Neighbor (Copy, D, T) = 0
                       else Map (Neighbor (G, Inv (D), T)) /= 0
                            and then Neighbor (Copy, D, T) = Map (Neighbor (G, Inv (D), T)))));
            pragma Loop_Invariant
              (Copy (Head).Label = G (U).Label
               and then
                 (for all T in Slot =>
                    (if T > S or else Neighbor (G, U, T) = 0 then Neighbor (Copy, Head, T) = 0
                     else Map (Neighbor (G, U, T)) /= 0
                          and then Neighbor (Copy, Head, T) = Map (Neighbor (G, U, T)))));
            pragma Loop_Invariant
              (for all D in Head + 1 .. Capacity =>
                 Copy (D).Label = 0 and then (for all T in Slot => Neighbor (Copy, D, T) = 0));
            pragma Loop_Invariant
              (for all D in 2 .. Size =>
                 Parent (D) in 1 .. D - 1
                 and then Neighbor (G, Inv (Parent (D)), Via (D)) = Inv (D));
         end loop;
         exit when Head = Size;
         Head := Head + 1;
      end loop;
      Lemma_Reachable (G, Start, Map, Inv, Parent, Via, Size);
      return (Size => Size, Copy => Copy, Map => Map, Orig => Inv);
   end Clone;
end Clone_Graph;
