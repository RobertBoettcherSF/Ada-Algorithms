pragma Ada_2022;

--  Bounded introsort for eight values.
--  Sort computes 2 * floor(log2(8)) = 6 once. Sort_Range then either
--  insertion-sorts a slice of at most Insertion_Cutoff (2) elements,
--  heapsorts a longer slice whose remaining depth is 0, or
--  Lomuto-partitions the slice around its last element and recurses
--  on both sides with Depth - 1. The budget is not recomputed per slice.
--  Heapify is the Floyd build on the whole array (the length-8 fallback
--  and the direct heap check). Partition is one Lomuto step on the
--  whole array.

package body Intro_Sort with SPARK_Mode => On is

   --  Parent of a 1-based heap index. Children of P are 2*P and 2*P+1.
   function Parent (I : Index) return Index is (I / 2)
   with
     Global => null,
     Pre    => I > Index'First,
     Post   =>
       Parent'Result in Index'First .. I - 1
       and then 2 * Parent'Result <= I
       and then I <= 2 * Parent'Result + 1;

   function Has_Left (Heap_Last, I : Index) return Boolean is
     (2 * I <= Integer (Heap_Last))
   with
     Global => null,
     Pre    => I <= Heap_Last;

   --  Left child 2*I. The right child, when it exists, is 2*I+1.
   function Left_Child (Heap_Last, I : Index) return Index
   with
     Global => null,
     Pre    =>
       I <= Heap_Last
       and then Has_Left (Heap_Last, I),
     Post   =>
       Left_Child'Result = 2 * I
       and then Left_Child'Result in I + 1 .. Heap_Last
       and then Parent (Left_Child'Result) = I
       and then
         (if Left_Child'Result < Heap_Last then
            Parent (Left_Child'Result + 1) = I)
   is
      L : Index;
   begin
      pragma Assert (2 * I in Index);
      L := 2 * I;
      pragma Assert (L / 2 = I);
      pragma Assert (Parent (L) = I);
      if L < Heap_Last then
         pragma Assert ((L + 1) / 2 = I);
         pragma Assert (Parent (L + 1) = I);
      end if;
      return L;
   end Left_Child;

   --  A (L .. R) is nondecreasing. L > R is the empty slice (used for a
   --  suffix that has not started).
   function Sorted_Slice (A : Input_Array; L, R : Natural) return Boolean is
     (L >= R
      or else (for all K in L .. R - 1 =>
                 A (Index (K)) <= A (Index (K + 1))))
   with
     Ghost,
     Global => null,
     Pre    => R <= Index'Last and then (L > R or else L in 1 .. R);

   --  Parent form of a max-heap on 1 .. Last: every node is <= its parent.
   function Is_Heap (A : Input_Array; Last : Index) return Boolean is
     (for all I in Index =>
        (if I > Index'First and then I <= Last then
           A (Parent (I)) >= A (I)))
   with Ghost, Global => null;

   --  Heap edges whose parent index is >= Bound. Bound = 1 is the whole heap.
   function Heap_From
     (A : Input_Array; Last : Index; Bound : Natural) return Boolean
   is
     (Bound > Natural (Last)
      or else
        (for all I in Index =>
           (if I > Index'First and then I <= Last
              and then Natural (Parent (I)) >= Bound
            then
              A (Parent (I)) >= A (I))))
   with Ghost, Global => null;

   --  A (H) <= each suffix slot from S onward. S = Index'Last + 1 is empty.
   function Slot_Leq_From
     (A : Input_Array; H : Index; S : Natural) return Boolean
   is
     (if S > Index'Last then True
      else A (H) <= A (Index (S)) and then Slot_Leq_From (A, H, S + 1))
   with
     Ghost,
     Global             => null,
     Pre                => S >= 1 and then S <= Index'Last + 1,
     Subprogram_Variant => (Decreases => Index'Last + 1 - S);

   --  Slots H .. Heap_Last are each <= the suffix past Heap_Last.
   function Heap_Leq_From
     (A : Input_Array; H : Natural; Heap_Last : Index) return Boolean
   is
     (if H > Natural (Heap_Last) then True
      else Slot_Leq_From (A, Index (H), Natural (Heap_Last) + 1)
           and then Heap_Leq_From (A, H + 1, Heap_Last))
   with
     Ghost,
     Global             => null,
     Pre                => H >= 1 and then H <= Index'Last + 1,
     Subprogram_Variant => (Decreases => Index'Last + 1 - H);

   --  Every live heap slot is <= every already extracted suffix slot.
   function Heap_Leq_Suffix (A : Input_Array; Heap_Last : Index) return Boolean
   is (Heap_Leq_From (A, 1, Heap_Last))
   with Ghost, Global => null;

   --  Heap edges hold except those whose parent is the hole R.
   function Heap_Except_Hole
     (A : Input_Array; Last, Root, R : Index) return Boolean
   is
     (for all I in Index =>
        (if I > Index'First and then I <= Last
           and then Parent (I) >= Root and then Parent (I) /= R
         then
           A (Parent (I)) >= A (I)))
   with
     Ghost,
     Global => null,
     Pre    => Root <= Last and then R in Root .. Last;

   package Perm_Lemmas with Ghost is
      procedure Lemma_Occ_Frame (A, B : Input_Array; Last : Natural)
      with
        Global             => null,
        Pre                =>
          Last <= Index'Last
          and then
            (for all K in Index =>
               (if Natural (K) <= Last then A (K) = B (K))),
        Post               =>
          (for all V in Value => Occ (A, V, Last) = Occ (B, V, Last)),
        Subprogram_Variant => (Decreases => Last);

      procedure Lemma_Occ_Set
        (A, B : Input_Array; K : Index; Last : Natural)
      with
        Global             => null,
        Pre                =>
          Last in Natural (K) .. Natural (Index'Last)
          and then (for all J in Index => (if J /= K then A (J) = B (J))),
        Post               =>
          (for all V in Value =>
             Occ (B, V, Last)
             = Occ (A, V, Last)
               - (if A (K) = V then 1 else 0)
               + (if B (K) = V then 1 else 0)),
        Subprogram_Variant => (Decreases => Last);

      procedure Lemma_Swap (A, B : Input_Array; X, Y : Index)
      with
        Global => null,
        Pre    =>
          B (X) = A (Y)
          and then B (Y) = A (X)
          and then
            (for all J in Index =>
               (if J /= X and then J /= Y then A (J) = B (J))),
        Post   => Is_Perm (A, B);
   end Perm_Lemmas;

   package body Perm_Lemmas is
      procedure Lemma_Occ_Frame (A, B : Input_Array; Last : Natural) is
      begin
         if Last >= 1 then
            Lemma_Occ_Frame (A, B, Last - 1);
         end if;
      end Lemma_Occ_Frame;

      procedure Lemma_Occ_Set
        (A, B : Input_Array; K : Index; Last : Natural)
      is
      begin
         if Last > Natural (K) then
            Lemma_Occ_Set (A, B, K, Last - 1);
         else
            Lemma_Occ_Frame (A, B, Natural (K) - 1);
         end if;
      end Lemma_Occ_Set;

      procedure Lemma_Swap (A, B : Input_Array; X, Y : Index) is
      begin
         if X = Y then
            Lemma_Occ_Frame (A, B, Index'Last);
            return;
         end if;
         declare
            C : constant Input_Array := (A with delta X => A (Y));
         begin
            Lemma_Occ_Set (A, C, X, Index'Last);
            Lemma_Occ_Set (C, B, Y, Index'Last);
         end;
      end Lemma_Swap;
   end Perm_Lemmas;
   use Perm_Lemmas;

   procedure Swap (A : in out Input_Array; X, Y : Index)
   with
     Global => null,
     Post   =>
       A (X) = A'Old (Y)
       and then A (Y) = A'Old (X)
       and then
         (for all K in Index =>
            (if K /= X and then K /= Y then A (K) = A'Old (K)))
       and then Is_Perm (A, A'Old)
   is
      T      : constant Value := A (X);
      Before : constant Input_Array := A with Ghost;
   begin
      A (X) := A (Y);
      A (Y) := T;
      Lemma_Swap (Before, A, X, Y);
   end Swap;

   procedure Lemma_Project_Slot
     (A : Input_Array; H : Natural; Heap_Last : Index)
   with
     Ghost,
     Global => null,
     Pre    =>
       H in 1 .. Natural (Heap_Last)
       and then Heap_Leq_From (A, H, Heap_Last),
     Post   =>
       Slot_Leq_From (A, Index (H), Natural (Heap_Last) + 1)
       and then Heap_Leq_From (A, H + 1, Heap_Last)
   is
   begin
      pragma Assert
        (Heap_Leq_From (A, H, Heap_Last)
         = (Slot_Leq_From (A, Index (H), Natural (Heap_Last) + 1)
            and then Heap_Leq_From (A, H + 1, Heap_Last)));
   end Lemma_Project_Slot;

   --  Walk from the root side of the heap until Target's suffix bound.
   procedure Lemma_Slot_Of
     (A : Input_Array; Target, Heap_Last : Index)
   with
     Ghost,
     Global => null,
     Pre    => Target <= Heap_Last and then Heap_Leq_Suffix (A, Heap_Last),
     Post   => Slot_Leq_From (A, Target, Natural (Heap_Last) + 1)
   is
      H : Natural := 1;
   begin
      while H < Natural (Target) loop
         pragma Loop_Invariant (H in 1 .. Natural (Target));
         pragma Loop_Invariant (Heap_Leq_From (A, H, Heap_Last));
         pragma Loop_Variant (Increases => H);

         Lemma_Project_Slot (A, H, Heap_Last);
         H := H + 1;
      end loop;
      pragma Assert (H = Natural (Target));
      pragma Assert (Heap_Leq_From (A, H, Heap_Last));
      Lemma_Project_Slot (A, H, Heap_Last);
   end Lemma_Slot_Of;

   --  After (Dst) = Before (Src), and the suffix from S on is unchanged.
   procedure Lemma_Carry_Slot
     (Before, After : Input_Array; Src, Dst : Index; S : Natural)
   with
     Ghost,
     Global             => null,
     Pre                =>
       S in 1 .. Index'Last + 1
       and then After (Dst) = Before (Src)
       and then
         (for all K in Index =>
            (if Natural (K) >= S then After (K) = Before (K)))
       and then Slot_Leq_From (Before, Src, S),
     Post               => Slot_Leq_From (After, Dst, S),
     Subprogram_Variant => (Decreases => Index'Last + 1 - S)
   is
   begin
      if S <= Index'Last then
         pragma Assert
           (Slot_Leq_From (Before, Src, S)
            = (Before (Src) <= Before (Index (S))
               and then Slot_Leq_From (Before, Src, S + 1)));
         pragma Assert (After (Index (S)) = Before (Index (S)));
         pragma Assert (After (Dst) <= After (Index (S)));
         Lemma_Carry_Slot (Before, After, Src, Dst, S + 1);
         pragma Assert
           (Slot_Leq_From (After, Dst, S)
            = (After (Dst) <= After (Index (S))
               and then Slot_Leq_From (After, Dst, S + 1)));
      end if;
   end Lemma_Carry_Slot;

   procedure Lemma_Carry_Heap
     (Before, After : Input_Array;
      H             : Natural;
      Heap_Last, X, Y : Index)
   with
     Ghost,
     Global             => null,
     Pre                =>
       H in 1 .. Index'Last + 1
       and then X <= Heap_Last
       and then Y <= Heap_Last
       and then After (X) = Before (Y)
       and then After (Y) = Before (X)
       and then
         (for all K in Index =>
            (if K /= X and then K /= Y then After (K) = Before (K)))
       and then
         (for all K in Index =>
            (if K > Heap_Last then After (K) = Before (K)))
       and then Heap_Leq_From (Before, H, Heap_Last)
       and then Slot_Leq_From (Before, X, Natural (Heap_Last) + 1)
       and then Slot_Leq_From (Before, Y, Natural (Heap_Last) + 1),
     Post               => Heap_Leq_From (After, H, Heap_Last),
     Subprogram_Variant => (Decreases => Index'Last + 1 - H)
   is
      S : constant Natural := Natural (Heap_Last) + 1;
   begin
      if H <= Natural (Heap_Last) then
         Lemma_Project_Slot (Before, H, Heap_Last);
         if Index (H) = X then
            Lemma_Carry_Slot (Before, After, Y, Index (H), S);
         elsif Index (H) = Y then
            Lemma_Carry_Slot (Before, After, X, Index (H), S);
         else
            Lemma_Carry_Slot (Before, After, Index (H), Index (H), S);
         end if;
         pragma Assert
           (Heap_Leq_From (After, H, Heap_Last)
            = (Slot_Leq_From (After, Index (H), S)
               and then Heap_Leq_From (After, H + 1, Heap_Last)));
         Lemma_Carry_Heap (Before, After, H + 1, Heap_Last, X, Y);
      end if;
   end Lemma_Carry_Heap;

   --  Swapping two slots inside the live heap keeps every heap slot <= the
   --  extracted suffix.
   procedure Lemma_Swap_Keeps_Suffix
     (Before, After : Input_Array; X, Y, Heap_Last : Index)
   with
     Ghost,
     Global => null,
     Pre    =>
       X <= Heap_Last
       and then Y <= Heap_Last
       and then Heap_Leq_Suffix (Before, Heap_Last)
       and then After (X) = Before (Y)
       and then After (Y) = Before (X)
       and then
         (for all K in Index =>
            (if K /= X and then K /= Y then After (K) = Before (K))),
     Post   => Heap_Leq_Suffix (After, Heap_Last)
   is
   begin
      Lemma_Slot_Of (Before, X, Heap_Last);
      Lemma_Slot_Of (Before, Y, Heap_Last);
      Lemma_Carry_Heap (Before, After, 1, Heap_Last, X, Y);
   end Lemma_Swap_Keeps_Suffix;

   --  No extracted suffix yet: the bound holds for every array.
   procedure Lemma_No_Suffix (A : Input_Array)
   with
     Ghost,
     Global => null,
     Post   => Heap_Leq_Suffix (A, Index'Last)
   is
      H : Natural := Index'Last + 1;
   begin
      pragma Assert (Heap_Leq_From (A, H, Index'Last));
      loop
         pragma Loop_Invariant (H in 1 .. Index'Last + 1);
         pragma Loop_Invariant (Heap_Leq_From (A, H, Index'Last));
         pragma Loop_Variant (Decreases => H);

         exit when H = 1;
         declare
            Prev : constant Natural := H;
         begin
            H := H - 1;
            pragma Assert (Slot_Leq_From (A, Index (H), Index'Last + 1));
            pragma Assert (Heap_Leq_From (A, Prev, Index'Last));
            pragma Assert
              (Heap_Leq_From (A, H, Index'Last)
               = (Slot_Leq_From (A, Index (H), Index'Last + 1)
                  and then Heap_Leq_From (A, Prev, Index'Last)));
            pragma Assert (Heap_Leq_From (A, H, Index'Last));
         end;
      end loop;
   end Lemma_No_Suffix;

   --  The root is <= the first already-extracted slot, when there is one.
   procedure Lemma_Root_Leq_Successor (A : Input_Array; Heap_Last : Index)
   with
     Ghost,
     Global => null,
     Pre    => Heap_Leq_Suffix (A, Heap_Last),
     Post   =>
       (if Heap_Last < Index'Last then
          A (Index'First) <= A (Index (Natural (Heap_Last) + 1)))
   is
   begin
      if Heap_Last < Index'Last then
         Lemma_Slot_Of (A, Index'First, Heap_Last);
         pragma Assert
           (Slot_Leq_From (A, Index'First, Natural (Heap_Last) + 1)
            = (A (Index'First) <= A (Index (Natural (Heap_Last) + 1))
               and then
               Slot_Leq_From (A, Index'First, Natural (Heap_Last) + 2)));
      end if;
   end Lemma_Root_Leq_Successor;

   --  A one-element heap sitting under a sorted suffix is <= its neighbor.
   procedure Lemma_First_Leq_Second (A : Input_Array)
   with
     Ghost,
     Global => null,
     Pre    => Heap_Leq_Suffix (A, Index'First),
     Post   => A (Index'First) <= A (Index'First + 1)
   is
   begin
      Lemma_Root_Leq_Successor (A, Index'First);
   end Lemma_First_Leq_Second;

   --  The root of a max-heap is a maximum of 1 .. Last.
   procedure Lemma_Root_Is_Max (A : Input_Array; Last : Index)
   with
     Ghost,
     Global => null,
     Pre    => Is_Heap (A, Last),
     Post   =>
       (for all K in Index => (if K <= Last then A (Index'First) >= A (K)))
   is
   begin
      for K in Natural'(1) .. Natural (Last) loop
         pragma Loop_Invariant
           (for all J in 1 .. K - 1 => A (Index'First) >= A (Index (J)));
         pragma Loop_Invariant (Is_Heap (A, Last));

         declare
            P : Index := Index (K);
         begin
            pragma Assert (A (P) >= A (Index (K)));
            while P > Index'First loop
               pragma Loop_Invariant (P in Index'First .. Last);
               pragma Loop_Invariant (A (P) >= A (Index (K)));
               pragma Loop_Invariant (Is_Heap (A, Last));
               pragma Loop_Variant (Decreases => P);

               pragma Assert (P > Index'First);
               pragma Assert (A (Parent (P)) >= A (P));
               P := Parent (P);
               pragma Assert (A (P) >= A (Index (K)));
            end loop;
            pragma Assert (P = Index'First);
            pragma Assert (A (Index'First) >= A (Index (K)));
         end;
      end loop;
   end Lemma_Root_Is_Max;

   --  Child form (2*I and 2*I+1) and parent form describe the same full heap.
   procedure Lemma_Heap_Same (A : Input_Array)
   with
     Ghost,
     Global => null,
     Post   => Is_Max_Heap (A) = Is_Heap (A, Index'Last)
   is
   begin
      pragma Assert (Parent (2) = 1);
      pragma Assert (Parent (3) = 1);
      pragma Assert (Parent (4) = 2);
      pragma Assert (Parent (5) = 2);
      pragma Assert (Parent (6) = 3);
      pragma Assert (Parent (7) = 3);
      pragma Assert (Parent (8) = 4);

      for N in 2 .. 8 loop
         pragma Loop_Invariant
           (for all J in 2 .. N - 1 =>
              (if Is_Max_Heap (A) then
                 A (Parent (Index (J))) >= A (Index (J))));
         pragma Loop_Invariant
           (for all J in 2 .. N - 1 =>
              (if A (Parent (Index (J))) >= A (Index (J)) then
                 (if J = 2 then A (1) >= A (2)
                  elsif J = 3 then A (1) >= A (3)
                  elsif J = 4 then A (2) >= A (4)
                  elsif J = 5 then A (2) >= A (5)
                  elsif J = 6 then A (3) >= A (6)
                  elsif J = 7 then A (3) >= A (7)
                  else A (4) >= A (8))));
         declare
            I : constant Index := Index (N);
            P : constant Index := Parent (I);
         begin
            pragma Assert (2 * P <= Integer (I) and then Integer (I) <= 2 * P + 1);
            pragma Assert (I = 2 * P or else I = 2 * P + 1);
            if Is_Max_Heap (A) then
               pragma Assert (A (P) >= A (I));
            end if;
         end;
      end loop;

      pragma Assert
        (Is_Heap (A, Index'Last)
         = (A (Parent (2)) >= A (2) and then A (Parent (3)) >= A (3)
            and then A (Parent (4)) >= A (4) and then A (Parent (5)) >= A (5)
            and then A (Parent (6)) >= A (6) and then A (Parent (7)) >= A (7)
            and then A (Parent (8)) >= A (8)));
   end Lemma_Heap_Same;

   --  Restore the max-heap on 1 .. Heap_Last, sifting from Root.
   --  Both sub-heaps under Root are already heaps (Heap_From from Root+1).
   procedure Sift_Down_Restore
     (A : in out Input_Array; Root : Index; Heap_Last : Index)
   with
     Global => null,
     Pre    =>
       Root <= Heap_Last
       and then Heap_From (A, Heap_Last, Natural (Root) + 1)
       and then Heap_Leq_Suffix (A, Heap_Last),
     Post   =>
       Heap_From (A, Heap_Last, Natural (Root))
       and then Heap_Leq_Suffix (A, Heap_Last)
       and then
         (for all K in Index => (if K > Heap_Last then A (K) = A'Old (K)))
       and then
         (for all K in Index => (if K < Root then A (K) = A'Old (K)))
       and then Is_Perm (A, A'Old)
   is
      R : Index := Root;
   begin
      loop
         pragma Loop_Invariant (R in Root .. Heap_Last);
         pragma Loop_Invariant (Is_Perm (A, A'Loop_Entry));
         pragma Loop_Invariant
           (for all K in Index =>
              (if K > Heap_Last then A (K) = A'Loop_Entry (K)));
         pragma Loop_Invariant
           (for all K in Index =>
              (if K < Root then A (K) = A'Loop_Entry (K)));
         pragma Loop_Invariant (Heap_Except_Hole (A, Heap_Last, Root, R));
         pragma Loop_Invariant (if R > Root then A (Parent (R)) >= A (R));
         pragma Loop_Invariant (Heap_Leq_Suffix (A, Heap_Last));
         pragma Loop_Invariant
           (if R > Root and then Has_Left (Heap_Last, R) then
              A (Parent (R)) >= A (Left_Child (Heap_Last, R))
              and then
              (if Left_Child (Heap_Last, R) < Heap_Last then
                 A (Parent (R)) >= A (Left_Child (Heap_Last, R) + 1)));
         pragma Loop_Variant (Decreases => Heap_Last - R + 1);

         if not Has_Left (Heap_Last, R) then
            pragma Assert (Heap_From (A, Heap_Last, Natural (Root)));
            return;
         end if;

         declare
            Left  : Index := Left_Child (Heap_Last, R);
            Child : Index := Left;
         begin
            pragma Assert (Left in R + 1 .. Heap_Last);
            pragma Assert (Parent (Left) = R);
            pragma Assert (if Left < Heap_Last then Parent (Left + 1) = R);

            if Left < Heap_Last and then A (Left) < A (Left + 1) then
               Child := Left + 1;
            end if;

            pragma Assert (Child = Left or else Child = Left + 1);
            pragma Assert (Parent (Child) = R);
            pragma Assert
              (if Has_Left (Heap_Last, Child) then
                 Parent (Left_Child (Heap_Last, Child)) = Child
                 and then A (Child) >= A (Left_Child (Heap_Last, Child))
                 and then
                 (if Left_Child (Heap_Last, Child) < Heap_Last then
                    Parent (Left_Child (Heap_Last, Child) + 1) = Child
                    and then
                    A (Child) >= A (Left_Child (Heap_Last, Child) + 1)));
            pragma Assert (A (Child) >= A (Left));
            pragma Assert (if Left < Heap_Last then A (Child) >= A (Left + 1));
            pragma Assert (if R > Root then A (Parent (R)) >= A (Child));

            if A (R) >= A (Child) then
               pragma Assert (A (R) >= A (Left));
               pragma Assert
                 (if Left < Heap_Last then A (R) >= A (Left + 1));
               pragma Assert
                 (for all I in Index =>
                    (if I > Index'First and then I <= Heap_Last
                       and then Parent (I) = R
                     then
                       I = Left or else I = Left + 1));
               pragma Assert
                 (for all I in Index =>
                    (if I > Index'First and then I <= Heap_Last
                       and then Parent (I) >= Root
                     then
                       A (Parent (I)) >= A (I)));
               pragma Assert (Heap_From (A, Heap_Last, Natural (Root)));
               return;
            end if;

            declare
               Before : constant Input_Array := A with Ghost;
            begin
               Swap (A, R, Child);
               Lemma_Swap_Keeps_Suffix (Before, A, R, Child, Heap_Last);
            end;

            pragma Assert (A (R) >= A (Left));
            pragma Assert (if Left < Heap_Last then A (R) >= A (Left + 1));
            pragma Assert (A (R) >= A (Child));
            pragma Assert (Parent (Child) = R);
            pragma Assert (if R > Root then A (Parent (R)) >= A (R));
            pragma Assert
              (if Has_Left (Heap_Last, Child) then
                 A (R) >= A (Left_Child (Heap_Last, Child))
                 and then
                 (if Left_Child (Heap_Last, Child) < Heap_Last then
                    A (R) >= A (Left_Child (Heap_Last, Child) + 1)));
            pragma Assert
              (for all I in Index =>
                 (if I > Index'First and then I <= Heap_Last
                    and then Parent (I) = R
                  then
                    I = Left or else I = Left + 1));
            pragma Assert
              (for all I in Index =>
                 (if I > Index'First and then I <= Heap_Last
                    and then Parent (I) = R
                  then
                    A (R) >= A (I)));
            pragma Assert (Heap_Except_Hole (A, Heap_Last, Root, Child));

            R := Child;
            pragma Assert (if R > Root then A (Parent (R)) >= A (R));
         end;
      end loop;
   end Sift_Down_Restore;

   procedure Heapify (A : in out Input_Array) is
      Start : Index := Parent (Index'Last);
   begin
      --  Leaves have no children, so every edge below the last parent holds.
      pragma Assert (Start = Index'Last / 2);
      pragma Assert
        (for all I in Index =>
           (if I > Index'First then Parent (I) <= Index'Last / 2));
      pragma Assert (Heap_From (A, Index'Last, Natural (Start) + 1));
      Lemma_No_Suffix (A);

      loop
         pragma Loop_Invariant (Start in Index'First .. Parent (Index'Last));
         pragma Loop_Invariant (Is_Perm (A, A'Loop_Entry));
         pragma Loop_Invariant
           (Heap_From (A, Index'Last, Natural (Start) + 1));
         pragma Loop_Invariant (Heap_Leq_Suffix (A, Index'Last));
         pragma Loop_Variant (Decreases => Start);

         Sift_Down_Restore (A, Start, Index'Last);
         pragma Assert (Heap_From (A, Index'Last, Natural (Start)));

         exit when Start = Index'First;
         Start := Start - 1;
      end loop;

      pragma Assert (Is_Heap (A, Index'Last));
      Lemma_Heap_Same (A);
   end Heapify;
   function Heap_Sorted (Input : Input_Array) return Input_Array
   with
     Global => null,
     Post   =>
       Is_Sorted (Heap_Sorted'Result)
       and then Is_Perm (Heap_Sorted'Result, Input)
   is
      Work      : Input_Array := Input;
      Heap_Last : Index;
   begin
      Heapify (Work);
      Lemma_Heap_Same (Work);
      pragma Assert (Is_Heap (Work, Index'Last));
      Lemma_No_Suffix (Work);
      Lemma_Root_Is_Max (Work, Index'Last);

      Heap_Last := Index'Last;
      pragma Assert (Sorted_Slice (Work, Natural (Index'Last) + 1, Index'Last));

      while Heap_Last > Index'First loop
         pragma Loop_Invariant (Heap_Last in Index'First + 1 .. Index'Last);
         pragma Loop_Invariant (Is_Perm (Work, Input));
         pragma Loop_Invariant (Is_Heap (Work, Heap_Last));
         pragma Loop_Invariant
           (Sorted_Slice (Work, Natural (Heap_Last) + 1, Index'Last));
         pragma Loop_Invariant (Heap_Leq_Suffix (Work, Heap_Last));
         pragma Loop_Variant (Decreases => Heap_Last);

         Lemma_Root_Is_Max (Work, Heap_Last);
         pragma Assert
           (for all K in 1 .. Natural (Heap_Last) =>
              Work (Index'First) >= Work (Index (K)));

         declare
            Old_Root : constant Value := Work (Index'First);
            Old_Next : constant Value :=
              (if Heap_Last < Index'Last then
                 Work (Index (Natural (Heap_Last) + 1))
               else Work (Index'First));
         begin
            Lemma_Root_Leq_Successor (Work, Heap_Last);
            pragma Assert
              (if Heap_Last < Index'Last then Old_Root <= Old_Next);

            Swap (Work, Index'First, Heap_Last);

            pragma Assert (Work (Heap_Last) = Old_Root);
            if Heap_Last < Index'Last then
               pragma Assert
                 (Work (Index (Natural (Heap_Last) + 1)) = Old_Next);
               pragma Assert
                 (Work (Heap_Last) <= Work (Index (Natural (Heap_Last) + 1)));
            end if;
         end;
         pragma Assert (Sorted_Slice (Work, Natural (Heap_Last), Index'Last));
         pragma Assert
           (for all H in 1 .. Natural (Heap_Last) - 1 =>
              (for all S in Natural (Heap_Last) .. Natural (Index'Last) =>
                 Work (Index (H)) <= Work (Index (S))));
         pragma Assert
           (Heap_From (Work, Index (Natural (Heap_Last) - 1), Natural (Index'First) + 1));

         Heap_Last := Heap_Last - 1;

         pragma Assert (Heap_Leq_Suffix (Work, Heap_Last));
         pragma Assert (Heap_From (Work, Heap_Last, Natural (Index'First) + 1));

         Sift_Down_Restore (Work, Index'First, Heap_Last);
         pragma Assert (Is_Heap (Work, Heap_Last));
         pragma Assert
           (Sorted_Slice (Work, Natural (Heap_Last) + 1, Index'Last));
         pragma Assert (Heap_Leq_Suffix (Work, Heap_Last));
      end loop;

      pragma Assert (Heap_Last = Index'First);
      pragma Assert (Sorted_Slice (Work, 2, Index'Last));
      pragma Assert (Heap_Leq_Suffix (Work, Index'First));
      Lemma_First_Leq_Second (Work);
      pragma Assert (Is_Sorted (Work));
      return Work;
   end Heap_Sorted;
   procedure Exchange (A : in out Input_Array; X, Y : Index)
   with
     Global => null,
     Post   =>
       A (X) = A'Old (Y)
       and then A (Y) = A'Old (X)
       and then
         (for all K in Index =>
            (if K /= X and then K /= Y then A (K) = A'Old (K)))
   is
      T : constant Value := A (X);
   begin
      A (X) := A (Y);
      A (Y) := T;
   end Exchange;

   --  Length of the inclusive slice Lo .. Hi. Lo <= Hi, so the result
   --  is in 1 .. 8.
   function Slice_Length (Lo, Hi : Index) return Natural is
     (Natural (Hi) - Natural (Lo) + 1)
   with
     Global => null,
     Pre    => Lo <= Hi,
     Post   => Slice_Length'Result in 1 .. Index'Last;

   --  Left child of I in a heap rooted at Lo. Relative index D = I - Lo
   --  has left child at Lo + 2*D + 1 (the ordinary 2*I when Lo = 1).
   function Slice_Has_Left (Lo, Heap_Last, I : Index) return Boolean is
     (Heap_Last > Lo
      and then Integer (I) - Integer (Lo)
           <= (Integer (Heap_Last) - Integer (Lo) - 1) / 2)
   with
     Global => null,
     Pre    => Lo <= Heap_Last and then I in Lo .. Heap_Last;

   function Slice_Left (Lo, Heap_Last, I : Index) return Index
   with
     Global => null,
     Pre    =>
       Lo <= Heap_Last
       and then I in Lo .. Heap_Last
       and then Slice_Has_Left (Lo, Heap_Last, I),
     Post   => Slice_Left'Result in I + 1 .. Heap_Last
   is
      D : constant Integer := Integer (I) - Integer (Lo);
      N : constant Integer := Integer (Heap_Last) - Integer (Lo);
      L : Integer;
   begin
      pragma Assert (D in 0 .. 7);
      pragma Assert (N in 1 .. 7);
      pragma Assert (Heap_Last > Lo);
      pragma Assert (D <= (N - 1) / 2);
      pragma Assert (2 * D <= N - 1);
      L := Integer (Lo) + 2 * D + 1;
      pragma Assert (L <= Integer (Heap_Last));
      pragma Assert (L >= Integer (I) + 1);
      pragma Assert (L in Integer (Index'First) .. Integer (Index'Last));
      return Index (L);
   end Slice_Left;

   --  Ascending order on Lo .. Hi. The caller has Lo < Hi.
   function Slice_Sorted (A : Input_Array; Lo, Hi : Index) return Boolean is
     (for all I in Lo .. Hi - 1 => A (I) <= A (I + 1))
   with
     Global => null,
     Pre    => Lo < Hi;

   --  Restore the max-heap on Lo .. Heap_Last, sifting from Root.
   --  The larger child is chosen; equal children keep the left one.
   --  A swap happens only when the child is strictly greater.
   procedure Sift_Down_Slice
     (A : in out Input_Array; Lo, Root, Heap_Last : Index)
   with
     Global => null,
     Pre    => Lo <= Root and then Root <= Heap_Last,
     Post   =>
       (for all K in Index =>
          (if K < Lo or else K > Heap_Last then A (K) = A'Old (K)))
   is
      R : Index := Root;
   begin
      loop
         pragma Loop_Invariant (R in Root .. Heap_Last);
         pragma Loop_Invariant
           (for all K in Index =>
              (if K < Lo or else K > Heap_Last then A (K) = A'Loop_Entry (K)));
         pragma Loop_Variant (Decreases => Integer (Heap_Last) - Integer (R));

         if not Slice_Has_Left (Lo, Heap_Last, R) then
            return;
         end if;

         declare
            Left  : constant Index := Slice_Left (Lo, Heap_Last, R);
            Child : Index := Left;
         begin
            pragma Assert (Left in R + 1 .. Heap_Last);
            if Left < Heap_Last and then A (Left) < A (Left + 1) then
               pragma Assert (Left < Index'Last);
               Child := Left + 1;
            end if;
            pragma Assert (Child in R + 1 .. Heap_Last);

            if A (R) >= A (Child) then
               return;
            end if;

            Exchange (A, R, Child);
            pragma Assert
              (for all K in Index =>
                 (if K < Lo or else K > Heap_Last then
                    A (K) = A'Loop_Entry (K)));
            R := Child;
         end;
      end loop;
   end Sift_Down_Slice;

   --  Floyd build of a max-heap on the slice Lo .. Hi (length at least 2).
   procedure Heapify_Slice (A : in out Input_Array; Lo, Hi : Index)
   with
     Global => null,
     Pre    => Lo < Hi,
     Post   =>
       (for all K in Index'First .. Lo - 1 => A (K) = A'Old (K))
       and then (for all K in Hi + 1 .. Index'Last => A (K) = A'Old (K))
   is
      Start : Index;
   begin
      declare
         Off : constant Integer := (Integer (Hi) - Integer (Lo) - 1) / 2;
         S   : constant Integer := Integer (Lo) + Off;
      begin
         pragma Assert (Integer (Hi) > Integer (Lo));
         pragma Assert (Off in 0 .. 3);
         pragma Assert (S >= Integer (Lo));
         pragma Assert (S <= Integer (Hi) - 1);
         pragma Assert (S in Integer (Index'First) .. Integer (Index'Last));
         Start := Index (S);
      end;

      loop
         pragma Loop_Invariant (Start in Lo .. Hi);
         pragma Loop_Invariant
           (for all K in Index =>
              (if K < Lo or else K > Hi then A (K) = A'Loop_Entry (K)));
         pragma Loop_Variant (Decreases => Start);

         Sift_Down_Slice (A, Lo, Start, Hi);

         exit when Start = Lo;
         pragma Assert (Start > Index'First);
         Start := Start - 1;
      end loop;
   end Heapify_Slice;

   --  Heapsort of a slice that is not the whole array. Same child rule
   --  as Heapify: larger child, left child on a tie, swap only when the
   --  child is strictly greater.
   procedure Heap_Sort_Slice (A : in out Input_Array; Lo, Hi : Index)
   with
     Global => null,
     Pre    => Lo <= Hi,
     Post   =>
       (for all K in Index'First .. Lo - 1 => A (K) = A'Old (K))
       and then (for all K in Hi + 1 .. Index'Last => A (K) = A'Old (K))
   is
      Heap_Last : Index;
      Original  : constant Input_Array := A with Ghost;
   begin
      if Lo = Hi then
         return;
      end if;

      Heapify_Slice (A, Lo, Hi);
      pragma Assert
        (for all K in Index =>
           (if K < Lo or else K > Hi then A (K) = Original (K)));

      Heap_Last := Hi;
      while Heap_Last > Lo loop
         pragma Loop_Invariant
           (Natural (Heap_Last) in Natural (Lo) + 1 .. Natural (Hi));
         pragma Loop_Invariant
           (for all K in Index =>
              (if K < Lo or else K > Hi then A (K) = Original (K)));
         pragma Loop_Variant (Decreases => Heap_Last);

         Exchange (A, Lo, Heap_Last);
         pragma Assert (Heap_Last > Index'First);
         Heap_Last := Heap_Last - 1;
         Sift_Down_Slice (A, Lo, Lo, Heap_Last);
      end loop;
   end Heap_Sort_Slice;

   procedure Heap_Sort_Full (A : in out Input_Array)
   with
     Global => null,
     Post   => Is_Sorted (A) and then Is_Perm (A, A'Old)
   is
   begin
      A := Heap_Sorted (A);
   end Heap_Sort_Full;

   procedure Heap_Sort_Range (A : in out Input_Array; Lo, Hi : Index) is
   begin
      if Lo = Hi then
         return;
      elsif Lo = Index'First and then Hi = Index'Last then
         Heap_Sort_Full (A);
      else
         Heap_Sort_Slice (A, Lo, Hi);
      end if;
   end Heap_Sort_Range;

   --  Lomuto partition of A (Lo .. Hi). The pivot is A (Hi). On return
   --  P is the pivot's index, A (Lo .. P - 1) <= A (P), and
   --  A (P + 1 .. Hi) >= A (P). Cells outside Lo .. Hi are untouched.
   procedure Partition_Range
     (A : in out Input_Array; Lo, Hi : Index; P : out Index) is
      Pivot : constant Value := A (Hi);
      I     : Index := Lo;
      J     : Index := Lo;
   begin
      while J < Hi loop
         pragma Loop_Invariant (J in Lo .. Hi - 1);
         pragma Loop_Invariant (I in Lo .. J);
         pragma Loop_Invariant (A (Hi) = Pivot);
         pragma Loop_Invariant
           (for all K in Lo .. Hi => (if K < I then A (K) <= Pivot));
         pragma Loop_Invariant
           (for all K in Lo .. Hi =>
              (if K >= I and then K < J then A (K) > Pivot));
         pragma Loop_Invariant
           (for all K in Index'First .. Lo - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in Hi + 1 .. Index'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Variant (Increases => J);

         if A (J) <= Pivot then
            Exchange (A, I, J);
            I := I + 1;
         end if;
         J := J + 1;
      end loop;

      Exchange (A, I, Hi);
      P := I;
   end Partition_Range;

   procedure Partition
     (Input : Input_Array; Output : out Input_Array; Pivot_Index : out Index)
   is
      Work : Input_Array := Input;
   begin
      Partition_Range (Work, Index'First, Index'Last, Pivot_Index);
      Output := Work;
   end Partition;

   --  Insertion sort of one or two elements. A longer slice never comes
   --  here: Insertion_Cutoff is 2.
   procedure Insertion_Range (A : in out Input_Array; Lo, Hi : Index)
   with
     Global => null,
     Pre    => Lo <= Hi and then Natural (Hi) - Natural (Lo) <= 1,
     Post   =>
       (for all K in Index'First .. Lo - 1 => A (K) = A'Old (K))
       and then (for all K in Hi + 1 .. Index'Last => A (K) = A'Old (K))
   is
   begin
      if Lo < Hi and then A (Lo) > A (Hi) then
         Exchange (A, Lo, Hi);
      end if;
   end Insertion_Range;

   --  One introsort step on Lo .. Hi.
   --  A slice of at most Insertion_Cutoff (2) elements is insertion-sorted.
   --  A longer slice whose remaining depth is 0 is heapsorted.
   --  Otherwise the slice is Lomuto-partitioned around its last element
   --  and both sides are sorted with Depth - 1. Depth is not recomputed
   --  from the slice length.
   procedure Sort_Range
     (A              : in out Input_Array;
      Lo, Hi         : Index;
      Depth          : Natural;
      Flag_Heap      : out Boolean;
      Flag_Unsorted  : out Boolean)
   with
     Global             => null,
     Pre                => Lo <= Hi,
     Post               =>
       (for all K in Index'First .. Lo - 1 => A (K) = A'Old (K))
       and then (for all K in Hi + 1 .. Index'Last => A (K) = A'Old (K)),
     Subprogram_Variant => (Decreases => Depth, Decreases => Hi - Lo)
   is
   begin
      Flag_Heap := False;
      Flag_Unsorted := False;

      if Slice_Length (Lo, Hi) <= Insertion_Cutoff then
         Insertion_Range (A, Lo, Hi);
      elsif Depth = 0 then
         declare
            Observed : Input_Array := A;
         begin
            --  Length is at least 3 here, so the slice is not a single cell.
            pragma Assert (Lo < Hi);
            if Lo = Index'First and then Hi = Index'Last then
               Heapify (Observed);
               Flag_Unsorted := not Is_Sorted (Observed);
            else
               Heapify_Slice (Observed, Lo, Hi);
               Flag_Unsorted := not Slice_Sorted (Observed, Lo, Hi);
            end if;
         end;
         Heap_Sort_Range (A, Lo, Hi);
         Flag_Heap := True;
      else
         declare
            P             : Index;
            Left_Heap     : Boolean := False;
            Right_Heap    : Boolean := False;
            Left_Unsorted : Boolean := False;
            Right_Unsorted : Boolean := False;
         begin
            pragma Assert (Depth > 0);
            pragma Assert (Lo < Hi);
            Partition_Range (A, Lo, Hi, P);

            if P > Lo then
               Sort_Range (A, Lo, P - 1, Depth - 1, Left_Heap, Left_Unsorted);
            end if;
            if P < Hi then
               Sort_Range
                 (A, P + 1, Hi, Depth - 1, Right_Heap, Right_Unsorted);
            end if;
            Flag_Heap := Left_Heap or Right_Heap;
            Flag_Unsorted := Left_Unsorted or Right_Unsorted;
         end;
      end if;
   end Sort_Range;

   --  2 * floor(log2(Index'Last)). Three halvings of 8 give 3, then
   --  the budget is 6. Sort calls this once; slices only decrement it.
   function Full_Depth_Limit return Natural
   with
     Global => null,
     Post   => Full_Depth_Limit'Result = Depth_Limit
   is
      N : Natural := Index'Last;
      L : Natural := 0;
   begin
      pragma Assert (N = 8);
      N := N / 2;
      L := L + 1;
      pragma Assert (N = 4 and then L = 1);
      N := N / 2;
      L := L + 1;
      pragma Assert (N = 2 and then L = 2);
      N := N / 2;
      L := L + 1;
      pragma Assert (N = 1 and then L = 3);
      return 2 * L;
   end Full_Depth_Limit;

   procedure Sort_Limited
     (Input             : Input_Array;
      Depth             : Natural;
      Output            : out Input_Array;
      Used_Heap         : out Boolean;
      Heap_Was_Unsorted : out Boolean)
   is
      Work          : Input_Array := Input;
      Flag_Heap     : Boolean;
      Flag_Unsorted : Boolean;
   begin
      Sort_Range
        (Work, Index'First, Index'Last, Depth, Flag_Heap, Flag_Unsorted);
      Output := Work;
      Used_Heap := Flag_Heap;
      Heap_Was_Unsorted := Flag_Unsorted;
   end Sort_Limited;

   function Sort (Input : Input_Array) return Input_Array is
      Result            : Input_Array;
      Depth             : constant Natural := Full_Depth_Limit;
      Used_Heap         : Boolean;
      Heap_Was_Unsorted : Boolean;
   begin
      --  One budget for the whole array. Sort_Range only subtracts one
      --  on each recursive call.
      pragma Assert (Depth = Depth_Limit);
      Sort_Limited (Input, Depth, Result, Used_Heap, Heap_Was_Unsorted);
      pragma Unreferenced (Used_Heap, Heap_Was_Unsorted);
      return Result;
   end Sort;

end Intro_Sort;
