--  Quantum_Sort body — SPARK Level 4 classical educational models of
--  quantum-sorting notions. Comparison proves via Insert_Step;
--  Parallel_Network via Gap_Pass + Insertion_Pass; Frequency via
--  Select_Min_Step; Space_Bounded via capped cocktail rounds +
--  Bubble_Finish (same proof split as Shell / Cocktail SPARK ports).

package body Quantum_Sort
  with SPARK_Mode => On
is

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
   is
      T : Integer;
   begin
      if X = Y then
         return;
      end if;
      T     := A (X);
      A (X) := A (Y);
      A (Y) := T;
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
   is
      Key : constant Integer := A (I);
      J   : Index := I;
   begin
      while J > 1 and then Key < A (J - 1) loop
         pragma Loop_Invariant (J in 2 .. I);
         pragma Loop_Invariant (Sorted_Slice (A, 1, J - 1));
         pragma Loop_Invariant (Sorted_Slice (A, J + 1, I));
         pragma Loop_Invariant
           (for all K in J + 1 .. I => A (K) > Key);
         pragma Loop_Invariant
           (for all K in J + 1 .. I => A (J - 1) <= A (K));
         pragma Loop_Invariant
           (if J < I then A (J) = A (J + 1) else A (J) = Key);
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Variant (Decreases => J);

         A (J) := A (J - 1);
         J     := J - 1;
      end loop;

      pragma Assert (J in 1 .. I);
      pragma Assert (Sorted_Slice (A, 1, J - 1));
      pragma Assert (Sorted_Slice (A, J + 1, I));
      pragma Assert (for all K in J + 1 .. I => A (K) > Key);
      pragma Assert (J = 1 or else A (J - 1) <= Key);

      A (J) := Key;

      pragma Assert (if J > 1 then A (J - 1) <= A (J));
      pragma Assert (if J < I then A (J) <= A (J + 1));
      pragma Assert (Sorted_Slice (A, 1, I));
   end Insert_Step;

   procedure Insertion_Pass (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A) and then Is_Sorted (A)
   is
   begin
      pragma Assert (Sorted_Slice (A, 1, 1));

      for I in 2 .. A'Last loop
         Insert_Step (A, I);

         pragma Loop_Invariant (In_Bounds (A));
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
       Post   => In_Bounds (A)
   is
      Key : Integer;
      J   : Index;
   begin
      for I in Gap + 1 .. A'Last loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (I in Gap + 1 .. A'Last + 1);

         Key := A (I);
         J   := I;

         while J >= Gap + 1 and then A (J - Gap) > Key loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (J in Gap + 1 .. I);
            pragma Loop_Invariant (J <= A'Last);
            pragma Loop_Variant (Decreases => J);

            A (J) := A (J - Gap);
            J     := J - Gap;
         end loop;

         A (J) := Key;
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
   -- Cocktail / bubble helpers (Space_Bounded)
   ---------------------------------------------------------------------------

   procedure Forward_Pass
     (A       : in out Element_Array;
      Lo, Hi  : Index;
      Swapped : in out Boolean)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 2
         and then Lo in 1 .. A'Last
         and then Hi in 1 .. A'Last
         and then Lo < Hi,
       Post   => In_Bounds (A)
   is
   begin
      for I in Lo .. Hi - 1 loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (I + 1 <= A'Last);

         if A (I) > A (I + 1) then
            Swap (A, I, I + 1);
            Swapped := True;
         end if;
      end loop;
   end Forward_Pass;

   procedure Backward_Pass
     (A       : in out Element_Array;
      Lo, Hi  : Index;
      Swapped : in out Boolean)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 2
         and then Lo in 1 .. A'Last
         and then Hi in 1 .. A'Last
         and then Lo < Hi,
       Post   => In_Bounds (A)
   is
      I : Index;
   begin
      I := Hi;
      while I > Lo loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (I in Lo + 1 .. Hi);
         pragma Loop_Invariant (I in 2 .. A'Last);
         pragma Loop_Variant (Decreases => I);

         if A (I - 1) > A (I) then
            Swap (A, I - 1, I);
            Swapped := True;
         end if;

         I := I - 1;
      end loop;
   end Backward_Pass;

   procedure Bubble_Pass
     (A       : in out Element_Array;
      Bound   : Index;
      Swapped : out Boolean)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Last >= 2
         and then Bound in 2 .. A'Last
         and then Sorted_Slice (A, Bound + 1, A'Last)
         and then Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Bound, A'Last)
         and then Prefix_Leq_Suffix (A, 1, Bound - 1, Bound, A'Last)
         and then
           (if not Swapped then Sorted_Slice (A, 1, Bound))
   is
   begin
      Swapped := False;

      for I in 1 .. Bound - 1 loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all K in 1 .. I => A (K) <= A (I));
         pragma Loop_Invariant (Sorted_Slice (A, Bound + 1, A'Last));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (if not Swapped then Sorted_Slice (A, 1, I));

         if A (I) > A (I + 1) then
            Swap (A, I, I + 1);
            Swapped := True;
         end if;

         pragma Assert (for all K in 1 .. I + 1 => A (K) <= A (I + 1));
         pragma Assert (if not Swapped then Sorted_Slice (A, 1, I + 1));
      end loop;

      pragma Assert (for all K in 1 .. Bound => A (K) <= A (Bound));
      pragma Assert (Sorted_Slice (A, Bound + 1, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));
      pragma Assert (Bound = A'Last or else A (Bound) <= A (Bound + 1));
      pragma Assert (Sorted_Slice (A, Bound, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, Bound - 1, Bound, A'Last));
      pragma Assert (if not Swapped then Sorted_Slice (A, 1, Bound));
   end Bubble_Pass;

   procedure Bubble_Finish (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A) and then Is_Sorted (A)
   is
      Bound   : Index;
      Swapped : Boolean;
   begin
      Bound := A'Last;

      pragma Assert (Sorted_Slice (A, Bound + 1, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));

      loop
         pragma Loop_Invariant (Bound in 2 .. A'Last);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, Bound + 1, A'Last));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));
         pragma Loop_Variant (Decreases => Bound);

         Bubble_Pass (A, Bound, Swapped);

         pragma Assert (Sorted_Slice (A, Bound, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, 1, Bound - 1, Bound, A'Last));

         if not Swapped then
            pragma Assert (Sorted_Slice (A, 1, Bound));
            pragma Assert (Sorted_Slice (A, Bound, A'Last));
            pragma Assert (Is_Sorted (A));
            return;
         end if;

         exit when Bound = 2;

         Bound := Bound - 1;

         pragma Assert (Sorted_Slice (A, Bound + 1, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));
      end loop;

      pragma Assert (Bound = 2);
      pragma Assert (Sorted_Slice (A, 2, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, 1, 2, A'Last));
      pragma Assert (Is_Sorted (A));
   end Bubble_Finish;

   ---------------------------------------------------------------------------
   -- Public entry points
   ---------------------------------------------------------------------------

   procedure Sort_Comparison (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      pragma Assert (Sorted_Slice (A, 1, 1));

      for I in 2 .. A'Last loop
         Insert_Step (A, I);

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, 1, I));
         pragma Loop_Invariant (Is_Sorted (A (1 .. I)));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last =>
              A (K) = A'Loop_Entry (K));
      end loop;
   end Sort_Comparison;

   procedure Sort_Parallel_Network (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      for K in Gaps'Range loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (A'Length >= 2);

         declare
            G : constant Positive := Gaps (K);
         begin
            if G > 1 and then G < A'Length then
               Gap_Pass (A, G);
            end if;
         end;
      end loop;

      Insertion_Pass (A);
   end Sort_Parallel_Network;

   procedure Sort_Frequency (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      pragma Assert (Sorted_Slice (A, 1, 0));
      pragma Assert (Prefix_Leq_Suffix (A, 1, 0, 1, A'Last));

      for I in 1 .. A'Last - 1 loop
         Select_Min_Step (A, I);

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, 1, I));
         pragma Loop_Invariant (Prefix_Leq_Suffix (A, 1, I, I + 1, A'Last));
         pragma Loop_Invariant (Is_Sorted (A (1 .. I)));
      end loop;

      pragma Assert (Sorted_Slice (A, 1, A'Last - 1));
      pragma Assert (Prefix_Leq_Suffix (A, 1, A'Last - 1, A'Last, A'Last));
      pragma Assert (Is_Sorted (A));
   end Sort_Frequency;

   procedure Sort_Space_Bounded (A : in out Element_Array) is
      Lo      : Index;
      Hi      : Index;
      Swapped : Boolean;
   begin
      if A'Length <= 1 then
         return;
      end if;

      Lo := 1;
      Hi := A'Last;

      for Iter in 1 .. Max_N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (A'Length >= 2);
         pragma Loop_Invariant (Lo in 1 .. A'Last);
         pragma Loop_Invariant (Hi in 1 .. A'Last);

         exit when Lo >= Hi;

         Swapped := False;
         Forward_Pass (A, Lo, Hi, Swapped);
         exit when not Swapped;
         Hi := Hi - 1;

         exit when Lo >= Hi;

         Swapped := False;
         Backward_Pass (A, Lo, Hi, Swapped);
         exit when not Swapped;
         Lo := Lo + 1;
      end loop;

      Bubble_Finish (A);
   end Sort_Space_Bounded;

end Quantum_Sort;
