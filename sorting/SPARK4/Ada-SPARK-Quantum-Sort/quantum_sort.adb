--  Quantum_Sort body — SPARK Level 4 classical educational models of
--  quantum-sorting notions. Comparison proves via Insert_Step;
--  Parallel_Network via Gap_Pass + Insertion_Pass; Frequency via
--  Select_Min_Step; Space_Bounded via cocktail shaker passes that carry
--  a sorted-prefix / sorted-suffix window invariant (no bubble finish).

package body Quantum_Sort
  with SPARK_Mode => On
is
   --  Same_Occ quantifies over every Integer value, so contracts and
   --  invariants of this body (all proved by gnatprove) are not checked at
   --  run time; the Posts of the Sort_* procedures in the spec (sorted,
   --  Is_Perm) still are.
   pragma Assertion_Policy
     (Pre => Ignore, Post => Ignore, Loop_Invariant => Ignore, Assert => Ignore);

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
        (A, B : Element_Array; K : Positive; Last : Natural)
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
      procedure Lemma_Swap (A, B : Element_Array; X, Y : Positive)
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

      --  The executable Is_Perm and the logical Same_Occ agree.
      procedure Lemma_Same_Perm (A, B : Element_Array)
      with
        Global => null,
        Pre    => In_Bounds (A) and then In_Bounds (B) and then Same_Occ (A, B),
        Post   => Is_Perm (A, B);

      procedure Lemma_Same_Trans (A, B, C : Element_Array)
      with
        Global => null,
        Pre    => In_Bounds (A) and then In_Bounds (B) and then In_Bounds (C)
                  and then Same_Occ (A, B) and then Same_Occ (B, C),
        Post   => Same_Occ (A, C);
   end Perm_Lemmas;

   package body Perm_Lemmas is

      procedure Lemma_Occ_Frame (A, B : Element_Array; Last : Natural) is
      begin
         if Last >= A'First then
            Lemma_Occ_Frame (A, B, Last - 1);
         end if;
      end Lemma_Occ_Frame;

      procedure Lemma_Occ_Set
        (A, B : Element_Array; K : Positive; Last : Natural) is
      begin
         if Last > K then
            Lemma_Occ_Set (A, B, K, Last - 1);
         else
            Lemma_Occ_Frame (A, B, K - 1);
         end if;
      end Lemma_Occ_Set;

      procedure Lemma_Swap (A, B : Element_Array; X, Y : Positive) is
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

      procedure Lemma_Same_Trans (A, B, C : Element_Array) is null;

   end Perm_Lemmas;
   use Perm_Lemmas;


   --  Marcin Ciura gaps that fit Max_N = 64 (descending), ending with 1.
   Gaps : constant array (Positive range <>) of Positive :=
     [57, 23, 10, 4, 1];

   ---------------------------------------------------------------------------
   -- Ghost helpers
   ---------------------------------------------------------------------------

   --  Adjacent nondecreasing on A (L .. R). Vacuous when L >= R.
   function Sorted_Slice
     (A : Element_Array; L, R : Natural) return Boolean
   is
     (L >= R
      or else (for all K in L .. R - 1 => A (K) <= A (K + 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= 1
       and then R <= A'Last;

   --  Every element of A (Lo_P .. Hi_P) is <= every element of A (Lo_S .. Hi_S).
   function Prefix_Leq_Suffix
     (A                      : Element_Array;
      Lo_P, Hi_P, Lo_S, Hi_S : Natural) return Boolean
   is
     (Hi_P < Lo_P
      or else Hi_S < Lo_S
      or else
        (for all K in Lo_P .. Hi_P =>
           (for all L in Lo_S .. Hi_S => A (K) <= A (L))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Lo_P >= 1
       and then Hi_P <= A'Last
       and then Lo_S >= 1
       and then Hi_S <= A'Last;

   procedure Swap (A : in out Element_Array; X, Y : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then X in 1 .. A'Last
         and then Y in 1 .. A'Last,
       Post   =>
         In_Bounds (A)
         and then A (X) = A'Old (Y)
         and then A (Y) = A'Old (X)
         and then
           (for all K in 1 .. A'Last =>
              (if K /= X and then K /= Y then A (K) = A'Old (K)))
         and then Same_Occ (A'Old, A)
   is
      T  : Integer;
      A0 : constant Element_Array := A with Ghost;
   begin
      if X = Y then
         Lemma_Occ_Frame (A0, A, A'Last);
         return;
      end if;
      T     := A (X);
      A (X) := A (Y);
      A (Y) := T;
      Lemma_Swap (A0, A, X, Y);
   end Swap;

   ---------------------------------------------------------------------------
   -- Insertion helpers (Comparison + Parallel Network gap-1 finish)
   ---------------------------------------------------------------------------

   procedure Insert_Step (A : in out Element_Array; I : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then I in 2 .. A'Last
         and then Sorted_Slice (A, 1, I - 1),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, 1, I)
         and then (for all K in I + 1 .. A'Last => A (K) = A'Old (K))
         and then Same_Occ (A'Old, A)
   is
      Key : constant Integer := A (I);
      J   : Index := I;
      A0  : constant Element_Array := A with Ghost;
      Prev : Element_Array (A'Range) with Ghost;
   begin
      Lemma_Occ_Frame (A0, A, A'Last);
      --  Insertion by adjacent exchanges: Key moves down past every
      --  larger neighbour.
      while J > 1 and then Key < A (J - 1) loop
         pragma Loop_Invariant (J <= I);
         pragma Loop_Invariant (A (J) = Key);
         pragma Loop_Invariant (Sorted_Slice (A, 1, J - 1));
         pragma Loop_Invariant (Sorted_Slice (A, J + 1, I));
         pragma Loop_Invariant
           (for all K in J + 1 .. I => A (K) > Key);
         pragma Loop_Invariant
           (if J < I and then J > 1 then A (J - 1) <= A (J + 1));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant (Same_Occ (A0, A));
         pragma Loop_Variant (Decreases => J);

         Prev := A;
         Swap (A, J - 1, J);
         Lemma_Same_Trans (A0, Prev, A);
         J := J - 1;
      end loop;

      pragma Assert (J in 1 .. I);
      pragma Assert (Sorted_Slice (A, 1, J - 1));
      pragma Assert (Sorted_Slice (A, J + 1, I));
      pragma Assert (for all K in J + 1 .. I => A (K) > Key);
      pragma Assert (J = 1 or else A (J - 1) <= Key);
      pragma Assert (A (J) = Key);

      pragma Assert (if J > 1 then A (J - 1) <= A (J));
      pragma Assert (if J < I then A (J) <= A (J + 1));
      pragma Assert (Sorted_Slice (A, 1, I));
   end Insert_Step;

   procedure Insertion_Pass (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A) and then Is_Sorted (A) and then Same_Occ (A'Old, A)
   is
      A0   : constant Element_Array := A with Ghost;
      Prev : Element_Array (A'Range) with Ghost;
   begin
      Lemma_Occ_Frame (A0, A, A'Last);
      pragma Assert (Sorted_Slice (A, 1, 1));

      for I in 2 .. A'Last loop
         Prev := A;
         Insert_Step (A, I);
         Lemma_Same_Trans (A0, Prev, A);

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Same_Occ (A0, A));
         pragma Loop_Invariant (Sorted_Slice (A, 1, I));
         pragma Loop_Invariant (Is_Sorted (A (1 .. I)));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last =>
              A (K) = A'Loop_Entry (K));
      end loop;
   end Insertion_Pass;

   --  h-sort for Gap > 1: only In_Bounds / RTE (sortedness from gap 1).
   procedure Gap_Pass (A : in out Element_Array; Gap : Positive)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 2
         and then Gap in 2 .. A'Last - 1,
       Post   => In_Bounds (A) and then Same_Occ (A'Old, A)
   is
      Key  : Integer;
      J    : Index;
      A0   : constant Element_Array := A with Ghost;
      Prev : Element_Array (A'Range) with Ghost;
   begin
      Lemma_Occ_Frame (A0, A, A'Last);
      for I in Gap + 1 .. A'Last loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (I in Gap + 1 .. A'Last + 1);
         pragma Loop_Invariant (Same_Occ (A0, A));

         Key := A (I);
         J   := I;

         --  Gapped insertion by exchanges: Key moves down Gap at a time
         --  past every larger element.
         while J >= Gap + 1 and then A (J - Gap) > Key loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (J in Gap + 1 .. I);
            pragma Loop_Invariant (J <= A'Last);
            pragma Loop_Invariant (A (J) = Key);
            pragma Loop_Invariant (Same_Occ (A0, A));
            pragma Loop_Variant (Decreases => J);

            Prev := A;
            Swap (A, J - Gap, J);
            Lemma_Same_Trans (A0, Prev, A);
            J := J - Gap;
         end loop;
      end loop;
   end Gap_Pass;

   ---------------------------------------------------------------------------
   -- Selection helper (Frequency)
   ---------------------------------------------------------------------------

   procedure Select_Min_Step (A : in out Element_Array; I : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Last >= 2
         and then I in 1 .. A'Last - 1
         and then Sorted_Slice (A, 1, I - 1)
         and then Prefix_Leq_Suffix (A, 1, I - 1, I, A'Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, 1, I)
         and then Prefix_Leq_Suffix (A, 1, I, I + 1, A'Last)
         and then Same_Occ (A'Old, A)
   is
      Min_Index : Index := I;
   begin
      for J in I + 1 .. A'Last loop
         pragma Loop_Invariant (Min_Index in I .. J - 1);
         pragma Loop_Invariant
           (for all K in I .. J - 1 => A (Min_Index) <= A (K));
         pragma Loop_Invariant (Sorted_Slice (A, 1, I - 1));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, 1, I - 1, I, A'Last));
         pragma Loop_Invariant
           (for all K in 1 .. A'Last => A (K) = A'Loop_Entry (K));

         if A (J) < A (Min_Index) then
            Min_Index := J;
         end if;
      end loop;

      pragma Assert (Min_Index in I .. A'Last);
      pragma Assert (for all K in I .. A'Last => A (Min_Index) <= A (K));
      pragma Assert (Sorted_Slice (A, 1, I - 1));
      pragma Assert (Prefix_Leq_Suffix (A, 1, I - 1, I, A'Last));
      pragma Assert (I = 1 or else A (I - 1) <= A (Min_Index));

      Swap (A, I, Min_Index);

      pragma Assert (for all K in I .. A'Last => A (I) <= A (K));
      pragma Assert (I = 1 or else A (I - 1) <= A (I));
      pragma Assert (Sorted_Slice (A, 1, I));
      pragma Assert (Prefix_Leq_Suffix (A, 1, I, I + 1, A'Last));
   end Select_Min_Step;

   ---------------------------------------------------------------------------
   -- Cocktail helpers (Space_Bounded)
   ---------------------------------------------------------------------------

   --  Window invariant shared by both passes and by the shaker loop:
   --    A (1 .. Lo - 1) is sorted and <= everything from Lo on (the
   --    minima already moved down by backward passes), and
   --    A (Hi + 1 .. A'Last) is sorted and >= everything up to Hi (the
   --    maxima already moved up by forward passes).

   --  One forward pass over A (Lo .. Hi): adjacent swaps carry the
   --  maximum of the window to Hi, so the sorted suffix grows by one.
   --  Swapped is False iff no pair was exchanged, i.e. the window was
   --  already sorted.
   procedure Forward_Pass
     (A       : in out Element_Array;
      Lo, Hi  : Index;
      Swapped : out Boolean)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Lo in 1 .. A'Last
         and then Hi in Lo + 1 .. A'Last
         and then Sorted_Slice (A, 1, Lo - 1)
         and then Prefix_Leq_Suffix (A, 1, Lo - 1, Lo, A'Last)
         and then Sorted_Slice (A, Hi + 1, A'Last)
         and then Prefix_Leq_Suffix (A, 1, Hi, Hi + 1, A'Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, 1, Lo - 1)
         and then Prefix_Leq_Suffix (A, 1, Lo - 1, Lo, A'Last)
         and then Sorted_Slice (A, Hi, A'Last)
         and then Prefix_Leq_Suffix (A, 1, Hi - 1, Hi, A'Last)
         and then (if not Swapped then Sorted_Slice (A, Lo, Hi))
         and then Same_Occ (A'Old, A)
   is
      A0   : constant Element_Array := A with Ghost;
      Prev : Element_Array (A'Range) with Ghost;
   begin
      Lemma_Occ_Frame (A0, A, A'Last);
      Swapped := False;
      for I in Lo .. Hi - 1 loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Same_Occ (A0, A));
         pragma Loop_Invariant (for all K in Lo .. I => A (K) <= A (I));
         pragma Loop_Invariant
           (for all K in 1 .. Lo - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant (Sorted_Slice (A, 1, Lo - 1));
         pragma Loop_Invariant (Prefix_Leq_Suffix (A, 1, Lo - 1, Lo, A'Last));
         pragma Loop_Invariant (Sorted_Slice (A, Hi + 1, A'Last));
         pragma Loop_Invariant (Prefix_Leq_Suffix (A, 1, Hi, Hi + 1, A'Last));
         pragma Loop_Invariant (if not Swapped then Sorted_Slice (A, Lo, I));

         if A (I) > A (I + 1) then
            Prev := A;
            Swap (A, I, I + 1);
            Lemma_Same_Trans (A0, Prev, A);
            Swapped := True;
         end if;

         pragma Assert (for all K in Lo .. I + 1 => A (K) <= A (I + 1));
         pragma Assert (if not Swapped then Sorted_Slice (A, Lo, I + 1));
      end loop;

      pragma Assert (for all K in Lo .. Hi => A (K) <= A (Hi));
      pragma Assert (Hi = A'Last or else A (Hi) <= A (Hi + 1));
      pragma Assert (Sorted_Slice (A, Hi, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, Hi - 1, Hi, A'Last));
   end Forward_Pass;

   --  One backward pass over A (Lo .. Hi): adjacent swaps carry the
   --  minimum of the window down to Lo, so the sorted prefix grows by one.
   --  Swapped is False iff the window was already sorted. While loop (not
   --  reverse for) so the index stays in Index.
   procedure Backward_Pass
     (A       : in out Element_Array;
      Lo, Hi  : Index;
      Swapped : out Boolean)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Lo in 1 .. A'Last
         and then Hi in Lo + 1 .. A'Last
         and then Sorted_Slice (A, 1, Lo - 1)
         and then Prefix_Leq_Suffix (A, 1, Lo - 1, Lo, A'Last)
         and then Sorted_Slice (A, Hi + 1, A'Last)
         and then Prefix_Leq_Suffix (A, 1, Hi, Hi + 1, A'Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, 1, Lo)
         and then Prefix_Leq_Suffix (A, 1, Lo, Lo + 1, A'Last)
         and then Sorted_Slice (A, Hi + 1, A'Last)
         and then Prefix_Leq_Suffix (A, 1, Hi, Hi + 1, A'Last)
         and then (if not Swapped then Sorted_Slice (A, Lo, Hi))
         and then Same_Occ (A'Old, A)
   is
      I    : Index := Hi;
      A0   : constant Element_Array := A with Ghost;
      Prev : Element_Array (A'Range) with Ghost;
   begin
      Lemma_Occ_Frame (A0, A, A'Last);
      Swapped := False;
      while I > Lo loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Same_Occ (A0, A));
         pragma Loop_Invariant (I in Lo + 1 .. Hi);
         pragma Loop_Invariant (for all K in I .. Hi => A (I) <= A (K));
         pragma Loop_Invariant
           (for all K in 1 .. I - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in Hi + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant (Sorted_Slice (A, 1, Lo - 1));
         pragma Loop_Invariant (Prefix_Leq_Suffix (A, 1, Lo - 1, Lo, A'Last));
         pragma Loop_Invariant (Sorted_Slice (A, Hi + 1, A'Last));
         pragma Loop_Invariant (Prefix_Leq_Suffix (A, 1, Hi, Hi + 1, A'Last));
         pragma Loop_Invariant (if not Swapped then Sorted_Slice (A, I, Hi));
         pragma Loop_Variant (Decreases => I);

         if A (I - 1) > A (I) then
            Prev := A;
            Swap (A, I - 1, I);
            Lemma_Same_Trans (A0, Prev, A);
            Swapped := True;
         end if;

         pragma Assert (for all K in I - 1 .. Hi => A (I - 1) <= A (K));
         pragma Assert (if not Swapped then Sorted_Slice (A, I - 1, Hi));
         I := I - 1;
      end loop;

      pragma Assert (for all K in Lo .. Hi => A (Lo) <= A (K));
      pragma Assert (Lo = 1 or else A (Lo - 1) <= A (Lo));
      pragma Assert (Sorted_Slice (A, 1, Lo));
      pragma Assert (Prefix_Leq_Suffix (A, 1, Lo, Lo + 1, A'Last));
   end Backward_Pass;

   ---------------------------------------------------------------------------
   -- Public entry points
   ---------------------------------------------------------------------------

   procedure Sort_Comparison (A : in out Element_Array) is
      A0   : constant Element_Array := A with Ghost;
      Prev : Element_Array (A'Range) with Ghost;
   begin
      Lemma_Occ_Frame (A0, A, A'Last);
      if A'Length <= 1 then
         Lemma_Same_Perm (A, A0);
         return;
      end if;

      pragma Assert (Sorted_Slice (A, 1, 1));

      for I in 2 .. A'Last loop
         Prev := A;
         Insert_Step (A, I);
         Lemma_Same_Trans (A0, Prev, A);

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Same_Occ (A0, A));
         pragma Loop_Invariant (Sorted_Slice (A, 1, I));
         pragma Loop_Invariant (Is_Sorted (A (1 .. I)));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last =>
              A (K) = A'Loop_Entry (K));
      end loop;
      Lemma_Same_Perm (A, A0);
   end Sort_Comparison;

   procedure Sort_Parallel_Network (A : in out Element_Array) is
      A0   : constant Element_Array := A with Ghost;
      Prev : Element_Array (A'Range) with Ghost;
   begin
      Lemma_Occ_Frame (A0, A, A'Last);
      if A'Length <= 1 then
         Lemma_Same_Perm (A, A0);
         return;
      end if;

      for K in Gaps'Range loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (A'Length >= 2);
         pragma Loop_Invariant (Same_Occ (A0, A));

         declare
            G : constant Positive := Gaps (K);
         begin
            if G > 1 and then G < A'Length then
               Prev := A;
               Gap_Pass (A, G);
               Lemma_Same_Trans (A0, Prev, A);
            end if;
         end;
      end loop;

      Prev := A;
      Insertion_Pass (A);
      Lemma_Same_Trans (A0, Prev, A);
      Lemma_Same_Perm (A, A0);
   end Sort_Parallel_Network;

   procedure Sort_Frequency (A : in out Element_Array) is
      A0   : constant Element_Array := A with Ghost;
      Prev : Element_Array (A'Range) with Ghost;
   begin
      Lemma_Occ_Frame (A0, A, A'Last);
      if A'Length <= 1 then
         Lemma_Same_Perm (A, A0);
         return;
      end if;

      pragma Assert (Sorted_Slice (A, 1, 0));
      pragma Assert (Prefix_Leq_Suffix (A, 1, 0, 1, A'Last));

      for I in 1 .. A'Last - 1 loop
         Prev := A;
         Select_Min_Step (A, I);
         Lemma_Same_Trans (A0, Prev, A);

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Same_Occ (A0, A));
         pragma Loop_Invariant (Sorted_Slice (A, 1, I));
         pragma Loop_Invariant (Prefix_Leq_Suffix (A, 1, I, I + 1, A'Last));
         pragma Loop_Invariant (Is_Sorted (A (1 .. I)));
      end loop;

      pragma Assert (Sorted_Slice (A, 1, A'Last - 1));
      pragma Assert (Prefix_Leq_Suffix (A, 1, A'Last - 1, A'Last, A'Last));
      pragma Assert (Is_Sorted (A));
      Lemma_Same_Perm (A, A0);
   end Sort_Frequency;

   procedure Sort_Space_Bounded (A : in out Element_Array) is
      Lo      : Index;
      Hi      : Index;
      Swapped : Boolean;
      A0      : constant Element_Array := A with Ghost;
      Prev    : Element_Array (A'Range) with Ghost;
   begin
      Lemma_Occ_Frame (A0, A, A'Last);
      if A'Length <= 1 then
         Lemma_Same_Perm (A, A0);
         return;
      end if;

      Lo := 1;
      Hi := A'Last;

      while Lo < Hi loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Lo in 1 .. A'Last);
         pragma Loop_Invariant (Hi in Lo + 1 .. A'Last);
         pragma Loop_Invariant (Sorted_Slice (A, 1, Lo - 1));
         pragma Loop_Invariant (Prefix_Leq_Suffix (A, 1, Lo - 1, Lo, A'Last));
         pragma Loop_Invariant (Sorted_Slice (A, Hi + 1, A'Last));
         pragma Loop_Invariant (Prefix_Leq_Suffix (A, 1, Hi, Hi + 1, A'Last));
         pragma Loop_Invariant (Same_Occ (A0, A));
         pragma Loop_Variant (Decreases => Hi - Lo);

         --  Forward: bubble the largest of the window up to Hi.
         Prev := A;
         Forward_Pass (A, Lo, Hi, Swapped);
         Lemma_Same_Trans (A0, Prev, A);
         if not Swapped then
            --  Window sorted: prefix, window and suffix join up.
            pragma Assert (Sorted_Slice (A, 1, A'Last));
            Lemma_Same_Perm (A, A0);
            return;
         end if;
         Hi := Hi - 1;
         exit when Lo = Hi;

         --  Backward: bubble the smallest of the window down to Lo.
         Prev := A;
         Backward_Pass (A, Lo, Hi, Swapped);
         Lemma_Same_Trans (A0, Prev, A);
         if not Swapped then
            pragma Assert (Sorted_Slice (A, 1, A'Last));
            Lemma_Same_Perm (A, A0);
            return;
         end if;
         Lo := Lo + 1;
      end loop;

      --  Window of at most one element left between prefix and suffix.
      pragma Assert (Sorted_Slice (A, 1, A'Last));
      Lemma_Same_Perm (A, A0);
   end Sort_Space_Bounded;

end Quantum_Sort;
