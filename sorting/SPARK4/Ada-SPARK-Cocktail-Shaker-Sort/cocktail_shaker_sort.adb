--  Cocktail_Shaker_Sort body - SPARK Level 4 bidirectional bubble
--  (cocktail shaker) sort. Forward passes carry the window maximum up to
--  Hi, backward passes carry the window minimum down to Lo; the window
--  invariant (sorted prefix <= rest, sorted suffix >= rest) proves
--  Is_Sorted directly, with no extra bubble sort at the end.

package body Cocktail_Shaker_Sort
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
       and then L >= A'First
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
       and then Lo_P >= A'First
       and then Hi_P <= A'Last
       and then Lo_S >= A'First
       and then Hi_S <= A'Last;

   procedure Swap (A : in out Element_Array; X, Y : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then X in A'Range
         and then Y in A'Range,
       Post   =>
         In_Bounds (A)
         and then A (X) = A'Old (Y)
         and then A (Y) = A'Old (X)
         and then
           (for all K in A'Range =>
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

   --  Window invariant shared by both passes and by the shaker loop:
   --    A (A'First .. Lo - 1) is sorted and <= everything from Lo on (the
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
         and then Lo in A'Range
         and then Hi in Lo + 1 .. A'Last
         and then Sorted_Slice (A, A'First, Lo - 1)
         and then Prefix_Leq_Suffix (A, A'First, Lo - 1, Lo, A'Last)
         and then Sorted_Slice (A, Hi + 1, A'Last)
         and then Prefix_Leq_Suffix (A, A'First, Hi, Hi + 1, A'Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, A'First, Lo - 1)
         and then Prefix_Leq_Suffix (A, A'First, Lo - 1, Lo, A'Last)
         and then Sorted_Slice (A, Hi, A'Last)
         and then Prefix_Leq_Suffix (A, A'First, Hi - 1, Hi, A'Last)
         and then (if not Swapped then Sorted_Slice (A, Lo, Hi))
   is
   begin
      Swapped := False;
      for I in Lo .. Hi - 1 loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (for all K in Lo .. I => A (K) <= A (I));
         pragma Loop_Invariant
           (for all K in A'First .. Lo - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant (Sorted_Slice (A, A'First, Lo - 1));
         pragma Loop_Invariant (Prefix_Leq_Suffix (A, A'First, Lo - 1, Lo, A'Last));
         pragma Loop_Invariant (Sorted_Slice (A, Hi + 1, A'Last));
         pragma Loop_Invariant (Prefix_Leq_Suffix (A, A'First, Hi, Hi + 1, A'Last));
         pragma Loop_Invariant (if not Swapped then Sorted_Slice (A, Lo, I));

         if A (I) > A (I + 1) then
            Swap (A, I, I + 1);
            Swapped := True;
         end if;

         pragma Assert (for all K in Lo .. I + 1 => A (K) <= A (I + 1));
         pragma Assert (if not Swapped then Sorted_Slice (A, Lo, I + 1));
      end loop;

      pragma Assert (for all K in Lo .. Hi => A (K) <= A (Hi));
      pragma Assert (Hi = A'Last or else A (Hi) <= A (Hi + 1));
      pragma Assert (Sorted_Slice (A, Hi, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, A'First, Hi - 1, Hi, A'Last));
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
         and then Lo in A'Range
         and then Hi in Lo + 1 .. A'Last
         and then Sorted_Slice (A, A'First, Lo - 1)
         and then Prefix_Leq_Suffix (A, A'First, Lo - 1, Lo, A'Last)
         and then Sorted_Slice (A, Hi + 1, A'Last)
         and then Prefix_Leq_Suffix (A, A'First, Hi, Hi + 1, A'Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, A'First, Lo)
         and then Prefix_Leq_Suffix (A, A'First, Lo, Lo + 1, A'Last)
         and then Sorted_Slice (A, Hi + 1, A'Last)
         and then Prefix_Leq_Suffix (A, A'First, Hi, Hi + 1, A'Last)
         and then (if not Swapped then Sorted_Slice (A, Lo, Hi))
   is
      I : Index := Hi;
   begin
      Swapped := False;
      while I > Lo loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (I in Lo + 1 .. Hi);
         pragma Loop_Invariant (for all K in I .. Hi => A (I) <= A (K));
         pragma Loop_Invariant
           (for all K in A'First .. I - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in Hi + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant (Sorted_Slice (A, A'First, Lo - 1));
         pragma Loop_Invariant (Prefix_Leq_Suffix (A, A'First, Lo - 1, Lo, A'Last));
         pragma Loop_Invariant (Sorted_Slice (A, Hi + 1, A'Last));
         pragma Loop_Invariant (Prefix_Leq_Suffix (A, A'First, Hi, Hi + 1, A'Last));
         pragma Loop_Invariant (if not Swapped then Sorted_Slice (A, I, Hi));
         pragma Loop_Variant (Decreases => I);

         if A (I - 1) > A (I) then
            Swap (A, I - 1, I);
            Swapped := True;
         end if;

         pragma Assert (for all K in I - 1 .. Hi => A (I - 1) <= A (K));
         pragma Assert (if not Swapped then Sorted_Slice (A, I - 1, Hi));
         I := I - 1;
      end loop;

      pragma Assert (for all K in Lo .. Hi => A (Lo) <= A (K));
      pragma Assert (Lo = A'First or else A (Lo - 1) <= A (Lo));
      pragma Assert (Sorted_Slice (A, A'First, Lo));
      pragma Assert (Prefix_Leq_Suffix (A, A'First, Lo, Lo + 1, A'Last));
   end Backward_Pass;

   procedure Sort (A : in out Element_Array) is
      Lo      : Index;
      Hi      : Index;
      Swapped : Boolean;
   begin
      if A'Length <= 1 then
         return;
      end if;

      Lo := A'First;
      Hi := A'Last;

      while Lo < Hi loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Lo in A'Range);
         pragma Loop_Invariant (Hi in Lo + 1 .. A'Last);
         pragma Loop_Invariant (Sorted_Slice (A, A'First, Lo - 1));
         pragma Loop_Invariant (Prefix_Leq_Suffix (A, A'First, Lo - 1, Lo, A'Last));
         pragma Loop_Invariant (Sorted_Slice (A, Hi + 1, A'Last));
         pragma Loop_Invariant (Prefix_Leq_Suffix (A, A'First, Hi, Hi + 1, A'Last));
         pragma Loop_Variant (Decreases => Hi - Lo);

         --  Forward: bubble the largest of the window up to Hi.
         Forward_Pass (A, Lo, Hi, Swapped);
         if not Swapped then
            --  Window sorted: prefix, window and suffix join up.
            pragma Assert (Sorted_Slice (A, A'First, A'Last));
            return;
         end if;
         Hi := Hi - 1;
         exit when Lo = Hi;

         --  Backward: bubble the smallest of the window down to Lo.
         Backward_Pass (A, Lo, Hi, Swapped);
         if not Swapped then
            pragma Assert (Sorted_Slice (A, A'First, A'Last));
            return;
         end if;
         Lo := Lo + 1;
      end loop;

      --  Window of at most one element left between prefix and suffix.
      pragma Assert (Sorted_Slice (A, A'First, A'Last));
   end Sort;

end Cocktail_Shaker_Sort;
