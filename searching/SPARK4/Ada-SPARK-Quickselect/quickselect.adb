--  Quickselect body — SPARK Level 4 iterative in-place Quickselect.
--  Median-of-three parks a middle-ish pivot at Hi; Lomuto partition lands
--  it in a final slot P. The outer loop shrinks Lo .. Hi toward Target and
--  is bounded by Max_N. Ghost Prefix_Leq_Window / Suffix_Geq_Window plus
--  the Lomuto split reassemble into Is_Kth_Partitioned.

package body Quickselect
  with SPARK_Mode => On
is

   --  One past the live range (Lomuto write cursor after a full left fill).
   subtype Cursor is Natural range 0 .. Max_N + 1;

   --  Every A (L .. R) is <= V. Vacuous when L > R.
   function All_Leq
     (A    : Element_Array;
      L, R : Natural;
      V    : Integer) return Boolean
   is
     (L > R or else (for all K in L .. R => A (K) <= V))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= 1
       and then R <= A'Last;

   --  Every A (L .. R) is >= V. Vacuous when L > R.
   function All_Geq
     (A    : Element_Array;
      L, R : Natural;
      V    : Integer) return Boolean
   is
     (L > R or else (for all K in L .. R => A (K) >= V))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= 1
       and then R <= A'Last;

   --  Every element left of the window is <= every element in the window.
   function Prefix_Leq_Window
     (A : Element_Array; Lo, Hi : Natural) return Boolean
   is
     (Lo <= 1
      or else
        (for all I in 1 .. Lo - 1 =>
           (for all J in Lo .. Hi => A (I) <= A (J))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Lo >= 1
       and then Hi in Lo - 1 .. A'Last
       and then Hi <= A'Last;

   --  Every element right of the window is >= every element in the window.
   function Suffix_Geq_Window
     (A : Element_Array; Lo, Hi : Natural) return Boolean
   is
     (Hi >= A'Last
      or else
        (for all I in Hi + 1 .. A'Last =>
           (for all J in Lo .. Hi => A (I) >= A (J))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Lo >= 1
       and then Hi in Lo - 1 .. A'Last
       and then Hi <= A'Last;

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

   --  Order A(Lo), A(Mid), A(Hi) and move the median to Hi (Lomuto pivot).
   --  Preserves Prefix_Leq_Window / Suffix_Geq_Window on Lo .. Hi.
   procedure Median_Of_Three
     (A      : in out Element_Array;
      Lo, Hi : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Last >= 2
         and then Lo in 1 .. A'Last
         and then Hi in Lo + 2 .. A'Last
         and then Prefix_Leq_Window (A, Lo, Hi)
         and then Suffix_Geq_Window (A, Lo, Hi),
       Post   =>
         In_Bounds (A)
         and then Prefix_Leq_Window (A, Lo, Hi)
         and then Suffix_Geq_Window (A, Lo, Hi)
         and then
           (for all K in 1 .. Lo - 1 => A (K) = A'Old (K))
         and then
           (for all K in Hi + 1 .. A'Last => A (K) = A'Old (K))
   is
      Mid : constant Index := Lo + (Hi - Lo) / 2;
   begin
      pragma Assert (Mid in Lo .. Hi);
      pragma Assert (Mid /= Lo or else Mid /= Hi);
      pragma Assert (Mid >= Lo and then Mid <= Hi);

      if A (Mid) < A (Lo) then
         Swap (A, Lo, Mid);
      end if;
      pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
      pragma Assert (Suffix_Geq_Window (A, Lo, Hi));

      if A (Hi) < A (Lo) then
         Swap (A, Lo, Hi);
      end if;
      pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
      pragma Assert (Suffix_Geq_Window (A, Lo, Hi));

      if A (Hi) < A (Mid) then
         Swap (A, Mid, Hi);
      end if;
      pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
      pragma Assert (Suffix_Geq_Window (A, Lo, Hi));

      --  A(Lo) <= A(Mid) <= A(Hi); median sits at Mid. Park it at Hi.
      Swap (A, Mid, Hi);
      pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
      pragma Assert (Suffix_Geq_Window (A, Lo, Hi));
   end Median_Of_Three;

   --  Lomuto partition of A (Lo .. Hi). Pivot is A(Hi) on entry.
   --  Returns P such that A(Lo .. P-1) <= A(P) and A(P+1 .. Hi) > A(P).
   --  Preserves Prefix / Suffix window predicates on Lo .. Hi.
   procedure Partition
     (A      : in out Element_Array;
      Lo, Hi : Index;
      P      : out Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Last >= 2
         and then Lo in 1 .. A'Last
         and then Hi in Lo + 1 .. A'Last
         and then Prefix_Leq_Window (A, Lo, Hi)
         and then Suffix_Geq_Window (A, Lo, Hi),
       Post   =>
         In_Bounds (A)
         and then P in Lo .. Hi
         and then All_Leq (A, Lo, P - 1, A (P))
         and then All_Geq (A, P + 1, Hi, A (P))
         and then Prefix_Leq_Window (A, Lo, Hi)
         and then Suffix_Geq_Window (A, Lo, Hi)
         and then
           (for all K in 1 .. Lo - 1 => A (K) = A'Old (K))
         and then
           (for all K in Hi + 1 .. A'Last => A (K) = A'Old (K))
   is
      Pivot : Integer;
      I     : Cursor;
   begin
      if Hi - Lo >= 2 then
         Median_Of_Three (A, Lo, Hi);
      end if;

      Pivot := A (Hi);
      I     := Cursor (Lo);

      pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
      pragma Assert (Suffix_Geq_Window (A, Lo, Hi));
      pragma Assert (All_Leq (A, Lo, Lo - 1, Pivot));

      for J in Lo .. Hi - 1 loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (I in Lo .. J);
         pragma Loop_Invariant (A (Hi) = Pivot);
         pragma Loop_Invariant (All_Leq (A, Lo, I - 1, Pivot));
         pragma Loop_Invariant
           (for all K in I .. J - 1 => A (K) > Pivot);
         pragma Loop_Invariant (Prefix_Leq_Window (A, Lo, Hi));
         pragma Loop_Invariant (Suffix_Geq_Window (A, Lo, Hi));
         pragma Loop_Invariant
           (for all K in 1 .. Lo - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in Hi + 1 .. A'Last => A (K) = A'Loop_Entry (K));

         if A (J) <= Pivot then
            pragma Assert (I in 1 .. A'Last);
            pragma Assert (J in 1 .. A'Last);
            Swap (A, Index (I), J);
            I := I + 1;
         end if;

         pragma Assert (I in Lo .. J + 1);
         pragma Assert (All_Leq (A, Lo, I - 1, Pivot));
         pragma Assert (for all K in I .. J => A (K) > Pivot);
         pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
         pragma Assert (Suffix_Geq_Window (A, Lo, Hi));
      end loop;

      pragma Assert (I in Lo .. Hi);
      pragma Assert (A (Hi) = Pivot);
      pragma Assert (All_Leq (A, Lo, I - 1, Pivot));
      pragma Assert (for all K in I .. Hi - 1 => A (K) > Pivot);
      pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
      pragma Assert (Suffix_Geq_Window (A, Lo, Hi));

      Swap (A, Index (I), Hi);

      P := Index (I);

      pragma Assert (P in Lo .. Hi);
      pragma Assert (A (P) = Pivot);
      pragma Assert (All_Leq (A, Lo, P - 1, A (P)));
      pragma Assert (for all K in P + 1 .. Hi => A (K) > Pivot);
      pragma Assert (All_Geq (A, P + 1, Hi, A (P)));
      pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
      pragma Assert (Suffix_Geq_Window (A, Lo, Hi));
   end Partition;

   --  From window invariants + Lomuto split at Target, conclude Is_Kth.
   procedure Lemma_Kth_At_Pivot
     (A              : Element_Array;
      Lo, P, Hi, K   : Index)
     with
       Ghost             => True,
       Always_Terminates => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then A'Length >= 1
         and then K in 1 .. A'Length
         and then Lo in 1 .. A'Last
         and then Hi in Lo .. A'Last
         and then P = K
         and then P in Lo .. Hi
         and then Prefix_Leq_Window (A, Lo, Hi)
         and then Suffix_Geq_Window (A, Lo, Hi)
         and then All_Leq (A, Lo, P - 1, A (P))
         and then All_Geq (A, P + 1, Hi, A (P)),
       Post              => Is_Kth_Partitioned (A, K)
   is
   begin
      pragma Assert (A'First = 1);
      pragma Assert (P = K);
      --  Left of Target: 1 .. Lo-1 via Prefix, Lo .. P-1 via Lomuto.
      pragma Assert
        (for all I in 1 .. Lo - 1 => A (I) <= A (P));
      pragma Assert
        (for all I in Lo .. P - 1 => A (I) <= A (P));
      pragma Assert
        (for all I in 1 .. P - 1 => A (I) <= A (P));
      --  Right of Target: P+1 .. Hi via Lomuto, Hi+1 .. Last via Suffix.
      pragma Assert
        (for all I in P + 1 .. Hi => A (I) >= A (P));
      pragma Assert
        (for all I in Hi + 1 .. A'Last => A (I) >= A (P));
      pragma Assert
        (for all I in P + 1 .. A'Last => A (I) >= A (P));
      pragma Assert (Is_Kth_Partitioned (A, K));
   end Lemma_Kth_At_Pivot;

   --  Singleton window Lo = Hi = Target ⇒ Is_Kth from Prefix / Suffix.
   procedure Lemma_Kth_Singleton
     (A         : Element_Array;
      Lo, Hi, K : Index)
     with
       Ghost             => True,
       Always_Terminates => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then A'Length >= 1
         and then K in 1 .. A'Length
         and then Lo = Hi
         and then Lo = K
         and then Lo in 1 .. A'Last
         and then Prefix_Leq_Window (A, Lo, Hi)
         and then Suffix_Geq_Window (A, Lo, Hi),
       Post              => Is_Kth_Partitioned (A, K)
   is
   begin
      pragma Assert (A'First = 1);
      pragma Assert (Lo = K and then Hi = K);
      pragma Assert
        (for all I in 1 .. Lo - 1 => A (I) <= A (Lo));
      pragma Assert
        (for all I in Hi + 1 .. A'Last => A (I) >= A (Hi));
      pragma Assert (Is_Kth_Partitioned (A, K));
   end Lemma_Kth_Singleton;

   --  After P > Target: new window Lo .. P-1 still satisfies Prefix / Suffix.
   procedure Lemma_Shrink_Left
     (A                  : Element_Array;
      Lo, P, Hi, Target  : Index)
     with
       Ghost             => True,
       Always_Terminates => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then Lo in 1 .. A'Last
         and then Hi in Lo .. A'Last
         and then P in Lo + 1 .. Hi
         and then Target in Lo .. P - 1
         and then Prefix_Leq_Window (A, Lo, Hi)
         and then Suffix_Geq_Window (A, Lo, Hi)
         and then All_Leq (A, Lo, P - 1, A (P))
         and then All_Geq (A, P + 1, Hi, A (P)),
       Post              =>
         Prefix_Leq_Window (A, Lo, P - 1)
         and then Suffix_Geq_Window (A, Lo, P - 1)
   is
   begin
      --  Prefix on smaller window: left of Lo <= subset of old window.
      pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
      pragma Assert (Prefix_Leq_Window (A, Lo, P - 1));

      --  Suffix: P .. Last must be >= every element of Lo .. P-1.
      --  A(P) >= all of Lo..P-1 (from All_Leq); P+1..Hi >= A(P); Hi+1..Last
      --  >= all of old window (hence >= Lo..P-1).
      pragma Assert (All_Leq (A, Lo, P - 1, A (P)));
      pragma Assert
        (for all J in Lo .. P - 1 => A (P) >= A (J));
      pragma Assert
        (for all I in P + 1 .. Hi =>
           (for all J in Lo .. P - 1 => A (I) >= A (J)));
      pragma Assert
        (for all I in Hi + 1 .. A'Last =>
           (for all J in Lo .. P - 1 => A (I) >= A (J)));
      pragma Assert
        (for all I in P .. A'Last =>
           (for all J in Lo .. P - 1 => A (I) >= A (J)));
      pragma Assert (Suffix_Geq_Window (A, Lo, P - 1));
   end Lemma_Shrink_Left;

   --  After P < Target: new window P+1 .. Hi still satisfies Prefix / Suffix.
   procedure Lemma_Shrink_Right
     (A                  : Element_Array;
      Lo, P, Hi, Target  : Index)
     with
       Ghost             => True,
       Always_Terminates => True,
       Global            => null,
       Pre               =>
         In_Bounds (A)
         and then Lo in 1 .. A'Last
         and then Hi in Lo .. A'Last
         and then P in Lo .. Hi - 1
         and then Target in P + 1 .. Hi
         and then Prefix_Leq_Window (A, Lo, Hi)
         and then Suffix_Geq_Window (A, Lo, Hi)
         and then All_Leq (A, Lo, P - 1, A (P))
         and then All_Geq (A, P + 1, Hi, A (P)),
       Post              =>
         Prefix_Leq_Window (A, P + 1, Hi)
         and then Suffix_Geq_Window (A, P + 1, Hi)
   is
   begin
      pragma Assert (Suffix_Geq_Window (A, Lo, Hi));
      pragma Assert (Suffix_Geq_Window (A, P + 1, Hi));

      --  Prefix: 1 .. P must be <= every element of P+1 .. Hi.
      --  Lo..P-1 <= A(P) (All_Leq); A(P) <= all of P+1..Hi (All_Geq);
      --  1..Lo-1 <= all of old window (hence <= P+1..Hi).
      pragma Assert (All_Geq (A, P + 1, Hi, A (P)));
      pragma Assert
        (for all J in P + 1 .. Hi => A (P) <= A (J));
      pragma Assert
        (for all I in Lo .. P - 1 =>
           (for all J in P + 1 .. Hi => A (I) <= A (J)));
      pragma Assert
        (for all I in 1 .. Lo - 1 =>
           (for all J in P + 1 .. Hi => A (I) <= A (J)));
      pragma Assert
        (for all I in 1 .. P =>
           (for all J in P + 1 .. Hi => A (I) <= A (J)));
      pragma Assert (Prefix_Leq_Window (A, P + 1, Hi));
   end Lemma_Shrink_Right;

   procedure Select_Kth (A : in out Element_Array; K : Positive) is
      Target : constant Index := K;
      Lo     : Index;
      Hi     : Index;
      P      : Index;
   begin
      pragma Assert (A'First = 1);
      pragma Assert (Target in 1 .. A'Last);

      if A'Length = 1 then
         pragma Assert (Target = 1 and then A'Last = 1);
         pragma Assert (Is_Kth_Partitioned (A, K));
         return;
      end if;

      Lo := 1;
      Hi := A'Last;

      pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
      pragma Assert (Suffix_Geq_Window (A, Lo, Hi));
      pragma Assert (Target in Lo .. Hi);
      pragma Assert (Hi - Lo <= Max_N - 1);

      for Step in 1 .. Max_N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (A'Length >= 2);
         pragma Loop_Invariant (Lo in 1 .. A'Last);
         pragma Loop_Invariant (Hi in Lo .. A'Last);
         pragma Loop_Invariant (Target in Lo .. Hi);
         pragma Loop_Invariant (Prefix_Leq_Window (A, Lo, Hi));
         pragma Loop_Invariant (Suffix_Geq_Window (A, Lo, Hi));
         pragma Loop_Invariant (Hi - Lo <= Max_N - Step);

         if Lo = Hi then
            Lemma_Kth_Singleton (A, Lo, Hi, Target);
            pragma Assert (Is_Kth_Partitioned (A, K));
            return;
         end if;

         pragma Assert (Hi >= Lo + 1);
         pragma Assert (A'Last >= 2);

         Partition (A, Lo, Hi, P);

         pragma Assert (P in Lo .. Hi);
         pragma Assert (All_Leq (A, Lo, P - 1, A (P)));
         pragma Assert (All_Geq (A, P + 1, Hi, A (P)));
         pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
         pragma Assert (Suffix_Geq_Window (A, Lo, Hi));
         pragma Assert (Target in Lo .. Hi);

         if P = Target then
            Lemma_Kth_At_Pivot (A, Lo, P, Hi, Target);
            pragma Assert (Is_Kth_Partitioned (A, K));
            return;
         elsif P > Target then
            pragma Assert (P >= Target + 1);
            pragma Assert (P >= Lo + 1);
            pragma Assert (Target in Lo .. P - 1);
            Lemma_Shrink_Left (A, Lo, P, Hi, Target);
            Hi := P - 1;
            pragma Assert (Hi >= Lo);
            pragma Assert (Target in Lo .. Hi);
            pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
            pragma Assert (Suffix_Geq_Window (A, Lo, Hi));
            pragma Assert (Hi - Lo < Max_N - Step + 1);
         else
            pragma Assert (P < Target);
            pragma Assert (P <= Hi - 1);
            pragma Assert (Target in P + 1 .. Hi);
            Lemma_Shrink_Right (A, Lo, P, Hi, Target);
            Lo := P + 1;
            pragma Assert (Lo <= Hi);
            pragma Assert (Target in Lo .. Hi);
            pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
            pragma Assert (Suffix_Geq_Window (A, Lo, Hi));
         end if;

         pragma Assert (Hi - Lo <= Max_N - Step - 1);
      end loop;

      --  Measure Hi - Lo <= Max_N - Step forces Lo = Hi by Step = Max_N;
      --  the loop body would have returned. Help the postcondition.
      pragma Assert (Lo = Hi);
      Lemma_Kth_Singleton (A, Lo, Hi, Target);
      pragma Assert (Is_Kth_Partitioned (A, K));
   end Select_Kth;

   function Select_Kth_Copy (A : Element_Array; K : Positive) return Integer is
      Copy : Element_Array := A;
   begin
      Select_Kth (Copy, K);
      return Copy (K);
   end Select_Kth_Copy;

   function Median (A : Element_Array) return Integer is
      N : constant Positive := A'Length;
      K : Positive;
   begin
      if N rem 2 = 1 then
         K := (N + 1) / 2;
      else
         K := N / 2;
      end if;
      return Select_Kth_Copy (A, K);
   end Median;

end Quickselect;
