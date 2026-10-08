--  Patience_Sorting body: SPARK Level 4 patience sort with a static node
--  pool. The deal and the k-way merge are proved to sort on their own
--  (no bubble-sort safety net):
--    * pile order: inside one pile, a newer node is <= every older node,
--      and a node's Below link is the newest older node of the same pile;
--    * popped-node invariant: the nodes still on a pile are an
--      oldest-first prefix of that pile, its top is the newest of them,
--      so every unpopped node is >= the top of its pile;
--    * the merge always outputs the smallest top, hence a value <= every
--      unpopped node, and a ghost count of unpopped nodes shows the merge
--      only stops after N outputs.
--  Ghost state: Pile_Of (node -> pile id, fixed once dealt), Alive (node
--  not yet output) and Slot_Of (pile id -> its current slot in Pile_Tops,
--  updated when an empty pile's slot is reused by the last pile).

package body Patience_Sorting
  with SPARK_Mode => On
is

   --  0 = null / empty stack link. Live nodes occupy 1 .. Used (<= Max_N).
   subtype Node_Index is Natural range 0 .. Max_N;
   None : constant Node_Index := 0;
   subtype Node_Id is Positive range 1 .. Max_N;

   --  Cursor one past the live range (merge Out_I sentinel).
   subtype Cursor is Natural range 0 .. Max_N + 1;

   type Stack_Node is record
      Value : Integer    := 0;
      Below : Node_Index := None;
   end record;

   type Node_Pool is array (Node_Id) of Stack_Node;
   type Top_Array is array (Node_Id) of Node_Index;

   type Pile_Map  is array (Node_Id) of Index   with Ghost;
   type Alive_Map is array (Node_Id) of Boolean with Ghost;
   type Slot_Map  is array (Node_Id) of Index   with Ghost;

   --  Number of nodes in 1 .. K that are not yet output.
   function Count_Alive (Al : Alive_Map; K : Index) return Natural is
     (if K = 0 then 0
      else Count_Alive (Al, K - 1) + (if Al (K) then 1 else 0))
   with
     Ghost,
     Global             => null,
     Post               => Count_Alive'Result <= K,
     Subprogram_Variant => (Decreases => K);

   procedure Lemma_Count_All (Al : Alive_Map; K : Index)
     with
       Ghost,
       Global => null,
       Pre    => (for all U in 1 .. K => Al (U)),
       Post   => Count_Alive (Al, K) = K
   is
   begin
      for J in 1 .. K loop
         pragma Loop_Invariant (Count_Alive (Al, J) = J);
      end loop;
   end Lemma_Count_All;

   --  Clearing one alive node lowers the count by exactly one.
   procedure Lemma_Count_Clear
     (Before, After : Alive_Map; T : Node_Id; K : Index)
     with
       Ghost,
       Global => null,
       Pre    =>
         T <= K
         and then Before (T)
         and then not After (T)
         and then
           (for all U in Node_Id => (if U /= T then After (U) = Before (U))),
       Post   => Count_Alive (After, K) = Count_Alive (Before, K) - 1
   is
   begin
      for J in 1 .. K loop
         pragma Loop_Invariant
           (Count_Alive (After, J) + (if J >= T then 1 else 0)
              = Count_Alive (Before, J));
      end loop;
   end Lemma_Count_Clear;

   --  No alive node in 1 .. K means a zero count.
   procedure Lemma_None_Alive (Al : Alive_Map; K : Index)
     with
       Ghost,
       Global => null,
       Post   =>
         (if (for all U in 1 .. K => not Al (U))
          then Count_Alive (Al, K) = 0)
   is
   begin
      if (for all U in 1 .. K => not Al (U)) then
         for J in 1 .. K loop
            pragma Loop_Invariant (Count_Alive (Al, J) = 0);
         end loop;
      end if;
   end Lemma_None_Alive;

   procedure Patience_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 1,
       Post   => In_Bounds (A) and then Is_Sorted (A)
   is
      N : constant Index := A'Last;

      Pool      : Node_Pool := [others => (Value => 0, Below => None)];
      Used      : Index     := 0;
      Pile_Tops : Top_Array := [others => None];
      Num_Piles : Index     := 0;

      Pile_Of    : Pile_Map  := [others => 0]     with Ghost;
      Alive      : Alive_Map with Ghost;
      Alive_Prev : Alive_Map with Ghost;
      Slot_Of    : Slot_Map  with Ghost;

      X_Val    : Integer;
      J        : Positive;
      Lo, Hi   : Natural;
      Mid      : Natural;
      Best     : Positive;
      Best_Val : Integer;
      Node     : Node_Index;
      Next     : Node_Index;
      Out_I    : Cursor;
   begin
      ------------------------------------------------------------------
      -- Phase 1: deal each A (I) onto the leftmost pile whose top is
      -- >= A (I), else onto a new pile to the right.
      ------------------------------------------------------------------
      for I in 1 .. N loop
         pragma Loop_Invariant (Used = I - 1);
         pragma Loop_Invariant (Num_Piles <= Used);
         pragma Loop_Invariant
           (for all T in 1 .. Num_Piles =>
              Pile_Tops (T) in 1 .. Used
              and then Pile_Of (Pile_Tops (T)) = T);
         pragma Loop_Invariant
           (for all U in 1 .. Used =>
              Pile_Of (U) in 1 .. Num_Piles
              and then U <= Pile_Tops (Pile_Of (U)));
         pragma Loop_Invariant
           (for all U in 1 .. Used =>
              Pool (U).Below < U
              and then
                (if Pool (U).Below /= None
                 then Pile_Of (Pool (U).Below) = Pile_Of (U)));
         --  Pile order: Below is the newest older node of the same pile,
         --  and every older node of the pile is >= the newer one.
         pragma Loop_Invariant
           (for all U in 1 .. Used =>
              (for all V in 1 .. U - 1 =>
                 (if Pile_Of (V) = Pile_Of (U)
                  then V <= Pool (U).Below
                       and then Pool (V).Value >= Pool (U).Value)));

         X_Val := A (I);

         --  Binary search: leftmost pile whose top >= X_Val.
         Lo := 1;
         Hi := Num_Piles;
         while Lo <= Hi loop
            pragma Loop_Invariant (Lo in 1 .. Num_Piles + 1);
            pragma Loop_Invariant (Hi <= Num_Piles);
            pragma Loop_Invariant (Lo <= Hi + 1);
            pragma Loop_Invariant
              (Hi + 1 > Num_Piles
               or else Pool (Pile_Tops (Hi + 1)).Value >= X_Val);
            pragma Loop_Variant (Decreases => Hi + 1 - Lo);

            Mid := Lo + (Hi - Lo) / 2;

            if Pool (Pile_Tops (Mid)).Value >= X_Val then
               Hi := Mid - 1;
            else
               Lo := Mid + 1;
            end if;
         end loop;

         J := Lo;
         pragma Assert (J in 1 .. Num_Piles + 1);
         pragma Assert
           (J > Num_Piles or else Pool (Pile_Tops (J)).Value >= X_Val);

         Used := Used + 1;
         Pool (Used).Value := X_Val;
         if J <= Num_Piles then
            --  Push onto pile J: X_Val <= its top <= every older node.
            pragma Assert
              (for all V in 1 .. Used - 1 =>
                 (if Pile_Of (V) = J
                  then V <= Pile_Tops (J)
                       and then Pool (V).Value
                                  >= Pool (Pile_Tops (J)).Value));
            Pool (Used).Below := Pile_Tops (J);
            Pile_Tops (J) := Used;
            Pile_Of (Used) := J;
         else
            --  New pile to the right (no older node shares its id).
            Pool (Used).Below := None;
            Num_Piles := Num_Piles + 1;
            Pile_Tops (Num_Piles) := Used;
            Pile_Of (Used) := Num_Piles;
         end if;
      end loop;

      pragma Assert (Used = N);
      pragma Assert (Num_Piles in 1 .. N);

      ------------------------------------------------------------------
      -- Phase 2: k-way merge. Repeatedly output the smallest pile top
      -- and pop it; an emptied pile's slot is taken by the last pile.
      ------------------------------------------------------------------
      Alive := [for U in Node_Id => U <= N];
      Slot_Of := [for P in Node_Id => P];
      Lemma_Count_All (Alive, N);
      Out_I := 1;

      loop
         pragma Loop_Invariant (Out_I in 1 .. N + 1);
         pragma Loop_Invariant (Num_Piles <= N);
         pragma Loop_Invariant (Count_Alive (Alive, N) = N + 1 - Out_I);
         pragma Loop_Invariant
           (for all T in 1 .. Num_Piles =>
              Pile_Tops (T) in 1 .. N
              and then Alive (Pile_Tops (T))
              and then Slot_Of (Pile_Of (Pile_Tops (T))) = T);
         --  Every unpopped node is on a live slot and not newer than
         --  that slot's top.
         pragma Loop_Invariant
           (for all U in 1 .. N =>
              (if Alive (U)
               then Slot_Of (Pile_Of (U)) in 1 .. Num_Piles
                    and then Pile_Of (Pile_Tops (Slot_Of (Pile_Of (U))))
                               = Pile_Of (U)
                    and then U <= Pile_Tops (Slot_Of (Pile_Of (U)))));
         --  Unpopped nodes of a pile are an oldest-first prefix of it.
         pragma Loop_Invariant
           (for all U in 1 .. N =>
              (if Alive (U)
               then
                 (for all V in 1 .. U - 1 =>
                    (if Pile_Of (V) = Pile_Of (U) then Alive (V)))));
         pragma Loop_Invariant
           (for all U in 1 .. N =>
              (for all V in 1 .. U - 1 =>
                 (if Pile_Of (V) = Pile_Of (U)
                  then V <= Pool (U).Below
                       and then Pool (V).Value >= Pool (U).Value)));
         pragma Loop_Invariant
           (for all K in 1 .. Out_I - 2 => A (K) <= A (K + 1));
         pragma Loop_Invariant
           (Out_I = 1
            or else
              (for all U in 1 .. N =>
                 (if Alive (U) then A (Out_I - 1) <= Pool (U).Value)));
         pragma Loop_Variant (Decreases => N + 1 - Out_I);

         exit when Num_Piles = 0 or else Out_I > N;

         Best := 1;
         Best_Val := Pool (Pile_Tops (1)).Value;

         for Q in 2 .. Num_Piles loop
            pragma Loop_Invariant (Best in 1 .. Q - 1);
            pragma Loop_Invariant (Best_Val = Pool (Pile_Tops (Best)).Value);
            pragma Loop_Invariant
              (for all T in 1 .. Q - 1 =>
                 Best_Val <= Pool (Pile_Tops (T)).Value);

            if Pool (Pile_Tops (Q)).Value < Best_Val then
               Best := Q;
               Best_Val := Pool (Pile_Tops (Q)).Value;
            end if;
         end loop;

         --  The smallest top is <= every unpopped node (pile order).
         pragma Assert
           (for all U in 1 .. N =>
              (if Alive (U)
               then U = Pile_Tops (Slot_Of (Pile_Of (U)))
                    or else
                      (U < Pile_Tops (Slot_Of (Pile_Of (U)))
                       and then Pile_Of (U)
                                  = Pile_Of (Pile_Tops (Slot_Of (Pile_Of (U)))))));
         pragma Assert
           (for all U in 1 .. N =>
              (if Alive (U)
               then Pool (Pile_Tops (Slot_Of (Pile_Of (U)))).Value
                      <= Pool (U).Value));
         pragma Assert
           (for all U in 1 .. N =>
              (if Alive (U)
               then Best_Val <= Pool (Pile_Tops (Slot_Of (Pile_Of (U)))).Value));
         pragma Assert
           (for all U in 1 .. N =>
              (if Alive (U) then Best_Val <= Pool (U).Value));

         Node := Pile_Tops (Best);
         A (Out_I) := Pool (Node).Value;
         Out_I := Out_I + 1;

         Alive_Prev := Alive;
         Alive (Node) := False;
         Lemma_Count_Clear (Alive_Prev, Alive, Node, N);

         --  Pop; if the pile empties, the last pile takes its slot.
         Next := Pool (Node).Below;
         if Next = None then
            pragma Assert
              (for all U in 1 .. N =>
                 (if Alive (U) then Pile_Of (U) /= Pile_Of (Node)));
            pragma Assert
              (for all U in 1 .. N =>
                 (if Alive (U) then Slot_Of (Pile_Of (U)) /= Best));
            if Best < Num_Piles then
               Pile_Tops (Best) := Pile_Tops (Num_Piles);
               Slot_Of (Pile_Of (Pile_Tops (Best))) := Best;
               pragma Assert
                 (for all U in 1 .. N =>
                    (if Alive (U)
                     then Slot_Of (Pile_Of (U)) in 1 .. Num_Piles - 1
                          and then Pile_Of (Pile_Tops (Slot_Of (Pile_Of (U))))
                                     = Pile_Of (U)
                          and then U <= Pile_Tops (Slot_Of (Pile_Of (U)))));
            end if;
            Num_Piles := Num_Piles - 1;
         else
            pragma Assert (Alive (Next));
            pragma Assert (Pile_Of (Next) = Pile_Of (Node));
            pragma Assert
              (for all U in 1 .. N =>
                 (if Alive (U) and then Pile_Of (U) = Pile_Of (Node)
                  then U < Node and then U <= Next));
            Pile_Tops (Best) := Next;
         end if;
      end loop;

      --  The merge stopped: either every node is out (Out_I = N + 1), or
      --  no live slot is left, which leaves no alive node and so forces
      --  the count, N + 1 - Out_I, to zero as well.
      Lemma_None_Alive (Alive, N);
      pragma Assert (Out_I = N + 1);
   end Patience_Phase;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Patience_Phase (A);
   end Sort;

end Patience_Sorting;
