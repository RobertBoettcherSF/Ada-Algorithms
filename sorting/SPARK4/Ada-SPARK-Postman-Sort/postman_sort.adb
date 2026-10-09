--  Postman_Sort body: SPARK Level 4 MSD postal distribution, proved to
--  sort on its own (no bubble-sort safety net, no clamps).
--
--  MSD_Range (Lo, Hi, P) is called on a slice whose keys all share the
--  same prefix Key / 10**P / Base (Same_Prefix). It counts the digit
--  (Key / 10**P) rem Base of every key, turns the counts into exact
--  bucket starts (Sum_To), scatters stably into Work and copies back.
--  The proof tracks, per digit D, that the slots Lo + Sum_To (Count, D)
--  .. Lo + Sum_To (Count, D + 1) - 1 hold exactly keys of digit D with
--  the slice's prefix; the regions tile Lo .. Hi because the counts sum
--  to the slice length. Each bucket shares the prefix one digit lower
--  (Lemma_Div_Div), so the recursive call applies; at P = 0 a bucket
--  holds equal keys. Adjacent buckets are ordered because a smaller
--  digit under the same prefix means a smaller key (Lemma_Order).
--  Permutation is checked by the tests, not stated in the contracts.

package body Postman_Sort
  with SPARK_Mode => On
is

   subtype Pow_Index is Natural range 0 .. 9;
   subtype Pos_Pow is Pow_Index range 1 .. 9;

   --  10 ** P. 10 ** 9 is the largest power of Base that fits in Integer.
   function Pow10 (P : Pow_Index) return Positive is
     (case P is
        when 0 => 1,
        when 1 => 10,
        when 2 => 100,
        when 3 => 1_000,
        when 4 => 10_000,
        when 5 => 100_000,
        when 6 => 1_000_000,
        when 7 => 10_000_000,
        when 8 => 100_000_000,
        when 9 => 1_000_000_000)
   with Global => null;

   --  Digit of Key at significance 10 ** P.
   function Digit_Of (Key : Natural; P : Pow_Index) return Digit_Index is
     ((Key / Pow10 (P)) rem Base)
   with Global => null;

   ---------------------------------------------------------------------------
   -- Ghost model
   ---------------------------------------------------------------------------

   --  Key with its lowest P + 1 digits removed.
   function Prefix (Key : Natural; P : Pow_Index) return Natural is
     (Key / Pow10 (P) / Base)
   with Ghost => True, Global => null;

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

   --  Every key in A (L .. H) has the same prefix as V at P.
   function Same_Prefix
     (A : Element_Array; L, H : Natural; P : Pow_Index; V : Natural)
      return Boolean
   is
     (for all K in L .. H => Prefix (A (K), P) = Prefix (V, P))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A) and then Keys_Ok (A)
       and then L >= 1 and then H <= A'Last;

   --  Number of K in L .. H whose key has digit D at P (negative keys,
   --  excluded by Keys_Ok everywhere it is used, count for no digit; the
   --  guard keeps the recursive Pre O(1) when it is executed).
   function Cnt
     (A : Element_Array; L, H : Natural; P : Pow_Index; D : Digit_Index)
      return Natural
   is
     (if H < L then 0
      else Cnt (A, L, H - 1, P, D)
           + (if A (H) >= 0 and then Digit_Of (A (H), P) = D then 1 else 0))
   with
     Ghost              => True,
     Global             => null,
     Pre                =>
       In_Bounds (A) and then L >= 1 and then H <= A'Last,
     Post               =>
       Cnt'Result <= (if H < L then 0 else H - L + 1),
     Subprogram_Variant => (Decreases => H);

   --  Count (0) + ... + Count (D - 1).
   subtype Digit_Bound is Natural range 0 .. Base;

   function Sum_To (C : Count_Array; D : Digit_Bound) return Natural is
     (if D = 0 then 0 else Sum_To (C, D - 1) + C (D - 1))
   with
     Ghost              => True,
     Global             => null,
     Post               => Sum_To'Result <= D * Max_N,
     Subprogram_Variant => (Decreases => D);

   ---------------------------------------------------------------------------
   -- Arithmetic lemmas (case split on P: division by a constant)
   ---------------------------------------------------------------------------

   --  Dropping one more digit: K / 10**P = K / 10**(P-1) / Base.
   procedure Lemma_Div_Div (K : Natural; P : Pos_Pow)
     with
       Ghost  => True,
       Global => null,
       Post   => K / Pow10 (P) = K / Pow10 (P - 1) / Base
   is
   begin
      case P is
         when 1 => null;
         when 2 => pragma Assert (K / 100 = K / 10 / 10);
         when 3 => pragma Assert (K / 1_000 = K / 100 / 10);
         when 4 => pragma Assert (K / 10_000 = K / 1_000 / 10);
         when 5 => pragma Assert (K / 100_000 = K / 10_000 / 10);
         when 6 => pragma Assert (K / 1_000_000 = K / 100_000 / 10);
         when 7 => pragma Assert (K / 10_000_000 = K / 1_000_000 / 10);
         when 8 => pragma Assert (K / 100_000_000 = K / 10_000_000 / 10);
         when 9 =>
            pragma Assert (K / 1_000_000_000 = K / 100_000_000 / 10);
      end case;
   end Lemma_Div_Div;

   --  Division by 10 ** P is monotonic.
   procedure Lemma_Div_Mono (Small, Big : Natural; P : Pow_Index)
     with
       Ghost  => True,
       Global => null,
       Pre    => Small <= Big,
       Post   => Small / Pow10 (P) <= Big / Pow10 (P)
   is
   begin
      case P is
         when 0 => null;
         when 1 => pragma Assert (Small / 10 <= Big / 10);
         when 2 => pragma Assert (Small / 100 <= Big / 100);
         when 3 => pragma Assert (Small / 1_000 <= Big / 1_000);
         when 4 => pragma Assert (Small / 10_000 <= Big / 10_000);
         when 5 => pragma Assert (Small / 100_000 <= Big / 100_000);
         when 6 => pragma Assert (Small / 1_000_000 <= Big / 1_000_000);
         when 7 => pragma Assert (Small / 10_000_000 <= Big / 10_000_000);
         when 8 => pragma Assert (Small / 100_000_000 <= Big / 100_000_000);
         when 9 => pragma Assert (Small / 1_000_000_000 <= Big / 1_000_000_000);
      end case;
   end Lemma_Div_Mono;

   --  Same prefix and a smaller digit: a smaller key.
   procedure Lemma_Order (X, Y : Natural; P : Pow_Index)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         Prefix (X, P) = Prefix (Y, P)
         and then Digit_Of (X, P) < Digit_Of (Y, P),
       Post   => X < Y
   is
      QX : constant Natural := X / Pow10 (P);
      QY : constant Natural := Y / Pow10 (P);
   begin
      pragma Assert (QX = QX / Base * Base + QX rem Base);
      pragma Assert (QY = QY / Base * Base + QY rem Base);
      pragma Assert (QX < QY);
   end Lemma_Order;

   --  Same prefix and digit: the same key / 10 ** P.
   procedure Lemma_Same_Quot (X, Y : Natural; P : Pow_Index)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         Prefix (X, P) = Prefix (Y, P)
         and then Digit_Of (X, P) = Digit_Of (Y, P),
       Post   => X / Pow10 (P) = Y / Pow10 (P)
   is
      QX : constant Natural := X / Pow10 (P);
      QY : constant Natural := Y / Pow10 (P);
   begin
      pragma Assert (QX = QX / Base * Base + QX rem Base);
      pragma Assert (QY = QY / Base * Base + QY rem Base);
   end Lemma_Same_Quot;

   ---------------------------------------------------------------------------
   -- Counting lemmas
   ---------------------------------------------------------------------------

   --  Cnt grows with the upper end.
   procedure Lemma_Cnt_Mono
     (A : Element_Array; L, I, H : Natural; P : Pow_Index; D : Digit_Index)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A) and then L >= 1 and then H <= A'Last and then I <= H,
       Post   => Cnt (A, L, I, P, D) <= Cnt (A, L, H, P, D)
   is
      C0 : constant Natural := Cnt (A, L, I, P, D);
   begin
      for J in I .. H loop
         pragma Loop_Invariant (C0 <= Cnt (A, L, J, P, D));
      end loop;
   end Lemma_Cnt_Mono;

   --  Adding one to C (E) adds one to Sum_To (C, D) when E < D.
   procedure Lemma_Sum_Inc
     (C_Old, C_New : Count_Array; E : Digit_Index; D : Digit_Bound)
     with
       Ghost              => True,
       Global             => null,
       Pre                =>
         C_New (E) = C_Old (E) + 1
         and then (for all J in Digit_Index =>
                     (if J /= E then C_New (J) = C_Old (J))),
       Post               =>
         Sum_To (C_New, D) = Sum_To (C_Old, D) + (if E < D then 1 else 0),
       Subprogram_Variant => (Decreases => D)
   is
   begin
      if D > 0 then
         Lemma_Sum_Inc (C_Old, C_New, E, D - 1);
      end if;
   end Lemma_Sum_Inc;

   --  Sum_To is monotonic in D.
   procedure Lemma_Sum_Mono (C : Count_Array)
     with
       Ghost  => True,
       Global => null,
       Post   =>
         (for all D1 in 0 .. Base =>
            (for all D2 in D1 .. Base => Sum_To (C, D1) <= Sum_To (C, D2)))
   is
   begin
      for D1 in reverse 0 .. Base loop
         for D2 in D1 .. Base loop
            pragma Loop_Invariant
              (for all D3 in D1 .. D2 => Sum_To (C, D1) <= Sum_To (C, D3));
         end loop;
         pragma Loop_Invariant
           (for all D4 in D1 .. Base =>
              (for all D2 in D4 .. Base => Sum_To (C, D4) <= Sum_To (C, D2)));
      end loop;
   end Lemma_Sum_Mono;

   ---------------------------------------------------------------------------
   -- Bucket lemmas
   ---------------------------------------------------------------------------

   --  Keys of one digit under one prefix share the prefix one digit lower.
   procedure Lemma_Bucket_Pre
     (A : Element_Array; L, H : Natural; P : Pos_Pow; D : Digit_Index;
      V : Natural)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A) and then Keys_Ok (A)
         and then L >= 1 and then H <= A'Last and then L <= H
         and then (for all K in L .. H =>
                     Digit_Of (A (K), P) = D
                     and then Prefix (A (K), P) = Prefix (V, P)),
       Post   => Same_Prefix (A, L, H, P - 1, A (L))
   is
   begin
      Lemma_Div_Div (A (L), P);
      for K in L .. H loop
         Lemma_Same_Quot (A (K), A (L), P);
         Lemma_Div_Div (A (K), P);
         pragma Loop_Invariant
           (for all J in L .. K => Prefix (A (J), P - 1) = Prefix (A (L), P - 1));
      end loop;
   end Lemma_Bucket_Pre;

   --  After the recursive call: same prefix one digit lower as the old
   --  first key, so the digit and prefix at P are those of that key.
   procedure Lemma_Bucket_Post
     (A : Element_Array; L, H : Natural; P : Pos_Pow; W : Natural)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A) and then Keys_Ok (A)
         and then L >= 1 and then H <= A'Last
         and then Same_Prefix (A, L, H, P - 1, W),
       Post   =>
         (for all K in L .. H =>
            Digit_Of (A (K), P) = Digit_Of (W, P)
            and then Prefix (A (K), P) = Prefix (W, P))
   is
   begin
      Lemma_Div_Div (W, P);
      for K in L .. H loop
         Lemma_Div_Div (A (K), P);
         pragma Loop_Invariant
           (for all J in L .. K =>
              Digit_Of (A (J), P) = Digit_Of (W, P)
              and then Prefix (A (J), P) = Prefix (W, P));
      end loop;
   end Lemma_Bucket_Post;

   --  At P = 0 keys with the same digit and prefix are equal.
   procedure Lemma_Bucket_Units
     (A : Element_Array; L, H : Natural; D : Digit_Index; V : Natural)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A) and then Keys_Ok (A)
         and then L >= 1 and then H <= A'Last
         and then (for all K in L .. H =>
                     Digit_Of (A (K), 0) = D
                     and then Prefix (A (K), 0) = Prefix (V, 0)),
       Post   => Sorted_Slice (A, L, H)
   is
   begin
      for K in L .. H loop
         Lemma_Same_Quot (A (K), A (L), 0);
         pragma Loop_Invariant (for all J in L .. K => A (J) = A (L));
      end loop;
   end Lemma_Bucket_Units;

   --  An all-zero histogram sums to zero.
   procedure Lemma_Sum_Zero (C : Count_Array)
     with
       Ghost  => True,
       Global => null,
       Pre    => (for all J in Digit_Index => C (J) = 0),
       Post   => Sum_To (C, Base) = 0
   is
   begin
      for E in 1 .. Base loop
         pragma Loop_Invariant (Sum_To (C, E - 1) = 0);
         pragma Assert (Sum_To (C, E) = Sum_To (C, E - 1) + C (E - 1));
      end loop;
   end Lemma_Sum_Zero;

   --  Every key <= Max_Key with Max_Key / 10 ** P < Base has prefix 0.
   procedure Lemma_Top_Prefix
     (A : Element_Array; Max_Key : Natural; P : Pow_Index)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A) and then Keys_Ok (A) and then A'Length >= 1
         and then (for all K in A'Range => A (K) <= Max_Key)
         and then Max_Key / Pow10 (P) < Base,
       Post   => Same_Prefix (A, 1, A'Last, P, A (1))
   is
   begin
      for K in A'Range loop
         Lemma_Div_Mono (A (K), Max_Key, P);
         pragma Loop_Invariant
           (for all J in 1 .. K => Prefix (A (J), P) = 0);
      end loop;
   end Lemma_Top_Prefix;

   --  Buckets E = 0 .. Base - 1 cover Lo .. Hi in order; each holds keys
   --  of digit E with one prefix and is sorted: the whole slice is sorted.
   procedure Lemma_Tile
     (A     : Element_Array;
      Lo, Hi : Positive;
      P     : Pow_Index;
      Count : Count_Array;
      V0    : Natural)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A) and then Keys_Ok (A)
         and then Lo <= Hi and then Hi <= A'Last
         and then Sum_To (Count, Base) = Hi - Lo + 1
         and then
           (for all D1 in 0 .. Base =>
              (for all D2 in D1 .. Base =>
                 Sum_To (Count, D1) <= Sum_To (Count, D2)))
         and then
           (for all E in Digit_Index =>
              (for all J in Lo + Sum_To (Count, E)
                            .. Lo + Sum_To (Count, E + 1) - 1 =>
                 Digit_Of (A (J), P) = E
                 and then Prefix (A (J), P) = Prefix (V0, P)))
         and then
           (for all E in Digit_Index =>
              Sorted_Slice
                (A, Lo + Sum_To (Count, E), Lo + Sum_To (Count, E + 1) - 1)),
       Post   =>
         Sorted_Slice (A, Lo, Hi) and then Same_Prefix (A, Lo, Hi, P, V0)
   is
   begin
      for E in Digit_Index loop
         pragma Loop_Invariant
           (Sorted_Slice (A, Lo, Lo + Sum_To (Count, E) - 1));
         pragma Loop_Invariant
           (for all J in Lo .. Lo + Sum_To (Count, E) - 1 =>
              Digit_Of (A (J), P) < E
              and then Prefix (A (J), P) = Prefix (V0, P));
         pragma Assert
           (Sum_To (Count, E + 1) = Sum_To (Count, E) + Count (E));
         if Count (E) > 0 and then Sum_To (Count, E) > 0 then
            Lemma_Order
              (A (Lo + Sum_To (Count, E) - 1), A (Lo + Sum_To (Count, E)), P);
         end if;
         pragma Assert
           (Sorted_Slice (A, Lo, Lo + Sum_To (Count, E + 1) - 1));
         pragma Assert
           (for all J in Lo .. Lo + Sum_To (Count, E + 1) - 1 =>
              Digit_Of (A (J), P) < E + 1
              and then Prefix (A (J), P) = Prefix (V0, P));
      end loop;
   end Lemma_Tile;

   ---------------------------------------------------------------------------
   -- Phases
   ---------------------------------------------------------------------------

   --  Greatest value in nonempty nonnegative A.
   function Max_Value (A : Element_Array) return Natural
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Keys_Ok (A)
         and then A'Length >= 1,
       Post   => (for all K in A'Range => A (K) <= Max_Value'Result)
   is
      M : Natural := A (1);
   begin
      for I in 2 .. A'Last loop
         pragma Loop_Invariant (for all K in 1 .. I - 1 => A (K) <= M);

         if A (I) > M then
            M := A (I);
         end if;
      end loop;

      return M;
   end Max_Value;

   --  Least P with Max_Key / 10 ** P < Base: every key's digits above P
   --  are zero.
   function Highest_Pow (Max_Key : Natural) return Pow_Index
     with
       Global => null,
       Post   => Max_Key / Pow10 (Highest_Pow'Result) < Base
   is
      P : Pow_Index := 0;
   begin
      while P < Pow_Index'Last and then Max_Key / Pow10 (P) >= Base loop
         pragma Loop_Variant (Increases => P);
         P := P + 1;
      end loop;

      return P;
   end Highest_Pow;

   --  Exclusive bucket starts: Start (D) = Count (0) + ... + Count (D - 1).
   procedure Prefix_Starts
     (Count : Count_Array;
      Start : out Count_Array)
     with
       Global => null,
       Pre    =>
         Sum_To (Count, Base) <= Max_N
         and then
           (for all D1 in 0 .. Base =>
              (for all D2 in D1 .. Base =>
                 Sum_To (Count, D1) <= Sum_To (Count, D2))),
       Post   => (for all K in Digit_Index => Start (K) = Sum_To (Count, K))
   is
   begin
      Start := [others => 0];

      for K in 1 .. Base - 1 loop
         pragma Loop_Invariant
           (for all J in 0 .. K - 1 => Start (J) = Sum_To (Count, J));
         Start (K) := Start (K - 1) + Count (K - 1);
      end loop;
   end Prefix_Starts;

   --  MSD distribution of A (Lo .. Hi) on digit P and below. All keys in
   --  the slice share their prefix above P.
   procedure MSD_Range
     (A      : in out Element_Array;
      Lo, Hi : Index;
      P      : Pow_Index)
     with
       Global             => null,
       Pre                =>
         In_Bounds (A)
         and then Keys_Ok (A)
         and then Lo in 1 .. A'Last
         and then Hi in Lo .. A'Last
         and then Same_Prefix (A, Lo, Hi, P, A (Lo)),
       Post               =>
         In_Bounds (A)
         and then Keys_Ok (A)
         and then (for all K in 1 .. A'Last =>
                     (if K < Lo or else K > Hi then A (K) = A'Old (K)))
         and then Sorted_Slice (A, Lo, Hi)
         and then Same_Prefix (A, Lo, Hi, P, A'Old (Lo)),
       Subprogram_Variant => (Decreases => P)
   is
      Count : Count_Array := [others => 0];
      Start : Count_Array;
      Work  : Work_Array := [others => 0];
      D     : Digit_Index;
      B_Lo  : Positive;
      B_Hi  : Positive;
      V0    : constant Natural := A (Lo) with Ghost;
      A_In  : constant Element_Array := A with Ghost;
   begin
      if Hi = Lo then
         return;
      end if;

      Lemma_Sum_Zero (Count);

      --  Histogram of the digit at P on the slice.
      for I in Lo .. Hi loop
         pragma Loop_Invariant
           (for all E in Digit_Index => Count (E) = Cnt (A, Lo, I - 1, P, E));
         pragma Loop_Invariant (Sum_To (Count, Base) = I - Lo);

         D := Digit_Of (A (I), P);
         declare
            C_Prev : constant Count_Array := Count with Ghost;
         begin
            Count (D) := Count (D) + 1;
            pragma Assert
              (for all E in Digit_Index => Count (E) = Cnt (A, Lo, I, P, E));
            Lemma_Sum_Inc (C_Prev, Count, D, Base);
         end;
      end loop;
      pragma Assert (Sum_To (Count, Base) = Hi - Lo + 1);

      Lemma_Sum_Mono (Count);
      Prefix_Starts (Count, Start);

      --  Stable scatter, left to right: the key goes to the next free slot
      --  of its digit's region.
      declare
         Start0 : constant Count_Array := Start with Ghost;
      begin
         for I in Lo .. Hi loop
            pragma Loop_Invariant (for all J in Work'Range => Work (J) >= 0);
            pragma Loop_Invariant
              (for all E in Digit_Index =>
                 Start (E) = Start0 (E) + Cnt (A, Lo, I - 1, P, E));
            pragma Loop_Invariant
              (for all E in Digit_Index =>
                 Start (E) <= Sum_To (Count, E + 1)
                 and then Lo + Start (E) - 1 <= Hi);
            pragma Loop_Invariant
              (for all E in Digit_Index =>
                 (for all J in Lo + Start0 (E) .. Lo + Start (E) - 1 =>
                    Work (J) >= 0
                    and then Digit_Of (Work (J), P) = E
                    and then Prefix (Work (J), P) = Prefix (V0, P)));

            D := Digit_Of (A (I), P);
            Lemma_Cnt_Mono (A, Lo, I, Hi, P, D);
            pragma Assert (Start (D) < Start0 (D) + Count (D));
            pragma Assert (Start0 (D) + Count (D) = Sum_To (Count, D + 1));
            pragma Assert
              (for all E in Digit_Index =>
                 (if E < D then Start (E) <= Start0 (D)));
            pragma Assert
              (for all E in Digit_Index =>
                 (if E > D then Start (D) < Start0 (E)));

            Work (Lo + Start (D)) := A (I);
            Start (D) := Start (D) + 1;
         end loop;

         pragma Assert
           (for all E in Digit_Index =>
              Start (E) = Sum_To (Count, E + 1));
         pragma Assert
           (for all E in Digit_Index =>
              (for all J in Lo + Sum_To (Count, E)
                            .. Lo + Sum_To (Count, E + 1) - 1 =>
                 Work (J) >= 0
                 and then Digit_Of (Work (J), P) = E
                 and then Prefix (Work (J), P) = Prefix (V0, P)));
      end;

      --  Gather Work (Lo .. Hi) back into A.
      pragma Assert (for all J in Work'Range => Work (J) >= 0);
      for I in Lo .. Hi loop
         pragma Loop_Invariant
           (for all K in 1 .. A'Last =>
              (if K < Lo or else K >= I then A (K) = A_In (K)));
         pragma Loop_Invariant (for all K in Lo .. I - 1 => A (K) = Work (K));
         pragma Loop_Invariant (Keys_Ok (A));
         A (I) := Work (I);
      end loop;
      pragma Assert (Keys_Ok (A));

      pragma Assert
        (for all E in Digit_Index =>
           (for all J in Lo + Sum_To (Count, E)
                         .. Lo + Sum_To (Count, E + 1) - 1 =>
              A (J) >= 0
              and then Digit_Of (A (J), P) = E
              and then Prefix (A (J), P) = Prefix (V0, P)));

      --  Sort each bucket on the next lower digit.
      Prefix_Starts (Count, Start);
      for DD in Digit_Index loop
         pragma Loop_Invariant (Keys_Ok (A));
         pragma Loop_Invariant
           (for all K in 1 .. A'Last =>
              (if K < Lo or else K > Hi then A (K) = A_In (K)));
         pragma Loop_Invariant
           (for all E in Digit_Index =>
              (for all J in Lo + Sum_To (Count, E)
                            .. Lo + Sum_To (Count, E + 1) - 1 =>
                 Digit_Of (A (J), P) = E
                 and then Prefix (A (J), P) = Prefix (V0, P)));
         pragma Loop_Invariant
           (for all E in 0 .. DD - 1 =>
              Sorted_Slice
                (A, Lo + Sum_To (Count, E), Lo + Sum_To (Count, E + 1) - 1));

         if Count (DD) > 1 then
            B_Lo := Lo + Start (DD);
            B_Hi := B_Lo + Count (DD) - 1;
            pragma Assert (B_Hi = Lo + Sum_To (Count, DD + 1) - 1);
            if P = 0 then
               Lemma_Bucket_Units (A, B_Lo, B_Hi, DD, V0);
            else
               Lemma_Bucket_Pre (A, B_Lo, B_Hi, P, DD, V0);
               declare
                  A_Pre : constant Element_Array := A with Ghost;
               begin
                  MSD_Range (A, B_Lo, B_Hi, P - 1);
                  Lemma_Bucket_Post (A, B_Lo, B_Hi, P, A_Pre (B_Lo));
                  pragma Assert
                    (for all E in Digit_Index =>
                       (if E /= DD then
                          (for all J in Lo + Sum_To (Count, E)
                                        .. Lo + Sum_To (Count, E + 1) - 1 =>
                             A (J) = A_Pre (J))));
               end;
            end if;
         end if;
         pragma Assert
           (Sorted_Slice
              (A, Lo + Sum_To (Count, DD), Lo + Sum_To (Count, DD + 1) - 1));
      end loop;

      --  The buckets tile Lo .. Hi in digit order.
      Lemma_Tile (A, Lo, Hi, P, Count, V0);
      pragma Assert (Sorted_Slice (A, Lo, Hi));
   end MSD_Range;

   --  MSD postman phase: find the top digit, distribute from there.
   procedure Postman_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Keys_Ok (A)
         and then A'Length >= 2,
       Post   => In_Bounds (A) and then Is_Sorted (A)
   is
      Max_Key : Natural;
      P       : Pow_Index;
   begin
      Max_Key := Max_Value (A);
      if Max_Key = 0 then
         --  All zeros: already sorted.
         pragma Assert (for all K in A'Range => A (K) = 0);
         return;
      end if;

      P := Highest_Pow (Max_Key);
      Lemma_Top_Prefix (A, Max_Key, P);
      pragma Assert (Same_Prefix (A, 1, A'Last, P, A (1)));
      MSD_Range (A, 1, A'Last, P);
   end Postman_Phase;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Postman_Phase (A);
   end Sort;

end Postman_Sort;
