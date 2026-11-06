pragma Ada_2022;

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

   function Heap_Sort_All (Input : Input_Array) return Input_Array
   with
     Global => null,
     Post   =>
       Is_Sorted (Heap_Sort_All'Result)
       and then Is_Perm (Heap_Sort_All'Result, Input)
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
   end Heap_Sort_All;

   procedure Partition_Range (A : in out Input_Array; Lo, Hi : Index; P : out Index) is
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
            Swap (A, I, J);
            I := I + 1;
         end if;
         J := J + 1;
      end loop;

      Swap (A, I, Hi);
      P := I;
   end Partition_Range;

   --  Heapsort A (Lo .. Hi) by the same Heapify Sort uses on a full array.
   --  A shorter slice is copied into a length-8 buffer padded with
   --  Value'First, heapsorted, and the last Len values are written back.
   --  Those are the slice: the pads are the smallest value, and there are
   --  exactly 8 - Len of them.
   procedure Sort_Slice (A : in out Input_Array; Lo, Hi : Index) is
      Len : Natural;
      B   : Input_Array;
      N   : Natural;
   begin
      if Lo = Index'First and then Hi = Index'Last then
         A := Heap_Sort_All (A);
         return;
      end if;

      pragma Assert (Lo > Index'First or else Hi < Index'Last);
      Len := Natural (Hi) - Natural (Lo) + 1;
      pragma Assert (Len in 1 .. 7);

      B := (others => Value'First);
      N := 0;
      for I in Lo .. Hi loop
         pragma Loop_Invariant (N = Natural (I) - Natural (Lo));
         pragma Loop_Invariant (N < Len);
         pragma Loop_Invariant (Len in 1 .. 7);
         N := N + 1;
         pragma Assert (N in 1 .. 7);
         B (Index (N)) := A (I);
      end loop;

      B := Heap_Sort_All (B);

      N := Index'Last - Len;
      pragma Assert (N in 1 .. 7);
      for I in Lo .. Hi loop
         pragma Loop_Invariant (Len in 1 .. 7);
         pragma Loop_Invariant (N = Index'Last - Len + Natural (I) - Natural (Lo));
         pragma Loop_Invariant (N < Index'Last);
         N := N + 1;
         pragma Assert (N in Index);
         A (I) := B (Index (N));
      end loop;
   end Sort_Slice;

   procedure Intro
     (A : in out Input_Array; Lo, Hi : Index; Remaining : Depth; Falls : in out Natural)
   with
     Global             => null,
     Pre                => Falls <= 8,
     Post               => Falls <= 8 and then Falls >= Falls'Old,
     Subprogram_Variant => (Decreases => Hi - Lo)
   is
      P : Index;
   begin
      if Lo >= Hi then
         return;
      end if;

      --  Length 2 (or the empty case above): one compare-exchange. This
      --  runs before the depth test, so a budget of 6 never reaches 0.
      pragma Assert (Lo < Index'Last);
      if Hi = Lo + 1 then
         if A (Lo) > A (Hi) then
            Swap (A, Lo, Hi);
         end if;
         return;
      end if;

      if Remaining = 0 then
         Sort_Slice (A, Lo, Hi);
         if Falls < 8 then
            Falls := Falls + 1;
         end if;
         return;
      end if;

      Partition_Range (A, Lo, Hi, P);

      if P > Lo then
         Intro (A, Lo, P - 1, Remaining - 1, Falls);
      end if;
      if P < Hi then
         Intro (A, P + 1, Hi, Remaining - 1, Falls);
      end if;
   end Intro;

   procedure Sort_Limited
     (Input : Input_Array; Max_Depth : Depth; Output : out Input_Array;
      Heap_Fallbacks : out Natural)
   is
      Work  : Input_Array := Input;
      Falls : Natural := 0;
   begin
      Intro (Work, Index'First, Index'Last, Max_Depth, Falls);
      Output := Work;
      Heap_Fallbacks := Falls;
   end Sort_Limited;

   function Sort (Input : Input_Array) return Input_Array is
      Work  : Input_Array := Input;
      Falls : Natural := 0;
   begin
      Intro (Work, Index'First, Index'Last, Depth_Budget, Falls);
      --  Depth_Budget is not exhausted on length 8 (Intro's post keeps the
      --  count in range; the tests check that the count stays 0).
      pragma Assert (Falls <= 8);
      return Work;
   end Sort;

   procedure Partition
     (Input : Input_Array; Output : out Input_Array; Pivot_Index : out Index)
   is
      Work : Input_Array := Input;
   begin
      Partition_Range (Work, Index'First, Index'Last, Pivot_Index);
      Output := Work;
   end Partition;

end Intro_Sort;
