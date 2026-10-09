--  Quickselect body — SPARK Level 4 iterative in-place Quickselect.
--  Median-of-three parks a middle-ish pivot at Hi; Lomuto partition lands
--  it in a final slot P. The outer loop shrinks Lo .. Hi toward Target and
--  terminates by Loop_Variant (Hi - Lo decreases). Ghost Prefix_Leq_Window
--  / Suffix_Geq_Window plus the Lomuto split reassemble into
--  Is_Kth_Partitioned.

package body Quickselect
  with SPARK_Mode => On
is

   --  Any origin: the internals count positions 1 .. A'Length, and
   --  position K is A (A'First + (K - 1)).

   --  One past the live range (Lomuto write cursor after a full left fill).
   subtype Cursor is Natural range 0 .. Max_N + 1;

   --  Every A (L .. R) is <= V. Vacuous when L > R.
   function All_Leq
     (A    : Element_Array;
      L, R : Natural;
      V    : Integer) return Boolean
   is
     (L > R or else (for all K in L .. R => A (A'First + (K - 1)) <= V))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= 1
       and then R <= A'Length;

   --  Every A (L .. R) is >= V. Vacuous when L > R.
   function All_Geq
     (A    : Element_Array;
      L, R : Natural;
      V    : Integer) return Boolean
   is
     (L > R or else (for all K in L .. R => A (A'First + (K - 1)) >= V))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= 1
       and then R <= A'Length;

   --  Every element left of the window is <= every element in the window.
   function Prefix_Leq_Window
     (A : Element_Array; Lo, Hi : Natural) return Boolean
   is
     (Lo <= 1
      or else
        (for all I in 1 .. Lo - 1 =>
           (for all J in Lo .. Hi => A (A'First + (I - 1)) <= A (A'First + (J - 1)))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Lo >= 1
       and then Hi in Lo - 1 .. A'Length
       and then Hi <= A'Length;

   --  Every element right of the window is >= every element in the window.
   function Suffix_Geq_Window
     (A : Element_Array; Lo, Hi : Natural) return Boolean
   is
     (Hi >= A'Length
      or else
        (for all I in Hi + 1 .. A'Length =>
           (for all J in Lo .. Hi => A (A'First + (I - 1)) >= A (A'First + (J - 1)))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Lo >= 1
       and then Hi in Lo - 1 .. A'Length
       and then Hi <= A'Length;

   procedure Swap (A : in out Element_Array; X, Y : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then X in 1 .. A'Length
         and then Y in 1 .. A'Length,
       Post   =>
         In_Bounds (A)
         and then A (A'First + (X - 1)) = A'Old (A'First + (Y - 1))
         and then A (A'First + (Y - 1)) = A'Old (A'First + (X - 1))
         and then
           (for all K in 1 .. A'Length =>
              (if K /= X and then K /= Y then A (A'First + (K - 1)) = A'Old (A'First + (K - 1))))
   is
      T : Integer;
   begin
      if X = Y then
         return;
      end if;
      T     := A (A'First + (X - 1));
      A (A'First + (X - 1)) := A (A'First + (Y - 1));
      A (A'First + (Y - 1)) := T;
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
         and then A'Length >= 2
         and then Lo in 1 .. A'Length
         and then Hi in Lo + 2 .. A'Length
         and then Prefix_Leq_Window (A, Lo, Hi)
         and then Suffix_Geq_Window (A, Lo, Hi),
       Post   =>
         In_Bounds (A)
         and then Prefix_Leq_Window (A, Lo, Hi)
         and then Suffix_Geq_Window (A, Lo, Hi)
         and then
           (for all K in 1 .. Lo - 1 => A (A'First + (K - 1)) = A'Old (A'First + (K - 1)))
         and then
           (for all K in Hi + 1 .. A'Length => A (A'First + (K - 1)) = A'Old (A'First + (K - 1)))
   is
      Mid : constant Index := Lo + (Hi - Lo) / 2;
   begin
      pragma Assert (Mid in Lo .. Hi);
      pragma Assert (Mid in Lo + 1 .. Hi - 1);
      pragma Assert (Mid >= Lo and then Mid <= Hi);

      if A (A'First + (Mid - 1)) < A (A'First + (Lo - 1)) then
         Swap (A, Lo, Mid);
      end if;
      pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
      pragma Assert (Suffix_Geq_Window (A, Lo, Hi));

      if A (A'First + (Hi - 1)) < A (A'First + (Lo - 1)) then
         Swap (A, Lo, Hi);
      end if;
      pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
      pragma Assert (Suffix_Geq_Window (A, Lo, Hi));

      if A (A'First + (Hi - 1)) < A (A'First + (Mid - 1)) then
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
         and then A'Length >= 2
         and then Lo in 1 .. A'Length
         and then Hi in Lo + 1 .. A'Length
         and then Prefix_Leq_Window (A, Lo, Hi)
         and then Suffix_Geq_Window (A, Lo, Hi),
       Post   =>
         In_Bounds (A)
         and then P in Lo .. Hi
         and then All_Leq (A, Lo, P - 1, A (A'First + (P - 1)))
         and then All_Geq (A, P + 1, Hi, A (A'First + (P - 1)))
         and then Prefix_Leq_Window (A, Lo, Hi)
         and then Suffix_Geq_Window (A, Lo, Hi)
         and then
           (for all K in 1 .. Lo - 1 => A (A'First + (K - 1)) = A'Old (A'First + (K - 1)))
         and then
           (for all K in Hi + 1 .. A'Length => A (A'First + (K - 1)) = A'Old (A'First + (K - 1)))
   is
      Pivot : Integer;
      I     : Cursor;
   begin
      if Hi - Lo >= 2 then
         Median_Of_Three (A, Lo, Hi);
      end if;

      Pivot := A (A'First + (Hi - 1));
      I     := Cursor (Lo);

      pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
      pragma Assert (Suffix_Geq_Window (A, Lo, Hi));
      pragma Assert (All_Leq (A, Lo, Lo - 1, Pivot));

      for J in Lo .. Hi - 1 loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (I in Lo .. J);
         pragma Loop_Invariant (A (A'First + (Hi - 1)) = Pivot);
         pragma Loop_Invariant (All_Leq (A, Lo, I - 1, Pivot));
         pragma Loop_Invariant
           (for all K in I .. J - 1 => A (A'First + (K - 1)) > Pivot);
         pragma Loop_Invariant (Prefix_Leq_Window (A, Lo, Hi));
         pragma Loop_Invariant (Suffix_Geq_Window (A, Lo, Hi));
         pragma Loop_Invariant
           (for all K in 1 .. Lo - 1 => A (A'First + (K - 1)) = A'Loop_Entry (A'First + (K - 1)));
         pragma Loop_Invariant
           (for all K in Hi + 1 .. A'Length => A (A'First + (K - 1)) = A'Loop_Entry (A'First + (K - 1)));

         if A (A'First + (J - 1)) <= Pivot then
            pragma Assert (I in 1 .. A'Length);
            pragma Assert (J in 1 .. A'Length);
            Swap (A, Index (I), J);
            I := I + 1;
         end if;

         pragma Assert (I in Lo .. J + 1);
         pragma Assert (All_Leq (A, Lo, I - 1, Pivot));
         pragma Assert (for all K in I .. J => A (A'First + (K - 1)) > Pivot);
         pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
         pragma Assert (Suffix_Geq_Window (A, Lo, Hi));
      end loop;

      pragma Assert (I in Lo .. Hi);
      pragma Assert (A (A'First + (Hi - 1)) = Pivot);
      pragma Assert (All_Leq (A, Lo, I - 1, Pivot));
      pragma Assert (for all K in I .. Hi - 1 => A (A'First + (K - 1)) > Pivot);
      pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
      pragma Assert (Suffix_Geq_Window (A, Lo, Hi));

      Swap (A, Index (I), Hi);

      P := Index (I);

      pragma Assert (P in Lo .. Hi);
      pragma Assert (A (A'First + (P - 1)) = Pivot);
      pragma Assert (All_Leq (A, Lo, P - 1, A (A'First + (P - 1))));
      pragma Assert (for all K in P + 1 .. Hi => A (A'First + (K - 1)) > Pivot);
      pragma Assert (All_Geq (A, P + 1, Hi, A (A'First + (P - 1))));
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
         and then Lo in 1 .. A'Length
         and then Hi in Lo .. A'Length
         and then P = K
         and then P in Lo .. Hi
         and then Prefix_Leq_Window (A, Lo, Hi)
         and then Suffix_Geq_Window (A, Lo, Hi)
         and then All_Leq (A, Lo, P - 1, A (A'First + (P - 1)))
         and then All_Geq (A, P + 1, Hi, A (A'First + (P - 1))),
       Post              => Is_Kth_Partitioned (A, K)
   is
   begin
      pragma Assert (P = K);
      --  Left of Target: 1 .. Lo-1 via Prefix, Lo .. P-1 via Lomuto.
      pragma Assert
        (for all I in 1 .. Lo - 1 => A (A'First + (I - 1)) <= A (A'First + (P - 1)));
      pragma Assert
        (for all I in Lo .. P - 1 => A (A'First + (I - 1)) <= A (A'First + (P - 1)));
      pragma Assert
        (for all I in 1 .. P - 1 => A (A'First + (I - 1)) <= A (A'First + (P - 1)));
      --  Right of Target: P+1 .. Hi via Lomuto, Hi+1 .. Last via Suffix.
      pragma Assert
        (for all I in P + 1 .. Hi => A (A'First + (I - 1)) >= A (A'First + (P - 1)));
      pragma Assert
        (for all I in Hi + 1 .. A'Length => A (A'First + (I - 1)) >= A (A'First + (P - 1)));
      pragma Assert
        (for all I in P + 1 .. A'Length => A (A'First + (I - 1)) >= A (A'First + (P - 1)));
      --  Same facts at absolute indexes: I is position I - A'First + 1.
      pragma Assert
        (for all I in A'Range =>
           (if I < A'First + (P - 1)
            then A (A'First + ((I - A'First + 1) - 1)) <= A (A'First + (P - 1))));
      pragma Assert
        (for all I in A'Range =>
           (if I > A'First + (P - 1)
            then A (A'First + ((I - A'First + 1) - 1)) >= A (A'First + (P - 1))));
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
         and then Lo in 1 .. A'Length
         and then Prefix_Leq_Window (A, Lo, Hi)
         and then Suffix_Geq_Window (A, Lo, Hi),
       Post              => Is_Kth_Partitioned (A, K)
   is
   begin
      pragma Assert (Lo = K and then Hi = K);
      pragma Assert
        (for all I in 1 .. Lo - 1 => A (A'First + (I - 1)) <= A (A'First + (Lo - 1)));
      pragma Assert
        (for all I in Hi + 1 .. A'Length => A (A'First + (I - 1)) >= A (A'First + (Hi - 1)));
      --  Same facts at absolute indexes: I is position I - A'First + 1.
      pragma Assert
        (for all I in A'Range =>
           (if I < A'First + (Lo - 1)
            then A (A'First + ((I - A'First + 1) - 1)) <= A (A'First + (Lo - 1))));
      pragma Assert
        (for all I in A'Range =>
           (if I > A'First + (Lo - 1)
            then A (A'First + ((I - A'First + 1) - 1)) >= A (A'First + (Lo - 1))));
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
         and then Lo in 1 .. A'Length
         and then Hi in Lo .. A'Length
         and then P in Lo + 1 .. Hi
         and then Target in Lo .. P - 1
         and then Prefix_Leq_Window (A, Lo, Hi)
         and then Suffix_Geq_Window (A, Lo, Hi)
         and then All_Leq (A, Lo, P - 1, A (A'First + (P - 1)))
         and then All_Geq (A, P + 1, Hi, A (A'First + (P - 1))),
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
      pragma Assert (All_Leq (A, Lo, P - 1, A (A'First + (P - 1))));
      pragma Assert
        (for all J in Lo .. P - 1 => A (A'First + (P - 1)) >= A (A'First + (J - 1)));
      pragma Assert
        (for all I in P + 1 .. Hi =>
           (for all J in Lo .. P - 1 => A (A'First + (I - 1)) >= A (A'First + (J - 1))));
      pragma Assert
        (for all I in Hi + 1 .. A'Length =>
           (for all J in Lo .. P - 1 => A (A'First + (I - 1)) >= A (A'First + (J - 1))));
      pragma Assert
        (for all I in P .. A'Length =>
           (for all J in Lo .. P - 1 => A (A'First + (I - 1)) >= A (A'First + (J - 1))));
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
         and then Lo in 1 .. A'Length
         and then Hi in Lo .. A'Length
         and then P in Lo .. Hi - 1
         and then Target in P + 1 .. Hi
         and then Prefix_Leq_Window (A, Lo, Hi)
         and then Suffix_Geq_Window (A, Lo, Hi)
         and then All_Leq (A, Lo, P - 1, A (A'First + (P - 1)))
         and then All_Geq (A, P + 1, Hi, A (A'First + (P - 1))),
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
      pragma Assert (All_Geq (A, P + 1, Hi, A (A'First + (P - 1))));
      pragma Assert
        (for all J in P + 1 .. Hi => A (A'First + (P - 1)) <= A (A'First + (J - 1)));
      pragma Assert
        (for all I in Lo .. P - 1 =>
           (for all J in P + 1 .. Hi => A (A'First + (I - 1)) <= A (A'First + (J - 1))));
      pragma Assert
        (for all I in 1 .. Lo - 1 =>
           (for all J in P + 1 .. Hi => A (A'First + (I - 1)) <= A (A'First + (J - 1))));
      pragma Assert
        (for all I in 1 .. P =>
           (for all J in P + 1 .. Hi => A (A'First + (I - 1)) <= A (A'First + (J - 1))));
      pragma Assert (Prefix_Leq_Window (A, P + 1, Hi));
   end Lemma_Shrink_Right;

   procedure Select_Kth (A : in out Element_Array; K : Positive) is
      Target : constant Index := K;
      Lo     : Index;
      Hi     : Index;
      P      : Index;
   begin
      pragma Assert (Target <= A'Length);

      if A'Length = 1 then
         pragma Assert (Target = 1 and then A'Length = 1);
         pragma Assert (Is_Kth_Partitioned (A, K));
         return;
      end if;

      Lo := 1;
      Hi := A'Length;

      pragma Assert (Prefix_Leq_Window (A, Lo, Hi));
      pragma Assert (Suffix_Geq_Window (A, Lo, Hi));
      pragma Assert (Target in Lo .. Hi);

      while Lo /= Hi loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (A'Length >= 2);
         pragma Loop_Invariant (Lo in 1 .. A'Length);
         pragma Loop_Invariant (Hi in Lo .. A'Length);
         pragma Loop_Invariant (Target in Lo .. Hi);
         pragma Loop_Invariant (Prefix_Leq_Window (A, Lo, Hi));
         pragma Loop_Invariant (Suffix_Geq_Window (A, Lo, Hi));
         pragma Loop_Variant (Decreases => Hi - Lo);

         pragma Assert (Hi >= Lo + 1);
         pragma Assert (A'Length >= 2);

         Partition (A, Lo, Hi, P);

         pragma Assert (P in Lo .. Hi);
         pragma Assert (All_Leq (A, Lo, P - 1, A (A'First + (P - 1))));
         pragma Assert (All_Geq (A, P + 1, Hi, A (A'First + (P - 1))));
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
      end loop;

      --  Each iteration shrinks Hi - Lo (Loop_Variant); on exit the window
      --  is the single position Target.
      Lemma_Kth_Singleton (A, Lo, Hi, Target);
      pragma Assert (Is_Kth_Partitioned (A, K));
   end Select_Kth;

   function Select_Kth_Copy (A : Element_Array; K : Positive) return Integer is
      Copy : Element_Array := A;
   begin
      Select_Kth (Copy, K);
      return Copy (Copy'First + (K - 1));
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
