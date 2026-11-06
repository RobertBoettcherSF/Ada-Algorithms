--  Pigeonhole_Sort body — SPARK Level 4 pigeonhole sort with static
--  Counts / Work. Count + prefix + stable scatter are proved to sort on
--  their own (ghost Sum_Below / Occ with induction lemmas); there is no
--  finishing pass and no clamp.

--  Run-time cost: the ghost walk, loop invariants and assertions count
--  every hole with recursive Occ; all are proved (make prove) and skipped
--  at run time. The Posts of Sort and Pigeonhole_Phase (sorted, Is_Perm)
--  still execute.
pragma Assertion_Policy (Ghost => Ignore, Loop_Invariant => Ignore, Assert => Ignore);

package body Pigeonhole_Sort
  with SPARK_Mode => On
is

   --  Proved phase: origin 1 and Last in 0 .. Max_N (the previous shape
   --  guard). Public Sort slides any origin onto that shape and back:
   --  position K is stored at A (A'First + K - 1).
   function From_One (A : Element_Array) return Boolean is
     (A'First = 1 and then A'Last in 0 .. Max_N)
   with Global => null;

   function Pos (A : Element_Array; K : Positive) return Positive is
     (A'First + (K - 1))
   with
     Pre  =>
       In_Bounds (A) and then A'Length >= 1 and then K <= A'Length,
     Post => Pos'Result in A'Range;

   procedure Lemma_Slide_Sorted (A, Local : Element_Array)
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then In_Bounds (Local)
       and then Local'First = 1
       and then Local'Last = A'Length
       and then Is_Sorted (Local)
       and then (for all K in 1 .. A'Length => A (Pos (A, K)) = Local (K)),
     Post   => Is_Sorted (A)
   is
   begin
      if A'Length <= 1 then
         return;
      end if;
      for I in A'First .. A'Last - 1 loop
         pragma Loop_Invariant
           (for all J in A'First .. I - 1 => A (J) <= A (J + 1));
         pragma Assert (I - A'First + 1 in 1 .. A'Length - 1);
         pragma Assert (A (I) = Local (I - A'First + 1));
         pragma Assert (A (I + 1) = Local ((I + 1) - A'First + 1));
      end loop;
   end Lemma_Slide_Sorted;

   procedure Lemma_Occ_Slide
     (A, Local : Element_Array; V : Integer; K : Natural)
   with
     Ghost              => True,
     Global             => null,
     Pre                =>
       In_Bounds (A)
       and then In_Bounds (Local)
       and then Local'First = 1
       and then Local'Last = A'Length
       and then A'Length >= 1
       and then K <= A'Length
       and then (for all J in 1 .. A'Length => A (Pos (A, J)) = Local (J)),
     Post               =>
       (if K = 0 then True
        else Occ (A, V, Pos (A, K)) = Occ (Local, V, K)),
     Subprogram_Variant => (Decreases => K)
   is
   begin
      if K > 0 then
         Lemma_Occ_Slide (A, Local, V, K - 1);
         if K = 1 then
            pragma Assert (Pos (A, 1) = A'First);
         else
            pragma Assert (Pos (A, K) - 1 = Pos (A, K - 1));
         end if;
      end if;
   end Lemma_Occ_Slide;

   procedure Lemma_Slide_Perm (A, Old, Local, Saved : Element_Array)
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then In_Bounds (Old)
       and then A'First = Old'First
       and then A'Last = Old'Last
       and then A'Length >= 1
       and then In_Bounds (Local)
       and then In_Bounds (Saved)
       and then Local'First = 1
       and then Local'Last = A'Length
       and then Saved'First = 1
       and then Saved'Last = A'Length
       and then Is_Perm (Local, Saved)
       and then (for all K in 1 .. A'Length => A (Pos (A, K)) = Local (K))
       and then (for all K in 1 .. A'Length => Old (Pos (Old, K)) = Saved (K)),
     Post   => Is_Perm (A, Old)
   is
      N : constant Natural := A'Length;
   begin
      pragma Assert (Pos (A, N) = A'Last);
      pragma Assert (Pos (Old, N) = Old'Last);
      for I in A'Range loop
         pragma Loop_Invariant
           (for all J in A'First .. I - 1 =>
              Occ (A, A (J), A'Last) = Occ (Old, A (J), Old'Last));
         Lemma_Occ_Slide (A, Local, A (I), N);
         Lemma_Occ_Slide (Old, Saved, A (I), N);
         pragma Assert (A (I) = Local (I - A'First + 1));
      end loop;
      for I in Old'Range loop
         pragma Loop_Invariant
           (for all J in A'Range =>
              Occ (A, A (J), A'Last) = Occ (Old, A (J), Old'Last));
         pragma Loop_Invariant
           (for all J in Old'First .. I - 1 =>
              Occ (A, Old (J), A'Last) = Occ (Old, Old (J), Old'Last));
         Lemma_Occ_Slide (A, Local, Old (I), N);
         Lemma_Occ_Slide (Old, Saved, Old (I), N);
         pragma Assert (Old (I) = Saved (I - Old'First + 1));
      end loop;
   end Lemma_Slide_Perm;

   procedure Lemma_Keys_Slide (A, Local : Element_Array)
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Keys_In_Range (A)
       and then In_Bounds (Local)
       and then Local'First = 1
       and then Local'Last = A'Length
       and then A'Length >= 1
       and then (for all K in 1 .. A'Length => Local (K) = A (Pos (A, K))),
     Post   => Keys_In_Range (Local)
   is
   begin
      for I in 1 .. Local'Last loop
         pragma Loop_Invariant
           (for all X in 1 .. I - 1 =>
              (for all Y in 1 .. Local'Last =>
                 Long_Long_Integer (Local (X)) - Long_Long_Integer (Local (Y))
                   < Long_Long_Integer (Max_Range)));
         for J in 1 .. Local'Last loop
            pragma Loop_Invariant
              (for all Y in 1 .. J - 1 =>
                 Long_Long_Integer (Local (I)) - Long_Long_Integer (Local (Y))
                   < Long_Long_Integer (Max_Range));
            pragma Assert (Local (I) = A (Pos (A, I)));
            pragma Assert (Local (J) = A (Pos (A, J)));
         end loop;
      end loop;
   end Lemma_Keys_Slide;

   --  Adjacent nondecreasing on A (L .. R). Vacuous when L >= R.
   function Sorted_Slice
     (A : Element_Array; L, R : Natural) return Boolean
   is
     (L >= R
      or else (for all K in L .. R - 1 => A (K) <= A (K + 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       From_One (A)
       and then L >= 1
       and then R <= A'Last;

   --  Number of keys in the holes below H: C (0) + ... + C (H - 1).
   subtype Bin_Bound is Natural range 0 .. Max_Range;

   function Sum_Below (C : Count_Array; H : Bin_Bound) return Natural is
     (if H = 0 then 0 else Sum_Below (C, H - 1) + C (H - 1))
   with
     Ghost              => True,
     Global             => null,
     Post               => Sum_Below'Result <= H * Max_N,
     Subprogram_Variant => (Decreases => H);

   --  All holes empty: no keys below any H.
   procedure Lemma_Zero (C : Count_Array; H : Bin_Bound)
     with
       Ghost              => True,
       Global             => null,
       Pre                => (for all K in Hole_Index => C (K) = 0),
       Post               => Sum_Below (C, H) = 0,
       Subprogram_Variant => (Decreases => H)
   is
   begin
      if H > 0 then
         Lemma_Zero (C, H - 1);
      end if;
   end Lemma_Zero;

   --  One more key in hole J adds one to every sum that covers J.
   procedure Lemma_Inc
     (Before, After : Count_Array; J : Hole_Index; H : Bin_Bound)
     with
       Ghost              => True,
       Global             => null,
       Pre                =>
         After (J) = Before (J) + 1
         and then (for all K in Hole_Index =>
                     (if K /= J then After (K) = Before (K))),
       Post               =>
         Sum_Below (After, H) = Sum_Below (Before, H) + (if J < H then 1 else 0),
       Subprogram_Variant => (Decreases => H)
   is
   begin
      if H > 0 then
         Lemma_Inc (Before, After, J, H - 1);
      end if;
   end Lemma_Inc;

   --  Sums only grow with H.
   procedure Lemma_Mono (C : Count_Array; H1, H2 : Bin_Bound)
     with
       Ghost              => True,
       Global             => null,
       Pre                => H1 <= H2,
       Post               => Sum_Below (C, H1) <= Sum_Below (C, H2),
       Subprogram_Variant => (Decreases => H2)
   is
   begin
      if H2 > H1 then
         Lemma_Mono (C, H1, H2 - 1);
      end if;
   end Lemma_Mono;

   --  Key X measured from Mn, without overflow.
   function Rel (X, Mn : Integer) return Long_Long_Integer is
     (Long_Long_Integer (X) - Long_Long_Integer (Mn))
   with Global => null;

   --  How many of A (1 .. I) fall into hole K.
   function Occ
     (A : Element_Array; Mn : Integer; I : Natural; K : Hole_Index)
      return Natural
   is
     (if I = 0 then 0
      else Occ (A, Mn, I - 1, K)
           + (if Rel (A (I), Mn) = Long_Long_Integer (K) then 1 else 0))
   with
     Ghost              => True,
     Global             => null,
     Pre                => From_One (A) and then I <= A'Last,
     Post               => Occ'Result <= I,
     Subprogram_Variant => (Decreases => I);

   procedure Lemma_Occ_Mono
     (A : Element_Array; Mn : Integer; I, J : Natural; K : Hole_Index)
     with
       Ghost              => True,
       Global             => null,
       Pre                => From_One (A) and then I <= J and then J <= A'Last,
       Post               => Occ (A, Mn, I, K) <= Occ (A, Mn, J, K),
       Subprogram_Variant => (Decreases => J)
   is
   begin
      if J > I then
         Lemma_Occ_Mono (A, Mn, I, J - 1, K);
      end if;
   end Lemma_Occ_Mono;

   --  Hole counts are value counts: hole K holds exactly the keys
   --  Mn + K.
   procedure Lemma_Link (A : Element_Array; Mn : Integer; Last : Natural; K : Hole_Index)
     with
       Ghost              => True,
       Global             => null,
       Pre                => From_One (A) and then Last <= A'Last
                             and then Long_Long_Integer (Mn) + Long_Long_Integer (K)
                                      <= Long_Long_Integer (Integer'Last),
       Post               => Occ (A, Mn + K, Last) = Occ (A, Mn, Last, K),
       Subprogram_Variant => (Decreases => Last)
   is
   begin
      if Last > 0 then
         Lemma_Link (A, Mn, Last - 1, K);
      end if;
   end Lemma_Link;

   --  Educational pigeonhole: min/max, count, prefix offsets, stable
   --  scatter into Work, copy back. Proved to sort on its own: hole K
   --  owns the Work slots Sum_Below (Counts, K) + 1 .. Sum_Below
   --  (Counts, K + 1), the scatter fills exactly those slots with
   --  Min_Val + K, and the holes are laid out in key order. Only the
   --  Top = Max_Val - Min_Val + 1 holes that keys can reach are walked.
   procedure Pigeonhole_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    =>
         From_One (A)
         and then A'Length >= 2
         and then Keys_In_Range (A),
       Post   => From_One (A) and then Is_Sorted (A) and then Is_Perm (A, A'Old)
   is
      A0      : constant Element_Array := A with Ghost;
      N       : constant Positive := A'Last;
      Min_Val : Integer;
      Max_Val : Integer;
      Counts  : Count_Array := [others => 0];
      Next    : Count_Array := [others => 0];
      Work    : Work_Array := [others => 0];
      Total   : Natural := 0;
      Top     : Bin_Bound;
      H       : Hole_Index;
      Dest    : Positive;
      Before  : Count_Array with Ghost;
      Prev    : Count_Array with Ghost;
      Start   : Count_Array with Ghost;
      Pos     : Natural := 0 with Ghost;
   begin
      Min_Val := A (1);
      Max_Val := A (1);

      for X in 2 .. N loop
         pragma Loop_Invariant (Min_Val <= Max_Val);
         pragma Loop_Invariant
           (for all J in 1 .. X - 1 => A (J) in Min_Val .. Max_Val);
         pragma Loop_Invariant (for some J in 1 .. X - 1 => A (J) = Min_Val);
         pragma Loop_Invariant (for some J in 1 .. X - 1 => A (J) = Max_Val);

         if A (X) < Min_Val then
            Min_Val := A (X);
         elsif A (X) > Max_Val then
            Max_Val := A (X);
         end if;
      end loop;

      --  Keys_In_Range bounds Max_Val - Min_Val, so every key has a hole.
      pragma Assert (Rel (Max_Val, Min_Val) < Long_Long_Integer (Max_Range));
      pragma Assert
        (for all J in 1 .. N =>
           Rel (A (J), Min_Val) in 0 .. Long_Long_Integer (Max_Range) - 1);

      --  Holes 0 .. Top - 1 cover Min_Val .. Max_Val; only these are used.
      Top := Bin_Bound (Rel (Max_Val, Min_Val) + 1);
      pragma Assert
        (for all J in 1 .. N => Rel (A (J), Min_Val) < Long_Long_Integer (Top));

      --  Count how many items fall into each pigeonhole.
      Lemma_Zero (Counts, Top);
      for I in 1 .. N loop
         pragma Loop_Invariant
           (for all K in 0 .. Top - 1 => Counts (K) = Occ (A, Min_Val, I - 1, K));
         pragma Loop_Invariant
           (for all K in Top .. Max_Range - 1 => Counts (K) = 0);
         pragma Loop_Invariant (Sum_Below (Counts, Top) = I - 1);

         H := Hole_Index (Rel (A (I), Min_Val));
         Before := Counts;
         Counts (H) := Counts (H) + 1;
         Lemma_Inc (Before, Counts, H, Top);
      end loop;
      pragma Assert
        (for all K in 0 .. Top - 1 => Counts (K) = Occ (A, Min_Val, N, K));
      pragma Assert (Sum_Below (Counts, Top) = N);

      --  Next (H) := first slot of hole H minus one (exclusive prefix).
      --  Hole K owns the slots Next (K) + 1 .. Next (K) + Counts (K); the
      --  invariants say these runs follow one another in key order.
      for HH in 0 .. Top - 1 loop
         pragma Loop_Invariant (Total = Sum_Below (Counts, HH));
         pragma Loop_Invariant (Total <= N);
         pragma Loop_Invariant (if HH > 0 then Next (0) = 0);
         pragma Loop_Invariant
           (for all K in 0 .. HH - 1 => Next (K) + Counts (K) <= Total);
         pragma Loop_Invariant
           (for all K in 0 .. HH - 1 =>
              Next (K) + Counts (K) = (if K = HH - 1 then Total else Next (K + 1)));
         pragma Loop_Invariant
           (for all K1 in 0 .. HH - 1 =>
              (for all K2 in K1 + 1 .. HH - 1 =>
                 Next (K1) + Counts (K1) <= Next (K2)));

         Lemma_Mono (Counts, HH + 1, Top);
         Next (HH) := Total;
         Total := Total + Counts (HH);
      end loop;
      pragma Assert (Total = N);
      pragma Assert (Next (0) = 0);
      pragma Assert
        (for all K in 0 .. Top - 1 => Next (K) + Counts (K) <= N);
      pragma Assert
        (for all K in 0 .. Top - 1 =>
           Next (K) + Counts (K) = (if K = Top - 1 then N else Next (K + 1)));
      pragma Assert
        (for all K1 in 0 .. Top - 1 =>
           (for all K2 in K1 + 1 .. Top - 1 =>
              Next (K1) + Counts (K1) <= Next (K2)));
      Start := Next;
      pragma Assert (Start (0) = 0);
      pragma Assert
        (for all K in 0 .. Top - 1 => Start (K) + Counts (K) <= N);
      pragma Assert
        (for all K in 0 .. Top - 1 =>
           Start (K) + Counts (K) = (if K = Top - 1 then N else Start (K + 1)));
      pragma Assert
        (for all K1 in 0 .. Top - 1 =>
           (for all K2 in K1 + 1 .. Top - 1 =>
              Start (K1) + Counts (K1) <= Start (K2)));

      --  Stable scatter: place each item into its hole segment L→R.
      for I in 1 .. N loop
         pragma Loop_Invariant
           (for all K in 0 .. Top - 1 =>
              Next (K) = Start (K) + Occ (A, Min_Val, I - 1, K));
         pragma Loop_Invariant
           (for all K in 0 .. Top - 1 => Next (K) <= Start (K) + Counts (K));
         pragma Loop_Invariant
           (for all K in 0 .. Top - 1 =>
              (for all P in Start (K) + 1 .. Next (K) =>
                 Rel (Work (P), Min_Val) = Long_Long_Integer (K)));

         H := Hole_Index (Rel (A (I), Min_Val));
         Lemma_Occ_Mono (A, Min_Val, I, N, H);
         pragma Assert (Next (H) < Start (H) + Counts (H));
         Dest := Next (H) + 1;
         pragma Assert
           (for all K in 0 .. Top - 1 =>
              (if K < H then Next (K) < Dest
               elsif K > H then Start (K) >= Dest));
         Work (Dest) := A (I);
         Prev := Next;
         Next (H) := Dest;
         pragma Assert
           (for all K in 0 .. Top - 1 =>
              Next (K) = Prev (K) + (if K = H then 1 else 0));
      end loop;
      pragma Assert
        (for all K in 0 .. Top - 1 => Next (K) = Start (K) + Counts (K));

      --  Read contiguous hole segments back into A (key order).
      for I in 1 .. N loop
         pragma Loop_Invariant (for all J in 1 .. I - 1 => A (J) = Work (J));
         A (I) := Work (I);
      end loop;

      --  Ghost walk over the holes: A (1 .. Pos) is sorted and holds only
      --  keys below Min_Val + K, where Pos = Start (K).
      --  Counting along: A (1 .. Pos) holds Counts (K2) copies of
      --  Min_Val + K2 for every hole K2 < K and nothing else.
      for K in 0 .. Top - 1 loop
         pragma Loop_Invariant (Pos = Start (K));
         pragma Loop_Invariant (Sorted_Slice (A, 1, Pos));
         pragma Loop_Invariant
           (for all P in 1 .. Pos =>
              Rel (A (P), Min_Val) < Long_Long_Integer (K));
         pragma Loop_Invariant (for all P in 1 .. Pos => Rel (A (P), Min_Val) >= 0);
         pragma Loop_Invariant
           (for all K2 in 0 .. Top - 1 =>
              Occ (A, Min_Val + K2, Pos) = (if K2 < K then Counts (K2) else 0));
         pragma Assert
           (for all P in Pos + 1 .. Pos + Counts (K) =>
              Rel (A (P), Min_Val) = Long_Long_Integer (K));
         pragma Assert (for all P in Pos + 1 .. Pos + Counts (K) => A (P) = Min_Val + K);
         for P in 1 .. Counts (K) loop
            pragma Loop_Invariant
              (for all K2 in 0 .. Top - 1 =>
                 Occ (A, Min_Val + K2, Pos + P) =
                   (if K2 < K then Counts (K2) elsif K2 = K then P else 0));
         end loop;
         pragma Assert
           (for all K2 in 0 .. Top - 1 =>
              Occ (A, Min_Val + K2, Pos + Counts (K)) = (if K2 <= K then Counts (K2) else 0));
         Pos := Pos + Counts (K);
      end loop;
      pragma Assert (Pos = N);
      pragma Assert (Sorted_Slice (A, 1, N));

      --  Same value counts as A0, hole by hole; other values are absent
      --  from both.
      for K2 in 0 .. Top - 1 loop
         Lemma_Link (A0, Min_Val, N, K2);
         pragma Loop_Invariant
           (for all J in 0 .. K2 => Occ (A, Min_Val + J, N) = Occ (A0, Min_Val + J, N));
      end loop;
      pragma Assert (for all I in 1 .. N => A (I) in Min_Val .. Max_Val);
      pragma Assert (for all I in 1 .. N => A0 (I) in Min_Val .. Max_Val);
      pragma Assert
        (for all I in 1 .. N =>
           A (I) - Min_Val in 0 .. Top - 1 and then A (I) = Min_Val + (A (I) - Min_Val));
      pragma Assert
        (for all I in 1 .. N =>
           A0 (I) - Min_Val in 0 .. Top - 1 and then A0 (I) = Min_Val + (A0 (I) - Min_Val));
      pragma Assert (for all J in 0 .. Top - 1 => Occ (A, Min_Val + J, N) = Occ (A0, Min_Val + J, N));
      for I in 1 .. N loop
         pragma Assert (A (I) - Min_Val in 0 .. Top - 1);
         pragma Assert (Occ (A, Min_Val + (A (I) - Min_Val), N) = Occ (A0, Min_Val + (A (I) - Min_Val), N));
         pragma Assert (A0 (I) - Min_Val in 0 .. Top - 1);
         pragma Assert (Occ (A, Min_Val + (A0 (I) - Min_Val), N) = Occ (A0, Min_Val + (A0 (I) - Min_Val), N));
         pragma Loop_Invariant (for all I2 in 1 .. I => Occ (A, A (I2), N) = Occ (A0, A (I2), N));
         pragma Loop_Invariant (for all I2 in 1 .. I => Occ (A, A0 (I2), N) = Occ (A0, A0 (I2), N));
      end loop;
      pragma Assert (Is_Perm (A, A0));
   end Pigeonhole_Phase;

   procedure Sort (A : in out Element_Array) is
      Original : constant Element_Array := A with Ghost;
      N : constant Natural := A'Length;
   begin
      if N <= 1 then
         return;
      end if;

      declare
         Local : Element_Array (1 .. N) := [others => 0];
      begin
         for K in 1 .. N loop
            Local (K) := A (Pos (A, K));
            pragma Loop_Invariant
              (for all J in 1 .. K => Local (J) = A (Pos (A, J)));
         end loop;

         declare
            Saved : constant Element_Array := Local with Ghost;
         begin
            pragma Assert
              (for all K in 1 .. N => Saved (K) = Original (Pos (Original, K)));
         Lemma_Keys_Slide (A, Local);
         Pigeonhole_Phase (Local);
            for K in 1 .. N loop
               A (Pos (A, K)) := Local (K);
               pragma Loop_Invariant
                 (for all J in 1 .. K => A (Pos (A, J)) = Local (J));
            end loop;

            pragma Assert (Is_Perm (Local, Saved));
            pragma Assert
              (for all K in 1 .. N => Saved (K) = Original (Pos (Original, K)));
            Lemma_Slide_Sorted (A, Local);
            Lemma_Slide_Perm (A, Original, Local, Saved);
         end;
      end;
   end Sort;

end Pigeonhole_Sort;
