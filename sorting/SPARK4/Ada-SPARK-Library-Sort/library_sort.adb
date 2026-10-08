--  Library_Sort body: library sort (gapped insertion sort, epsilon = 1).
--  The values live in a working array W (1 .. Cap), Cap = 2 n, with free
--  slots between them.  Each new value goes to the slot found by a binary
--  search over W that skips free slots; if that slot is taken, the values
--  up to the nearest free slot (right, else left) move one place.  After
--  1, 2, 4, 8, .. insertions the values are spread out again with a free
--  slot after each.  At the end the occupied slots are packed into A.
--
--  Proof: the occupied slots of W are always in nondecreasing order
--  (Sorted_W) and there are exactly Count of them (Occ), so a free slot
--  always exists while Count < Cap and the final pack writes all n
--  values in order.  Nothing else sorts the array.

package body Library_Sort
  with SPARK_Mode => On
is

   subtype Cap_Index is Natural range 0 .. Max_Cap;
   subtype Cap_Pos is Positive range 1 .. Max_Cap;
   subtype Cap_Ext is Positive range 1 .. Max_Cap + 1;

   type Slot is record
      Occupied : Boolean := False;
      Value    : Integer := 0;
   end record;

   type Working_Array is array (Cap_Pos) of Slot;

   Free : constant Slot := (Occupied => False, Value => 0);

   ---------------------------------------------------------------------------
   -- Ghost model
   ---------------------------------------------------------------------------

   --  Number of occupied slots in W (1 .. R).
   function Occ (W : Working_Array; R : Cap_Index) return Cap_Index is
     (if R = 0 then 0
      else Occ (W, R - 1) + (if W (R).Occupied then 1 else 0))
   with
     Ghost              => True,
     Subprogram_Variant => (Decreases => R),
     Post               => Occ'Result <= R;

   --  The occupied slots of W (1 .. Cap) hold nondecreasing values.
   function Sorted_W (W : Working_Array; Cap : Cap_Index) return Boolean is
     (for all I in 1 .. Cap =>
        (for all J in I + 1 .. Cap =>
           (if W (I).Occupied and then W (J).Occupied
            then W (I).Value <= W (J).Value)))
   with Ghost => True;

   --  Every pair of A (1 .. R) is ordered.
   function Sorted_Pairs (A : Element_Array; R : Natural) return Boolean is
     (for all I in 1 .. R =>
        (for all J in I .. R => A (I) <= A (J)))
   with
     Ghost => True,
     Pre   => A'First = 1 and then R <= A'Last;

   --  Number of occupied slots in W (L .. R), counted by halving the
   --  range.  Same number as Occ (W, R) - Occ (W, L - 1) (see
   --  Lemma_Occ_In_Prefix), but a one-slot change is re-counted along one
   --  path of halves, which keeps the executed lemmas below cheap.
   function Occ_In
     (W : Working_Array; L : Cap_Pos; R : Cap_Index) return Cap_Index
   is
     (if L > R then 0
      elsif L = R then (if W (L).Occupied then 1 else 0)
      else Occ_In (W, L, (L + R) / 2) + Occ_In (W, (L + R) / 2 + 1, R))
   with
     Ghost              => True,
     Subprogram_Variant => (Decreases => R - L),
     Post               =>
       Occ_In'Result <= (if L > R then 0 else R - L + 1);

   --  Occ_In agrees with the prefix count Occ.
   procedure Lemma_Occ_In_Prefix
     (W : Working_Array; L : Cap_Pos; R : Cap_Index)
     with
       Ghost              => True,
       Subprogram_Variant => (Decreases => R - L),
       Pre                => L <= R,
       Post               => Occ (W, R) = Occ (W, L - 1) + Occ_In (W, L, R)
   is
      M : Cap_Pos;
   begin
      if L < R then
         M := (L + R) / 2;
         Lemma_Occ_In_Prefix (W, L, M);
         Lemma_Occ_In_Prefix (W, M + 1, R);
      end if;
   end Lemma_Occ_In_Prefix;

   --  Same occupancy on W1 (L .. R) and W2 (L .. R) gives the same count.
   procedure Lemma_Occ_In_Equal
     (W1, W2 : Working_Array; L : Cap_Pos; R : Cap_Index)
     with
       Ghost              => True,
       Subprogram_Variant => (Decreases => R - L),
       Pre                =>
         (for all K in L .. R => W1 (K).Occupied = W2 (K).Occupied),
       Post               => Occ_In (W1, L, R) = Occ_In (W2, L, R)
   is
      M : Cap_Pos;
   begin
      if L < R then
         M := (L + R) / 2;
         Lemma_Occ_In_Equal (W1, W2, L, M);
         Lemma_Occ_In_Equal (W1, W2, M + 1, R);
      end if;
   end Lemma_Occ_In_Equal;

   --  Changing the occupancy of one slot I in L .. R changes the count by
   --  that slot's own contribution.
   procedure Lemma_Occ_In_Update
     (W1, W2 : Working_Array; I : Cap_Pos; L : Cap_Pos; R : Cap_Index)
     with
       Ghost              => True,
       Subprogram_Variant => (Decreases => R - L),
       Pre                =>
         I in L .. R
         and then
           (for all K in L .. R =>
              (if K /= I then W1 (K).Occupied = W2 (K).Occupied)),
       Post               =>
         Occ_In (W2, L, R) + (if W1 (I).Occupied then 1 else 0)
         = Occ_In (W1, L, R) + (if W2 (I).Occupied then 1 else 0)
   is
      M : Cap_Pos;
   begin
      if L < R then
         M := (L + R) / 2;
         if I <= M then
            Lemma_Occ_In_Update (W1, W2, I, L, M);
            Lemma_Occ_In_Equal (W1, W2, M + 1, R);
         else
            Lemma_Occ_In_Equal (W1, W2, L, M);
            Lemma_Occ_In_Update (W1, W2, I, M + 1, R);
         end if;
      end if;
   end Lemma_Occ_In_Update;

   --  Number of odd I in 1 .. X with I < 2 Count.
   function Odd_Below
     (X : Cap_Index; Count : Cap_Index) return Cap_Index
   is
     ((Natural'Min (X, 2 * Count) + 1) / 2)
   with
     Ghost => True,
     Pre   => 2 * Count <= Max_Cap;

   --  W (L .. R) occupied exactly at the odd slots below 2 Count (the
   --  layout Spread writes) gives Occ_In = Odd_Below (R) - Odd_Below (L - 1).
   procedure Lemma_Spread_Count
     (W : Working_Array; Count : Cap_Index; L : Cap_Pos; R : Cap_Index)
     with
       Ghost              => True,
       Subprogram_Variant => (Decreases => R - L),
       Pre                =>
         2 * Count <= Max_Cap
         and then L <= R
         and then
           (for all I in L .. R =>
              W (I).Occupied = (I mod 2 = 1 and then I < 2 * Count)),
       Post               =>
         Occ_In (W, L, R)
         = Odd_Below (R, Count) - Odd_Below (L - 1, Count)
   is
      M : Cap_Pos;
   begin
      if L < R then
         M := (L + R) / 2;
         Lemma_Spread_Count (W, Count, L, M);
         Lemma_Spread_Count (W, Count, M + 1, R);
      end if;
   end Lemma_Spread_Count;

   ---------------------------------------------------------------------------
   -- Library sort steps
   ---------------------------------------------------------------------------

   --  Binary search over W (1 .. Cap) that skips free slots.  Result: every
   --  occupied slot before it holds a value <= X, every occupied slot from
   --  it on holds a value > X (so equal keys keep their order).  The slot
   --  just before the result is occupied (or the result is 1), so the
   --  result never lies beyond the first slot after the last value.
   function Search
     (W : Working_Array; Cap : Cap_Pos; X : Integer) return Cap_Ext
     with
       Pre  => Sorted_W (W, Cap),
       Post =>
         Search'Result <= Cap + 1
         and then (Search'Result = 1 or else W (Search'Result - 1).Occupied)
         and then
           (for all I in 1 .. Search'Result - 1 =>
              (if W (I).Occupied then W (I).Value <= X))
         and then
           (for all I in Search'Result .. Cap =>
              (if W (I).Occupied then X < W (I).Value))
   is
      Lo  : Cap_Ext := 1;
      Hi  : Cap_Index := Cap;
      Mid : Cap_Pos;
      M   : Cap_Index;
   begin
      while Lo <= Hi loop
         pragma Loop_Invariant (Hi <= Cap);
         pragma Loop_Invariant (Lo = 1 or else W (Lo - 1).Occupied);
         pragma Loop_Invariant
           (for all I in 1 .. Lo - 1 =>
              (if W (I).Occupied then W (I).Value <= X));
         pragma Loop_Invariant
           (for all I in Hi + 1 .. Cap =>
              (if W (I).Occupied then X < W (I).Value));
         pragma Loop_Variant (Decreases => Hi - Lo);

         Mid := Lo + (Hi - Lo) / 2;

         --  Nearest occupied slot at or after Mid within Lo .. Hi, else
         --  at or before Mid.
         M := Mid;
         while M < Hi and then not W (M).Occupied loop
            pragma Loop_Invariant (M in Mid .. Hi - 1);
            pragma Loop_Invariant
              (for all I in Mid .. M => not W (I).Occupied);
            pragma Loop_Variant (Increases => M);
            M := M + 1;
         end loop;

         if not W (M).Occupied then
            --  W (Mid .. Hi) is free; look left of Mid.
            pragma Assert (for all I in Mid .. Hi => not W (I).Occupied);
            M := Mid;
            while M > Lo and then not W (M).Occupied loop
               pragma Loop_Invariant (M in Lo + 1 .. Mid);
               pragma Loop_Invariant
                 (for all I in M .. Hi => not W (I).Occupied);
               pragma Loop_Variant (Decreases => M);
               M := M - 1;
            end loop;
            if not W (M).Occupied then
               --  W (Lo .. Hi) is all free.
               pragma Assert (for all I in Lo .. Hi => not W (I).Occupied);
               return Lo;
            end if;
            pragma Assert (for all I in M + 1 .. Hi => not W (I).Occupied);
         end if;

         pragma Assert (M in Lo .. Hi and then W (M).Occupied);
         if W (M).Value <= X then
            pragma Assert
              (for all I in Lo .. M =>
                 (if W (I).Occupied then W (I).Value <= W (M).Value));
            Lo := M + 1;
         else
            pragma Assert
              (for all I in M .. Cap =>
                 (if W (I).Occupied then W (M).Value <= W (I).Value));
            Hi := M - 1;
         end if;
      end loop;
      return Lo;
   end Search;

   --  Insert X into W (1 .. Cap), keeping the occupied slots in order.
   --  The last slot must be free, so a free slot exists at or right of
   --  the search result (Sort keeps the tail of W free: see there).  If W
   --  was free from some slot T on, it stays free from T + 1 on.
   procedure Insert
     (W     : in out Working_Array;
      Cap   : Cap_Pos;
      Count : Cap_Index;
      X     : Integer)
     with
       Pre  =>
         Count < Cap
         and then Occ_In (W, 1, Cap) = Count
         and then Sorted_W (W, Cap)
         and then not W (Cap).Occupied,
       Post =>
         Occ_In (W, 1, Cap) = Count + 1
         and then Sorted_W (W, Cap)
         and then
           (for all T in 1 .. Cap =>
              (if (for all I in T .. Cap => not W'Old (I).Occupied)
               then (for all I in T + 1 .. Cap => not W (I).Occupied)))
   is
      Pos : constant Cap_Ext := Search (W, Cap, X);
      J   : Cap_Pos;
      K   : Cap_Pos;
      Old : constant Working_Array := W with Ghost;
   begin
      pragma Assert (Pos <= Cap);

      --  Nearest free slot at or right of Pos (W (Cap) is free).
      J := Pos;
      while W (J).Occupied loop
         pragma Loop_Invariant (J in Pos .. Cap - 1);
         pragma Loop_Invariant (for all I in Pos .. J => W (I).Occupied);
         pragma Loop_Variant (Increases => J);
         J := J + 1;
      end loop;

      --  Move W (Pos .. J - 1) to W (Pos + 1 .. J), then put X at Pos.
      K := J;
      while K > Pos loop
         pragma Loop_Invariant (K in Pos + 1 .. J);
         pragma Loop_Invariant
           (for all I in 1 .. Cap =>
              W (I) = (if I in K + 1 .. J then Old (I - 1) else Old (I)));
         pragma Loop_Variant (Decreases => K);
         W (K) := W (K - 1);
         K := K - 1;
      end loop;
      W (Pos) := (Occupied => True, Value => X);

      pragma Assert
        (for all I in 1 .. Cap =>
           (if I /= J then W (I).Occupied = Old (I).Occupied));
      Lemma_Occ_In_Update (Old, W, J, 1, Cap);
      pragma Assert
        (for all I in 1 .. Cap =>
           (if W (I).Occupied
            then (if I < Pos then W (I).Value <= X
                  elsif I > Pos then X < W (I).Value)));
      pragma Assert (for all I in J + 1 .. Cap => W (I) = Old (I));
   end Insert;

   --  Copy the occupied values of W (1 .. Cap), in slot order, to
   --  Dense (1 .. Count).
   procedure Gather
     (W     : Working_Array;
      Cap   : Cap_Pos;
      Dense : out Element_Array;
      Count : out Cap_Index)
     with
       Pre  =>
         Dense'First = 1
         and then Dense'Last = Max_Cap
         and then Sorted_W (W, Cap),
       Post =>
         Count = Occ_In (W, 1, Cap)
         and then Sorted_Pairs (Dense, Count)
   is
   begin
      Dense := [others => 0];
      Count := 0;
      for I in 1 .. Cap loop
         pragma Loop_Invariant (Count = Occ (W, I - 1));
         pragma Loop_Invariant (Sorted_Pairs (Dense, Count));
         pragma Loop_Invariant
           (Count = 0
            or else (for all S in I .. Cap =>
                       (if W (S).Occupied then Dense (Count) <= W (S).Value)));

         if W (I).Occupied then
            Count := Count + 1;
            Dense (Count) := W (I).Value;
         end if;
      end loop;
      Lemma_Occ_In_Prefix (W, 1, Cap);
   end Gather;

   --  Rewrite W (1 .. Cap) with Dense (1 .. Count) at slots 1, 3, 5, ..,
   --  2 Count - 1: one free slot after each value.
   procedure Spread
     (W     : out Working_Array;
      Cap   : Cap_Pos;
      Dense : Element_Array;
      Count : Cap_Index)
     with
       Pre  =>
         Dense'First = 1
         and then Dense'Last = Max_Cap
         and then Count >= 1
         and then 2 * Count <= Cap
         and then Sorted_Pairs (Dense, Count),
       Post =>
         Occ_In (W, 1, Cap) = Count
         and then Sorted_W (W, Cap)
         and then (for all I in 2 * Count .. Cap => not W (I).Occupied)
   is
   begin
      W := [others => Free];
      for K in 1 .. Count loop
         pragma Loop_Invariant
           (for all I in 1 .. Cap =>
              (if I mod 2 = 1 and then I < 2 * K - 1
               then W (I) = (Occupied => True, Value => Dense ((I + 1) / 2))
               else not W (I).Occupied));
         W (2 * K - 1) := (Occupied => True, Value => Dense (K));
      end loop;
      pragma Assert
        (for all I in 1 .. Cap =>
           (if I mod 2 = 1 and then I < 2 * Count
            then W (I) = (Occupied => True, Value => Dense ((I + 1) / 2))
            else not W (I).Occupied));
      pragma Assert (for all I in 2 * Count .. Cap => not W (I).Occupied);
      Lemma_Spread_Count (W, Count, 1, Cap);
   end Spread;

   procedure Sort (A : in out Element_Array) is
      N         : constant Index := A'Last;
      W         : Working_Array;
      Dense     : Element_Array (1 .. Max_Cap);
      Cap       : Cap_Pos;
      Count     : Index;
      Next_Goal : Positive range 1 .. Max_Cap;
      K         : Cap_Index;
   begin
      if N <= 1 then
         return;
      end if;
      Cap := 2 * N;

      Dense := [others => 0];
      Dense (1) := A (1);
      Spread (W, Cap, Dense, 1);
      Count := 1;
      Next_Goal := 1;

      for Src in 2 .. N loop
         pragma Loop_Invariant (Count = Src - 1);
         pragma Loop_Invariant (Count <= Next_Goal);
         pragma Loop_Invariant (Next_Goal <= 2 * Count);
         pragma Loop_Invariant (Occ_In (W, 1, Cap) = Count);
         pragma Loop_Invariant (Sorted_W (W, Cap));
         --  Slots from Count + Next_Goal / 2 on are free: a rebalance with
         --  g values leaves slots 2 g .. Cap free and each insertion fills
         --  at most one slot past the last value.  Since that bound stays
         --  below Cap, W (Cap) is free for every insertion.
         pragma Loop_Invariant
           (Count = Next_Goal
            or else (for all I in Count + Next_Goal / 2 .. Cap =>
                       not W (I).Occupied));

         --  Rebalance after 1, 2, 4, 8, .. insertions.
         if Count = Next_Goal then
            Gather (W, Cap, Dense, K);
            Spread (W, Cap, Dense, K);
            Next_Goal := 2 * Next_Goal;
         end if;
         pragma Assert
           (for all I in Count + Next_Goal / 2 .. Cap => not W (I).Occupied);
         pragma Assert (Count + Next_Goal / 2 < Cap);

         Insert (W, Cap, Count, A (Src));
         pragma Assert
           (for all I in Count + Next_Goal / 2 + 1 .. Cap =>
              not W (I).Occupied);
         Count := Count + 1;
      end loop;

      --  Pack the occupied slots, in order, into A (1 .. N).
      Gather (W, Cap, Dense, K);
      pragma Assert (K = N);
      A := Dense (1 .. N);
      pragma Assert (Sorted_Pairs (A, N));
   end Sort;

end Library_Sort;
