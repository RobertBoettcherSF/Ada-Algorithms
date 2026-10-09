--  Counting_Sort body — SPARK Level 4 classic counting sort.
--  Histogram over 0 .. Max_Key, then emit each key Hist (K) times
--  left-to-right (reconstruction / CDF expansion). When Element is the
--  key, equal keys are identical so content-level stability is vacuous;
--  tests check permutation and agreement with a stable reference.
--  Ghost Occ / Sum_Occ / Sum_Hist lemmas (binary-split induction) show
--  sum(Hist) = N so the emit cursor fills A'Range; sortedness grows
--  with the outer key loop.

package body Counting_Sort
  with SPARK_Mode => On
is

   --  The body's own Asserts, Loop_Invariants and ghost Pre/Posts are
   --  proved by gnatprove; at run time they would recount the whole key
   --  range per write, so only the spec Post of Sort (Is_Sorted and
   --  Is_Perm) is checked there.
   pragma Assertion_Policy
     (Loop_Invariant => Ignore, Assert => Ignore,
      Pre => Ignore, Post => Ignore);

   --  Any origin: the internals count positions 1 .. A'Length, and
   --  position K is A (A'First + (K - 1)).

   function Sorted_Slice
     (A : Element_Array; L, R : Natural) return Boolean
   is
     (L >= R
      or else (for all J in L .. R - 1 => A (A'First + (J - 1)) <= A (A'First + (J + 1 - 1))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= 1
       and then R <= A'Length;

   --  Occurrences of K among positions 1 .. Last, i.e. the spec's Occ
   --  over A (A'First .. A'First + (Last - 1)).
   function Occ_P
     (A : Element_Array; Last : Natural; K : Element) return Natural
   is
     (if Last = 0 then 0 else Occ (A, K, A'First + (Last - 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    => In_Bounds (A) and then Last <= A'Length,
     Post   => Occ_P'Result <= Last;

   --  B agrees with A on positions 1 .. Last.
   procedure Lemma_Occ_P_Frame (A, B : Element_Array; Last : Natural)
   with
     Ghost              => True,
     Global             => null,
     Pre                =>
       In_Bounds (A) and then In_Bounds (B)
       and then A'First = B'First
       and then Last <= A'Length and then Last <= B'Length
       and then (for all J in 1 .. Last =>
                   A (A'First + (J - 1)) = B (B'First + (J - 1))),
     Post               =>
       (for all K in Element => Occ_P (A, Last, K) = Occ_P (B, Last, K)),
     Subprogram_Variant => (Decreases => Last)
   is
   begin
      if Last > 0 then
         Lemma_Occ_P_Frame (A, B, Last - 1);
      end if;
   end Lemma_Occ_P_Frame;

   function Sum_Occ
     (A : Element_Array; Last : Natural; Lo, Hi : Integer) return Natural
   is
     (if Lo > Hi then 0
      else Occ_P (A, Last, Lo) + Sum_Occ (A, Last, Lo + 1, Hi))
   with
     Ghost              => True,
     Global             => null,
     Pre                =>
       In_Bounds (A)
       and then Last <= A'Length
       and then Lo >= 0
       and then Hi <= Max_Key,
     Post               =>
       Sum_Occ'Result <= Last * (if Hi >= Lo then Hi - Lo + 1 else 0),
     Subprogram_Variant =>
       (Decreases => (if Lo > Hi then 0 else Hi - Lo + 1));

   function Sum_Hist
     (Hist : Count_Array; Lo, Hi : Integer) return Natural
   is
     (if Lo > Hi then 0
      else Hist (Lo) + Sum_Hist (Hist, Lo + 1, Hi))
   with
     Ghost              => True,
     Global             => null,
     Pre                =>
       Lo >= 0
       and then Hi <= Max_Key
       and then (for all K in Element => Hist (K) <= Max_N),
     Post               =>
       Sum_Hist'Result
         <= Max_N * (if Hi >= Lo then Hi - Lo + 1 else 0),
     Subprogram_Variant =>
       (Decreases => (if Lo > Hi then 0 else Hi - Lo + 1));


   procedure Lemma_Sum_Occ_Split
     (A : Element_Array; Last : Natural; Lo, Mid, Hi : Integer)
     with
       Ghost             => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then Last <= A'Length
         and then Lo >= 0
         and then Hi <= Max_Key
         and then Mid >= Lo - 1
         and then Mid <= Hi,
       Post              =>
         Sum_Occ (A, Last, Lo, Hi)
         = Sum_Occ (A, Last, Lo, Mid)
           + Sum_Occ (A, Last, Mid + 1, Hi),
       Subprogram_Variant =>
         (Decreases => (if Lo > Mid then 0 else Mid - Lo + 1))
   is
   begin
      if Lo > Mid then
         pragma Assert (Sum_Occ (A, Last, Lo, Mid) = 0);
      elsif Lo = Mid then
         null;
      else
         Lemma_Sum_Occ_Split (A, Last, Lo + 1, Mid, Hi);
      end if;
   end Lemma_Sum_Occ_Split;

   procedure Lemma_Sum_Occ_Step
     (A : Element_Array; Last : Natural; Lo, Hi : Integer)
     with
       Ghost             => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then Last in 1 .. A'Length
         and then Lo >= 0
         and then Hi <= Max_Key,
       Post              =>
         Sum_Occ (A, Last, Lo, Hi)
         = Sum_Occ (A, Last - 1, Lo, Hi)
           + (if Lo <= A (A'First + (Last - 1)) and then A (A'First + (Last - 1)) <= Hi
              then 1
              else 0),
       Subprogram_Variant =>
         (Decreases => (if Lo > Hi then 0 else Hi - Lo + 1))
   is
      Mid : Integer;
   begin
      if Lo > Hi then
         null;
      elsif Lo = Hi then
         if A (A'First + (Last - 1)) = Lo then
            pragma Assert
              (Occ_P (A, Last, Lo) = Occ_P (A, Last - 1, Lo) + 1);
         else
            pragma Assert
              (Occ_P (A, Last, Lo) = Occ_P (A, Last - 1, Lo));
         end if;
      else
         Mid := Lo + (Hi - Lo) / 2;
         pragma Assert (Mid >= Lo and then Mid < Hi);
         Lemma_Sum_Occ_Step (A, Last, Lo, Mid);
         Lemma_Sum_Occ_Step (A, Last, Mid + 1, Hi);
         Lemma_Sum_Occ_Split (A, Last, Lo, Mid, Hi);
         Lemma_Sum_Occ_Split (A, Last - 1, Lo, Mid, Hi);
      end if;
   end Lemma_Sum_Occ_Step;

   procedure Lemma_Sum_Occ_Is_Length
     (A : Element_Array; Last : Natural)
     with
       Ghost             => True,
       Global            => null,
       Pre               => In_Bounds (A) and then Last <= A'Length,
       Post              => Sum_Occ (A, Last, 0, Max_Key) = Last,
       Subprogram_Variant => (Decreases => Last)
   is
   begin
      if Last = 0 then
         return;
      end if;
      Lemma_Sum_Occ_Is_Length (A, Last - 1);
      Lemma_Sum_Occ_Step (A, Last, 0, Max_Key);
      pragma Assert (Sum_Occ (A, Last - 1, 0, Max_Key) = Last - 1);
      pragma Assert
        (Sum_Occ (A, Last, 0, Max_Key)
         = Sum_Occ (A, Last - 1, 0, Max_Key) + 1);
   end Lemma_Sum_Occ_Is_Length;


   procedure Lemma_Sum_Hist_Split
     (Hist : Count_Array; Lo, Mid, Hi : Integer)
     with
       Ghost             => True,
       Global            => null,
       Pre               =>
         Lo >= 0
         and then Hi <= Max_Key
         and then Mid >= Lo - 1
         and then Mid <= Hi
         and then (for all K in Element => Hist (K) <= Max_N),
       Post              =>
         Sum_Hist (Hist, Lo, Hi)
         = Sum_Hist (Hist, Lo, Mid) + Sum_Hist (Hist, Mid + 1, Hi),
       Subprogram_Variant =>
         (Decreases => (if Lo > Mid then 0 else Mid - Lo + 1))
   is
   begin
      if Lo > Mid then
         pragma Assert (Sum_Hist (Hist, Lo, Mid) = 0);
      elsif Lo = Mid then
         null;
      else
         Lemma_Sum_Hist_Split (Hist, Lo + 1, Mid, Hi);
      end if;
   end Lemma_Sum_Hist_Split;

   procedure Lemma_Sum_Hist_Eq_Occ
     (A        : Element_Array;
      N        : Index;
      Hist     : Count_Array;
      Lo, Hi   : Integer)
     with
       Ghost             => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then N = A'Length
         and then N >= 1
         and then Lo >= 0
         and then Hi <= Max_Key
         and then (for all K in Element => Hist (K) = Occ_P (A, N, K))
         and then (for all K in Element => Hist (K) <= Max_N),
       Post              =>
         Sum_Hist (Hist, Lo, Hi) = Sum_Occ (A, N, Lo, Hi),
       Subprogram_Variant =>
         (Decreases => (if Lo > Hi then 0 else Hi - Lo + 1))
   is
      Mid : Integer;
   begin
      if Lo > Hi then
         null;
      elsif Lo = Hi then
         pragma Assert (Hist (Lo) = Occ_P (A, N, Lo));
      else
         Mid := Lo + (Hi - Lo) / 2;
         pragma Assert (Mid >= Lo and then Mid < Hi);
         Lemma_Sum_Hist_Eq_Occ (A, N, Hist, Lo, Mid);
         Lemma_Sum_Hist_Eq_Occ (A, N, Hist, Mid + 1, Hi);
         Lemma_Sum_Occ_Split (A, N, Lo, Mid, Hi);
         Lemma_Sum_Hist_Split (Hist, Lo, Mid, Hi);
      end if;
   end Lemma_Sum_Hist_Eq_Occ;

   procedure Lemma_Hist_Sum_Is_N
     (A : Element_Array; N : Index; Hist : Count_Array)
     with
       Ghost             => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then N = A'Length
         and then N >= 1
         and then (for all K in Element => Hist (K) = Occ_P (A, N, K))
         and then (for all K in Element => Hist (K) <= Max_N),
       Post              => Sum_Hist (Hist, 0, Max_Key) = N
   is
   begin
      Lemma_Sum_Occ_Is_Length (A, N);
      Lemma_Sum_Hist_Eq_Occ (A, N, Hist, 0, Max_Key);
   end Lemma_Hist_Sum_Is_N;

   procedure Sort (A : in out Element_Array) is
      subtype Cursor is Natural range 0 .. Max_N + 1;

      Hist : Count_Array := [others => 0];
      Pos  : Cursor;
      N    : Index;
      A0   : constant Element_Array := A with Ghost;
   begin
      if A'Length <= 1 then
         return;
      end if;

      N := A'Length;

      for I in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all K in Element => Hist (K) = Occ_P (A, I - 1, K));
         pragma Loop_Invariant
           (for all K in Element => Hist (K) <= I - 1);
         pragma Loop_Invariant
           (for all K in Element => Hist (K) <= Max_N);

         Hist (A (A'First + (I - 1))) := Hist (A (A'First + (I - 1))) + 1;
      end loop;

      pragma Assert (for all K in Element => Hist (K) = Occ_P (A, N, K));
      pragma Assert (for all K in Element => Hist (K) <= N);

      pragma Assert
        (for all K in Element => Hist (K) = Occ_P (A0, N, K));
      Lemma_Hist_Sum_Is_N (A, N, Hist);
      pragma Assert (Sum_Hist (Hist, 0, Max_Key) = N);

      Pos := 1;
      pragma Assert (Sorted_Slice (A, 1, 0));

      for K in Element loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Pos in 1 .. N + 1);
         pragma Loop_Invariant
           (Pos = 1 + Sum_Hist (Hist, 0, K - 1));
         pragma Loop_Invariant
           (Pos + Sum_Hist (Hist, K, Max_Key) = N + 1);
         pragma Loop_Invariant (Sorted_Slice (A, 1, Pos - 1));
         pragma Loop_Invariant
           (for all J in 1 .. Pos - 1 => A (A'First + (J - 1)) <= K);
         pragma Loop_Invariant (Pos = 1 or else A (A'First + (Pos - 1 - 1)) <= K);
         pragma Loop_Invariant
           (for all KK in Element => Hist (KK) <= N);
         pragma Loop_Invariant (Sum_Hist (Hist, 0, Max_Key) = N);
         pragma Loop_Invariant
           (for all KK in Element => Hist (KK) = Occ_P (A0, N, KK));
         pragma Loop_Invariant
           (for all KK in Element =>
              Occ_P (A, Pos - 1, KK) = (if KK < K then Hist (KK) else 0));

         declare
            C    : Natural := 0;
            Pos0 : constant Cursor := Pos;
         begin
            pragma Assert
              (Pos0 + Hist (K) + Sum_Hist (Hist, K + 1, Max_Key)
               = N + 1);

            while C < Hist (K) loop
               pragma Loop_Invariant (C <= Hist (K));   --  C >= 0: Natural
               pragma Loop_Invariant (Pos = Pos0 + C);
               pragma Loop_Invariant
                 (Pos0 + Hist (K) + Sum_Hist (Hist, K + 1, Max_Key)
                  = N + 1);
               pragma Loop_Invariant (Pos in 1 .. N);
               pragma Loop_Invariant
                 (Pos + (Hist (K) - C) <= N + 1);
               pragma Loop_Invariant (Sorted_Slice (A, 1, Pos - 1));
               pragma Loop_Invariant
                 (for all J in 1 .. Pos - 1 => A (A'First + (J - 1)) <= K);
               pragma Loop_Invariant
                 (Pos = 1 or else A (A'First + (Pos - 1 - 1)) <= K);
               pragma Loop_Invariant
                 (for all J in Pos0 .. Pos - 1 => A (A'First + (J - 1)) = K);
               pragma Loop_Invariant
                 (for all KK in Element =>
                    Occ_P (A, Pos - 1, KK)
                    = (if KK < K then Hist (KK) elsif KK = K then C else 0));
               pragma Loop_Variant (Decreases => Hist (K) - C);

               declare
                  Before : constant Element_Array := A with Ghost;
               begin
                  A (A'First + (Pos - 1)) := K;
                  Lemma_Occ_P_Frame (Before, A, Pos - 1);
               end;
               pragma Assert (Pos = 1 or else A (A'First + (Pos - 1 - 1)) <= A (A'First + (Pos - 1)));
               pragma Assert
                 (for all KK in Element =>
                    Occ_P (A, Pos, KK)
                    = Occ_P (A, Pos - 1, KK) + (if KK = K then 1 else 0));
               Pos := Pos + 1;
               C   := C + 1;
            end loop;

            pragma Assert (Pos = Pos0 + Hist (K));
         end;

         Lemma_Sum_Hist_Split (Hist, 0, K - 1, K);
         pragma Assert
           (Sum_Hist (Hist, 0, K)
            = Sum_Hist (Hist, 0, K - 1) + Hist (K));
         pragma Assert (Pos = 1 + Sum_Hist (Hist, 0, K));
         pragma Assert (Sorted_Slice (A, 1, Pos - 1));
      end loop;

      pragma Assert (Pos = N + 1);
      pragma Assert (Sorted_Slice (A, 1, N));
      pragma Assert
        (for all J in 1 .. N - 1 =>
           A (A'First + (J - 1)) <= A (A'First + J));
      pragma Assert (A'First + (N - 1) = A'Last);
      pragma Assert
        (for all I in A'First .. A'Last - 1 =>
           A (A'First + ((I - A'First + 1) - 1))
           <= A (A'First + (I - A'First + 1)));
      pragma Assert
        (for all I in A'Range =>
           (if I < A'Last then A (I) <= A (I + 1)));
      pragma Assert (Is_Sorted (A));
      pragma Assert
        (for all KK in Element => Occ_P (A, N, KK) = Occ_P (A0, N, KK));
      pragma Assert (N > 0);
      pragma Assert (A0'First = A'First and then A0'Last = A'Last);
      pragma Assert
        (for all KK in Element => Occ_P (A, N, KK) = Occ (A, KK, A'Last));
      pragma Assert
        (for all KK in Element => Occ_P (A0, N, KK) = Occ (A0, KK, A0'Last));
      pragma Assert
        (for all KK in Element =>
           Occ (A, KK, A'Last) = Occ (A0, KK, A0'Last));
      pragma Assert
        (for all I in A'Range =>
           Occ (A, A (I), A'Last) = Occ (A0, A (I), A0'Last));
      pragma Assert
        (for all I in A0'Range =>
           Occ (A, A0 (I), A'Last) = Occ (A0, A0 (I), A0'Last));
      pragma Assert (Is_Perm (A, A0));
   end Sort;

end Counting_Sort;
