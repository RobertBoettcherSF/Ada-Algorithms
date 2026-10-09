--  Stooge_Sort body: SPARK Level 4 recursive 2/3-2/3-2/3 sort, proved to
--  sort on its own (no bubble-sort safety net).
--
--  Stooge_Range (Lo, Hi) proves that A (Lo .. Hi) ends sorted (pairwise)
--  and that, for every threshold X, the number of elements >= X in
--  Lo .. Hi is unchanged. The count is the classic "largest third"
--  argument made checkable: after the first recursive call the middle
--  third (at least T elements) is >= every element of the first third,
--  so after the second call the last T places hold values >= each of
--  those elements; the third call then only rearranges values that are
--  all <= the smallest of the last T places.
--
--  The Post states the count equality only at the values present in
--  Lo .. Hi (Same_Counts), so it stays cheap to execute under -gnata;
--  Lemma_Count_Any lifts it to every threshold.

package body Stooge_Sort
  with SPARK_Mode => On
is

   --  Postconditions and assertions inside this body are proof
   --  obligations, proved by gnatprove and not evaluated at run time:
   --  Same_Occ quantifies over every Integer value. (The Post of Sort in
   --  the spec, Is_Sorted and Is_Perm, is still checked at run time under
   --  -gnata.) The ghost proof code (lemmas, snapshots) is not run
   --  either; it only serves the proof.
   pragma Assertion_Policy (Post => Ignore, Assert => Ignore, Ghost => Ignore);

   ---------------------------------------------------------------------------
   -- Permutation proof (ghost). Same_Occ is the logical multiset equality
   -- over every Integer value; it only appears in loop invariants and in
   -- lemma contracts, which are proved and not evaluated at run time (an
   -- evaluation would range over all Integer values).
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
      pragma Assertion_Policy (Pre => Ignore, Post => Ignore);

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
        (A, B : Element_Array; K : Live_Index; Last : Natural)
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
      procedure Lemma_Swap (A, B : Element_Array; X, Y : Live_Index)
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

      procedure Lemma_Same_Perm (A, B : Element_Array)
      with
        Global => null,
        Pre    => In_Bounds (A) and then In_Bounds (B) and then Same_Occ (A, B),
        Post   => Is_Perm (A, B);
   end Perm_Lemmas;

   package body Perm_Lemmas is

      procedure Lemma_Occ_Frame (A, B : Element_Array; Last : Natural) is
      begin
         if Last >= A'First then
            Lemma_Occ_Frame (A, B, Last - 1);
         end if;
      end Lemma_Occ_Frame;

      procedure Lemma_Occ_Set
        (A, B : Element_Array; K : Live_Index; Last : Natural) is
      begin
         if Last > K then
            Lemma_Occ_Set (A, B, K, Last - 1);
         else
            Lemma_Occ_Frame (A, B, K - 1);
         end if;
      end Lemma_Occ_Set;

      procedure Lemma_Swap (A, B : Element_Array; X, Y : Live_Index) is
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

      procedure Lemma_Same_Perm (A, B : Element_Array) is null;

   end Perm_Lemmas;
   use Perm_Lemmas;

   ---------------------------------------------------------------------------
   -- Ghost model
   ---------------------------------------------------------------------------

   --  Pairwise nondecreasing on A (L .. R). Vacuous when L >= R.
   function Sorted_Pw
     (A : Element_Array; L, R : Natural) return Boolean
   is
     (for all I in L .. R =>
        (for all J in I .. R => A (I) <= A (J)))
   with
     Ghost  => True,
     Global => null,
     Pre    => In_Bounds (A) and then L >= A'First and then R <= A'Last;

   --  Number of K in L .. H with A (K) >= X.
   function Count_Ge
     (A : Element_Array; L, H : Natural; X : Integer) return Natural
   is
     (if H < L then 0
      else Count_Ge (A, L, H - 1, X) + (if A (H) >= X then 1 else 0))
   with
     Ghost              => True,
     Global             => null,
     Pre                =>
       In_Bounds (A) and then L >= A'First and then H <= A'Last,
     Post               =>
       Count_Ge'Result <= (if H < L then 0 else H - L + 1),
     Subprogram_Variant => (Decreases => H);

   --  Same count of elements >= X in L .. H, for every X that occurs in
   --  A (L .. H) or B (L .. H).
   function Same_Counts
     (A, B : Element_Array; L, H : Natural) return Boolean
   is
     (for all J in L .. H =>
        Count_Ge (A, L, H, A (J)) = Count_Ge (B, L, H, A (J))
        and then Count_Ge (A, L, H, B (J)) = Count_Ge (B, L, H, B (J)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A) and then In_Bounds (B)
       and then A'First = B'First and then A'Last = B'Last
       and then L >= A'First and then H <= A'Last;

   ---------------------------------------------------------------------------
   -- Counting lemmas
   ---------------------------------------------------------------------------

   procedure Lemma_Split (A : Element_Array; L, M, H : Natural; X : Integer)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A) and then L >= A'First and then H <= A'Last
         and then M >= L - 1 and then M <= H,
       Post   =>
         Count_Ge (A, L, H, X) = Count_Ge (A, L, M, X) + Count_Ge (A, M + 1, H, X)
   is
   begin
      for J in M + 1 .. H loop
         pragma Loop_Invariant
           (Count_Ge (A, L, J, X) = Count_Ge (A, L, M, X) + Count_Ge (A, M + 1, J, X));
      end loop;
   end Lemma_Split;

   procedure Lemma_Frame (A, B : Element_Array; L, H : Natural; X : Integer)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A) and then In_Bounds (B)
         and then A'First = B'First and then A'Last = B'Last
         and then L >= A'First and then H <= A'Last
         and then (for all K in L .. H => A (K) = B (K)),
       Post   => Count_Ge (A, L, H, X) = Count_Ge (B, L, H, X)
   is
   begin
      for J in L .. H loop
         pragma Loop_Invariant (Count_Ge (A, L, J, X) = Count_Ge (B, L, J, X));
      end loop;
   end Lemma_Frame;

   procedure Lemma_Zero_If (A : Element_Array; L, H : Natural; X : Integer)
     with
       Ghost  => True,
       Global => null,
       Pre    => In_Bounds (A) and then L >= A'First and then H <= A'Last,
       Post   =>
         (if (for all K in L .. H => A (K) < X)
          then Count_Ge (A, L, H, X) = 0)
   is
   begin
      if (for all K in L .. H => A (K) < X) then
         for J in L .. H loop
            pragma Loop_Invariant (Count_Ge (A, L, J, X) = 0);
         end loop;
      end if;
   end Lemma_Zero_If;

   --  M1 .. M2 all >= X gives at least M2 - M1 + 1 elements >= X.
   procedure Lemma_Lower
     (A : Element_Array; L, H, M1, M2 : Natural; X : Integer)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A) and then L >= A'First and then H <= A'Last
         and then L <= M1 and then M1 <= M2 and then M2 <= H
         and then (for all K in M1 .. M2 => A (K) >= X),
       Post   => Count_Ge (A, L, H, X) >= M2 - M1 + 1
   is
   begin
      for J in L .. H loop
         pragma Loop_Invariant
           (Count_Ge (A, L, J, X)
              >= (if J < M1 then 0 else Integer'Min (J, M2) - M1 + 1));
      end loop;
   end Lemma_Lower;

   --  L .. M all < X leaves at most H - M elements >= X in L .. H.
   procedure Lemma_Upper_If
     (A : Element_Array; L, M, H : Natural; X : Integer)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A) and then L >= A'First and then H <= A'Last
         and then L <= M and then M <= H,
       Post   =>
         (if (for all K in L .. M => A (K) < X)
          then Count_Ge (A, L, H, X) <= H - M)
   is
   begin
      if (for all K in L .. M => A (K) < X) then
         for J in L .. H loop
            pragma Loop_Invariant
              (Count_Ge (A, L, J, X) <= (if J <= M then 0 else J - M));
         end loop;
      end if;
   end Lemma_Upper_If;

   --  No element in [X, Y): the counts at X and at Y agree.
   procedure Lemma_Gap (A : Element_Array; L, H : Natural; X, Y : Integer)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A) and then L >= A'First and then H <= A'Last
         and then X <= Y
         and then (for all K in L .. H => A (K) < X or else A (K) >= Y),
       Post   => Count_Ge (A, L, H, X) = Count_Ge (A, L, H, Y)
   is
   begin
      for J in L .. H loop
         pragma Loop_Invariant (Count_Ge (A, L, J, X) = Count_Ge (A, L, J, Y));
      end loop;
   end Lemma_Gap;

   --  Equal counts at the values present give equal counts at any X: both
   --  counts at X equal the counts at the least present value >= X.
   procedure Lemma_Count_Any
     (A, B : Element_Array; L, H : Natural; X : Integer)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A) and then In_Bounds (B)
         and then A'First = B'First and then A'Last = B'Last
         and then L >= A'First and then H <= A'Last
         and then Same_Counts (A, B, L, H),
       Post   => Count_Ge (A, L, H, X) = Count_Ge (B, L, H, X)
   is
      Found : Boolean := False;
      M     : Integer := X;
      MK    : Natural := L;
      In_A  : Boolean := True;
   begin
      for K in L .. H loop
         if A (K) >= X and then (not Found or else A (K) < M) then
            Found := True;
            M := A (K);
            MK := K;
            In_A := True;
         end if;
         if B (K) >= X and then (not Found or else B (K) < M) then
            Found := True;
            M := B (K);
            MK := K;
            In_A := False;
         end if;
         pragma Loop_Invariant
           (if not Found
            then (for all J in L .. K => A (J) < X and then B (J) < X));
         pragma Loop_Invariant
           (if Found
            then M >= X and then MK in L .. K
                 and then (if In_A then A (MK) = M else B (MK) = M)
                 and then
                   (for all J in L .. K =>
                      (A (J) < X or else A (J) >= M)
                      and then (B (J) < X or else B (J) >= M)));
      end loop;

      if not Found then
         Lemma_Zero_If (A, L, H, X);
         Lemma_Zero_If (B, L, H, X);
      else
         Lemma_Gap (A, L, H, X, M);
         Lemma_Gap (B, L, H, X, M);
         pragma Assert (Count_Ge (A, L, H, M) = Count_Ge (B, L, H, M));
      end if;
   end Lemma_Count_Any;

   --  Swapping positions I < J inside L .. H keeps every count.
   procedure Lemma_Swap_Count
     (A, B : Element_Array; L, H, I, J : Natural; X : Integer)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A) and then In_Bounds (B)
         and then A'First = B'First and then A'Last = B'Last
         and then L >= A'First and then H <= A'Last
         and then L <= I and then I < J and then J <= H
         and then A (I) = B (J) and then A (J) = B (I)
         and then
           (for all K in A'Range =>
              (if K /= I and then K /= J then A (K) = B (K))),
       Post   => Count_Ge (A, L, H, X) = Count_Ge (B, L, H, X)
   is
   begin
      for K in L .. H loop
         pragma Loop_Invariant
           (Count_Ge (A, L, K, X)
              + (if I <= K and then K < J and then B (I) >= X then 1 else 0)
            = Count_Ge (B, L, K, X)
              + (if I <= K and then K < J and then A (I) >= X then 1 else 0));
      end loop;
   end Lemma_Swap_Count;

   procedure Lemma_Swap_Same
     (A, B : Element_Array; L, H, I, J : Natural)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A) and then In_Bounds (B)
         and then A'First = B'First and then A'Last = B'Last
         and then L >= A'First and then H <= A'Last
         and then L <= I and then I < J and then J <= H
         and then A (I) = B (J) and then A (J) = B (I)
         and then
           (for all K in A'Range =>
              (if K /= I and then K /= J then A (K) = B (K))),
       Post   => Same_Counts (A, B, L, H)
   is
   begin
      for K in L .. H loop
         Lemma_Swap_Count (A, B, L, H, I, J, A (K));
         Lemma_Swap_Count (A, B, L, H, I, J, B (K));
         pragma Loop_Invariant
           (for all K2 in L .. K =>
              Count_Ge (A, L, H, A (K2)) = Count_Ge (B, L, H, A (K2))
              and then Count_Ge (A, L, H, B (K2)) = Count_Ge (B, L, H, B (K2)));
      end loop;
   end Lemma_Swap_Same;

   --  Sorted L .. H with at least C elements >= X: the last C are >= X.
   procedure Lemma_Sorted_Top
     (A : Element_Array; L, H, C : Natural; X : Integer)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A) and then L >= A'First and then H <= A'Last
         and then C in 1 .. H - L + 1
         and then Sorted_Pw (A, L, H)
         and then Count_Ge (A, L, H, X) >= C,
       Post   => (for all Q in H - C + 1 .. H => A (Q) >= X)
   is
   begin
      Lemma_Upper_If (A, L, H - C + 1, H, X);
      pragma Assert (A (H - C + 1) >= X);
   end Lemma_Sorted_Top;

   ---------------------------------------------------------------------------
   -- The three steps of the stooge argument
   ---------------------------------------------------------------------------

   --  After the second call: the first two thirds are <= the last T places.
   procedure Lemma_After_Second
     (A1, A2 : Element_Array; Lo, Hi, T : Natural)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A1) and then In_Bounds (A2)
         and then A1'First = A2'First and then A1'Last = A2'Last
         and then Lo >= A1'First and then Hi <= A1'Last
         and then Lo <= Hi and then T in 1 .. Max_N
         and then Lo + 3 * T <= Hi + 1
         and then Sorted_Pw (A1, Lo, Hi - T)
         and then (for all K in Lo .. Lo + T - 1 => A2 (K) = A1 (K))
         and then Sorted_Pw (A2, Lo + T, Hi)
         and then Same_Counts (A2, A1, Lo + T, Hi),
       Post   =>
         (for all P in Lo .. Hi - T =>
            (for all Q in Hi - T + 1 .. Hi => A2 (P) <= A2 (Q)))
   is
   begin
      for P in Lo .. Lo + T - 1 loop
         --  The middle third Lo + T .. Hi - T (>= T elements) is >= A1 (P).
         Lemma_Lower (A1, Lo + T, Hi, Lo + T, Hi - T, A1 (P));
         Lemma_Count_Any (A2, A1, Lo + T, Hi, A1 (P));
         Lemma_Sorted_Top (A2, Lo + T, Hi, T, A1 (P));
         pragma Loop_Invariant
           (for all P2 in Lo .. P =>
              (for all Q in Hi - T + 1 .. Hi => A2 (P2) <= A2 (Q)));
      end loop;
   end Lemma_After_Second;

   --  After the third call: every value of Lo .. M1 is <= A2 (M1 + 1).
   procedure Lemma_After_Third
     (A2, A3 : Element_Array; Lo, M1, Hi : Natural)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A2) and then In_Bounds (A3)
         and then A2'First = A3'First and then A2'Last = A3'Last
         and then Lo >= A2'First and then Hi <= A2'Last
         and then Lo <= M1 and then M1 < Hi
         and then (for all P in Lo .. M1 => A2 (P) <= A2 (M1 + 1))
         and then Same_Counts (A3, A2, Lo, M1),
       Post   => (for all I in Lo .. M1 => A3 (I) <= A2 (M1 + 1))
   is
   begin
      for I in Lo .. M1 loop
         Lemma_Zero_If (A2, Lo, M1, A3 (I));
         Lemma_Count_Any (A3, A2, Lo, M1, A3 (I));
         Lemma_Lower (A3, Lo, M1, I, I, A3 (I));
         pragma Loop_Invariant
           (for all I2 in Lo .. I => A3 (I2) <= A2 (M1 + 1));
      end loop;
   end Lemma_After_Third;

   --  One threshold through the three calls: the count over Lo .. Hi is
   --  unchanged (each call keeps its own range's counts and the rest).
   procedure Lemma_Chain_X
     (A_In, A0, A1, A2, A3 : Element_Array; Lo, Hi, T : Natural; X : Integer)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A_In) and then In_Bounds (A0) and then In_Bounds (A1)
         and then In_Bounds (A2) and then In_Bounds (A3)
         and then A0'First = A_In'First and then A0'Last = A_In'Last
         and then A1'First = A_In'First and then A1'Last = A_In'Last
         and then A2'First = A_In'First and then A2'Last = A_In'Last
         and then A3'First = A_In'First and then A3'Last = A_In'Last
         and then Lo >= A_In'First and then Hi <= A_In'Last
         and then Lo <= Hi and then T in 1 .. Max_N
         and then Lo + 3 * T <= Hi + 1
         and then Same_Counts (A0, A_In, Lo, Hi)
         and then Same_Counts (A1, A0, Lo, Hi - T)
         and then (for all K in Hi - T + 1 .. Hi => A1 (K) = A0 (K))
         and then Same_Counts (A2, A1, Lo + T, Hi)
         and then (for all K in Lo .. Lo + T - 1 => A2 (K) = A1 (K))
         and then Same_Counts (A3, A2, Lo, Hi - T)
         and then (for all K in Hi - T + 1 .. Hi => A3 (K) = A2 (K)),
       Post   => Count_Ge (A3, Lo, Hi, X) = Count_Ge (A_In, Lo, Hi, X)
   is
   begin
      Lemma_Count_Any (A0, A_In, Lo, Hi, X);

      Lemma_Split (A1, Lo, Hi - T, Hi, X);
      Lemma_Split (A0, Lo, Hi - T, Hi, X);
      Lemma_Count_Any (A1, A0, Lo, Hi - T, X);
      Lemma_Frame (A1, A0, Hi - T + 1, Hi, X);

      Lemma_Split (A2, Lo, Lo + T - 1, Hi, X);
      Lemma_Split (A1, Lo, Lo + T - 1, Hi, X);
      Lemma_Count_Any (A2, A1, Lo + T, Hi, X);
      Lemma_Frame (A2, A1, Lo, Lo + T - 1, X);

      Lemma_Split (A3, Lo, Hi - T, Hi, X);
      Lemma_Split (A2, Lo, Hi - T, Hi, X);
      Lemma_Count_Any (A3, A2, Lo, Hi - T, X);
      Lemma_Frame (A3, A2, Hi - T + 1, Hi, X);
   end Lemma_Chain_X;

   procedure Lemma_Chain
     (A_In, A0, A1, A2, A3 : Element_Array; Lo, Hi, T : Natural)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A_In) and then In_Bounds (A0) and then In_Bounds (A1)
         and then In_Bounds (A2) and then In_Bounds (A3)
         and then A0'First = A_In'First and then A0'Last = A_In'Last
         and then A1'First = A_In'First and then A1'Last = A_In'Last
         and then A2'First = A_In'First and then A2'Last = A_In'Last
         and then A3'First = A_In'First and then A3'Last = A_In'Last
         and then Lo >= A_In'First and then Hi <= A_In'Last
         and then Lo <= Hi and then T in 1 .. Max_N
         and then Lo + 3 * T <= Hi + 1
         and then Same_Counts (A0, A_In, Lo, Hi)
         and then Same_Counts (A1, A0, Lo, Hi - T)
         and then (for all K in Hi - T + 1 .. Hi => A1 (K) = A0 (K))
         and then Same_Counts (A2, A1, Lo + T, Hi)
         and then (for all K in Lo .. Lo + T - 1 => A2 (K) = A1 (K))
         and then Same_Counts (A3, A2, Lo, Hi - T)
         and then (for all K in Hi - T + 1 .. Hi => A3 (K) = A2 (K)),
       Post   => Same_Counts (A3, A_In, Lo, Hi)
   is
   begin
      for J in Lo .. Hi loop
         Lemma_Chain_X (A_In, A0, A1, A2, A3, Lo, Hi, T, A3 (J));
         Lemma_Chain_X (A_In, A0, A1, A2, A3, Lo, Hi, T, A_In (J));
         pragma Loop_Invariant
           (for all J2 in Lo .. J =>
              Count_Ge (A3, Lo, Hi, A3 (J2)) = Count_Ge (A_In, Lo, Hi, A3 (J2))
              and then
                Count_Ge (A3, Lo, Hi, A_In (J2))
                  = Count_Ge (A_In, Lo, Hi, A_In (J2)));
      end loop;
   end Lemma_Chain;

   ---------------------------------------------------------------------------
   -- Algorithm
   ---------------------------------------------------------------------------

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

   --  Classic stooge on A (Lo .. Hi). Variant Hi - Lo decreases on each
   --  recursive call (span shrinks by T = floor(L/3) >= 1 when L > 2).
   procedure Stooge_Range
     (A      : in out Element_Array;
      Lo, Hi : Index)
     with
       Global             => null,
       Subprogram_Variant => (Decreases => Hi - Lo),
       Pre                =>
         In_Bounds (A)
         and then Lo in A'Range
         and then Hi in Lo .. A'Last,
       Post               =>
         In_Bounds (A)
         and then (for all K in A'First .. Lo - 1 => A (K) = A'Old (K))
         and then (for all K in Hi + 1 .. A'Last => A (K) = A'Old (K))
         and then Sorted_Pw (A, Lo, Hi)
         and then Same_Counts (A, A'Old, Lo, Hi)
         and then Same_Occ (A, A'Old)
   is
      A_In : constant Element_Array := A with Ghost;
      L    : Natural;
      T    : Index;
   begin
      if A (Lo) > A (Hi) then
         Swap (A, Lo, Hi);
         Lemma_Swap_Same (A, A_In, Lo, Hi, Lo, Hi);
         Lemma_Swap (A_In, A, Lo, Hi);
      end if;
      pragma Assert (Same_Occ (A, A_In));
      pragma Assert (Same_Counts (A, A_In, Lo, Hi));

      L := Hi - Lo + 1;
      if L <= 2 then
         return;
      end if;

      T := L / 3;
      pragma Assert (T >= 1);
      pragma Assert (Lo + 3 * T <= Hi + 1);

      declare
         A0 : constant Element_Array := A with Ghost;
      begin
         Stooge_Range (A, Lo, Hi - T);
         declare
            A1 : constant Element_Array := A with Ghost;
         begin
            pragma Assert (Same_Occ (A1, A_In));
            Stooge_Range (A, Lo + T, Hi);
            declare
               A2 : constant Element_Array := A with Ghost;
            begin
               pragma Assert (Same_Occ (A2, A_In));
               Lemma_After_Second (A1, A2, Lo, Hi, T);
               pragma Assert
                 (for all P in Lo .. Hi - T => A2 (P) <= A2 (Hi - T + 1));

               Stooge_Range (A, Lo, Hi - T);

               Lemma_After_Third (A2, A, Lo, Hi - T, Hi);
               pragma Assert (Sorted_Pw (A, Hi - T + 1, Hi));
               pragma Assert
                 (for all I in Lo .. Hi - T =>
                    (for all Q in Hi - T + 1 .. Hi => A (I) <= A (Q)));
               pragma Assert (Sorted_Pw (A, Lo, Hi));

               Lemma_Chain (A_In, A0, A1, A2, A, Lo, Hi, T);
               pragma Assert (Same_Occ (A, A_In));
            end;
         end;
      end;
   end Stooge_Range;

   procedure Sort (A : in out Element_Array) is
      A_In : constant Element_Array := A with Ghost;
   begin
      if A'Length <= 1 then
         return;
      end if;

      Stooge_Range (A, A'First, A'Last);
      Lemma_Same_Perm (A, A_In);
   end Sort;

end Stooge_Sort;
