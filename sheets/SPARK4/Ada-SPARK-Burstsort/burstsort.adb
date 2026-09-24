--  Burstsort body — SPARK Level 4 educational MSD / burst-bucket string
--  sort with static buffers. Burst / insert / collect prove only
--  In_Bounds / RTE; the final gap-1 bubble finish reuses Bubble_Pass /
--  Sorted_Slice / Prefix_Leq_Suffix so Sort proves Is_Sorted (same split
--  as Strand_Sort / Comb_Sort / Odd_Even_Sort). No Intentional Annotate.
--
--  Process_Slice avoids a full Character histogram (256-wide loops fight
--  Level-4 SMT time). Instead: in-place compact Ended, sort the active
--  region by Data (Depth+1), then burst / finish equal-character runs —
--  same emit order as a burst-trie walk (Ended, then ascending chars).

package body Burstsort
  with SPARK_Mode => On
is

   -------------------------------------------------------------------------
   -- Public helpers
   -------------------------------------------------------------------------

   function Make (S : String) return Bounded_String is
      B : Bounded_String;
   begin
      B.Length := S'Length;
      if S'Length > 0 then
         B.Data (1 .. S'Length) := S;
      end if;
      return B;
   end Make;

   function To_String (B : Bounded_String) return String is
   begin
      return B.Data (1 .. B.Length);
   end To_String;

   function "<" (Left, Right : Bounded_String) return Boolean is
     (declare
         L : constant Natural := Left.Length;
         R : constant Natural := Right.Length;
         M : constant Natural := Natural'Min (L, R);
      begin
         (for some I in 1 .. M =>
            Left.Data (I) < Right.Data (I)
            and then
              (for all J in 1 .. I - 1 => Left.Data (J) = Right.Data (J)))
         or else
           (L < R
            and then
              (for all J in 1 .. M => Left.Data (J) = Right.Data (J))));

   -------------------------------------------------------------------------
   -- Ghost helpers for Bubble_Finish
   -------------------------------------------------------------------------

   function Sorted_Slice
     (A : String_Array; L, R : Natural) return Boolean
   is
     (L >= R
      or else (for all K in L .. R - 1 => A (K) <= A (K + 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= 1
       and then R <= A'Last;

   function Prefix_Leq_Suffix
     (A                      : String_Array;
      Lo_P, Hi_P, Lo_S, Hi_S : Natural) return Boolean
   is
     (Hi_P < Lo_P
      or else Hi_S < Lo_S
      or else
        (for all K in Lo_P .. Hi_P =>
           (for all L in Lo_S .. Hi_S => A (K) <= A (L))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Lo_P >= 1
       and then Hi_P <= A'Last
       and then Lo_S >= 1
       and then Hi_S <= A'Last;

   procedure Lemma_Leq_Trans (X, Y, Z : Bounded_String)
     with
       Ghost             => True,
       Always_Terminates => True,
       Global            => null,
       Pre               => X <= Y and then Y <= Z,
       Post              => X <= Z
   is
   begin
      null;
   end Lemma_Leq_Trans;

   procedure Swap (A : in out String_Array; X, Y : Index)
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
      T : Bounded_String;
   begin
      if X = Y then
         return;
      end if;
      T     := A (X);
      A (X) := A (Y);
      A (Y) := T;
   end Swap;

   procedure Bubble_Pass
     (A       : in out String_Array;
      Bound   : Index;
      Swapped : out Boolean)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Last >= 2
         and then Bound in 2 .. A'Last
         and then Sorted_Slice (A, Bound + 1, A'Last)
         and then Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Bound, A'Last)
         and then Prefix_Leq_Suffix (A, 1, Bound - 1, Bound, A'Last)
         and then
           (if not Swapped then Sorted_Slice (A, 1, Bound))
   is
   begin
      Swapped := False;

      for I in 1 .. Bound - 1 loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all K in 1 .. I => A (K) <= A (I));
         pragma Loop_Invariant (Sorted_Slice (A, Bound + 1, A'Last));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (if not Swapped then Sorted_Slice (A, 1, I));

         if A (I) > A (I + 1) then
            Swap (A, I, I + 1);
            Swapped := True;
         else
            pragma Assert (A (I) <= A (I + 1));
            for K in 1 .. I loop
               pragma Loop_Invariant (In_Bounds (A));
               pragma Loop_Invariant (K in 1 .. I + 1);
               pragma Loop_Invariant
                 (for all J in 1 .. K - 1 => A (J) <= A (I + 1));
               pragma Loop_Invariant (A (I) <= A (I + 1));
               pragma Loop_Invariant
                 (for all J in 1 .. I => A (J) <= A (I));

               Lemma_Leq_Trans (A (K), A (I), A (I + 1));
               pragma Assert (A (K) <= A (I + 1));
            end loop;
         end if;

         pragma Assert (for all K in 1 .. I + 1 => A (K) <= A (I + 1));
         pragma Assert (if not Swapped then Sorted_Slice (A, 1, I + 1));
      end loop;

      pragma Assert (for all K in 1 .. Bound => A (K) <= A (Bound));
      pragma Assert (Sorted_Slice (A, Bound + 1, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));
      pragma Assert (Bound = A'Last or else A (Bound) <= A (Bound + 1));
      pragma Assert (Sorted_Slice (A, Bound, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, Bound - 1, Bound, A'Last));
      pragma Assert (if not Swapped then Sorted_Slice (A, 1, Bound));
   end Bubble_Pass;

   procedure Bubble_Finish (A : in out String_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A) and then Is_Sorted (A)
   is
      Bound   : Index;
      Swapped : Boolean;
   begin
      Bound := A'Last;

      pragma Assert (Sorted_Slice (A, Bound + 1, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));

      loop
         pragma Loop_Invariant (Bound in 2 .. A'Last);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, Bound + 1, A'Last));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));
         pragma Loop_Variant (Decreases => Bound);

         Bubble_Pass (A, Bound, Swapped);

         pragma Assert (Sorted_Slice (A, Bound, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, 1, Bound - 1, Bound, A'Last));

         if not Swapped then
            pragma Assert (Sorted_Slice (A, 1, Bound));
            pragma Assert (Sorted_Slice (A, Bound, A'Last));
            pragma Assert (Is_Sorted (A));
            return;
         end if;

         exit when Bound = 2;

         Bound := Bound - 1;

         pragma Assert (Sorted_Slice (A, Bound + 1, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));
      end loop;

      pragma Assert (Bound = 2);
      pragma Assert (Sorted_Slice (A, 2, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, 1, 2, A'Last));
      pragma Assert (Is_Sorted (A));
   end Bubble_Finish;

   -------------------------------------------------------------------------
   -- Educational MSD burst-bucket phase (In_Bounds / RTE only)
   -------------------------------------------------------------------------

   function Char_At (B : Bounded_String; Depth : Natural) return Character
   is (B.Data (Depth + 1))
   with
     Global => null,
     Pre    =>
       Depth < Max_String_Len
       and then B.Length > Depth;

   function Char_Less
     (Left, Right : Bounded_String; Depth : Natural) return Boolean
   is (Char_At (Left, Depth) < Char_At (Right, Depth))
   with
     Global => null,
     Pre    =>
       Depth < Max_String_Len
       and then Left.Length > Depth
       and then Right.Length > Depth;

   procedure Insertion_Sort_Slice
     (Work : in out String_Array;
      Lo   : Positive;
      Hi   : Natural)
     with
       Global => null,
       Pre    =>
         In_Bounds (Work)
         and then Lo >= 1
         and then Hi <= Work'Last
         and then Lo <= Hi + 1
         and then (if Hi >= Lo then Hi - Lo + 1 <= Burst_Threshold else True),
       Post   =>
         In_Bounds (Work)
         and then
           (for all K in 1 .. Work'Last =>
              (if K < Lo or else K > Hi then Work (K) = Work'Old (K)))
   is
      Key : Bounded_String;
      J   : Integer;
   begin
      if Hi <= Lo then
         return;
      end if;

      for I in Lo + 1 .. Hi loop
         pragma Loop_Invariant (In_Bounds (Work));
         pragma Loop_Invariant (I in Lo + 1 .. Hi + 1);
         pragma Loop_Invariant
           (for all K in 1 .. Work'Last =>
              (if K < Lo or else K > Hi then
                 Work (K) = Work'Loop_Entry (K)));

         Key := Work (I);
         J   := Integer (I) - 1;

         while J >= Integer (Lo) and then Key < Work (J) loop
            pragma Loop_Invariant (In_Bounds (Work));
            pragma Loop_Invariant (J in Integer (Lo) - 1 .. Integer (I) - 1);
            pragma Loop_Invariant (I in Lo + 1 .. Hi);
            pragma Loop_Invariant
              (for all K in 1 .. Work'Last =>
                 (if K < Lo or else K > Hi then
                    Work (K) = Work'Loop_Entry (K)));
            pragma Loop_Variant (Decreases => J - Integer (Lo) + 1);

            Work (J + 1) := Work (J);
            J := J - 1;
         end loop;

         Work (J + 1) := Key;
      end loop;
   end Insertion_Sort_Slice;

   procedure Sort_By_Char
     (Work  : in out String_Array;
      Lo    : Positive;
      Hi    : Natural;
      Depth : Natural)
     with
       Global => null,
       Pre    =>
         In_Bounds (Work)
         and then Lo >= 1
         and then Hi <= Work'Last
         and then Lo <= Hi + 1
         and then Depth < Max_String_Len
         and then
           (for all K in Lo .. Hi => Work (K).Length > Depth),
       Post   =>
         In_Bounds (Work)
         and then
           (for all K in 1 .. Work'Last =>
              (if K < Lo or else K > Hi then Work (K) = Work'Old (K)))
         and then
           (for all K in Lo .. Hi => Work (K).Length > Depth)
   is
      Key : Bounded_String;
      J   : Integer;
   begin
      if Hi <= Lo then
         return;
      end if;

      for I in Lo + 1 .. Hi loop
         pragma Loop_Invariant (In_Bounds (Work));
         pragma Loop_Invariant (I in Lo + 1 .. Hi + 1);
         pragma Loop_Invariant
           (for all K in 1 .. Work'Last =>
              (if K < Lo or else K > Hi then
                 Work (K) = Work'Loop_Entry (K)));
         pragma Loop_Invariant
           (for all K in Lo .. Hi => Work (K).Length > Depth);

         Key := Work (I);
         J   := Integer (I) - 1;

         while J >= Integer (Lo)
           and then Char_Less (Key, Work (J), Depth)
         loop
            pragma Loop_Invariant (In_Bounds (Work));
            pragma Loop_Invariant (J in Integer (Lo) - 1 .. Integer (I) - 1);
            pragma Loop_Invariant (I in Lo + 1 .. Hi);
            pragma Loop_Invariant
              (for all K in 1 .. Work'Last =>
                 (if K < Lo or else K > Hi then
                    Work (K) = Work'Loop_Entry (K)));
            pragma Loop_Invariant
              (for all K in Lo .. Hi => Work (K).Length > Depth);
            pragma Loop_Invariant (Key.Length > Depth);
            pragma Loop_Variant (Decreases => J - Integer (Lo) + 1);

            Work (J + 1) := Work (J);
            J := J - 1;
         end loop;

         Work (J + 1) := Key;
      end loop;
   end Sort_By_Char;

   procedure Process_Slice
     (Work  : in out String_Array;
      Lo    : Positive;
      Hi    : Natural;
      Depth : Natural)
     with
       Global => null,
       Pre    =>
         In_Bounds (Work)
         and then Lo >= 1
         and then Hi <= Work'Last
         and then Lo <= Hi + 1
         and then Depth <= Max_String_Len,
       Post   =>
         In_Bounds (Work)
         and then
           (for all K in 1 .. Work'Last =>
              (if K < Lo or else K > Hi then Work (K) = Work'Old (K))),
       Subprogram_Variant =>
         (Decreases => Max_String_Len - Depth + 1,
          Decreases => (if Hi >= Lo then Hi - Lo + 1 else 0));

   procedure Process_Slice
     (Work  : in out String_Array;
      Lo    : Positive;
      Hi    : Natural;
      Depth : Natural)
   is
      Count : constant Natural :=
        (if Hi >= Lo then Hi - Lo + 1 else 0);
   begin
      if Count <= 1 then
         return;
      end if;

      if Count <= Burst_Threshold then
         Insertion_Sort_Slice (Work, Lo, Hi);
         return;
      end if;

      if Depth >= Max_String_Len then
         return;
      end if;

      declare
         Write : Natural := Lo;
         Act_Lo : Positive;
         Act_Hi : constant Natural := Hi;
         Run_Lo : Positive;
         Run_Hi : Natural;
         Run_Count : Natural;
         Ch : Character;
         K : Natural;
      begin
         --  In-place partition: Ended (Length = Depth) to the front.
         for I in Lo .. Hi loop
            pragma Loop_Invariant (In_Bounds (Work));
            pragma Loop_Invariant (I in Lo .. Hi + 1);
            pragma Loop_Invariant (Write in Lo .. I);
            pragma Loop_Invariant
              (for all J in Lo .. Write - 1 => Work (J).Length <= Depth);
            pragma Loop_Invariant
              (for all J in Write .. I - 1 => Work (J).Length > Depth);
            pragma Loop_Invariant
              (for all J in 1 .. Work'Last =>
                 (if J < Lo or else J > Hi then
                    Work (J) = Work'Loop_Entry (J)));

            if Work (I).Length <= Depth then
               Swap (Work, Write, I);
               Write := Write + 1;
            end if;
         end loop;

         pragma Assert
           (for all J in Lo .. Write - 1 => Work (J).Length <= Depth);
         pragma Assert
           (for all J in Write .. Hi => Work (J).Length > Depth);

         if Write > Hi then
            --  All Ended — nothing to burst.
            return;
         end if;

         Act_Lo := Write;
         pragma Assert (Act_Lo <= Act_Hi);
         pragma Assert
           (for all J in Act_Lo .. Act_Hi => Work (J).Length > Depth);

         Sort_By_Char (Work, Act_Lo, Act_Hi, Depth);

         pragma Assert
           (for all J in Act_Lo .. Act_Hi => Work (J).Length > Depth);

         --  Equal-character runs: burst or insertion-finish.
         --  Length > Depth is required only on the remaining suffix
         --  Run_Lo .. Act_Hi (finished runs are outside child Preserves).
         Run_Lo := Act_Lo;
         while Run_Lo <= Act_Hi loop
            pragma Loop_Invariant (In_Bounds (Work));
            pragma Loop_Invariant (Run_Lo in Act_Lo .. Act_Hi + 1);
            pragma Loop_Invariant (Depth < Max_String_Len);
            pragma Loop_Invariant
              (for all J in Run_Lo .. Act_Hi => Work (J).Length > Depth);
            pragma Loop_Invariant
              (for all J in 1 .. Work'Last =>
                 (if J < Lo or else J > Hi then
                    Work (J) = Work'Loop_Entry (J)));
            pragma Loop_Variant (Decreases => Act_Hi + 1 - Run_Lo);

            exit when Run_Lo > Act_Hi;

            Ch := Char_At (Work (Run_Lo), Depth);
            K := Run_Lo;
            while K < Act_Hi
              and then Work (K + 1).Length > Depth
              and then Char_At (Work (K + 1), Depth) = Ch
            loop
               pragma Loop_Invariant (In_Bounds (Work));
               pragma Loop_Invariant (K in Run_Lo .. Act_Hi);
               pragma Loop_Invariant (Run_Lo in Act_Lo .. Act_Hi);
               pragma Loop_Invariant (Depth < Max_String_Len);
               pragma Loop_Invariant
                 (for all J in Run_Lo .. Act_Hi => Work (J).Length > Depth);
               pragma Loop_Variant (Decreases => Act_Hi - K);

               K := K + 1;
            end loop;
            Run_Hi := K;
            Run_Count := Run_Hi - Run_Lo + 1;

            if Run_Count <= Burst_Threshold then
               Insertion_Sort_Slice (Work, Run_Lo, Run_Hi);
            else
               Process_Slice (Work, Run_Lo, Run_Hi, Depth + 1);
            end if;

            exit when Run_Hi >= Act_Hi;
            --  Child Preserves positions > Run_Hi, so Length > Depth holds.
            pragma Assert
              (for all J in Run_Hi + 1 .. Act_Hi =>
                 Work (J).Length > Depth);
            Run_Lo := Run_Hi + 1;
         end loop;
      end;
   end Process_Slice;

   procedure Burst_Phase (A : in out String_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A)
   is
      N    : constant Index := A'Last;
      Work : String_Array (1 .. Max_N) :=
        [others => (Length => 0, Data => [others => ' '])];
   begin
      for I in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all T in 1 .. I - 1 => Work (T) = A (T));

         Work (I) := A (I);
      end loop;

      Process_Slice (Work, 1, N, 0);

      for I in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));

         A (I) := Work (I);
      end loop;
   end Burst_Phase;

   procedure Sort (A : in out String_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Burst_Phase (A);
      Bubble_Finish (A);
   end Sort;

end Burstsort;
