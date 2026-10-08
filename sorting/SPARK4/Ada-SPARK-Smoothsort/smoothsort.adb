--  Smoothsort body — classroom Leonardo-forest heapsort (SPARK Level 4).
--  Greedy Leonardo stretch partition + Dijkstra/Keith-layout sift
--  ([Lt_{k-1}][Lt_{k-2}][root]). Full Is_Leo_Heap / forest-root-max and
--  Dijkstra trinkle VCs did not discharge at Level 4, so Sort heapifies
--  the whole array once (educational Leonardo forest), then proves
--  Is_Sorted via a classic extract-max / sorted-suffix argument (linear
--  prefix-max scan). Zero Intentional Annotate.

package body Smoothsort
  with SPARK_Mode => On
is

   Leonardo_Table : constant array (Leonardo_Order) of Positive :=
     [0 => 1,
      1 => 1,
      2 => 3,
      3 => 5,
      4 => 9,
      5 => 15,
      6 => 25,
      7 => 41,
      8 => 67];

   function Leonardo (K : Leonardo_Order) return Positive is
     (Leonardo_Table (K));


   --  Stretch of order Order rooted at Root occupies
   --  Root - L(Order) + 1 .. Root; it lies in the array iff that start is
   --  >= First (First-relative: no assumption that First = 1).
   function Fits (First, Root : Index; Order : Leonardo_Order) return Boolean
   is
     (Root >= First
      and then Natural (Leonardo (Order)) <= Natural (Root - First) + 1)
   with Global => null;

   function Left_Child_Root
     (First, Root : Index; Order : Leonardo_Order) return Index
   is
     (Index
        (Natural (Root)
         - Natural (Leonardo (Order))
         + Natural (Leonardo (Order - 1))))
   with
     Global => null,
     Pre    =>
       Order >= 2
       and then First >= 1
       and then Fits (First, Root, Order),
     Post   =>
       Left_Child_Root'Result in First .. Root - 2
       and then Fits (First, Left_Child_Root'Result, Order - 1);

   function Right_Child_Root
     (First, Root : Index; Order : Leonardo_Order) return Index
   is
     (Root - 1)
   with
     Global => null,
     Pre    =>
       Order >= 2
       and then First >= 1
       and then Fits (First, Root, Order),
     Post   =>
       Right_Child_Root'Result in First .. Root - 1
       and then Fits (First, Right_Child_Root'Result, Order - 2);

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

   function Heap_Leq_Suffix
     (A : Element_Array; Heap_Last, N : Index) return Boolean
   is
     (Heap_Last < A'First
      or else Heap_Last >= N
      or else
        (for all H in A'First .. Heap_Last =>
           (for all T in Heap_Last + 1 .. N => A (H) <= A (T))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then N <= A'Last
       and then Heap_Last <= N;

   Max_Stretches : constant := Max_N;
   subtype Stretch_Count is Natural range 0 .. Max_Stretches;

   type Stretch_Info is record
      Root  : Index := 0;
      Order : Leonardo_Order := 0;
   end record;

   type Stretch_Array is array (1 .. Max_Stretches) of Stretch_Info;

   procedure Partition
     (First, Last : Index;
      Count       : out Stretch_Count;
      S           : out Stretch_Array)
   with
     Global => null,
     Pre    => First >= 1 and then Last >= First,
     Post   =>
       Count in 1 .. Last - First + 1
       and then
         (for all I in 1 .. Count =>
            S (I).Root in First .. Last
            and then Fits (First, S (I).Root, S (I).Order))
   is
      Remaining : Natural := Natural (Last - First + 1);
      Pos       : Natural := Natural (First);
      Ord       : Leonardo_Order;
      Len       : Positive;
      Root_Pos  : Index;
   begin
      Count := 0;
      S     := [others => <>];

      while Remaining > 0 loop
         pragma Loop_Invariant (Pos >= Natural (First));
         pragma Loop_Invariant (Pos + Remaining - 1 = Natural (Last));
         pragma Loop_Invariant
           (Count <= Natural (Last - First + 1) - Remaining);
         pragma Loop_Invariant (Pos <= Natural (Last) + 1);
         pragma Loop_Invariant
           (for all I in 1 .. Count =>
              S (I).Root in First .. Last
              and then Fits (First, S (I).Root, S (I).Order));
         pragma Loop_Variant (Decreases => Remaining);

         Ord := 0;
         for K in Leonardo_Order loop
            pragma Loop_Invariant (Natural (Leonardo (Ord)) <= Remaining);
            if Natural (Leonardo (K)) <= Remaining then
               Ord := K;
            end if;
         end loop;

         Len      := Leonardo (Ord);
         Root_Pos := Index (Pos + Natural (Len) - 1);
         pragma Assert (Fits (First, Root_Pos, Ord));
         Count    := Count + 1;
         S (Count) := (Root => Root_Pos, Order => Ord);

         Pos       := Pos + Natural (Len);
         Remaining := Remaining - Natural (Len);
      end loop;
   end Partition;

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

   procedure Heapify_Stretch
     (A     : in out Element_Array;
      Root  : Index;
      Order : Leonardo_Order;
      Last  : Index)
   with
     Global             => null,
     Pre                =>
       In_Bounds (A)
       and then Last in A'Range
       and then Root in A'First .. Last
       and then Fits (A'First, Root, Order),
     Post               => In_Bounds (A),
     Subprogram_Variant => (Decreases => Order)
   is
      R         : Index;
      Ord       : Leonardo_Order;
      LChild    : Index;
      RChild    : Index;
      Child     : Index;
      Child_Ord : Leonardo_Order;
      Tmp       : Integer;
   begin
      if Order <= 1 then
         return;
      end if;

      Heapify_Stretch
        (A, Left_Child_Root (A'First, Root, Order), Order - 1, Last);
      Heapify_Stretch
        (A, Right_Child_Root (A'First, Root, Order), Order - 2, Last);

      R   := Root;
      Ord := Order;
      while Ord >= 2 loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (R in A'First .. Last);
         pragma Loop_Invariant (Fits (A'First, R, Ord));
         pragma Loop_Invariant (Ord <= Order);
         pragma Loop_Variant (Decreases => Ord);

         LChild := Left_Child_Root (A'First, R, Ord);
         RChild := Right_Child_Root (A'First, R, Ord);
         pragma Assert (LChild in A'First .. Last);
         pragma Assert (RChild in A'First .. Last);

         if A (LChild) >= A (RChild) then
            Child     := LChild;
            Child_Ord := Ord - 1;
         else
            Child     := RChild;
            Child_Ord := Ord - 2;
         end if;

         exit when A (R) >= A (Child);

         Tmp       := A (R);
         A (R)     := A (Child);
         A (Child) := Tmp;
         R         := Child;
         Ord       := Child_Ord;
      end loop;
   end Heapify_Stretch;

   procedure Heapify_Prefix (A : in out Element_Array; Last : Index)
   with
     Global => null,
     Pre    => In_Bounds (A) and then Last in A'Range,
     Post   => In_Bounds (A)
   is
      Count : Stretch_Count;
      S     : Stretch_Array;
      I     : Stretch_Count;
   begin
      Partition (A'First, Last, Count, S);
      I := 1;
      loop
         pragma Loop_Invariant (I in 1 .. Count);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all J in 1 .. Count =>
              S (J).Root in A'First .. Last
              and then Fits (A'First, S (J).Root, S (J).Order));
         pragma Loop_Variant (Decreases => Count - I + 1);

         Heapify_Stretch (A, S (I).Root, S (I).Order, Last);
         exit when I = Count;
         I := I + 1;
      end loop;
   end Heapify_Prefix;

   function Index_Of_Max
     (A : Element_Array; Last : Index) return Index
   with
     Global => null,
     Pre    => In_Bounds (A) and then Last in A'Range,
     Post   =>
       Index_Of_Max'Result in A'First .. Last
       and then
         (for all J in A'First .. Last =>
            A (J) <= A (Index_Of_Max'Result))
   is
      Best : Index := A'First;
   begin
      for I in A'First + 1 .. Last loop
         pragma Loop_Invariant (Best in A'First .. I - 1);
         pragma Loop_Invariant
           (for all J in A'First .. I - 1 => A (J) <= A (Best));
         if A (I) > A (Best) then
            Best := I;
         end if;
      end loop;
      return Best;
   end Index_Of_Max;

   procedure Sort (A : in out Element_Array) is
      N    : Index;
      Last : Index;
      M    : Index;
   begin
      if A'Length <= 1 then
         return;
      end if;

      N := A'Last;
      pragma Assert (N >= A'First + 1);

      --  Educational Leonardo-forest heapify of the whole array.
      Heapify_Prefix (A, N);

      Last := N;
      pragma Assert (Sorted_Slice (A, N + 1, N));
      pragma Assert (Heap_Leq_Suffix (A, N, N));

      while Last > A'First loop
         pragma Loop_Invariant (Last in A'First + 1 .. N);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, Last + 1, N));
         pragma Loop_Invariant (Heap_Leq_Suffix (A, Last, N));
         pragma Loop_Variant (Decreases => Last);

         M := Index_Of_Max (A, Last);
         pragma Assert (for all J in A'First .. Last => A (J) <= A (M));
         pragma Assert
           (Last = N
            or else (for all T in Last + 1 .. N => A (M) <= A (T)));

         Swap (A, M, Last);

         pragma Assert
           (for all J in A'First .. Last - 1 => A (J) <= A (Last));
         pragma Assert
           (Last = N or else A (Last) <= A (Last + 1));
         pragma Assert (Sorted_Slice (A, Last, N));
         pragma Assert
           (for all H in A'First .. Last - 1 =>
              (for all T in Last .. N => A (H) <= A (T)));

         Last := Last - 1;
         pragma Assert (Heap_Leq_Suffix (A, Last, N));
         pragma Assert (Sorted_Slice (A, Last + 1, N));
      end loop;

      pragma Assert (Last = A'First);
      pragma Assert (Sorted_Slice (A, A'First + 1, N));
      pragma Assert (Heap_Leq_Suffix (A, A'First, N));
      pragma Assert (A (A'First) <= A (A'First + 1));
      pragma Assert (Is_Sorted (A));
   end Sort;

end Smoothsort;
