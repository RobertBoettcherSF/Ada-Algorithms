--  Heapsort body — SPARK Level 4 classic in-place binary max-heap
--  heapsort. Floyd bottom-up Heapify + extract-max with Sift_Down.
--  Ghost parent-form Is_Heap / Heap_From track the heap; extract-max
--  maintains a sorted suffix and Heap_Leq_Suffix so Sort proves
--  Is_Sorted. Public Sift_Down / Heapify keep lighter Posts; the
--  stronger heap restoration lives in body helpers used by Sort.

package body Heapsort
  with SPARK_Mode => On
is

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

   function Is_Heap (A : Element_Array; Last : Index) return Boolean is
     (Last < 2
      or else (for all I in 2 .. Last => A (I / 2) >= A (I)))
   with
     Ghost  => True,
     Global => null,
     Pre    => In_Bounds (A) and then Last <= A'Last;

   function Heap_From
     (A : Element_Array; Last : Index; Bound : Natural) return Boolean
   is
     (Last < 2
      or else Bound > Natural (Last)
      or else
        (for all I in 2 .. Last =>
           (if Natural (I / 2) >= Bound then A (I / 2) >= A (I))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Last <= A'Last
       and then Bound <= Natural (Max_N) + 1;

   function Heap_Leq_Suffix
     (A : Element_Array; Heap_Last, N : Index) return Boolean
   is
     (Heap_Last = 0
      or else Heap_Last >= N
      or else
        (for all H in 1 .. Heap_Last =>
           (for all S in Heap_Last + 1 .. N => A (H) <= A (S))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then N <= A'Last
       and then Heap_Last <= N;

   --  Heap property for parents in Root .. Last except the hole R.
   function Heap_Except_Hole
     (A : Element_Array; Last, Root, R : Index) return Boolean
   is
     (for all I in 2 .. Last =>
        (if I / 2 >= Root and then I / 2 /= R then A (I / 2) >= A (I)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Last <= A'Last
       and then Root in 1 .. Last
       and then R in Root .. Last;

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

   procedure Lemma_Root_Is_Max (A : Element_Array; Last : Index)
     with
       Ghost             => True,
       Always_Terminates => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then Last in 1 .. A'Last
         and then Is_Heap (A, Last),
       Post              =>
         (for all K in 1 .. Last => A (1) >= A (K))
   is
   begin
      for K in 1 .. Last loop
         pragma Loop_Invariant
           (for all J in 1 .. K - 1 => A (1) >= A (J));
         pragma Loop_Invariant (Is_Heap (A, Last));

         declare
            P : Index := K;
         begin
            pragma Assert (A (P) >= A (K));
            while P > 1 loop
               pragma Loop_Invariant (P in 1 .. Last);
               pragma Loop_Invariant (A (P) >= A (K));
               pragma Loop_Invariant (Is_Heap (A, Last));
               pragma Loop_Variant (Decreases => P);

               pragma Assert (P in 2 .. Last);
               pragma Assert (A (P / 2) >= A (P));
               P := P / 2;
               pragma Assert (A (P) >= A (K));
            end loop;
            pragma Assert (P = 1);
            pragma Assert (A (1) >= A (K));
         end;
      end loop;
   end Lemma_Root_Is_Max;

   procedure Sift_Down_Restore
     (A         : in out Element_Array;
      Root      : Index;
      Heap_Last : Index;
      N         : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then N in Heap_Last .. A'Last
         and then Heap_Last in 1 .. A'Last
         and then Root in 1 .. Heap_Last
         and then Heap_From (A, Heap_Last, Natural (Root) + 1)
         and then Heap_Leq_Suffix (A, Heap_Last, N),
       Post   =>
         In_Bounds (A)
         and then Heap_From (A, Heap_Last, Natural (Root))
         and then Heap_Leq_Suffix (A, Heap_Last, N)
         and then
           (for all K in Heap_Last + 1 .. A'Last => A (K) = A'Old (K))
         and then
           (for all K in 1 .. Root - 1 => A (K) = A'Old (K))
   is
      R     : Index := Root;
      Child : Index;
      Left  : Index;
   begin
      loop
         pragma Loop_Invariant (R in Root .. Heap_Last);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all K in Heap_Last + 1 .. A'Last =>
              A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in 1 .. Root - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (Heap_Except_Hole (A, Heap_Last, Root, R));
         pragma Loop_Invariant
           (if R > Root then A (R / 2) >= A (R));
         pragma Loop_Invariant (Heap_Leq_Suffix (A, Heap_Last, N));
         --  Parent of hole covers hole's children when hole is internal.
         pragma Loop_Invariant
           (if R > Root and then R <= Heap_Last / 2 then
              A (R / 2) >= A (2 * R)
              and then
              (if 2 * R < Heap_Last then A (R / 2) >= A (2 * R + 1)));
         pragma Loop_Variant (Decreases => Heap_Last - R + 1);

         if R > Heap_Last / 2 then
            pragma Assert (Heap_From (A, Heap_Last, Natural (Root)));
            return;
         end if;

         Left := 2 * R;
         pragma Assert (Left in 2 .. Heap_Last);
         Child := Left;

         if Left < Heap_Last and then A (Left) < A (Left + 1) then
            Child := Left + 1;
         end if;

         pragma Assert (Child = Left or else Child = Left + 1);
         pragma Assert (Child / 2 = R);
         pragma Assert (A (Child) >= A (Left));
         pragma Assert
           (if Left < Heap_Last then A (Child) >= A (Left + 1));

         --  Parent-of-hole covers larger child ⇒ survives the upward move.
         pragma Assert
           (if R > Root then A (R / 2) >= A (Child));

         if A (R) >= A (Child) then
            pragma Assert (A (R) >= A (Left));
            pragma Assert
              (if Left < Heap_Last then A (R) >= A (Left + 1));
            pragma Assert
              (for all I in 2 .. Heap_Last =>
                 (if I / 2 >= Root then A (I / 2) >= A (I)));
            pragma Assert (Heap_From (A, Heap_Last, Natural (Root)));
            return;
         end if;

         Swap (A, R, Child);

         pragma Assert (A (R) >= A (Left));
         pragma Assert
           (if Left < Heap_Last then A (R) >= A (Left + 1));
         pragma Assert (A (R) >= A (Child));

         --  Old hole R is repaired; new hole Child. Parent link for Child:
         pragma Assert (A (R) >= A (Child));
         --  A(R) grew to old A(Child); parent of R still covers new A(R)
         --  because parent covered Child before the swap.
         pragma Assert (if R > Root then A (R / 2) >= A (R));

         pragma Assert (Heap_Except_Hole (A, Heap_Last, Root, Child));
         pragma Assert (Heap_Leq_Suffix (A, Heap_Last, N));

         --  New parent (old R) covers Child's children (grandchildren).
         pragma Assert
           (if Child <= Heap_Last / 2 then
              A (R) >= A (2 * Child)
              and then
              (if 2 * Child < Heap_Last then A (R) >= A (2 * Child + 1)));

         R := Child;
         pragma Assert (if R > Root then A (R / 2) >= A (R));
      end loop;
   end Sift_Down_Restore;

   procedure Sift_Down
     (A         : in out Element_Array;
      Root      : Index;
      Heap_Last : Index)
   is
      R     : Index := Root;
      Child : Index;
      Left  : Index;
   begin
      loop
         pragma Loop_Invariant (R in Root .. Heap_Last);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all K in Heap_Last + 1 .. A'Last =>
              A (K) = A'Loop_Entry (K));
         pragma Loop_Variant (Decreases => Heap_Last - R + 1);

         if R > Heap_Last / 2 then
            return;
         end if;

         Left  := 2 * R;
         Child := Left;

         if Left < Heap_Last and then A (Left) < A (Left + 1) then
            Child := Left + 1;
         end if;

         if A (R) < A (Child) then
            Swap (A, R, Child);
            R := Child;
         else
            return;
         end if;
      end loop;
   end Sift_Down;

   procedure Heapify (A : in out Element_Array) is
      Start : Index;
      N     : Index;
   begin
      if A'Length <= 1 then
         return;
      end if;

      N     := A'Last;
      Start := N / 2;
      pragma Assert (Start in 1 .. N);
      pragma Assert (Heap_From (A, N, Natural (Start) + 1));
      pragma Assert (Heap_Leq_Suffix (A, N, N));

      loop
         pragma Loop_Invariant (Start in 1 .. N / 2);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Heap_From (A, N, Natural (Start) + 1));
         pragma Loop_Invariant (Heap_Leq_Suffix (A, N, N));
         pragma Loop_Variant (Decreases => Start);

         Sift_Down_Restore (A, Start, N, N);
         pragma Assert (Heap_From (A, N, Natural (Start)));

         exit when Start = 1;
         Start := Start - 1;
      end loop;

      pragma Assert (Is_Heap (A, N));
   end Heapify;

   procedure Sort (A : in out Element_Array) is
      Heap_Last : Index;
      N         : Index;
      Start     : Index;
   begin
      if A'Length <= 1 then
         return;
      end if;

      N := A'Last;
      pragma Assert (N in 2 .. Max_N);

      Start := N / 2;
      pragma Assert (Heap_From (A, N, Natural (Start) + 1));
      pragma Assert (Heap_Leq_Suffix (A, N, N));
      loop
         pragma Loop_Invariant (Start in 1 .. N / 2);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Heap_From (A, N, Natural (Start) + 1));
         pragma Loop_Invariant (Heap_Leq_Suffix (A, N, N));
         pragma Loop_Variant (Decreases => Start);

         Sift_Down_Restore (A, Start, N, N);
         pragma Assert (Heap_From (A, N, Natural (Start)));

         exit when Start = 1;
         Start := Start - 1;
      end loop;

      pragma Assert (Is_Heap (A, N));
      Lemma_Root_Is_Max (A, N);

      Heap_Last := N;
      pragma Assert (Sorted_Slice (A, N + 1, N));
      pragma Assert (Heap_Leq_Suffix (A, N, N));

      while Heap_Last > 1 loop
         pragma Loop_Invariant (Heap_Last in 2 .. N);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Is_Heap (A, Heap_Last));
         pragma Loop_Invariant (Sorted_Slice (A, Heap_Last + 1, N));
         pragma Loop_Invariant (Heap_Leq_Suffix (A, Heap_Last, N));
         pragma Loop_Variant (Decreases => Heap_Last);

         Lemma_Root_Is_Max (A, Heap_Last);
         pragma Assert (for all K in 1 .. Heap_Last => A (1) >= A (K));

         Swap (A, 1, Heap_Last);

         pragma Assert
           (Heap_Last = N
            or else A (Heap_Last) <= A (Heap_Last + 1));
         pragma Assert (Sorted_Slice (A, Heap_Last, N));
         pragma Assert
           (for all H in 1 .. Heap_Last - 1 =>
              (for all S in Heap_Last .. N => A (H) <= A (S)));

         pragma Assert (Heap_From (A, Heap_Last - 1, 2));

         Heap_Last := Heap_Last - 1;

         pragma Assert (Heap_Leq_Suffix (A, Heap_Last, N));
         pragma Assert (Heap_From (A, Heap_Last, 2));

         Sift_Down_Restore (A, 1, Heap_Last, N);
         pragma Assert (Is_Heap (A, Heap_Last));
         pragma Assert (Sorted_Slice (A, Heap_Last + 1, N));
         pragma Assert (Heap_Leq_Suffix (A, Heap_Last, N));
      end loop;

      pragma Assert (Heap_Last = 1);
      pragma Assert (Sorted_Slice (A, 2, N));
      pragma Assert (Heap_Leq_Suffix (A, 1, N));
      pragma Assert (A (1) <= A (2));
      pragma Assert (Is_Sorted (A));
   end Sort;

end Heapsort;
