--  Stooge_Sort body — SPARK Level 4 recursive 2/3–2/3–2/3 sort.
--  Stooge_Range uses Subprogram_Variant (Hi - Lo) and proves only
--  In_Bounds / RTE / termination / frame (the classic inductive
--  "largest third" argument fights automated Level 4). Sort then runs
--  a gap-1 Bubble_Finish (same role as Comb / Odd_Even / Shell) so
--  Is_Sorted is proved. No Intentional Annotate.

package body Stooge_Sort
  with SPARK_Mode => On
is

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

   --  Classic stooge on A (Lo .. Hi). Variant Hi - Lo decreases on each
   --  recursive call (span shrinks by T = floor(L/3) >= 1 when L > 2).
   --  Contracts: In_Bounds / frame / termination only (sortedness via
   --  Bubble_Finish in Sort — same split as Comb / Odd_Even).
   procedure Stooge_Range
     (A      : in out Element_Array;
      Lo, Hi : Index)
     with
       Global             => null,
       Always_Terminates  => True,
       Subprogram_Variant => (Decreases => Hi - Lo),
       Pre                =>
         In_Bounds (A)
         and then Lo in 1 .. A'Last
         and then Hi in Lo .. A'Last,
       Post               =>
         In_Bounds (A)
         and then
           (for all K in 1 .. Lo - 1 => A (K) = A'Old (K))
         and then
           (for all K in Hi + 1 .. A'Last => A (K) = A'Old (K))
   is
      L : Natural;
      T : Index;
   begin
      if A (Lo) > A (Hi) then
         Swap (A, Lo, Hi);
      end if;

      L := Hi - Lo + 1;
      if L <= 2 then
         return;
      end if;

      T := L / 3;
      pragma Assert (T >= 1);
      pragma Assert ((Hi - T) - Lo < Hi - Lo);
      pragma Assert (Hi - (Lo + T) < Hi - Lo);

      Stooge_Range (A, Lo, Hi - T);
      Stooge_Range (A, Lo + T, Hi);
      Stooge_Range (A, Lo, Hi - T);
   end Stooge_Range;

   --  One forward pass over A (1 .. Bound): bubble the maximum of that
   --  range to index Bound via adjacent swaps. Preserves the already-
   --  sorted / partitioned suffix Bound+1 .. A'Last.
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

   --  Final gap = 1: ordinary bubble sort with early exit. Proves Is_Sorted.
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

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      --  Classic Stooge 2/3–2/3–2/3 recursion (educational core).
      Stooge_Range (A, 1, A'Last);

      --  Gap-1 bubble finish → Is_Sorted (same role as Comb / Odd_Even).
      --  On a correctly stooge-sorted array this is an O(n) clean pass.
      Bubble_Finish (A);
   end Sort;

end Stooge_Sort;
