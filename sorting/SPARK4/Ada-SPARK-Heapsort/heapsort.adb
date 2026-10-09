--  Heapsort body — First-relative binary max-heap (any A'First = Lo).
--  Child existence is guarded before Left is computed:
--    if I - Lo <= (Hi - Lo - 1) / 2 then Child := Lo + 2 * (I - Lo) + 1
--  so the multiply never overflows near Index'Last. Ghost Is_Heap /
--  Heap_From / Heap_Leq_Suffix track the heap; Sort proves Is_Sorted.

package body Heapsort
  with SPARK_Mode => On
is

   --  Loop invariants and the Posts of the subprograms below are proved by
   --  gnatprove and not re-evaluated at run time: the permutation clauses
   --  (Same_Occ) quantify over every Integer value. The Post of the public
   --  Sort (spec) is still checked at run time, including Is_Perm.
   pragma Assertion_Policy (Loop_Invariant => Ignore, Post => Ignore);

   ---------------------------------------------------------------------------
   -- Permutation proof (ghost). Same_Occ: equal counts for every Integer.
   ---------------------------------------------------------------------------

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
      pragma Assertion_Policy (Pre => Ignore);

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

   end Perm_Lemmas;
   use Perm_Lemmas;

   function Parent (Lo, I : Index) return Index is
     (Lo + (I - Lo - 1) / 2)
   with
     Global => null,
     Pre    => I > Lo and then Lo >= 1,
     Post   =>
       Parent'Result in Lo .. I - 1
       --  Linear characterisation: I is child 2k+1 or 2k+2 of slot k.
       and then 2 * (Parent'Result - Lo) + 1 <= I - Lo
       and then I - Lo <= 2 * (Parent'Result - Lo) + 2;

   function Has_Left (Lo, Hi, I : Index) return Boolean is
     (Hi > Lo and then I - Lo <= (Hi - Lo - 1) / 2)
   with
     Global => null,
     Pre    =>
       Lo >= 1
       and then Hi >= Lo
       and then I in Lo .. Hi;

   function Left_Child (Lo, Hi, I : Index) return Index
   with
     Global => null,
     Pre    =>
       Lo >= 1
       and then Hi >= Lo
       and then I in Lo .. Hi
       and then Has_Left (Lo, Hi, I),
     Post   =>
       Left_Child'Result in I + 1 .. Hi
       and then Left_Child'Result = Lo + 2 * (I - Lo) + 1
       and then Parent (Lo, Left_Child'Result) = I
       and then
         (if Left_Child'Result < Hi then
            Parent (Lo, Left_Child'Result + 1) = I)
   is
      Off : constant Natural := I - Lo;
      L   : Index;
   begin
      --  Has_Left => Off <= (Hi-Lo-1)/2 => 2*Off+1 <= Hi-Lo => Lo+2*Off+1 <= Hi
      pragma Assert (2 * Off + 1 <= Hi - Lo);
      L := Lo + 2 * Off + 1;
      pragma Assert (L - Lo - 1 = 2 * Off);
      pragma Assert ((L - Lo - 1) / 2 = Off);
      pragma Assert (Parent (Lo, L) = I);
      if L < Hi then
         pragma Assert (L + 1 - Lo - 1 = 2 * Off + 1);
         pragma Assert ((L + 1 - Lo - 1) / 2 = Off);
         pragma Assert (Parent (Lo, L + 1) = I);
      end if;
      return L;
   end Left_Child;

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

   function Is_Heap
     (A : Element_Array; Lo, Last : Index) return Boolean
   is
     (Last <= Lo
      or else
        (for all I in Lo + 1 .. Last =>
           A (Parent (Lo, I)) >= A (I)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Lo = A'First
       and then Last <= A'Last
       and then Last >= Lo - 1;

   function Heap_From
     (A : Element_Array; Lo, Last : Index; Bound : Natural)
      return Boolean
   is
     (Last <= Lo
      or else Bound > Natural (Last)
      or else
        (for all I in Lo + 1 .. Last =>
           (if Natural (Parent (Lo, I)) >= Bound then
              A (Parent (Lo, I)) >= A (I))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Lo = A'First
       and then Last <= A'Last
       and then Bound <= Natural (Max_N) + 1;

   function Heap_Leq_Suffix
     (A : Element_Array; Lo, Heap_Last, N : Index) return Boolean
   is
     (Heap_Last < Lo
      or else Heap_Last >= N
      or else
        (for all H in Lo .. Heap_Last =>
           (for all S in Heap_Last + 1 .. N => A (H) <= A (S))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Lo = A'First
       and then N <= A'Last
       and then Heap_Last <= N;

   function Heap_Except_Hole
     (A : Element_Array; Lo, Last, Root, R : Index) return Boolean
   is
     (for all I in Lo + 1 .. Last =>
        (if Parent (Lo, I) >= Root and then Parent (Lo, I) /= R then
           A (Parent (Lo, I)) >= A (I)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Lo = A'First
       and then Last <= A'Last
       and then Root in Lo .. Last
       and then R in Root .. Last;

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
         and then Same_Occ (A, A'Old)
   is
      T : Integer;
      Before : constant Element_Array := A with Ghost;
   begin
      if X = Y then
         return;
      end if;
      T     := A (X);
      A (X) := A (Y);
      A (Y) := T;
      Lemma_Swap (Before, A, X, Y);
   end Swap;

   procedure Lemma_Root_Is_Max
     (A : Element_Array; Lo, Last : Index)
     with
       Ghost             => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then Lo = A'First
         and then Last in Lo .. A'Last
         and then Is_Heap (A, Lo, Last),
       Post              =>
         (for all K in Lo .. Last => A (Lo) >= A (K))
   is
   begin
      for K in Lo .. Last loop
         pragma Loop_Invariant
           (for all J in Lo .. K - 1 => A (Lo) >= A (J));
         pragma Loop_Invariant (Same_Occ (A, A'Loop_Entry));
         pragma Loop_Invariant (Is_Heap (A, Lo, Last));

         declare
            P : Index := K;
         begin
            pragma Assert (A (P) >= A (K));
            while P > Lo loop
               pragma Loop_Invariant (P in Lo .. Last);
               pragma Loop_Invariant (Same_Occ (A, A'Loop_Entry));
               pragma Loop_Invariant (A (P) >= A (K));
               pragma Loop_Invariant (Is_Heap (A, Lo, Last));
               pragma Loop_Variant (Decreases => P);

               pragma Assert (P in Lo + 1 .. Last);
               pragma Assert (A (Parent (Lo, P)) >= A (P));
               P := Parent (Lo, P);
               pragma Assert (A (P) >= A (K));
            end loop;
            pragma Assert (P = Lo);
            pragma Assert (A (Lo) >= A (K));
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
         and then Heap_Last in A'Range
         and then Root in A'First .. Heap_Last
         and then
           Heap_From (A, A'First, Heap_Last, Natural (Root) + 1)
         and then Heap_Leq_Suffix (A, A'First, Heap_Last, N),
       Post   =>
         In_Bounds (A)
         and then Heap_From (A, A'First, Heap_Last, Natural (Root))
         and then Heap_Leq_Suffix (A, A'First, Heap_Last, N)
         and then
           (for all K in Heap_Last + 1 .. A'Last => A (K) = A'Old (K))
         and then
           (for all K in A'First .. Root - 1 => A (K) = A'Old (K))
         and then Same_Occ (A, A'Old)
   is
      Lo    : constant Index := Index (A'First);
      R     : Index := Root;
      Child : Index;
      Left  : Index;
   begin
      loop
         pragma Loop_Invariant (R in Root .. Heap_Last);
         pragma Loop_Invariant (Same_Occ (A, A'Loop_Entry));
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all K in Heap_Last + 1 .. A'Last =>
              A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in Lo .. Root - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (Heap_Except_Hole (A, Lo, Heap_Last, Root, R));
         pragma Loop_Invariant
           (if R > Root then A (Parent (Lo, R)) >= A (R));
         pragma Loop_Invariant (Heap_Leq_Suffix (A, Lo, Heap_Last, N));
         pragma Loop_Invariant
           (if R > Root and then Has_Left (Lo, Heap_Last, R) then
              A (Parent (Lo, R)) >= A (Left_Child (Lo, Heap_Last, R))
              and then
              (if Left_Child (Lo, Heap_Last, R) < Heap_Last then
                 A (Parent (Lo, R)) >= A (Left_Child (Lo, Heap_Last, R) + 1)));
         pragma Loop_Variant (Decreases => Heap_Last - R + 1);

         if not Has_Left (Lo, Heap_Last, R) then
            pragma Assert (Heap_From (A, Lo, Heap_Last, Natural (Root)));
            return;
         end if;

         Left := Left_Child (Lo, Heap_Last, R);
         pragma Assert (Left in R + 1 .. Heap_Last);
         pragma Assert (Parent (Lo, Left) = R);
         pragma Assert
           (if Left < Heap_Last then Parent (Lo, Left + 1) = R);
         Child := Left;

         if Left < Heap_Last and then A (Left) < A (Left + 1) then
            Child := Left + 1;
         end if;

         pragma Assert (Child = Left or else Child = Left + 1);
         pragma Assert (Parent (Lo, Child) = R);
         --  Child's own children (if any) are covered by Child before the swap:
         --  hole is R, Parent(grand)=Child /= R, so Heap_Except_Hole applies.
         pragma Assert
           (if Has_Left (Lo, Heap_Last, Child) then
              Parent (Lo, Left_Child (Lo, Heap_Last, Child)) = Child
              and then A (Child) >= A (Left_Child (Lo, Heap_Last, Child))
              and then
              (if Left_Child (Lo, Heap_Last, Child) < Heap_Last then
                 Parent (Lo, Left_Child (Lo, Heap_Last, Child) + 1) = Child
                 and then
                 A (Child) >= A (Left_Child (Lo, Heap_Last, Child) + 1)));
         pragma Assert (A (Child) >= A (Left));
         pragma Assert
           (if Left < Heap_Last then A (Child) >= A (Left + 1));
         pragma Assert
           (if R > Root then A (Parent (Lo, R)) >= A (Child));

         if A (R) >= A (Child) then
            pragma Assert (A (R) >= A (Left));
            pragma Assert
              (if Left < Heap_Last then A (R) >= A (Left + 1));
            pragma Assert
              (for all I in Lo + 1 .. Heap_Last =>
                 (if Parent (Lo, I) = R then I = Left or else I = Left + 1));
            pragma Assert
              (for all I in Lo + 1 .. Heap_Last =>
                 (if Parent (Lo, I) >= Root then
                    A (Parent (Lo, I)) >= A (I)));
            pragma Assert (Heap_From (A, Lo, Heap_Last, Natural (Root)));
            return;
         end if;

         Swap (A, R, Child);
         --  A(R) is former A(Child); grandchildren stay under former Child value.

         pragma Assert (A (R) >= A (Left));
         pragma Assert
           (if Left < Heap_Last then A (R) >= A (Left + 1));
         pragma Assert (A (R) >= A (Child));
         pragma Assert (Parent (Lo, Child) = R);
         pragma Assert (if R > Root then A (Parent (Lo, R)) >= A (R));
         pragma Assert
           (if Has_Left (Lo, Heap_Last, Child) then
              A (R) >= A (Left_Child (Lo, Heap_Last, Child))
              and then
              (if Left_Child (Lo, Heap_Last, Child) < Heap_Last then
                 A (R) >= A (Left_Child (Lo, Heap_Last, Child) + 1)));
         pragma Assert
           (for all I in Lo + 1 .. Heap_Last =>
              (if Parent (Lo, I) = R then I = Left or else I = Left + 1));
         pragma Assert
           (for all I in Lo + 1 .. Heap_Last =>
              (if Parent (Lo, I) = R then A (R) >= A (I)));
         pragma Assert
           (Heap_Except_Hole (A, Lo, Heap_Last, Root, Child));
         pragma Assert (Heap_Leq_Suffix (A, Lo, Heap_Last, N));

         R := Child;
         pragma Assert (if R > Root then A (Parent (Lo, R)) >= A (R));
      end loop;
   end Sift_Down_Restore;

   procedure Sift_Down
     (A         : in out Element_Array;
      Root      : Index;
      Heap_Last : Index)
   is
      Lo    : constant Index := Index (A'First);
      R     : Index := Root;
      Child : Index;
      Left  : Index;
   begin
      loop
         pragma Loop_Invariant (R in Root .. Heap_Last);
         pragma Loop_Invariant (Same_Occ (A, A'Loop_Entry));
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all K in Heap_Last + 1 .. A'Last =>
              A (K) = A'Loop_Entry (K));
         pragma Loop_Variant (Decreases => Heap_Last - R + 1);

         if not Has_Left (Lo, Heap_Last, R) then
            return;
         end if;

         Left  := Left_Child (Lo, Heap_Last, R);
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
      N     : Index;
      Start : Index;
      Lo    : Index;
   begin
      if A'Length <= 1 then
         return;
      end if;

      Lo := Index (A'First);
      N  := Index (A'Last);
      --  Last parent = Parent (Lo, N) = Lo + (N - Lo - 1) / 2.
      Start := Parent (Lo, N);
      pragma Assert (Start in Lo .. N);
      pragma Assert (Heap_From (A, Lo, N, Natural (Start) + 1));
      pragma Assert (Heap_Leq_Suffix (A, Lo, N, N));

      loop
         pragma Loop_Invariant (Start in Lo .. Parent (Lo, N));
         pragma Loop_Invariant (Same_Occ (A, A'Loop_Entry));
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Heap_From (A, Lo, N, Natural (Start) + 1));
         pragma Loop_Invariant (Heap_Leq_Suffix (A, Lo, N, N));
         pragma Loop_Variant (Decreases => Start);

         Sift_Down_Restore (A, Start, N, N);
         pragma Assert (Heap_From (A, Lo, N, Natural (Start)));

         exit when Start = Lo;
         Start := Start - 1;
      end loop;

      pragma Assert (Is_Heap (A, Lo, N));
   end Heapify;

   procedure Sort (A : in out Element_Array) is
      Heap_Last : Index;
      N         : Index;
      Start     : Index;
      Lo        : Index;
   begin
      if A'Length <= 1 then
         return;
      end if;

      Lo := Index (A'First);
      N  := Index (A'Last);
      pragma Assert (N >= Lo + 1);

      Start := Parent (Lo, N);
      pragma Assert (Heap_From (A, Lo, N, Natural (Start) + 1));
      pragma Assert (Heap_Leq_Suffix (A, Lo, N, N));
      loop
         pragma Loop_Invariant (Start in Lo .. Parent (Lo, N));
         pragma Loop_Invariant (Same_Occ (A, A'Loop_Entry));
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Heap_From (A, Lo, N, Natural (Start) + 1));
         pragma Loop_Invariant (Heap_Leq_Suffix (A, Lo, N, N));
         pragma Loop_Variant (Decreases => Start);

         Sift_Down_Restore (A, Start, N, N);
         pragma Assert (Heap_From (A, Lo, N, Natural (Start)));

         exit when Start = Lo;
         Start := Start - 1;
      end loop;

      pragma Assert (Is_Heap (A, Lo, N));
      Lemma_Root_Is_Max (A, Lo, N);

      Heap_Last := N;
      pragma Assert (Sorted_Slice (A, N + 1, N));
      pragma Assert (Heap_Leq_Suffix (A, Lo, N, N));

      while Heap_Last > Lo loop
         pragma Loop_Invariant (Heap_Last in Lo + 1 .. N);
         pragma Loop_Invariant (Same_Occ (A, A'Loop_Entry));
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Is_Heap (A, Lo, Heap_Last));
         pragma Loop_Invariant (Sorted_Slice (A, Heap_Last + 1, N));
         pragma Loop_Invariant (Heap_Leq_Suffix (A, Lo, Heap_Last, N));
         pragma Loop_Variant (Decreases => Heap_Last);

         Lemma_Root_Is_Max (A, Lo, Heap_Last);
         pragma Assert
           (for all K in Lo .. Heap_Last => A (Lo) >= A (K));

         Swap (A, Lo, Heap_Last);

         pragma Assert
           (Heap_Last = N
            or else A (Heap_Last) <= A (Heap_Last + 1));
         pragma Assert (Sorted_Slice (A, Heap_Last, N));
         pragma Assert
           (for all H in Lo .. Heap_Last - 1 =>
              (for all S in Heap_Last .. N => A (H) <= A (S)));

         pragma Assert (Heap_From (A, Lo, Heap_Last - 1, Natural (Lo) + 1));

         Heap_Last := Heap_Last - 1;

         pragma Assert (Heap_Leq_Suffix (A, Lo, Heap_Last, N));
         pragma Assert (Heap_From (A, Lo, Heap_Last, Natural (Lo) + 1));

         Sift_Down_Restore (A, Lo, Heap_Last, N);
         pragma Assert (Is_Heap (A, Lo, Heap_Last));
         pragma Assert (Sorted_Slice (A, Heap_Last + 1, N));
         pragma Assert (Heap_Leq_Suffix (A, Lo, Heap_Last, N));
      end loop;

      pragma Assert (Heap_Last = Lo);
      pragma Assert (Sorted_Slice (A, Lo + 1, N));
      pragma Assert (Heap_Leq_Suffix (A, Lo, Lo, N));
      pragma Assert (A (Lo) <= A (Lo + 1));
      pragma Assert (Is_Sorted (A));
   end Sort;

end Heapsort;
