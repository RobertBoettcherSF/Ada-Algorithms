--  Burstsort body — SPARK Level 4 educational MSD / burst-bucket string
--  sort with static buffers, proved to sort on its own (no bubble-sort
--  safety net).
--
--  Process_Slice avoids a full Character histogram (256-wide loops fight
--  Level-4 SMT time). Instead: in-place compact Ended, sort the active
--  region by Data (Depth+1), then burst / finish equal-character runs —
--  same emit order as a burst-trie walk (Ended, then ascending chars).
--
--  Proof: every slice handed to Process_Slice shares its first Depth
--  characters (ghost Common). Ended strings (Length = Depth) are then
--  equal under the order and sort before the rest (Lemma_Ended); runs of
--  equal character Depth + 1 share Depth + 1 characters, so the recursive
--  call applies, and a smaller character at Depth + 1 means a smaller
--  string (Lemma_Char_Order). Insertion sorts keep every shared prefix
--  (ghost Keeps_Prefixes). Permutation is checked by the tests, not
--  stated in the contracts.

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
   -- Ghost model: sortedness and shared prefixes
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

   --  X has at least D characters and agrees with R on the first D.
   function Has_Prefix
     (X, R : Bounded_String; D : Natural) return Boolean
   is
     (X.Length >= D
      and then (for all J in 1 .. D => X.Data (J) = R.Data (J)))
   with
     Ghost  => True,
     Global => null,
     Pre    => D <= Max_String_Len;

   --  Every string of A (Lo .. Hi) has the first D characters of R.
   function Common
     (A : String_Array; Lo, Hi : Natural; R : Bounded_String; D : Natural)
      return Boolean
   is
     (for all K in Lo .. Hi => Has_Prefix (A (K), R, D))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A) and then Lo >= 1 and then Hi <= A'Last
       and then D <= Max_String_Len;

   --  Every prefix that all of Old (Lo .. Hi) share with Old (Lo) is
   --  still shared by all of A (Lo .. Hi).
   function Keeps_Prefixes
     (A, Old : String_Array; Lo, Hi : Natural) return Boolean
   is
     (for all D in 0 .. Max_String_Len =>
        (if Common (Old, Lo, Hi, Old (Lo), D)
         then Common (A, Lo, Hi, Old (Lo), D)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A) and then In_Bounds (Old) and then A'Last = Old'Last
       and then Lo in 1 .. Hi and then Hi <= A'Last;

   -------------------------------------------------------------------------
   -- Order lemmas
   -------------------------------------------------------------------------

   procedure Lemma_Lt_Asym (X, Y : Bounded_String)
     with
       Ghost  => True,
       Global => null,
       Pre    => X < Y,
       Post   => X <= Y
   is
   begin
      null;
   end Lemma_Lt_Asym;

   --  A string that ends at the shared prefix is <= every string with
   --  that prefix.
   procedure Lemma_Ended (X, Y, R : Bounded_String; D : Natural)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         D <= Max_String_Len
         and then Has_Prefix (X, R, D) and then Has_Prefix (Y, R, D)
         and then X.Length = D,
       Post   => X <= Y
   is
   begin
      pragma Assert (for all J in 1 .. D => X.Data (J) = Y.Data (J));
   end Lemma_Ended;

   --  With a shared prefix of D characters, character D + 1 decides.
   procedure Lemma_Char_Order (X, Y, R : Bounded_String; D : Natural)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         D < Max_String_Len
         and then Has_Prefix (X, R, D) and then Has_Prefix (Y, R, D)
         and then X.Length > D and then Y.Length > D
         and then X.Data (D + 1) < Y.Data (D + 1),
       Post   => X <= Y
   is
   begin
      pragma Assert (for all J in 1 .. D => X.Data (J) = Y.Data (J));
      pragma Assert (not (Y.Length < X.Length
                          and then (for all J in 1 .. Natural'Min
                                      (X.Length, Y.Length) =>
                                      Y.Data (J) = X.Data (J))));
   end Lemma_Char_Order;

   --  A slice of strings that all end at the shared prefix is sorted
   --  (they are all equal under the order).
   procedure Lemma_Ended_Sorted
     (A : String_Array; Lo, Hi : Natural; R : Bounded_String; D : Natural)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A) and then Lo >= 1 and then Hi <= A'Last
         and then D <= Max_String_Len
         and then Common (A, Lo, Hi, R, D)
         and then (for all K in Lo .. Hi => A (K).Length = D),
       Post   => Sorted_Slice (A, Lo, Hi)
   is
   begin
      for K in Lo .. Hi - 1 loop
         Lemma_Ended (A (K), A (K + 1), R, D);
         pragma Loop_Invariant
           (for all J in Lo .. K => A (J) <= A (J + 1));
      end loop;
   end Lemma_Ended_Sorted;

   --  Two sorted neighbouring slices with an ordered seam form one.
   procedure Lemma_Join (A : String_Array; Lo, M, Hi : Positive)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         In_Bounds (A) and then Lo <= M and then M <= Hi
         and then Hi <= A'Last
         and then Sorted_Slice (A, Lo, M - 1)
         and then Sorted_Slice (A, M, Hi)
         and then (M = Lo or else A (M - 1) <= A (M)),
       Post   => Sorted_Slice (A, Lo, Hi)
   is
   begin
      null;
   end Lemma_Join;

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

   -------------------------------------------------------------------------
   -- MSD burst-bucket phase
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

   --  Small bucket finish: insertion sort of Work (Lo .. Hi) under "<".
   procedure Insertion_Sort_Slice
     (Work : in out String_Array;
      Lo   : Positive;
      Hi   : Natural)
     with
       Global => null,
       Pre    =>
         In_Bounds (Work)
         and then Hi <= Work'Last
         and then Lo <= Hi + 1
         and then (if Hi >= Lo then Hi - Lo + 1 <= Burst_Threshold else True),
       Post   =>
         In_Bounds (Work)
         and then
           (for all K in 1 .. Work'Last =>
              (if K < Lo or else K > Hi then Work (K) = Work'Old (K)))
         and then Sorted_Slice (Work, Lo, Hi)
         and then (if Lo <= Hi then Keeps_Prefixes (Work, Work'Old, Lo, Hi))
   is
      Init : constant String_Array := Work with Ghost;
      Key  : Bounded_String;
      J    : Integer;
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
         pragma Loop_Invariant (Keeps_Prefixes (Work, Init, Lo, Hi));
         pragma Loop_Invariant (Sorted_Slice (Work, Lo, I - 1));

         Key := Work (I);
         J   := Integer (I) - 1;

         while J >= Integer (Lo) and then Key < Work (J) loop
            pragma Loop_Invariant (In_Bounds (Work));
            pragma Loop_Invariant (J in Integer (Lo) .. Integer (I) - 1);
            pragma Loop_Invariant
              (for all K in 1 .. Work'Last =>
                 (if K < Lo or else K > Hi then
                    Work (K) = Work'Loop_Entry (K)));
            pragma Loop_Invariant
              (Keeps_Prefixes (Work, Init, Lo, Hi));
            pragma Loop_Invariant
              (for all D in 0 .. Max_String_Len =>
                 (if Common (Init, Lo, Hi, Init (Lo), D)
                  then Has_Prefix (Key, Init (Lo), D)));
            --  Work (Lo .. I) without slot J + 1 is the old sorted run
            --  with Key removed; the moved part J + 2 .. I is above Key.
            pragma Loop_Invariant (Sorted_Slice (Work, Lo, J));
            pragma Loop_Invariant (Sorted_Slice (Work, J + 1, I));
            pragma Loop_Invariant
              (for all K in J + 2 .. I => Key < Work (K));
            pragma Loop_Invariant
              (J + 1 = I or else J < Lo or else Work (J) <= Work (J + 2));
            pragma Loop_Variant (Decreases => J - Integer (Lo) + 1);

            Work (J + 1) := Work (J);
            J := J - 1;
         end loop;

         Work (J + 1) := Key;
         if J + 2 <= I then
            Lemma_Lt_Asym (Key, Work (J + 2));
         end if;
         pragma Assert (Sorted_Slice (Work, Lo, I));
      end loop;
   end Insertion_Sort_Slice;

   --  Insertion sort of Work (Lo .. Hi) by the character at Depth + 1.
   procedure Sort_By_Char
     (Work  : in out String_Array;
      Lo    : Positive;
      Hi    : Natural;
      Depth : Natural)
     with
       Global => null,
       Pre    =>
         In_Bounds (Work)
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
         and then
           (for all K in Lo .. Hi - 1 =>
              Char_At (Work (K), Depth) <= Char_At (Work (K + 1), Depth))
         and then (if Lo <= Hi then Keeps_Prefixes (Work, Work'Old, Lo, Hi))
   is
      Init : constant String_Array := Work with Ghost;
      Key  : Bounded_String;
      J    : Integer;
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
         pragma Loop_Invariant (Keeps_Prefixes (Work, Init, Lo, Hi));
         pragma Loop_Invariant
           (for all K in Lo .. I - 2 =>
              Char_At (Work (K), Depth) <= Char_At (Work (K + 1), Depth));

         Key := Work (I);
         J   := Integer (I) - 1;

         while J >= Integer (Lo)
           and then Char_Less (Key, Work (J), Depth)
         loop
            pragma Loop_Invariant (In_Bounds (Work));
            pragma Loop_Invariant (J in Integer (Lo) .. Integer (I) - 1);
            pragma Loop_Invariant
              (for all K in 1 .. Work'Last =>
                 (if K < Lo or else K > Hi then
                    Work (K) = Work'Loop_Entry (K)));
            pragma Loop_Invariant
              (for all K in Lo .. Hi => Work (K).Length > Depth);
            pragma Loop_Invariant (Key.Length > Depth);
            pragma Loop_Invariant
              (Keeps_Prefixes (Work, Init, Lo, Hi));
            pragma Loop_Invariant
              (for all D in 0 .. Max_String_Len =>
                 (if Common (Init, Lo, Hi, Init (Lo), D)
                  then Has_Prefix (Key, Init (Lo), D)));
            pragma Loop_Invariant
              (for all K in Lo .. J - 1 =>
                 Char_At (Work (K), Depth) <= Char_At (Work (K + 1), Depth));
            pragma Loop_Invariant
              (for all K in J + 1 .. I - 1 =>
                 Char_At (Work (K), Depth) <= Char_At (Work (K + 1), Depth));
            pragma Loop_Invariant
              (for all K in J + 2 .. I =>
                 Char_At (Key, Depth) < Char_At (Work (K), Depth));
            pragma Loop_Invariant
              (J + 1 = I
               or else Char_At (Work (J), Depth) <= Char_At (Work (J + 2), Depth));
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
         and then Hi <= Work'Last
         and then Lo <= Hi + 1
         and then Depth <= Max_String_Len
         and then (if Lo <= Hi then Common (Work, Lo, Hi, Work (Lo), Depth)),
       Post   =>
         In_Bounds (Work)
         and then
           (for all K in 1 .. Work'Last =>
              (if K < Lo or else K > Hi then Work (K) = Work'Old (K)))
         and then Sorted_Slice (Work, Lo, Hi)
         and then
           (if Lo <= Hi then Common (Work, Lo, Hi, Work'Old (Lo), Depth)),
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
         --  Every string has all Max_String_Len characters of Work (Lo):
         --  they are all equal under the order.
         Lemma_Ended_Sorted (Work, Lo, Hi, Work (Lo), Depth);
         return;
      end if;

      declare
         R : constant Bounded_String := Work (Lo) with Ghost;
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
            pragma Loop_Invariant (Write in Lo .. I);
            pragma Loop_Invariant
              (for all J in Lo .. Write - 1 => Work (J).Length <= Depth);
            pragma Loop_Invariant
              (for all J in Write .. I - 1 => Work (J).Length > Depth);
            pragma Loop_Invariant
              (for all J in 1 .. Work'Last =>
                 (if J < Lo or else J > Hi then
                    Work (J) = Work'Loop_Entry (J)));
            pragma Loop_Invariant (Common (Work, Lo, Hi, R, Depth));

            if Work (I).Length <= Depth then
               Swap (Work, Write, I);
               Write := Write + 1;
            end if;
         end loop;

         pragma Assert
           (for all J in Lo .. Write - 1 => Work (J).Length = Depth);
         pragma Assert
           (for all J in Write .. Hi => Work (J).Length > Depth);
         Lemma_Ended_Sorted (Work, Lo, Write - 1, R, Depth);

         if Write > Hi then
            --  All Ended — nothing to burst.
            return;
         end if;

         Act_Lo := Write;
         pragma Assert (Act_Lo <= Act_Hi);
         pragma Assert
           (for all J in Act_Lo .. Act_Hi => Work (J).Length > Depth);

         declare
            Before : constant String_Array := Work with Ghost;
         begin
            pragma Assert
              (Common (Before, Act_Lo, Act_Hi, Before (Act_Lo), Depth));
            Sort_By_Char (Work, Act_Lo, Act_Hi, Depth);
            pragma Assert
              (Common (Work, Act_Lo, Act_Hi, Before (Act_Lo), Depth));
            pragma Assert (Has_Prefix (Before (Act_Lo), R, Depth));
            pragma Assert (Common (Work, Act_Lo, Act_Hi, R, Depth));
            pragma Assert
              (for all J in Lo .. Act_Lo - 1 => Work (J) = Before (J));
         end;

         pragma Assert
           (for all J in Act_Lo .. Act_Hi => Work (J).Length > Depth);
         pragma Assert (Common (Work, Lo, Hi, R, Depth));
         pragma Assert (Sorted_Slice (Work, Lo, Act_Lo - 1));

         --  Equal-character runs: burst or insertion-finish.
         Run_Lo := Act_Lo;
         while Run_Lo <= Act_Hi loop
            pragma Loop_Invariant (In_Bounds (Work));
            pragma Loop_Invariant (Run_Lo in Act_Lo .. Act_Hi);
            pragma Loop_Invariant (Depth < Max_String_Len);
            pragma Loop_Invariant
              (for all J in Run_Lo .. Act_Hi =>
                 Work (J) = Work'Loop_Entry (J));
            pragma Loop_Invariant
              (for all J in 1 .. Work'Last =>
                 (if J < Lo or else J > Hi then
                    Work (J) = Work'Loop_Entry (J)));
            pragma Loop_Invariant (Common (Work, Lo, Hi, R, Depth));
            pragma Loop_Invariant
              (for all J in Act_Lo .. Act_Hi => Work (J).Length > Depth);
            pragma Loop_Invariant
              (for all J in Run_Lo .. Act_Hi - 1 =>
                 Char_At (Work (J), Depth) <= Char_At (Work (J + 1), Depth));
            pragma Loop_Invariant (Sorted_Slice (Work, Lo, Run_Lo - 1));
            --  The last string placed so far sorts before the rest.
            pragma Loop_Invariant
              (Run_Lo = Lo
               or else Work (Run_Lo - 1).Length = Depth
               or else (Work (Run_Lo - 1).Length > Depth
                        and then Char_At (Work (Run_Lo - 1), Depth)
                                 < Char_At (Work (Run_Lo), Depth)));
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
                 (for all J in Run_Lo .. K => Char_At (Work (J), Depth) = Ch);
               pragma Loop_Variant (Decreases => Act_Hi - K);

               K := K + 1;
            end loop;
            Run_Hi := K;
            Run_Count := Run_Hi - Run_Lo + 1;
            pragma Assert
              (Run_Hi = Act_Hi
               or else Ch < Char_At (Work (Run_Hi + 1), Depth));
            --  The run shares Depth + 1 characters.
            pragma Assert
              (Common (Work, Run_Lo, Run_Hi, Work (Run_Lo), Depth + 1));

            declare
               Before : constant String_Array := Work with Ghost;
            begin
               if Run_Count <= Burst_Threshold then
                  Insertion_Sort_Slice (Work, Run_Lo, Run_Hi);
               else
                  Process_Slice (Work, Run_Lo, Run_Hi, Depth + 1);
               end if;
               pragma Assert
                 (Common (Work, Run_Lo, Run_Hi, Before (Run_Lo), Depth + 1));
               pragma Assert
                 (for all J in Lo .. Run_Lo - 1 => Work (J) = Before (J));
               pragma Assert (Sorted_Slice (Work, Lo, Run_Lo - 1));
            end;
            pragma Assert
              (for all J in Run_Lo .. Run_Hi =>
                 Work (J).Length > Depth
                 and then Char_At (Work (J), Depth) = Ch);
            pragma Assert (Common (Work, Lo, Hi, R, Depth));

            --  Join the run to the sorted part.
            if Run_Lo > Lo then
               if Work (Run_Lo - 1).Length = Depth then
                  Lemma_Ended (Work (Run_Lo - 1), Work (Run_Lo), R, Depth);
               else
                  Lemma_Char_Order
                    (Work (Run_Lo - 1), Work (Run_Lo), R, Depth);
               end if;
            end if;
            Lemma_Join (Work, Lo, Run_Lo, Run_Hi);
            pragma Assert (Sorted_Slice (Work, Lo, Run_Hi));

            exit when Run_Hi >= Act_Hi;
            Run_Lo := Run_Hi + 1;
         end loop;
         pragma Assert (Sorted_Slice (Work, Lo, Hi));
      end;
   end Process_Slice;

   --  Copy into the static Work buffer, burst-sort it, copy back.
   procedure Burst_Phase (A : in out String_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A) and then Is_Sorted (A)
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
         pragma Loop_Invariant
           (for all T in 1 .. I - 1 => A (T) = Work (T));

         A (I) := Work (I);
      end loop;
      pragma Assert (Sorted_Slice (Work, 1, N));
   end Burst_Phase;

   procedure Sort (A : in out String_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Burst_Phase (A);
   end Sort;

end Burstsort;
