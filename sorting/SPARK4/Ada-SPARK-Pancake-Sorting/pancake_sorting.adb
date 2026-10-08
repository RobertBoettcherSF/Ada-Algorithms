--  Pancake_Sorting body — SPARK Level 4 classic pancake sort.
--  Outer loop grows a sorted suffix via Place_Max; Flip reverses a
--  prefix. Indices are First-relative; flip arguments are prefix
--  lengths counted from A'First. Loop invariants track sortedness of the suffix and the
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
       and then L >= A'First
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
       and then Lo_P >= A'First
       and then Hi_P <= A'Last
       and then Lo_S >= A'First
       and then Hi_S <= A'Last;

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

   procedure Flip (A : in out Element_Array; K : Natural) is
      Orig : constant Element_Array := A;
   begin
      if K <= 1 then
         return;
      end if;

      declare
         --  Reverse A (F .. E): position P receives Orig (F + E - P).
         F : constant Index := A'First;
         E : constant Index := A'First + K - 1;
         I : Index := F;
         J : Index := E;
      begin
         while I < J loop
            pragma Loop_Invariant (I >= F);
            pragma Loop_Invariant (J <= E);
            pragma Loop_Invariant (I + J = F + E);
            pragma Loop_Invariant (I <= J);
            pragma Loop_Invariant
              (for all P in F .. I - 1 => A (P) = Orig (F + E - P));
            pragma Loop_Invariant
              (for all P in J + 1 .. E => A (P) = Orig (F + E - P));
            pragma Loop_Invariant
              (for all P in I .. J => A (P) = Orig (P));
            pragma Loop_Invariant
              (for all P in E + 1 .. A'Last => A (P) = Orig (P));

            Swap (A, I, J);

            pragma Assert (A (I) = Orig (F + E - I));
            pragma Assert (A (J) = Orig (F + E - J));

            I := I + 1;
            J := J - 1;
         end loop;

         pragma Assert (I >= J);
         pragma Assert (I + J = F + E);
         pragma Assert
           (for all P in F .. I - 1 => A (P) = Orig (F + E - P));
         pragma Assert
           (for all P in J + 1 .. E => A (P) = Orig (F + E - P));
         pragma Assert (if I = J then I = F + E - I);
         pragma Assert (if I = J then A (I) = Orig (I));
         pragma Assert (if I = J then A (I) = Orig (F + E - I));
         pragma Assert
           (for all P in F .. E => A (P) = Orig (F + E - P));
         pragma Assert
           (for all P in E + 1 .. A'Last => A (P) = Orig (P));
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

   --  Place a maximum of A (A'First .. Hi) at index Hi via at most two
   --  prefix flips. Preserves the already-sorted / partitioned suffix
   --  Hi+1 .. A'Last. Records 0..2 flip lengths into F1/F2 (0 = unused).
   procedure Place_Max
     (A     : in out Element_Array;
      Hi    : Index;
      F1    : out Natural;
      F2    : out Natural;
      NFlip : out Natural)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 2
         and then Hi in A'First + 1 .. A'Last
         and then Sorted_Slice (A, Hi + 1, A'Last)
         and then Prefix_Leq_Suffix (A, A'First, Hi, Hi + 1, A'Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Hi, A'Last)
         and then Prefix_Leq_Suffix (A, A'First, Hi - 1, Hi, A'Last)
         and then NFlip <= 2
         and then (if Hi = A'First + 1 then NFlip <= 1)
         and then (if NFlip = 2 then Hi >= A'First + 2)
         and then
           (NFlip
            <= Classic_Flip_Bound (Hi - A'First + 1)
               - Classic_Flip_Bound (Hi - A'First))
         and then (if NFlip = 0 then F1 = 0 and then F2 = 0)
         and then
           (if NFlip = 1 then F1 in 2 .. Hi - A'First + 1 and then F2 = 0)
         and then
           (if NFlip = 2 then
              F1 in 2 .. Hi - A'First + 1
              and then F2 in 2 .. Hi - A'First + 1)
   is
      Orig   : constant Element_Array := A;
      F      : constant Index := A'First;
      Max_At : Index := A'First;
   begin
      F1    := 0;
      F2    := 0;
      NFlip := 0;

      for I in F + 1 .. Hi loop
         pragma Loop_Invariant (Max_At in F .. I - 1);
         pragma Loop_Invariant
           (for all K in F .. I - 1 => A (K) <= A (Max_At));
         pragma Loop_Invariant
           (for all K in A'Range => A (K) = Orig (K));
         pragma Loop_Invariant (Sorted_Slice (A, Hi + 1, A'Last));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, F, Hi, Hi + 1, A'Last));

         --  Prefer the rightmost maximum so a nondecreasing prefix
         --  (including duplicate keys) is recognized as already placed.
         if A (I) >= A (Max_At) then
            Max_At := I;
         end if;
      end loop;

      pragma Assert (Max_At in F .. Hi);
      pragma Assert (for all K in F .. Hi => A (K) <= A (Max_At));
      pragma Assert (for all K in A'Range => A (K) = Orig (K));
      pragma Assert (Sorted_Slice (A, Hi + 1, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, F, Hi, Hi + 1, A'Last));
      pragma Assert
        (Hi = A'Last or else A (Max_At) <= A (Hi + 1));

      if Max_At = Hi then
         pragma Assert (for all K in F .. Hi => A (K) <= A (Hi));
         pragma Assert (Hi = A'Last or else A (Hi) <= A (Hi + 1));
         pragma Assert (Sorted_Slice (A, Hi, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, F, Hi - 1, Hi, A'Last));
         return;
      end if;

      --  Bring maximum to the front if it is not already there.
      if Max_At /= F then
         Flip (A, Max_At - F + 1);
         F1    := Max_At - F + 1;
         NFlip := 1;

         pragma Assert (A (F) = Orig (Max_At));
         pragma Assert
           (for all K in Max_At + 1 .. A'Last => A (K) = Orig (K));
         pragma Assert
           (for all K in F .. Max_At =>
              A (K) = Orig (F + Max_At - K));
         --  Rearrangement of F .. Max_At; Max_At+1 .. Hi unchanged:
         --  A(F) remains a maximum of F .. Hi.
         pragma Assert (for all K in F .. Hi => A (K) <= A (F));
         pragma Assert (Sorted_Slice (A, Hi + 1, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, F, Hi, Hi + 1, A'Last));
         pragma Assert
           (for all K in Hi + 1 .. A'Last => A (K) = Orig (K));
      else
         pragma Assert (A (F) = Orig (F));
         pragma Assert (for all K in F .. Hi => A (K) <= A (F));
      end if;

      pragma Assert (for all K in F .. Hi => A (K) <= A (F));
      pragma Assert (Hi = A'Last or else A (F) <= A (Hi + 1));
      pragma Assert (Sorted_Slice (A, Hi + 1, A'Last));
      pragma Assert
        (for all K in Hi + 1 .. A'Last => A (K) = Orig (K));

      declare
         Max_Val : constant Integer := A (F);
         Before  : constant Element_Array := A;
      begin
         --  Flip the prefix ending at Hi: places Max_Val at index Hi.
         Flip (A, Hi - F + 1);

         if NFlip = 0 then
            F1    := Hi - F + 1;
            NFlip := 1;
         else
            F2    := Hi - F + 1;
            NFlip := 2;
         end if;

         pragma Assert (A (Hi) = Before (F));
         pragma Assert (A (Hi) = Max_Val);
         pragma Assert
           (for all K in Hi + 1 .. A'Last => A (K) = Orig (K));
         pragma Assert
           (for all K in F .. Hi - 1 => A (K) = Before (F + Hi - K));
         pragma Assert
           (for all K in F + 1 .. Hi => Before (K) <= Max_Val);
         pragma Assert
           (for all K in F .. Hi - 1 => A (K) <= Max_Val);
         pragma Assert
           (for all K in F .. Hi - 1 => A (K) <= A (Hi));
         pragma Assert
           (Hi = A'Last or else A (Hi) <= A (Hi + 1));
         pragma Assert (Sorted_Slice (A, Hi, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, F, Hi - 1, Hi, A'Last));
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
        (Prefix_Leq_Suffix (A, A'First, A'Last, A'Last + 1, A'Last));

      for Hi in reverse A'First + 1 .. A'Last loop
         Place_Max (A, Hi, F1, F2, NFlip);
         --  Mention outs so flow analysis treats them as used.
         pragma Assert (NFlip <= 2);
         pragma Assert (F1 <= Hi - A'First + 1 or else NFlip = 0);
         pragma Assert (F2 <= Hi - A'First + 1 or else NFlip < 2);

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, Hi, A'Last));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, A'First, Hi - 1, Hi, A'Last));
         --  suffix sortedness tracked by Sorted_Slice above
      end loop;

      pragma Assert (Sorted_Slice (A, A'First + 1, A'Last));
      pragma Assert
        (Prefix_Leq_Suffix (A, A'First, A'First, A'First + 1, A'Last));
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
        (Prefix_Leq_Suffix (A, A'First, A'Last, A'Last + 1, A'Last));
      pragma Assert (Classic_Flip_Bound (A'Length) <= Max_Flips);

      for Hi in reverse A'First + 1 .. A'Last loop
         --  Flips recorded so far cover ends Hi+1 .. A'Last.
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (Count
            <= Classic_Flip_Bound (A'Length)
               - Classic_Flip_Bound (Hi - A'First + 1));
         pragma Loop_Invariant (Count <= Max_Flips);
         pragma Loop_Invariant
           (for all J in 1 .. Count => Flips (J) in 2 .. A'Length);
         pragma Loop_Invariant
           (if Hi < A'Last then Sorted_Slice (A, Hi + 1, A'Last)
            else True);
         pragma Loop_Invariant
           (if Hi < A'Last then
              Prefix_Leq_Suffix (A, A'First, Hi, Hi + 1, A'Last)
            else True);

         Place_Max (A, Hi, F1, F2, NFlip);

         pragma Assert
           (NFlip
            <= Classic_Flip_Bound (Hi - A'First + 1)
               - Classic_Flip_Bound (Hi - A'First));
         pragma Assert
           (Count
            <= Classic_Flip_Bound (A'Length)
               - Classic_Flip_Bound (Hi - A'First + 1));
         pragma Assert
           (Count + NFlip
            <= Classic_Flip_Bound (A'Length)
               - Classic_Flip_Bound (Hi - A'First));

         if NFlip >= 1 then
            Count := Count + 1;
            Flips (Count) := F1;
         end if;
         if NFlip = 2 then
            Count := Count + 1;
            Flips (Count) := F2;
         end if;

         pragma Assert (Sorted_Slice (A, Hi, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, A'First, Hi - 1, Hi, A'Last));
         pragma Assert
           (Count
            <= Classic_Flip_Bound (A'Length)
               - Classic_Flip_Bound (Hi - A'First));
      end loop;

      pragma Assert (Count <= Classic_Flip_Bound (A'Length));
      pragma Assert (Sorted_Slice (A, A'First + 1, A'Last));
      pragma Assert
        (Prefix_Leq_Suffix (A, A'First, A'First, A'First + 1, A'Last));
      pragma Assert (Is_Sorted (A));
   end Sort;

end Pancake_Sorting;
