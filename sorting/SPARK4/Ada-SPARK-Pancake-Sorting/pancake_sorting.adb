--  Pancake_Sorting body — SPARK Level 4 classic pancake sort.
--  Outer loop grows a sorted suffix via Place_Max; Flip reverses a
--  prefix. Loop invariants track sortedness of the suffix and the
--  partition property vs. the remaining prefix.

package body Pancake_Sorting
  with SPARK_Mode => On
is

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
       In_Bounds (A)
       and then L >= 1
       and then R <= A'Last;

   --  Every element of A (Lo_P .. Hi_P) is <= every element of A (Lo_S .. Hi_S).
   function Prefix_Leq_Suffix
     (A                      : Element_Array;
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

   procedure Flip (A : in out Element_Array; K : Natural) is
      Orig : constant Element_Array := A;
   begin
      if K <= 1 then
         return;
      end if;

      declare
         I : Index := 1;
         J : Index := K;
      begin
         while I < J loop
            pragma Loop_Invariant (I >= 1);
            pragma Loop_Invariant (J <= K);
            pragma Loop_Invariant (I + J = K + 1);
            pragma Loop_Invariant (I <= J);
            pragma Loop_Invariant
              (for all P in 1 .. I - 1 => A (P) = Orig (K - P + 1));
            pragma Loop_Invariant
              (for all P in J + 1 .. K => A (P) = Orig (K - P + 1));
            pragma Loop_Invariant
              (for all P in I .. J => A (P) = Orig (P));
            pragma Loop_Invariant
              (for all P in K + 1 .. A'Last => A (P) = Orig (P));

            Swap (A, I, J);

            pragma Assert (A (I) = Orig (K - I + 1));
            pragma Assert (A (J) = Orig (K - J + 1));

            I := I + 1;
            J := J - 1;
         end loop;

         pragma Assert (I >= J);
         pragma Assert (I + J = K + 1);
         pragma Assert
           (for all P in 1 .. I - 1 => A (P) = Orig (K - P + 1));
         pragma Assert
           (for all P in J + 1 .. K => A (P) = Orig (K - P + 1));
         pragma Assert (if I = J then I = K - I + 1);
         pragma Assert (if I = J then A (I) = Orig (I));
         pragma Assert (if I = J then A (I) = Orig (K - I + 1));
         pragma Assert
           (for all P in 1 .. K => A (P) = Orig (K - P + 1));
         pragma Assert
           (for all P in K + 1 .. A'Last => A (P) = Orig (P));
      end;
   end Flip;

   procedure Apply_Flips
     (A     : in out Element_Array;
      Flips : Flip_Sequence;
      Count : Natural)
   is
   begin
      for I in 1 .. Count loop
         pragma Loop_Invariant (In_Bounds (A));
         Flip (A, Flips (I));
      end loop;
   end Apply_Flips;

   --  Place a maximum of A (1 .. Size) at index Size via at most two
   --  prefix flips. Preserves the already-sorted / partitioned suffix
   --  Size+1 .. A'Last. Records 0..2 flip lengths into F1/F2 (0 = unused).
   procedure Place_Max
     (A     : in out Element_Array;
      Size  : Index;
      F1    : out Natural;
      F2    : out Natural;
      NFlip : out Natural)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Last >= 2
         and then Size in 2 .. A'Last
         and then Sorted_Slice (A, Size + 1, A'Last)
         and then Prefix_Leq_Suffix (A, 1, Size, Size + 1, A'Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Size, A'Last)
         and then Prefix_Leq_Suffix (A, 1, Size - 1, Size, A'Last)
         and then NFlip <= 2
         and then (if Size = 2 then NFlip <= 1)
         and then (if NFlip = 2 then Size >= 3)
         and then
           (NFlip
            <= Classic_Flip_Bound (Size) - Classic_Flip_Bound (Size - 1))
         and then (if NFlip = 0 then F1 = 0 and then F2 = 0)
         and then (if NFlip = 1 then F1 in 2 .. Size and then F2 = 0)
         and then
           (if NFlip = 2 then
              F1 in 2 .. Size and then F2 in 2 .. Size)
   is
      Orig   : constant Element_Array := A;
      Max_At : Index := 1;
   begin
      F1    := 0;
      F2    := 0;
      NFlip := 0;

      for I in 2 .. Size loop
         pragma Loop_Invariant (Max_At in 1 .. I - 1);
         pragma Loop_Invariant
           (for all K in 1 .. I - 1 => A (K) <= A (Max_At));
         pragma Loop_Invariant
           (for all K in 1 .. A'Last => A (K) = Orig (K));
         pragma Loop_Invariant (Sorted_Slice (A, Size + 1, A'Last));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, 1, Size, Size + 1, A'Last));

         --  Prefer the rightmost maximum so a nondecreasing prefix
         --  (including duplicate keys) is recognized as already placed.
         if A (I) >= A (Max_At) then
            Max_At := I;
         end if;
      end loop;

      pragma Assert (Max_At in 1 .. Size);
      pragma Assert (for all K in 1 .. Size => A (K) <= A (Max_At));
      pragma Assert (for all K in 1 .. A'Last => A (K) = Orig (K));
      pragma Assert (Sorted_Slice (A, Size + 1, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, Size, Size + 1, A'Last));
      pragma Assert
        (Size = A'Last or else A (Max_At) <= A (Size + 1));

      if Max_At = Size then
         pragma Assert (for all K in 1 .. Size => A (K) <= A (Size));
         pragma Assert (Size = A'Last or else A (Size) <= A (Size + 1));
         pragma Assert (Sorted_Slice (A, Size, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, 1, Size - 1, Size, A'Last));
         return;
      end if;

      --  Bring maximum to the front if it is not already there.
      if Max_At /= 1 then
         Flip (A, Max_At);
         F1    := Max_At;
         NFlip := 1;

         pragma Assert (A (1) = Orig (Max_At));
         pragma Assert
           (for all K in Max_At + 1 .. A'Last => A (K) = Orig (K));
         pragma Assert
           (for all K in 1 .. Max_At =>
              A (K) = Orig (Max_At - K + 1));
         --  Rearrangement of 1 .. Max_At; Max_At+1 .. Size unchanged:
         --  A(1) remains a maximum of 1 .. Size.
         pragma Assert (for all K in 1 .. Size => A (K) <= A (1));
         pragma Assert (Sorted_Slice (A, Size + 1, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, 1, Size, Size + 1, A'Last));
         pragma Assert
           (for all K in Size + 1 .. A'Last => A (K) = Orig (K));
      else
         pragma Assert (A (1) = Orig (1));
         pragma Assert (for all K in 1 .. Size => A (K) <= A (1));
      end if;

      pragma Assert (for all K in 1 .. Size => A (K) <= A (1));
      pragma Assert (Size = A'Last or else A (1) <= A (Size + 1));
      pragma Assert (Sorted_Slice (A, Size + 1, A'Last));
      pragma Assert
        (for all K in Size + 1 .. A'Last => A (K) = Orig (K));

      declare
         Max_Val : constant Integer := A (1);
         Before  : constant Element_Array := A;
      begin
         --  Flip prefix of length Size: places Max_Val at index Size.
         Flip (A, Size);

         if NFlip = 0 then
            F1    := Size;
            NFlip := 1;
         else
            F2    := Size;
            NFlip := 2;
         end if;

         pragma Assert (A (Size) = Before (1));
         pragma Assert (A (Size) = Max_Val);
         pragma Assert
           (for all K in Size + 1 .. A'Last => A (K) = Orig (K));
         pragma Assert
           (for all K in 1 .. Size - 1 => A (K) = Before (Size - K + 1));
         pragma Assert
           (for all K in 2 .. Size => Before (K) <= Max_Val);
         pragma Assert
           (for all K in 1 .. Size - 1 => A (K) <= Max_Val);
         pragma Assert
           (for all K in 1 .. Size - 1 => A (K) <= A (Size));
         pragma Assert
           (Size = A'Last or else A (Size) <= A (Size + 1));
         pragma Assert (Sorted_Slice (A, Size, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, 1, Size - 1, Size, A'Last));
      end;
   end Place_Max;

   procedure Sort (A : in out Element_Array) is
      F1, F2, NFlip : Natural;
   begin
      if A'Length <= 1 then
         return;
      end if;

      pragma Assert (Sorted_Slice (A, A'Last + 1, A'Last));
      pragma Assert
        (Prefix_Leq_Suffix (A, 1, A'Last, A'Last + 1, A'Last));

      for Size in reverse 2 .. A'Last loop
         Place_Max (A, Size, F1, F2, NFlip);
         --  Mention outs so flow analysis treats them as used.
         pragma Assert (NFlip <= 2);
         pragma Assert (F1 <= Size or else NFlip = 0);
         pragma Assert (F2 <= Size or else NFlip < 2);

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, Size, A'Last));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, 1, Size - 1, Size, A'Last));
         --  suffix sortedness tracked by Sorted_Slice above
      end loop;

      pragma Assert (Sorted_Slice (A, 2, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, 1, 2, A'Last));
      pragma Assert (Is_Sorted (A));
   end Sort;

   procedure Sort
     (A     : in out Element_Array;
      Flips : out Flip_Sequence;
      Count : out Natural)
   is
      F1, F2, NFlip : Natural;
   begin
      Flips := [others => 0];
      Count := 0;

      if A'Length <= 1 then
         return;
      end if;

      pragma Assert (Sorted_Slice (A, A'Last + 1, A'Last));
      pragma Assert
        (Prefix_Leq_Suffix (A, 1, A'Last, A'Last + 1, A'Last));
      pragma Assert (Classic_Flip_Bound (A'Length) <= Max_Flips);

      for Size in reverse 2 .. A'Last loop
         --  Flips recorded so far cover sizes Size+1 .. A'Last.
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (Count
            <= Classic_Flip_Bound (A'Length)
               - Classic_Flip_Bound (Size));
         pragma Loop_Invariant (Count <= Max_Flips);
         pragma Loop_Invariant
           (for all J in 1 .. Count => Flips (J) in 2 .. A'Last);
         pragma Loop_Invariant
           (if Size < A'Last then Sorted_Slice (A, Size + 1, A'Last)
            else True);
         pragma Loop_Invariant
           (if Size < A'Last then
              Prefix_Leq_Suffix (A, 1, Size, Size + 1, A'Last)
            else True);

         Place_Max (A, Size, F1, F2, NFlip);

         pragma Assert
           (NFlip
            <= Classic_Flip_Bound (Size) - Classic_Flip_Bound (Size - 1));
         pragma Assert
           (Count
            <= Classic_Flip_Bound (A'Length)
               - Classic_Flip_Bound (Size));
         pragma Assert
           (Count + NFlip
            <= Classic_Flip_Bound (A'Length)
               - Classic_Flip_Bound (Size - 1));

         if NFlip >= 1 then
            Count := Count + 1;
            Flips (Count) := F1;
         end if;
         if NFlip = 2 then
            Count := Count + 1;
            Flips (Count) := F2;
         end if;

         pragma Assert (Sorted_Slice (A, Size, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, 1, Size - 1, Size, A'Last));
         pragma Assert
           (Count
            <= Classic_Flip_Bound (A'Length)
               - Classic_Flip_Bound (Size - 1));
      end loop;

      pragma Assert (Count <= Classic_Flip_Bound (A'Length));
      pragma Assert (Sorted_Slice (A, 2, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, 1, 2, A'Last));
      pragma Assert (Is_Sorted (A));
   end Sort;

end Pancake_Sorting;
