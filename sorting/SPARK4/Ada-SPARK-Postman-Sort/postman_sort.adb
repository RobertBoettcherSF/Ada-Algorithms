--  Postman_Sort body — SPARK Level 4 MSD postal pigeonhole distribution.
--  Histogram / stable scatter / gather / recurse prove only In_Bounds /
--  RTE; the final gap-1 bubble finish reuses Bubble_Pass / Sorted_Slice /
--  Prefix_Leq_Suffix so Sort proves Is_Sorted (same split as Flashsort /
--  Strand_Sort / Pigeonhole_Sort). Recursion is bounded by
--  Subprogram_Variant on Exp.

package body Postman_Sort
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

   --  One forward pass over A (1 .. Bound): bubble the maximum of that
   --  range to index Bound via adjacent swaps.
   procedure Bubble_Pass
     (A       : in out Element_Array;
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

   --  Final gap = 1: ordinary bubble sort with early exit. Proves Is_Sorted.
   procedure Bubble_Finish (A : in out Element_Array)
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

   --  Digit of Key at power Exp: (Key / Exp) rem Base. Defensive clamp
   --  so RTE stays local if a key is somehow out of policy.
   function Digit_Of (Key, Exp : Integer) return Digit_Index
     with
       Global => null,
       Pre    => Key >= 0 and then Exp >= 1
   is
      Q : constant Integer := Key / Exp;
      R : constant Integer := Q rem Base;
   begin
      if R in Digit_Index then
         return Digit_Index (R);
      else
         return 0;
      end if;
   end Digit_Of;

   --  Greatest value in nonempty nonnegative A.
   function Max_Value (A : Element_Array) return Integer
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Keys_Ok (A)
         and then A'Length >= 1,
       Post   => Max_Value'Result >= 0
   is
      M : Integer := A (1);
   begin
      for I in 2 .. A'Last loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (M >= 0);

         if A (I) > M then
            M := A (I);
         end if;
      end loop;

      return M;
   end Max_Value;

   --  Highest power Exp = Base^p such that Exp <= Max_Key (and Exp fits
   --  in Integer). For Max_Key < Base the result is 1.
   function Highest_Exp (Max_Key : Integer) return Integer
     with
       Global => null,
       Pre    => Max_Key >= 0,
       Post   => Highest_Exp'Result >= 1
   is
      Exp : Integer := 1;
   begin
      while Max_Key / Exp >= Base
        and then Exp <= Integer'Last / Base
      loop
         pragma Loop_Invariant (Exp >= 1);
         pragma Loop_Variant (Increases => Exp);

         Exp := Exp * Base;
      end loop;

      return Exp;
   end Highest_Exp;

   --  Rebuild exclusive 0-based starting offsets from a histogram.
   --  Caps at Max_N so prefix addition cannot overflow (cardinality
   --  of the live range is n at run time; we do not prove the sum).
   procedure Prefix_Starts
     (Count : Count_Array;
      Start : out Count_Array)
     with
       Global => null,
       Pre    => (for all K in Digit_Index => Count (K) <= Max_N),
       Post   => (for all K in Digit_Index => Start (K) <= Max_N)
   is
      C : Natural;
   begin
      Start := [others => 0];
      Start (0) := 0;

      for K in 1 .. Base - 1 loop
         pragma Loop_Invariant (Start (0) = 0);
         pragma Loop_Invariant
           (for all J in Digit_Index => Count (J) <= Max_N);
         pragma Loop_Invariant
           (for all J in 0 .. K - 1 => Start (J) <= Max_N);

         C := Count (K - 1);
         if Start (K - 1) <= Max_N - C then
            Start (K) := Start (K - 1) + C;
         else
            Start (K) := Max_N;
         end if;
      end loop;
   end Prefix_Starts;

   --  MSD recurse on A (Lo .. Hi) at digit significance Exp.
   --  Only In_Bounds / Keys_Ok / RTE are proved.
   procedure MSD_Range
     (A   : in out Element_Array;
      Lo  : Index;
      Hi  : Index;
      Exp : Integer)
     with
       Global            => null,
       Always_Terminates => True,
       Pre               =>
         In_Bounds (A)
         and then Keys_Ok (A)
         and then Lo in 1 .. A'Last
         and then Hi in Lo .. A'Last
         and then Exp >= 1,
       Post              => In_Bounds (A) and then Keys_Ok (A),
       Subprogram_Variant => (Decreases => Exp)
   is
      Count    : Count_Array := [others => 0];
      Start    : Count_Array;
      Work     : Work_Array := [others => 0];
      D        : Digit_Index;
      Pos      : Natural;
      Dest     : Natural;
      Next_Exp : Integer;
      B_Lo     : Natural;
      B_Hi     : Natural;
   begin
      if Hi <= Lo then
         return;
      end if;

      --  Histogram of current MSD digits on the subrange.
      for I in Lo .. Hi loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Keys_Ok (A));
         pragma Loop_Invariant (Lo in 1 .. A'Last);
         pragma Loop_Invariant (Hi in Lo .. A'Last);
         pragma Loop_Invariant (Exp >= 1);
         pragma Loop_Invariant
           (for all K in Digit_Index => Count (K) <= I - Lo);
         pragma Loop_Invariant
           (for all K in Digit_Index => Count (K) <= Max_N);

         D := Digit_Of (A (I), Exp);
         Count (D) := Count (D) + 1;
      end loop;

      pragma Assert (for all K in Digit_Index => Count (K) <= Max_N);

      Prefix_Starts (Count, Start);
      pragma Assert (for all K in Digit_Index => Start (K) <= Max_N);

      --  Stable scatter: left → right so equal digits keep relative order.
      --  Dest / Start are capped so writes stay inside Work (1 .. Max_N).
      for I in Lo .. Hi loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Keys_Ok (A));
         pragma Loop_Invariant (Lo in 1 .. A'Last);
         pragma Loop_Invariant (Hi in Lo .. A'Last);
         pragma Loop_Invariant (Exp >= 1);
         pragma Loop_Invariant
           (for all K in Digit_Index => Start (K) <= Max_N);
         pragma Loop_Invariant
           (for all K in Digit_Index => Count (K) <= Max_N);
         pragma Loop_Invariant
           (for all K in 1 .. Max_N => Work (K) >= 0);

         D := Digit_Of (A (I), Exp);
         Pos := Start (D);
         if Pos <= Max_N - Lo then
            Dest := Lo + Pos;
            if Dest in 1 .. Max_N and then Dest in Lo .. Hi then
               Work (Dest) := A (I);
               if Start (D) < Max_N then
                  Start (D) := Start (D) + 1;
               end if;
            end if;
         end if;
      end loop;

      pragma Assert (for all K in 1 .. Max_N => Work (K) >= 0);

      --  Gather Work (Lo .. Hi) back into A. Other slots unchanged.
      for I in Lo .. Hi loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Lo in 1 .. A'Last);
         pragma Loop_Invariant (Hi in Lo .. A'Last);
         pragma Loop_Invariant
           (for all K in 1 .. Max_N => Work (K) >= 0);
         pragma Loop_Invariant
           (for all K in 1 .. A'Last =>
              (if K < Lo or else K > Hi then A (K) >= 0));
         pragma Loop_Invariant
           (for all K in Lo .. I - 1 => A (K) >= 0);

         A (I) := Work (I);

         pragma Assert (A (I) >= 0);
      end loop;

      pragma Assert (Keys_Ok (A));
      pragma Assert (In_Bounds (A));

      --  Units digit done; keys in each bucket share all examined digits.
      if Exp = 1 then
         return;
      end if;

      Next_Exp := Exp / Base;
      if Next_Exp < 1 then
         return;
      end if;

      pragma Assert (Next_Exp >= 1);
      pragma Assert (Next_Exp < Exp);

      --  Restore exclusive beginnings for bucket ranges from Count.
      Prefix_Starts (Count, Start);
      pragma Assert (for all K in Digit_Index => Start (K) <= Max_N);

      for DD in Digit_Index loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Keys_Ok (A));
         pragma Loop_Invariant (Next_Exp >= 1);
         pragma Loop_Invariant (Next_Exp < Exp);
         pragma Loop_Invariant (Lo in 1 .. A'Last);
         pragma Loop_Invariant (Hi in Lo .. A'Last);
         pragma Loop_Invariant
           (for all K in Digit_Index => Count (K) <= Max_N);
         pragma Loop_Invariant
           (for all K in Digit_Index => Start (K) <= Max_N);

         if Count (DD) > 1 then
            B_Lo := Natural (Lo) + Start (DD);
            if B_Lo in 1 .. A'Last
              and then Count (DD) - 1 <= A'Last - B_Lo
            then
               B_Hi := B_Lo + (Count (DD) - 1);
               if B_Hi in B_Lo .. A'Last then
                  MSD_Range (A, Index (B_Lo), Index (B_Hi), Next_Exp);
               end if;
            end if;
         end if;
      end loop;
   end MSD_Range;

   --  Educational MSD postman phase: max, Highest_Exp, MSD_Range.
   --  Only In_Bounds / Keys_Ok / RTE are proved.
   procedure Postman_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Keys_Ok (A)
         and then A'Length >= 2,
       Post   => In_Bounds (A) and then Keys_Ok (A)
   is
      Max_Key : Integer;
      Exp     : Integer;
   begin
      Max_Key := Max_Value (A);
      if Max_Key = 0 then
         --  All zeros — already sorted.
         return;
      end if;

      Exp := Highest_Exp (Max_Key);
      pragma Assert (Exp >= 1);
      MSD_Range (A, 1, A'Last, Exp);
   end Postman_Phase;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Postman_Phase (A);

      --  Gap-1 bubble finish → Is_Sorted (Flashsort / Strand L4 pattern).
      Bubble_Finish (A);
   end Sort;

end Postman_Sort;
