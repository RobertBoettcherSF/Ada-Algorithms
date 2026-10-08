--  Flashsort body: SPARK Level 4 Neubert flashsort, proved to sort on its
--  own (no bubble-sort safety net, no clamps, no step cap).
--
--  Classification: class K = 1 + floor ((M - 1) (X - Min) / (Max - Min))
--  lies in 1 .. M and is monotonic in X (Lemma_Div_Le, Lemma_Div_Mono).
--  The histogram and its inclusive prefix sums give the class regions
--  U (K - 1) + 1 .. U (K) exactly (ghost Cnt_C, Sum_To).
--  Permutation (cycle leader): L (K) is the last unfilled slot of region
--  K; slots L (K) + 1 .. U (K) hold class-K keys. The proof counts, per
--  class, the keys sitting in unfilled slots (ghost Cnt_U, with the cycle
--  leader's slot as a hole) plus the key in hand, and shows this equals
--  the number of unfilled slots of that class. So the key in hand always
--  has a free slot, every cycle closes at its leader, and when the outer
--  loop ends every region holds exactly its class.
--  Insertion sort then sorts each region; classes are monotonic, so the
--  regions are in order (Lemma_Class_Order). Permutation is checked by
--  the tests, not stated in the contracts.

package body Flashsort
  with SPARK_Mode => On
is

   subtype LLI is Long_Long_Integer;

   Max_Class : constant Positive := Max_N / Class_Divisor;   --  6
   subtype Class_Num is Positive range 2 .. Max_Class;
   subtype Class_Id is Positive range 1 .. Max_Class;
   subtype Class_Bound is Natural range 0 .. Max_Class;
   type Border_Array is array (Class_Bound) of Index;
   type Count_Array is array (Class_Id) of Index;

   --  Class parameters: number of classes and the key range.
   type Class_Params is record
      M      : Class_Num;
      Mn, Mx : Integer;
   end record;

   function Valid (CP : Class_Params) return Boolean is (CP.Mn < CP.Mx);

   ---------------------------------------------------------------------------
   -- Arithmetic lemmas
   ---------------------------------------------------------------------------

   procedure Lemma_Div_Le (Num, C, Den : LLI)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         Den in 1 .. 2 ** 33 and then C in 0 .. LLI (Max_Class)
         and then Num in 0 .. C * Den,
       Post   => Num / Den <= C
   is
      Q : constant LLI := Num / Den;
   begin
      pragma Assert (Q * Den <= Num);
      pragma Assert ((Q - C) * Den <= 0);
   end Lemma_Div_Le;

   procedure Lemma_Div_Mono (N1, N2, Den : LLI)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         Den in 1 .. 2 ** 33 and then N1 in 0 .. 2 ** 36
         and then N2 in N1 .. 2 ** 36,
       Post   => N1 / Den <= N2 / Den
   is
      Q1 : constant LLI := N1 / Den;
      Q2 : constant LLI := N2 / Den;
   begin
      pragma Assert (Q1 * Den <= N1);
      pragma Assert (N2 < (Q2 + 1) * Den);
      pragma Assert ((Q1 - Q2 - 1) * Den < 0);
   end Lemma_Div_Mono;

   --  Multiplying by a small class factor keeps the order (split by
   --  factor so every case is linear).
   procedure Lemma_Mul_Mono (C, Small, Big : LLI)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         C in 0 .. LLI (Max_Class) and then Small in 0 .. 2 ** 33
         and then Big in Small .. 2 ** 33,
       Post   => C * Small <= C * Big
   is
   begin
      case C is
         when 0 => pragma Assert (C * Small = 0 and then C * Big = 0);
         when 1 => null;
         when 2 =>
            pragma Assert (C * Small = 2 * Small and then C * Big = 2 * Big);
         when 3 =>
            pragma Assert (C * Small = 3 * Small and then C * Big = 3 * Big);
         when 4 =>
            pragma Assert (C * Small = 4 * Small and then C * Big = 4 * Big);
         when 5 =>
            pragma Assert (C * Small = 5 * Small and then C * Big = 5 * Big);
         when others =>
            pragma Assert (C * Small = 6 * Small and then C * Big = 6 * Big);
      end case;
   end Lemma_Mul_Mono;

   ---------------------------------------------------------------------------
   -- Classification
   ---------------------------------------------------------------------------

   function Class_Of (X : Integer; CP : Class_Params) return Class_Id
     with
       Global => null,
       Pre    => Valid (CP) and then X in CP.Mn .. CP.Mx,
       Post   =>
         Class_Of'Result <= CP.M
         and then LLI (Class_Of'Result)
                  = 1 + LLI (CP.M - 1) * (LLI (X) - LLI (CP.Mn))
                        / (LLI (CP.Mx) - LLI (CP.Mn))
   is
      C   : constant LLI := LLI (CP.M - 1);
      Num : constant LLI := C * (LLI (X) - LLI (CP.Mn));
      Den : constant LLI := LLI (CP.Mx) - LLI (CP.Mn);
   begin
      pragma Assert (Num <= C * Den);
      Lemma_Div_Le (Num, C, Den);
      return Class_Id (1 + Num / Den);
   end Class_Of;

   --  A larger class means a larger key.
   procedure Lemma_Class_Order (X, Y : Integer; CP : Class_Params)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         Valid (CP) and then X in CP.Mn .. CP.Mx and then Y in CP.Mn .. CP.Mx
         and then Class_Of (X, CP) < Class_Of (Y, CP),
       Post   => X < Y
   is
      C   : constant LLI := LLI (CP.M - 1);
      Den : constant LLI := LLI (CP.Mx) - LLI (CP.Mn);
   begin
      if Y <= X then
         Lemma_Mul_Mono (C, LLI (Y) - LLI (CP.Mn), LLI (X) - LLI (CP.Mn));
         pragma Assert
           (C * (LLI (Y) - LLI (CP.Mn)) <= C * (LLI (X) - LLI (CP.Mn)));
         Lemma_Div_Mono
           (C * (LLI (Y) - LLI (CP.Mn)), C * (LLI (X) - LLI (CP.Mn)), Den);
         pragma Assert (Class_Of (Y, CP) <= Class_Of (X, CP));
         pragma Assert (False);
      end if;
   end Lemma_Class_Order;

   ---------------------------------------------------------------------------
   -- Ghost model
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
     Pre    => In_Bounds (A) and then L >= 1 and then R <= A'Last;

   function In_Range (A : Element_Array; CP : Class_Params) return Boolean is
     (for all P in A'Range => A (P) in CP.Mn .. CP.Mx)
   with Ghost => True, Global => null;

   --  Keys of class K among A (1 .. H) (keys outside Mn .. Mx count for
   --  no class).
   function Cnt_C
     (A : Element_Array; H : Natural; CP : Class_Params; K : Class_Id)
      return Natural
   is
     (if H = 0 then 0
      else Cnt_C (A, H - 1, CP, K)
           + (if A (H) in CP.Mn .. CP.Mx
                and then Class_Of (A (H), CP) = K then 1 else 0))
   with
     Ghost              => True,
     Global             => null,
     Pre                => Valid (CP) and then In_Bounds (A) and then H <= A'Last,
     Post               => Cnt_C'Result <= H,
     Subprogram_Variant => (Decreases => H);

   --  Count (1) + ... + Count (K).
   function Sum_To (C : Count_Array; K : Class_Bound) return Natural is
     (if K = 0 then 0 else Sum_To (C, K - 1) + C (K))
   with
     Ghost              => True,
     Global             => null,
     Post               => Sum_To'Result <= K * Max_N,
     Subprogram_Variant => (Decreases => K);

   --  Borders: U (0) = 0, U (M) = N, U (K - 1) <= L (K) <= U (K).
   function Borders_Ok
     (L, U : Border_Array; M : Class_Num; N : Index) return Boolean
   is
     (U (0) = 0 and then U (M) = N
      and then (for all K1 in 0 .. M =>
                  (for all K2 in K1 .. M => U (K1) <= U (K2)))
      and then (for all K in 1 .. M => U (K - 1) <= L (K) and then L (K) <= U (K)))
   with Ghost => True, Global => null;

   --  Slot P is unfilled: it lies in U (K - 1) + 1 .. L (K) for some K.
   function Unfilled
     (L, U : Border_Array; M : Class_Num; P : Natural) return Boolean
   is
     (for some K in 1 .. M => U (K - 1) < P and then P <= L (K))
   with Ghost => True, Global => null;

   --  Keys of class K in unfilled slots of A (1 .. H), slot Hole excluded.
   function Cnt_U
     (A : Element_Array; L, U : Border_Array; CP : Class_Params;
      Hole : Natural; H : Natural; K : Class_Id) return Natural
   is
     (if H = 0 then 0
      else Cnt_U (A, L, U, CP, Hole, H - 1, K)
           + (if H /= Hole and then Unfilled (L, U, CP.M, H)
                and then A (H) in CP.Mn .. CP.Mx
                and then Class_Of (A (H), CP) = K then 1 else 0))
   with
     Ghost              => True,
     Global             => null,
     Pre                => Valid (CP) and then In_Bounds (A) and then H <= A'Last,
     Post               => Cnt_U'Result <= H,
     Subprogram_Variant => (Decreases => H);

   --  Slots L (K) + 1 .. U (K) hold keys of class K.
   function Filled_Ok
     (A : Element_Array; L, U : Border_Array; CP : Class_Params) return Boolean
   is
     (for all K in 1 .. CP.M =>
        (for all P in L (K) + 1 .. U (K) =>
           P in A'Range and then A (P) in CP.Mn .. CP.Mx
           and then Class_Of (A (P), CP) = K))
   with Ghost => True, Global => null, Pre => Valid (CP);

   function Sum_L (L : Border_Array) return Natural is
     (L (1) + L (2) + L (3) + L (4) + L (5) + L (6))
   with Ghost => True, Global => null;

   ---------------------------------------------------------------------------
   -- Counting lemmas
   ---------------------------------------------------------------------------

   procedure Lemma_Sum_Inc
     (C_Old, C_New : Count_Array; E : Class_Id; K : Class_Bound)
     with
       Ghost              => True,
       Global             => null,
       Pre                =>
         C_New (E) = C_Old (E) + 1
         and then (for all J in Class_Id =>
                     (if J /= E then C_New (J) = C_Old (J))),
       Post               =>
         Sum_To (C_New, K) = Sum_To (C_Old, K) + (if E <= K then 1 else 0),
       Subprogram_Variant => (Decreases => K)
   is
   begin
      if K > 0 then
         Lemma_Sum_Inc (C_Old, C_New, E, K - 1);
      end if;
   end Lemma_Sum_Inc;

   --  Classes above M are empty, so Sum_To stops growing at M.
   procedure Lemma_Sum_Top (C : Count_Array; M : Class_Num; K : Class_Bound)
     with
       Ghost              => True,
       Global             => null,
       Pre                => K >= M and then (for all J in Class_Id => (if J > M then C (J) = 0)),
       Post               => Sum_To (C, K) = Sum_To (C, M),
       Subprogram_Variant => (Decreases => K)
   is
   begin
      if K > M then
         Lemma_Sum_Top (C, M, K - 1);
      end if;
   end Lemma_Sum_Top;

   --  When L = U every slot of 1 .. N is unfilled, so Cnt_U = Cnt_C.
   procedure Lemma_All_Unfilled
     (A : Element_Array; U : Border_Array; CP : Class_Params; K : Class_Id)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         Valid (CP) and then In_Bounds (A)
         and then Borders_Ok (U, U, CP.M, A'Last),
       Post   => Cnt_U (A, U, U, CP, 0, A'Last, K) = Cnt_C (A, A'Last, CP, K)
   is
   begin
      for P in 1 .. A'Last loop
         --  Find the region of P.
         for R in 1 .. CP.M loop
            pragma Loop_Invariant (U (R - 1) < P);
            exit when P <= U (R);
         end loop;
         pragma Assert (Unfilled (U, U, CP.M, P));
         pragma Loop_Invariant
           (Cnt_U (A, U, U, CP, 0, P, K) = Cnt_C (A, P, CP, K));
      end loop;
   end Lemma_All_Unfilled;

   --  Slot J = L (B) becomes filled (L (B) decreases by one) and only A (J)
   --  may change: the unfilled count loses the old key at J (unless J is
   --  the hole).
   procedure Lemma_Fill
     (A_Old, A_New : Element_Array; L_Old, L_New, U : Border_Array;
      CP : Class_Params; Hole : Natural; B : Class_Id; K : Class_Id)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         Valid (CP) and then In_Bounds (A_Old) and then In_Bounds (A_New)
         and then A_Old'Last = A_New'Last
         and then B <= CP.M
         and then Borders_Ok (L_Old, U, CP.M, A_Old'Last)
         and then L_Old (B) > U (B - 1)
         and then L_New (B) = L_Old (B) - 1
         and then (for all J in Class_Bound =>
                     (if J /= B then L_New (J) = L_Old (J)))
         and then (for all P in A_Old'Range =>
                     (if P /= L_Old (B) then A_New (P) = A_Old (P))),
       Post   =>
         Cnt_U (A_New, L_New, U, CP, Hole, A_New'Last, K)
         = Cnt_U (A_Old, L_Old, U, CP, Hole, A_Old'Last, K)
           - (if L_Old (B) /= Hole
                and then A_Old (L_Old (B)) in CP.Mn .. CP.Mx
                and then Class_Of (A_Old (L_Old (B)), CP) = K
              then 1 else 0)
   is
      J : constant Positive := L_Old (B);
   begin
      for P in 1 .. A_Old'Last loop
         if P /= J then
            pragma Assert
              (Unfilled (L_New, U, CP.M, P) = Unfilled (L_Old, U, CP.M, P));
         else
            pragma Assert (Unfilled (L_Old, U, CP.M, P));
            pragma Assert
              (for all R in 1 .. CP.M =>
                 (if R /= B then not (U (R - 1) < P and then P <= L_New (R))));
            pragma Assert (not Unfilled (L_New, U, CP.M, P));
         end if;
         pragma Loop_Invariant
           (Cnt_U (A_New, L_New, U, CP, Hole, P, K)
            = Cnt_U (A_Old, L_Old, U, CP, Hole, P, K)
              - (if J <= P and then J /= Hole
                   and then A_Old (J) in CP.Mn .. CP.Mx
                   and then Class_Of (A_Old (J), CP) = K
                 then 1 else 0));
      end loop;
   end Lemma_Fill;

   --  Making an unfilled slot the hole removes its key from the count.
   procedure Lemma_Hole
     (A : Element_Array; L, U : Border_Array; CP : Class_Params;
      I : Positive; K : Class_Id)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         Valid (CP) and then In_Bounds (A) and then I <= A'Last,
       Post   =>
         Cnt_U (A, L, U, CP, I, A'Last, K)
         = Cnt_U (A, L, U, CP, 0, A'Last, K)
           - (if Unfilled (L, U, CP.M, I)
                and then A (I) in CP.Mn .. CP.Mx
                and then Class_Of (A (I), CP) = K
              then 1 else 0)
   is
   begin
      for P in 1 .. A'Last loop
         pragma Loop_Invariant
           (Cnt_U (A, L, U, CP, I, P, K)
            = Cnt_U (A, L, U, CP, 0, P, K)
              - (if I <= P and then Unfilled (L, U, CP.M, I)
                   and then A (I) in CP.Mn .. CP.Mx
                   and then Class_Of (A (I), CP) = K then 1 else 0));
      end loop;
   end Lemma_Hole;

   --  An unfilled slot holding a class-K key makes Cnt_U positive.
   procedure Lemma_Positive
     (A : Element_Array; L, U : Border_Array; CP : Class_Params; I : Positive)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         Valid (CP) and then In_Bounds (A) and then I <= A'Last
         and then Unfilled (L, U, CP.M, I)
         and then A (I) in CP.Mn .. CP.Mx,
       Post   => Cnt_U (A, L, U, CP, 0, A'Last, Class_Of (A (I), CP)) >= 1
   is
      K : constant Class_Id := Class_Of (A (I), CP);
   begin
      for P in I .. A'Last loop
         pragma Loop_Invariant (Cnt_U (A, L, U, CP, 0, P, K) >= 1);
      end loop;
   end Lemma_Positive;

   --  Lemma_Sum_Mono: Sum_To grows with K.
   procedure Lemma_Sum_Mono (C : Count_Array; K1, K2 : Class_Bound)
     with
       Ghost              => True,
       Global             => null,
       Pre                => K1 <= K2,
       Post               => Sum_To (C, K1) <= Sum_To (C, K2),
       Subprogram_Variant => (Decreases => K2)
   is
   begin
      if K2 > K1 then
         Lemma_Sum_Mono (C, K1, K2 - 1);
      end if;
   end Lemma_Sum_Mono;

   --  Initial counts: with L = U every class has all its keys unfilled.
   procedure Lemma_Init
     (A : Element_Array; U : Border_Array; CP : Class_Params)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         Valid (CP) and then In_Bounds (A)
         and then Borders_Ok (U, U, CP.M, A'Last)
         and then (for all K in 1 .. CP.M =>
                     Cnt_C (A, A'Last, CP, K) = U (K) - U (K - 1)),
       Post   =>
         (for all K in 1 .. CP.M =>
            Cnt_U (A, U, U, CP, 0, A'Last, K) = U (K) - U (K - 1))
   is
   begin
      for K in 1 .. CP.M loop
         Lemma_All_Unfilled (A, U, CP, K);
         pragma Loop_Invariant
           (for all K2 in 1 .. K =>
              Cnt_U (A, U, U, CP, 0, A'Last, K2) = U (K2) - U (K2 - 1));
      end loop;
   end Lemma_Init;

   --  Taking the key at unfilled slot I in hand keeps the counts.
   procedure Lemma_Take
     (A : Element_Array; L, U : Border_Array; CP : Class_Params; I : Positive)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         Valid (CP) and then In_Bounds (A) and then I <= A'Last
         and then In_Range (A, CP)
         and then Unfilled (L, U, CP.M, I)
         and then (for all K in 1 .. CP.M =>
                     Cnt_U (A, L, U, CP, 0, A'Last, K) = L (K) - U (K - 1)),
       Post   =>
         (for all K in 1 .. CP.M =>
            Cnt_U (A, L, U, CP, I, A'Last, K)
            + (if Class_Of (A (I), CP) = K then 1 else 0)
            = L (K) - U (K - 1))
   is
   begin
      for K in 1 .. CP.M loop
         Lemma_Hole (A, L, U, CP, I, K);
         pragma Loop_Invariant
           (for all K2 in 1 .. K =>
              Cnt_U (A, L, U, CP, I, A'Last, K2)
              + (if Class_Of (A (I), CP) = K2 then 1 else 0)
              = L (K2) - U (K2 - 1));
      end loop;
   end Lemma_Take;

   --  Once slot I is filled, excluding it as the hole changes nothing.
   procedure Lemma_Unhole
     (A : Element_Array; L, U : Border_Array; CP : Class_Params; I : Positive)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         Valid (CP) and then In_Bounds (A) and then I <= A'Last
         and then not Unfilled (L, U, CP.M, I),
       Post   =>
         (for all K in 1 .. CP.M =>
            Cnt_U (A, L, U, CP, I, A'Last, K) = Cnt_U (A, L, U, CP, 0, A'Last, K))
   is
   begin
      for K in 1 .. CP.M loop
         Lemma_Hole (A, L, U, CP, I, K);
         pragma Loop_Invariant
           (for all K2 in 1 .. K =>
              Cnt_U (A, L, U, CP, I, A'Last, K2)
              = Cnt_U (A, L, U, CP, 0, A'Last, K2));
      end loop;
   end Lemma_Unhole;

   --  Filling slot J = L_Old (B), for every class.
   procedure Lemma_Fill_All
     (A_Old, A_New : Element_Array; L_Old, L_New, U : Border_Array;
      CP : Class_Params; Hole : Natural; B : Class_Id)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         Valid (CP) and then In_Bounds (A_Old) and then In_Bounds (A_New)
         and then A_Old'Last = A_New'Last
         and then In_Range (A_Old, CP)
         and then B <= CP.M
         and then Borders_Ok (L_Old, U, CP.M, A_Old'Last)
         and then L_Old (B) > U (B - 1)
         and then L_New (B) = L_Old (B) - 1
         and then (for all J in Class_Bound =>
                     (if J /= B then L_New (J) = L_Old (J)))
         and then (for all P in A_Old'Range =>
                     (if P /= L_Old (B) then A_New (P) = A_Old (P))),
       Post   =>
         (for all K in 1 .. CP.M =>
            Cnt_U (A_New, L_New, U, CP, Hole, A_New'Last, K)
            = Cnt_U (A_Old, L_Old, U, CP, Hole, A_Old'Last, K)
              - (if L_Old (B) /= Hole
                   and then Class_Of (A_Old (L_Old (B)), CP) = K
                 then 1 else 0))
   is
   begin
      for K in 1 .. CP.M loop
         Lemma_Fill (A_Old, A_New, L_Old, L_New, U, CP, Hole, B, K);
         pragma Loop_Invariant
           (for all K2 in 1 .. K =>
              Cnt_U (A_New, L_New, U, CP, Hole, A_New'Last, K2)
              = Cnt_U (A_Old, L_Old, U, CP, Hole, A_Old'Last, K2)
                - (if L_Old (B) /= Hole
                     and then Class_Of (A_Old (L_Old (B)), CP) = K2
                   then 1 else 0));
      end loop;
   end Lemma_Fill_All;

   --  A skipped slot (I > L (class of A (I))) is already filled.
   procedure Lemma_Skip
     (A : Element_Array; L, U : Border_Array; CP : Class_Params; I : Positive)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         Valid (CP) and then In_Bounds (A) and then I <= A'Last
         and then In_Range (A, CP)
         and then Borders_Ok (L, U, CP.M, A'Last)
         and then Filled_Ok (A, L, U, CP)
         and then (for all K in 1 .. CP.M =>
                     L (K) = U (K - 1) or else U (K - 1) + 1 >= I)
         and then (for all K in 1 .. CP.M =>
                     Cnt_U (A, L, U, CP, 0, A'Last, K) = L (K) - U (K - 1))
         and then I > L (Class_Of (A (I), CP)),
       Post   => not Unfilled (L, U, CP.M, I)
   is
   begin
      if Unfilled (L, U, CP.M, I) then
         Lemma_Positive (A, L, U, CP, I);
         pragma Assert (False);
      end if;
   end Lemma_Skip;

   --  Sorted class regions in class order: the whole array is sorted.
   procedure Lemma_Tile
     (A : Element_Array; U : Border_Array; CP : Class_Params)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         Valid (CP) and then In_Bounds (A)
         and then In_Range (A, CP)
         and then Borders_Ok (U, U, CP.M, A'Last)
         and then (for all K in 1 .. CP.M =>
                     (for all P in U (K - 1) + 1 .. U (K) =>
                        Class_Of (A (P), CP) = K))
         and then (for all K in 1 .. CP.M =>
                     Sorted_Slice (A, U (K - 1) + 1, U (K))),
       Post   => Sorted_Slice (A, 1, A'Last)
   is
   begin
      for K in 1 .. CP.M loop
         pragma Loop_Invariant (Sorted_Slice (A, 1, U (K - 1)));
         pragma Loop_Invariant
           (for all P in 1 .. U (K - 1) => Class_Of (A (P), CP) < K);
         if U (K - 1) >= 1 and then U (K) > U (K - 1) then
            Lemma_Class_Order (A (U (K - 1)), A (U (K - 1) + 1), CP);
         end if;
         pragma Assert (Sorted_Slice (A, 1, U (K)));
         pragma Assert
           (for all P in 1 .. U (K) => Class_Of (A (P), CP) < K + 1);
      end loop;
   end Lemma_Tile;

   ---------------------------------------------------------------------------
   -- Phases
   ---------------------------------------------------------------------------

   --  m = max (2, n / Class_Divisor).
   function Class_Count (N : Index) return Class_Num
     with
       Global => null,
       Pre    => N >= 2,
       Post   => Class_Count'Result <= N
   is
      M : constant Natural := N / Class_Divisor;
   begin
      if M < 2 then
         return 2;
      end if;
      return M;
   end Class_Count;

   --  Insertion sort of region K leaves the earlier regions untouched.
   procedure Lemma_Regions_Keep
     (A_Old, A : Element_Array; U : Border_Array; M : Class_Num;
      K : Class_Id)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A_Old) and then In_Bounds (A)
         and then A_Old'Last = A'Last and then K <= M
         and then Borders_Ok (U, U, M, A'Last)
         and then (for all P in 1 .. U (K - 1) => A (P) = A_Old (P))
         and then (for all K2 in 1 .. K - 1 =>
                     Sorted_Slice (A_Old, U (K2 - 1) + 1, U (K2))),
       Post   =>
         (for all K2 in 1 .. K - 1 =>
            Sorted_Slice (A, U (K2 - 1) + 1, U (K2)))
   is
   begin
      for K2 in 1 .. K - 1 loop
         pragma Loop_Invariant
           (for all K3 in 1 .. K2 - 1 =>
              Sorted_Slice (A, U (K3 - 1) + 1, U (K3)));
         pragma Assert (U (K2) <= U (K - 1));
         pragma Assert
           (for all P in U (K2 - 1) + 1 .. U (K2) => A (P) = A_Old (P));
         pragma Assert (Sorted_Slice (A, U (K2 - 1) + 1, U (K2)));
      end loop;
   end Lemma_Regions_Keep;

   --  Insertion sort of A (Lo .. Hi); every key keeps class K.
   procedure Insertion_Range
     (A : in out Element_Array; Lo, Hi : Positive; CP : Class_Params;
      K : Class_Id)
     with
       Global => null,
       Pre    =>
         Valid (CP) and then In_Bounds (A)
         and then Lo <= Hi and then Hi <= A'Last
         and then (for all P in Lo .. Hi =>
                     A (P) in CP.Mn .. CP.Mx
                     and then Class_Of (A (P), CP) = K),
       Post   =>
         In_Bounds (A)
         and then (for all P in A'Range =>
                     (if P < Lo or else P > Hi then A (P) = A'Old (P)))
         and then (for all P in Lo .. Hi =>
                     A (P) in CP.Mn .. CP.Mx
                     and then Class_Of (A (P), CP) = K)
         and then Sorted_Slice (A, Lo, Hi)
   is
      Key : Integer;
      P   : Positive;
   begin
      for X in Lo + 1 .. Hi loop
         pragma Loop_Invariant
           (for all Q in A'Range =>
              (if Q < Lo or else Q > Hi then A (Q) = A'Loop_Entry (Q)));
         pragma Loop_Invariant
           (for all Q in Lo .. Hi =>
              A (Q) in CP.Mn .. CP.Mx and then Class_Of (A (Q), CP) = K);
         pragma Loop_Invariant (Sorted_Slice (A, Lo, X - 1));

         Key := A (X);
         P   := X;

         while P > Lo and then Key < A (P - 1) loop
            pragma Loop_Invariant (P in Lo + 1 .. X);
            pragma Loop_Invariant
              (for all Q in A'Range =>
                 (if Q < Lo or else Q > Hi then A (Q) = A'Loop_Entry (Q)));
            pragma Loop_Invariant
              (for all Q in Lo .. Hi =>
                 A (Q) in CP.Mn .. CP.Mx and then Class_Of (A (Q), CP) = K);
            pragma Loop_Invariant (Key in CP.Mn .. CP.Mx);
            pragma Loop_Invariant (Class_Of (Key, CP) = K);
            --  A (Lo .. X) without slot P is the old sorted run with Key
            --  removed; the moved part P + 1 .. X is above Key.
            pragma Loop_Invariant (Sorted_Slice (A, Lo, P - 1));
            pragma Loop_Invariant (Sorted_Slice (A, P, X));
            pragma Loop_Invariant
              (for all Q in P + 1 .. X => Key < A (Q));
            pragma Loop_Invariant
              (P = X or else A (P - 1) <= A (P + 1));
            pragma Loop_Variant (Decreases => P);

            A (P) := A (P - 1);
            P     := P - 1;
         end loop;

         A (P) := Key;
         pragma Assert (Sorted_Slice (A, Lo, X));
      end loop;
   end Insertion_Range;

   procedure Flashsort_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A) and then Is_Sorted (A)
   is
      N       : constant Index := A'Last;
      Min_Val : Integer;
      Max_Val : Integer;
      M       : Class_Num;
      Count   : Count_Array := [others => 0];
      L       : Border_Array;
      U       : Border_Array := [others => 0];
      J       : Positive;
      B       : Class_Id;
      T, Hold : Integer;
      Lo, Hi  : Natural;
   begin
      Min_Val := A (1);
      Max_Val := A (1);

      for X in 2 .. N loop
         pragma Loop_Invariant
           (for all P in 1 .. X - 1 => A (P) in Min_Val .. Max_Val);

         if A (X) < Min_Val then
            Min_Val := A (X);
         elsif A (X) > Max_Val then
            Max_Val := A (X);
         end if;
      end loop;

      --  All equal: already sorted; the denominator would be zero.
      if Min_Val = Max_Val then
         return;
      end if;

      M := Class_Count (N);

      declare
         CP : constant Class_Params := (M => M, Mn => Min_Val, Mx => Max_Val);
      begin
         pragma Assert (In_Range (A, CP));

         --  Histogram: Count (K) = number of class-K keys.
         for X in 1 .. N loop
            pragma Loop_Invariant
              (for all K in Class_Id => Count (K) = Cnt_C (A, X - 1, CP, K));
            pragma Loop_Invariant (Sum_To (Count, Max_Class) = X - 1);
            pragma Loop_Invariant
              (for all K in Class_Id => (if K > M then Count (K) = 0));

            B := Class_Of (A (X), CP);
            declare
               C_Prev : constant Count_Array := Count with Ghost;
            begin
               Count (B) := Count (B) + 1;
               Lemma_Sum_Inc (C_Prev, Count, B, Max_Class);
            end;
         end loop;
         Lemma_Sum_Top (Count, M, Max_Class);
         pragma Assert (Sum_To (Count, M) = N);

         --  Inclusive prefix sums: U (K) = Count (1) + ... + Count (K).
         for K in 1 .. M loop
            pragma Loop_Invariant
              (for all J2 in 0 .. K - 1 => U (J2) = Sum_To (Count, J2));
            pragma Loop_Invariant
              (for all J2 in 0 .. K - 1 =>
                 (for all J3 in J2 .. K - 1 => U (J2) <= U (J3)));
            pragma Loop_Invariant (U (0) = 0);
            pragma Loop_Invariant (U (K - 1) <= N);
            Lemma_Sum_Mono (Count, K, M);
            U (K) := U (K - 1) + Count (K);
         end loop;
         L := U;
         pragma Assert (Borders_Ok (L, U, M, N));
         Lemma_Init (A, U, CP);

         --  Cycle-leader permutation: every key goes to the last unfilled
         --  slot of its class region.
         for I in 1 .. N loop
            pragma Loop_Invariant (In_Range (A, CP));
            pragma Loop_Invariant (Borders_Ok (L, U, M, N));
            pragma Loop_Invariant (Filled_Ok (A, L, U, CP));
            pragma Loop_Invariant
              (for all K in 1 .. M => L (K) = U (K - 1) or else U (K - 1) + 1 >= I);
            pragma Loop_Invariant
              (for all K in 1 .. M =>
                 Cnt_U (A, L, U, CP, 0, N, K) = L (K) - U (K - 1));

            B := Class_Of (A (I), CP);

            if I <= L (B) then
               pragma Assert (Unfilled (L, U, M, I));
               T := A (I);
               Lemma_Take (A, L, U, CP, I);

               loop
                  pragma Loop_Invariant (In_Range (A, CP));
                  pragma Loop_Invariant (T in Min_Val .. Max_Val);
                  pragma Loop_Invariant (Borders_Ok (L, U, M, N));
                  pragma Loop_Invariant (Filled_Ok (A, L, U, CP));
                  pragma Loop_Invariant
                    (for all K in 1 .. M =>
                       L (K) = U (K - 1) or else U (K - 1) + 1 >= I);
                  pragma Loop_Invariant (Unfilled (L, U, M, I));
                  pragma Loop_Invariant
                    (for all K in 1 .. M =>
                       Cnt_U (A, L, U, CP, I, N, K)
                       + (if Class_Of (T, CP) = K then 1 else 0)
                       = L (K) - U (K - 1));
                  pragma Loop_Variant (Decreases => Sum_L (L));

                  B := Class_Of (T, CP);
                  pragma Assert (L (B) > U (B - 1));
                  J := L (B);
                  pragma Assert (J >= I);

                  declare
                     A_Old : constant Element_Array := A with Ghost;
                     L_Old : constant Border_Array := L with Ghost;
                     T_Old : constant Integer := T with Ghost;
                  begin
                     Hold  := A (J);
                     A (J) := T;
                     T     := Hold;
                     L (B) := L (B) - 1;
                     Lemma_Fill_All (A_Old, A, L_Old, L, U, CP, I, B);
                     pragma Assert (Class_Of (T_Old, CP) = B);
                     pragma Assert (T = A_Old (J));
                  end;
                  pragma Assert
                    (for all K in 1 .. M =>
                       Cnt_U (A, L, U, CP, I, N, K)
                       + (if J /= I and then Class_Of (T, CP) = K then 1 else 0)
                       = L (K) - U (K - 1));

                  exit when J = I;
               end loop;
               pragma Assert (not Unfilled (L, U, M, I));
               Lemma_Unhole (A, L, U, CP, I);
            else
               Lemma_Skip (A, L, U, CP, I);
            end if;
            pragma Assert (not Unfilled (L, U, M, I));
            pragma Assert
              (for all K in 1 .. M =>
                 L (K) = U (K - 1) or else U (K - 1) + 1 >= I + 1);
         end loop;

         pragma Assert (for all K in 1 .. M => L (K) = U (K - 1));
         pragma Assert (Borders_Ok (U, U, M, N));

         --  Insertion-sort each class region.
         for K in 1 .. M loop
            pragma Loop_Invariant (In_Range (A, CP));
            pragma Loop_Invariant
              (for all K2 in 1 .. M =>
                 (for all P in U (K2 - 1) + 1 .. U (K2) =>
                    Class_Of (A (P), CP) = K2));
            pragma Loop_Invariant
              (for all K2 in 1 .. K - 1 => Sorted_Slice (A, U (K2 - 1) + 1, U (K2)));

            Lo := U (K - 1) + 1;
            Hi := U (K);
            if Lo < Hi then
               declare
                  A_Pre : constant Element_Array := A with Ghost;
               begin
                  Insertion_Range (A, Lo, Hi, CP, K);
                  Lemma_Regions_Keep (A_Pre, A, U, M, K);
               end;
            end if;
            pragma Assert (Sorted_Slice (A, U (K - 1) + 1, U (K)));
         end loop;

         --  The regions tile 1 .. N in class order.
         Lemma_Tile (A, U, CP);
         pragma Assert (Sorted_Slice (A, 1, N));
      end;
   end Flashsort_Phase;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Flashsort_Phase (A);
   end Sort;

end Flashsort;
