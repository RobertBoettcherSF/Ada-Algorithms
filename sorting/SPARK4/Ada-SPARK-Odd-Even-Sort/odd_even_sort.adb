--  Odd_Even_Sort body — SPARK Level 4 sequential odd–even / brick sort.
--  Odd-then-even neighbour-swap cycles run until a cycle makes no swap;
--  that cycle has found every neighbour pair in order (Is_Sorted), and
--  termination is proved by the ghost Weight (A) = sum of
--  (K - A'First + 1) * A (K), which every swap of an out-of-order pair
--  raises. Phases and weights use the offset from A'First. No fallback
--  pass, no cap.

package body Odd_Even_Sort
  with SPARK_Mode => On
is
   --  Same_Occ quantifies over every Integer value, so contracts and
   --  invariants of this body (all proved by gnatprove) are not checked at
   --  run time; the Post of Sort in the spec (sorted, Is_Perm) still is.
   pragma Assertion_Policy
     (Pre => Ignore, Post => Ignore, Loop_Invariant => Ignore, Assert => Ignore);

   --  Adjacent nondecreasing on A (L .. R). Vacuous when L >= R.
   --  Termination measure: Weight (A) = 1 * A (A'First) + 2 * A (A'First
   --  + 1) + ... (position P = K - A'First + 1 weighs A (K)); a
   --  swap of an out-of-order neighbour pair (A (I) > A (I + 1)) raises it
   --  by A (I) - A (I + 1) >= 1, and it is bounded, so the cycles end.
   function Same_Occ (A, B : Element_Array) return Boolean is
     (A'First = B'First
      and then A'Last = B'Last
      and then (A'Length = 0
                or else (for all V in Integer =>
                           Occ (A, V, A'Last) = Occ (B, V, B'Last))))
   with
     Ghost,
     Global => null,
     Pre    => In_Bounds (A) and then In_Bounds (B);

   package Perm_Lemmas
     with Ghost
   is
      pragma Assertion_Policy (Pre => Ignore, Post => Ignore);

      --  Counts over A'First .. Last only see A'First .. Last.
      procedure Lemma_Occ_Frame (A, B : Element_Array; Last : Natural)
      with
        Global             => null,
        Pre                =>
          In_Bounds (A) and then In_Bounds (B)
          and then A'First = B'First
          and then Last <= A'Last and then Last <= B'Last
          and then (for all K in A'First .. Last => A (K) = B (K)),
        Post               =>
          (for all V in Integer => Occ (A, V, Last) = Occ (B, V, Last)),
        Subprogram_Variant => (Decreases => Last);

      --  B is A with slot K changed.
      procedure Lemma_Occ_Set
        (A, B : Element_Array; K : Live_Index; Last : Natural)
      with
        Global             => null,
        Pre                =>
          In_Bounds (A) and then In_Bounds (B)
          and then A'First = B'First and then A'Last = B'Last
          and then K in A'Range and then Last in K .. A'Last
          and then (for all J in A'Range => (if J /= K then A (J) = B (J))),
        Post               =>
          (for all V in Integer =>
             Occ (B, V, Last)
             = Occ (A, V, Last)
               - (if A (K) = V then 1 else 0)
               + (if B (K) = V then 1 else 0)),
        Subprogram_Variant => (Decreases => Last);

      --  B is A with slots X and Y exchanged.
      procedure Lemma_Swap (A, B : Element_Array; X, Y : Live_Index)
      with
        Global => null,
        Pre    =>
          In_Bounds (A) and then In_Bounds (B)
          and then A'First = B'First and then A'Last = B'Last
          and then X in A'Range and then Y in A'Range
          and then B (X) = A (Y) and then B (Y) = A (X)
          and then (for all J in A'Range =>
                      (if J /= X and then J /= Y then A (J) = B (J))),
        Post   => Same_Occ (A, B);

      procedure Lemma_Same_Perm (A, B : Element_Array)
      with
        Global => null,
        Pre    => In_Bounds (A) and then In_Bounds (B) and then Same_Occ (A, B),
        Post   => Is_Perm (A, B);
   end Perm_Lemmas;

   package body Perm_Lemmas is

      procedure Lemma_Occ_Frame (A, B : Element_Array; Last : Natural) is
      begin
         if Last >= A'First then
            Lemma_Occ_Frame (A, B, Last - 1);
         end if;
      end Lemma_Occ_Frame;

      procedure Lemma_Occ_Set
        (A, B : Element_Array; K : Live_Index; Last : Natural) is
      begin
         if Last > K then
            Lemma_Occ_Set (A, B, K, Last - 1);
         else
            Lemma_Occ_Frame (A, B, K - 1);
         end if;
      end Lemma_Occ_Set;

      procedure Lemma_Swap (A, B : Element_Array; X, Y : Live_Index) is
      begin
         if X = Y then
            Lemma_Occ_Frame (A, B, A'Last);
            return;
         end if;
         declare
            C : constant Element_Array := (A with delta X => A (Y));
         begin
            Lemma_Occ_Set (A, C, X, A'Last);
            Lemma_Occ_Set (C, B, Y, A'Last);
         end;
      end Lemma_Swap;

      procedure Lemma_Same_Perm (A, B : Element_Array) is null;

   end Perm_Lemmas;
   use Perm_Lemmas;

   Elem_Bound : constant := 2 ** 31;
   Term_Bound : constant := Max_N * Elem_Bound;   --  bound on one K * A (K)

   --  Position of index K counted from A'First (1 for A'First).
   function Pos (A : Element_Array; K : Integer) return Long_Long_Integer is
     (Long_Long_Integer (K) - Long_Long_Integer (A'First) + 1)
   with
     Ghost  => True,
     Global => null;

   --  Sum of Pos (K) * A (K) for K in A'First .. J (0 when J < A'First).
   function Weight_To (A : Element_Array; J : Index) return Long_Long_Integer is
     (if J < A'First then 0
      else Weight_To (A, J - 1) + Pos (A, J) * Long_Long_Integer (A (J)))
   with
     Ghost              => True,
     Global             => null,
     Pre                =>
       In_Bounds (A) and then J >= A'First - 1 and then J <= A'Last,
     Post               =>
       Weight_To'Result
         in -(Pos (A, J) * Term_Bound) .. Pos (A, J) * Term_Bound,
     Subprogram_Variant => (Decreases => J);

   function Weight (A : Element_Array) return Long_Long_Integer is
     (if A'Length = 0 then 0 else Weight_To (A, A'Last))
   with
     Ghost  => True,
     Global => null,
     Pre    => In_Bounds (A);

   --  Swapping A (I) and A (I + 1) changes the partial weights only from
   --  index I on: by Pos (I) * (A (I + 1) - A (I)) at I, by
   --  A (I) - A (I + 1) after.
   procedure Lemma_Swap_Weight
     (Old_A, New_A : Element_Array; I : Positive; J : Index)
     with
       Ghost              => True,
       Global             => null,
       Pre                =>
         In_Bounds (Old_A)
         and then In_Bounds (New_A)
         and then Old_A'First = New_A'First
         and then Old_A'Last = New_A'Last
         and then I >= Old_A'First
         and then I < Old_A'Last
         and then J >= Old_A'First - 1
         and then J <= Old_A'Last
         and then New_A (I) = Old_A (I + 1)
         and then New_A (I + 1) = Old_A (I)
         and then (for all K in Old_A'Range =>
                     (if K /= I and then K /= I + 1 then New_A (K) = Old_A (K))),
       Post               =>
         Weight_To (New_A, J) = Weight_To (Old_A, J)
           + (if J > I then Long_Long_Integer (Old_A (I)) - Long_Long_Integer (Old_A (I + 1))
              elsif J = I then Pos (Old_A, I)
                * (Long_Long_Integer (Old_A (I + 1)) - Long_Long_Integer (Old_A (I)))
              else 0),
       Subprogram_Variant => (Decreases => J)
   is
      X : constant Long_Long_Integer := Long_Long_Integer (Old_A (I)) with Ghost;
      Y : constant Long_Long_Integer := Long_Long_Integer (Old_A (I + 1)) with Ghost;
      LI : constant Long_Long_Integer := Pos (Old_A, I) with Ghost;
   begin
      if J < Old_A'First then
         return;
      end if;
      Lemma_Swap_Weight (Old_A, New_A, I, J - 1);
      if J = I then
         pragma Assert (New_A (J) = Old_A (I + 1));
         pragma Assert (Pos (New_A, J) = LI);
         pragma Assert (Pos (New_A, J) * Long_Long_Integer (New_A (J)) = LI * Y);
         pragma Assert (Weight_To (New_A, J) = Weight_To (New_A, J - 1) + LI * Y);
         pragma Assert (Weight_To (Old_A, J) = Weight_To (Old_A, J - 1) + LI * X);
         pragma Assert (Weight_To (New_A, J - 1) = Weight_To (Old_A, J - 1));
         pragma Assert (LI * Y - LI * X = LI * (Y - X));
      elsif J = I + 1 then
         pragma Assert (Pos (New_A, J) = LI + 1);
         pragma Assert (Pos (Old_A, J) = LI + 1);
         pragma Assert (New_A (J) = Old_A (I));
         pragma Assert
           (Pos (New_A, J) * Long_Long_Integer (New_A (J)) = (LI + 1) * X);
         pragma Assert
           (Pos (Old_A, J) * Long_Long_Integer (Old_A (J)) = (LI + 1) * Y);
         pragma Assert (Weight_To (New_A, J) = Weight_To (New_A, J - 1) + (LI + 1) * X);
         pragma Assert (Weight_To (Old_A, J) = Weight_To (Old_A, J - 1) + (LI + 1) * Y);
         pragma Assert (Weight_To (New_A, J - 1) = Weight_To (Old_A, J - 1) + LI * (Y - X));
         pragma Assert ((LI + 1) * X = LI * X + X);
         pragma Assert ((LI + 1) * Y = LI * Y + Y);
         pragma Assert (LI * (Y - X) = LI * Y - LI * X);
      else
         pragma Assert (New_A (J) = Old_A (J));
         pragma Assert (Weight_To (New_A, J) - Weight_To (New_A, J - 1)
                        = Weight_To (Old_A, J) - Weight_To (Old_A, J - 1));
      end if;
   end Lemma_Swap_Weight;

   --  Exchange the out-of-order neighbours A (I) > A (I + 1); Weight grows.
   procedure Swap_Up (A : in out Element_Array; I : Positive)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then I >= A'First
         and then I < A'Last
         and then A (I) > A (I + 1),
       Post   =>
         In_Bounds (A)
         and then A (I) = A'Old (I + 1)
         and then A (I + 1) = A'Old (I)
         and then
           (for all K in A'Range =>
              (if K /= I and then K /= I + 1 then A (K) = A'Old (K)))
         and then Weight (A) >= Weight (A'Old) + 1
         and then Same_Occ (A, A'Old)
   is
      Before : constant Element_Array := A with Ghost;
      T : constant Integer := A (I);
   begin
      A (I) := A (I + 1);
      A (I + 1) := T;
      Lemma_Swap_Weight (Before, A, I, A'Last);
      Lemma_Swap (Before, A, I, I + 1);
   end Swap_Up;

   --  One phase over the neighbour pairs (K, K + 1) whose position
   --  P = K - A'First + 1 has P rem 2 = Parity: Parity 0 is the odd phase
   --  (positions (2,3), (4,5), ...; Wikipedia 0-based offsets 1, 3, 5,
   --  ...), Parity 1 the even phase (positions (1,2), (3,4), ...; offsets
   --  0, 2, 4, ...). Without a swap the array is unchanged and
   --  every pair of this parity is in order; with one, Weight grew.
   subtype Parity_Bit is Natural range 0 .. 1;

   function Pairs_Ordered (A : Element_Array; Parity : Parity_Bit; Upto : Natural) return Boolean is
     (for all K in A'First .. Upto =>
        (if (K - A'First + 1) rem 2 = Parity and then K < A'Last
         then A (K) <= A (K + 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    => In_Bounds (A) and then Upto <= A'Last;

   procedure Phase
     (A : in out Element_Array; Parity : Parity_Bit; Swapped : out Boolean)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   =>
         In_Bounds (A)
         and then Same_Occ (A, A'Old)
         and then
           (if Swapped then Weight (A) >= Weight (A'Old) + 1
            else A = A'Old
                 and then Weight (A) = Weight (A'Old)
                 and then Pairs_Ordered (A, Parity, A'Last))
   is
      --  First K whose position K - A'First + 1 has rem 2 = Parity.
      I : Positive := A'First + (if Parity = 0 then 1 else 0);
      W_Entry : constant Long_Long_Integer := Weight (A) with Ghost;
      A_Entry : constant Element_Array := A with Ghost;
   begin
      Swapped := False;
      while I < A'Last loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (A'Last = A_Entry'Last);
         pragma Loop_Invariant (Same_Occ (A, A_Entry));
         pragma Loop_Invariant (I <= A'Last - 1);
         pragma Loop_Invariant (I >= A'First);
         pragma Loop_Invariant ((I - A'First + 1) rem 2 = Parity);
         pragma Loop_Invariant (if Swapped then Weight (A) >= W_Entry + 1 else Weight (A) = W_Entry);
         pragma Loop_Invariant
           (if not Swapped then A = A_Entry and then Pairs_Ordered (A, Parity, I - 1));
         pragma Loop_Variant (Increases => I);

         if A (I) > A (I + 1) then
            declare
               W : constant Long_Long_Integer := Weight (A) with Ghost;
            begin
               pragma Assert (W >= W_Entry);
               Swap_Up (A, I);
               pragma Assert (Weight (A) >= W + 1);
            end;
            Swapped := True;
         end if;
         pragma Assert (if Swapped then Weight (A) >= W_Entry + 1);
         pragma Assert
           (if not Swapped then Pairs_Ordered (A, Parity, I + 1));

         exit when A'Last - I < 2;
         I := I + 2;
      end loop;
      pragma Assert (if not Swapped then Pairs_Ordered (A, Parity, A'Last));
      pragma Assert (if Swapped then Weight (A) >= W_Entry + 1 else Weight (A) = W_Entry);
   end Phase;

   --  One full odd-then-even cycle. Swapped is True iff any neighbour pair
   --  was exchanged; without a swap every neighbour pair is in order.
   procedure Odd_Even_Cycle
     (A       : in out Element_Array;
      Swapped : out Boolean)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   =>
         In_Bounds (A)
         and then Same_Occ (A, A'Old)
         and then
           (if Swapped then Weight (A) >= Weight (A'Old) + 1
            else Is_Sorted (A))
   is
      Odd_Swapped, Even_Swapped : Boolean;
      W0 : constant Long_Long_Integer := Weight (A) with Ghost;
      A0 : constant Element_Array := A with Ghost;
   begin
      Phase (A, 0, Odd_Swapped);
      pragma Assert (if Odd_Swapped then Weight (A) >= W0 + 1 else A = A0);
      declare
         W1 : constant Long_Long_Integer := Weight (A) with Ghost;
         A1 : constant Element_Array := A with Ghost;
      begin
         pragma Assert (if Odd_Swapped then W1 >= W0 + 1 else W1 = W0);
         Phase (A, 1, Even_Swapped);
         pragma Assert (if Even_Swapped then Weight (A) >= W1 + 1 else A = A1);
         pragma Assert (if Even_Swapped then Weight (A) >= W1 + 1 else Weight (A) = W1);
         pragma Assert (if Odd_Swapped or else Even_Swapped then Weight (A) >= W0 + 1);
         if not Odd_Swapped and then not Even_Swapped then
            pragma Assert (A = A1);
            pragma Assert (Pairs_Ordered (A1, 0, A'Last));
            pragma Assert (Pairs_Ordered (A, 0, A'Last));
            pragma Assert (Pairs_Ordered (A, 1, A'Last));
            pragma Assert
              (for all K in A'First .. A'Last - 1 => A (K) <= A (K + 1));
         end if;
      end;
      Swapped := Odd_Swapped or else Even_Swapped;
   end Odd_Even_Cycle;

   procedure Sort (A : in out Element_Array) is
      Swapped : Boolean;
      Orig    : constant Element_Array := A with Ghost;
   begin
      if A'Length <= 1 then
         Lemma_Same_Perm (A, Orig);
         return;
      end if;

      --  Odd-even cycles until a cycle makes no swap (that cycle has found
      --  every neighbour pair in order). Each other cycle raises Weight by
      --  at least 1, and Weight is bounded, which proves termination.
      loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Same_Occ (A, Orig));
         pragma Loop_Invariant (A'Length >= 2);
         pragma Loop_Variant (Increases => Weight (A));

         Odd_Even_Cycle (A, Swapped);
         exit when not Swapped;
      end loop;
      Lemma_Same_Perm (A, Orig);
   end Sort;

end Odd_Even_Sort;
