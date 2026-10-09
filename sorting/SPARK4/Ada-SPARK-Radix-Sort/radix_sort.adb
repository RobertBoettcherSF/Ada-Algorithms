pragma Assertion_Policy (Ignore);

--  Radix_Sort body — SPARK Level 4 LSD radix sort, fixed Base = 256.
--  One counting-sort digit pass: digit = (key / 1) mod Base = key when
--  Max_Key = Base - 1. Histogram + reconstruction emit; ghost Occ /
--  Sum_Occ / Sum_Hist lemmas (binary-split induction) as in
--  Ada-SPARK-Counting-Sort. File-level Assertion_Policy (Ignore) keeps
--  gnatmake -gnata tests fast; GNATprove still discharges Asserts / contracts.

package body Radix_Sort
  with SPARK_Mode => On
is
   --  LSD digit at Exp = 1 equals the key for Key in 0 .. Max_Key.
   function Digit (Key : Element) return Digit_Index
   is (Key)
   with
     Global => null,
     Post   => Digit'Result = Key;

   function Sorted_Slice
     (A : Element_Array; L, R : Natural) return Boolean
   is
     (L >= R
      or else (for all J in L .. R - 1 => A (J) <= A (J + 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= A'First
       and then R <= A'Last;

   --  Occurrences of K in A (A'First .. Last): the spec's Occ with the
   --  arguments in the order this body's lemmas use.
   function Occ_P
     (A : Element_Array; Last : Natural; K : Element) return Natural
   is
     (Occ (A, K, Last))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A) and then Last >= A'First - 1 and then Last <= A'Last,
     Post   => Occ_P'Result <= Last - A'First + 1;

   --  B agrees with A on A'First .. Last.
   procedure Lemma_Occ_P_Frame (A, B : Element_Array; Last : Natural)
   with
     Ghost              => True,
     Global             => null,
     Pre                =>
       In_Bounds (A) and then In_Bounds (B)
       and then A'First = B'First
       and then Last >= A'First - 1
       and then Last <= A'Last and then Last <= B'Last
       and then (for all J in A'First .. Last => A (J) = B (J)),
     Post               =>
       (for all K in Element => Occ_P (A, Last, K) = Occ_P (B, Last, K)),
     Subprogram_Variant => (Decreases => Last)
   is
   begin
      if Last >= A'First then
         Lemma_Occ_P_Frame (A, B, Last - 1);
         pragma Assert
           (for all K in Element =>
              Occ_P (A, Last - 1, K) = Occ_P (B, Last - 1, K));
         pragma Assert
           (for all K in Element =>
              Occ (A, K, Last - 1) = Occ (B, K, Last - 1));
         pragma Assert (A (Last) = B (Last));
         pragma Assert
           (for all K in Element =>
              Occ (A, K, Last)
              = Occ (A, K, Last - 1) + (if A (Last) = K then 1 else 0));
         pragma Assert
           (for all K in Element =>
              Occ (B, K, Last)
              = Occ (B, K, Last - 1) + (if B (Last) = K then 1 else 0));
         pragma Assert
           (for all K in Element => Occ (A, K, Last) = Occ (B, K, Last));
      else
         pragma Assert
           (for all K in Element => Occ (A, K, Last) = 0);
         pragma Assert
           (for all K in Element => Occ (B, K, Last) = 0);
      end if;
      pragma Assert
        (for all K in Element => Occ_P (A, Last, K) = Occ_P (B, Last, K));
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
       and then Last >= A'First - 1
       and then Last <= A'Last
       and then Lo >= 0
       and then Hi <= Max_Key,
     Post               =>
       Sum_Occ'Result
         <= (Last - A'First + 1) * (if Hi >= Lo then Hi - Lo + 1 else 0),
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
         and then Last >= A'First - 1
         and then Last <= A'Last
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
         and then Last in A'Range
         and then Lo >= 0
         and then Hi <= Max_Key,
       Post              =>
         Sum_Occ (A, Last, Lo, Hi)
         = Sum_Occ (A, Last - 1, Lo, Hi)
           + (if Lo <= A (Last) and then A (Last) <= Hi
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
         if A (Last) = Lo then
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
       Pre               =>
         In_Bounds (A) and then Last >= A'First - 1 and then Last <= A'Last,
       Post              => Sum_Occ (A, Last, 0, Max_Key) = Last - A'First + 1,
       Subprogram_Variant => (Decreases => Last)
   is
   begin
      if Last < A'First then
         return;
      end if;
      Lemma_Sum_Occ_Is_Length (A, Last - 1);
      Lemma_Sum_Occ_Step (A, Last, 0, Max_Key);
      pragma Assert
        (Sum_Occ (A, Last - 1, 0, Max_Key) = Last - A'First);
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
         and then N = A'Last
         and then N >= A'First
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
         and then N = A'Last
         and then N >= A'First
         and then (for all K in Element => Hist (K) = Occ_P (A, N, K))
         and then (for all K in Element => Hist (K) <= Max_N),
       Post              => Sum_Hist (Hist, 0, Max_Key) = A'Length
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

      N := A'Last;   --  index of the last slot

      for I in A'Range loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all K in Element => Hist (K) = Occ_P (A, I - 1, K));
         pragma Loop_Invariant
           (for all K in Element => Hist (K) <= I - A'First);
         pragma Loop_Invariant
           (for all K in Element => Hist (K) <= Max_N);

         Hist (Digit (A (I))) := Hist (Digit (A (I))) + 1;
      end loop;

      pragma Assert (for all K in Element => Hist (K) = Occ_P (A, N, K));
      pragma Assert (for all K in Element => Hist (K) <= A'Length);

      pragma Assert
        (for all K in Element => Hist (K) = Occ_P (A0, N, K));
      Lemma_Hist_Sum_Is_N (A, N, Hist);
      pragma Assert (Sum_Hist (Hist, 0, Max_Key) = A'Length);

      Pos := A'First;
      pragma Assert (Sorted_Slice (A, A'First, A'First - 1));

      for K in Digit_Index loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Pos in A'First .. N + 1);
         pragma Loop_Invariant
           (Pos = A'First + Sum_Hist (Hist, 0, K - 1));
         pragma Loop_Invariant
           (Pos + Sum_Hist (Hist, K, Max_Key) = N + 1);
         pragma Loop_Invariant (Sorted_Slice (A, A'First, Pos - 1));
         pragma Loop_Invariant
           (for all J in A'First .. Pos - 1 => A (J) <= K);
         pragma Loop_Invariant (Pos = A'First or else A (Pos - 1) <= K);
         pragma Loop_Invariant
           (for all KK in Element => Hist (KK) <= A'Length);
         pragma Loop_Invariant (Sum_Hist (Hist, 0, Max_Key) = A'Length);
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
               pragma Loop_Invariant (C in 0 .. Hist (K));
               pragma Loop_Invariant (Pos = Pos0 + C);
               pragma Loop_Invariant
                 (Pos0 + Hist (K) + Sum_Hist (Hist, K + 1, Max_Key)
                  = N + 1);
               pragma Loop_Invariant (Pos in A'First .. N);
               pragma Loop_Invariant
                 (Pos + (Hist (K) - C) <= N + 1);
               pragma Loop_Invariant (Sorted_Slice (A, A'First, Pos - 1));
               pragma Loop_Invariant
                 (for all J in A'First .. Pos - 1 => A (J) <= K);
               pragma Loop_Invariant
                 (Pos = A'First or else A (Pos - 1) <= K);
               pragma Loop_Invariant
                 (for all J in Pos0 .. Pos - 1 => A (J) = K);
               pragma Loop_Invariant
                 (for all KK in Element =>
                    Occ_P (A, Pos - 1, KK)
                    = (if KK < K then Hist (KK) elsif KK = K then C else 0));
               pragma Loop_Variant (Decreases => Hist (K) - C);

               declare
                  Before : constant Element_Array := A with Ghost;
               begin
                  A (Pos) := K;
                  Lemma_Occ_P_Frame (Before, A, Pos - 1);
               end;
               pragma Assert (Pos = A'First or else A (Pos - 1) <= A (Pos));
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
         pragma Assert (Pos = A'First + Sum_Hist (Hist, 0, K));
         pragma Assert (Sorted_Slice (A, A'First, Pos - 1));
      end loop;

      pragma Assert (Pos = N + 1);
      pragma Assert (Sorted_Slice (A, A'First, N));
      pragma Assert (Is_Sorted (A));
      pragma Assert
        (for all KK in Element => Occ_P (A, N, KK) = Occ_P (A0, N, KK));
      pragma Assert (Is_Perm (A, A0));
   end Sort;

end Radix_Sort;
