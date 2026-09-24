--  Introselect body — iterative Quickselect with depth budget and BFPRT
--  median-of-medians (groups of 5) pivot fallback.

pragma Ada_2022;

package body Introselect
  with SPARK_Mode => Off
is

   procedure Check_Args (A : Element_Array; K : Positive) is
   begin
      if A'Length = 0 then
         raise Invalid_Argument with "empty array";
      end if;
      if A'Length > Max_N then
         raise Invalid_Argument with "array length exceeds Max_N";
      end if;
      if K > A'Length then
         raise Invalid_Argument with "K out of range";
      end if;
   end Check_Args;

   procedure Swap (A : in out Element_Array; I, J : Natural) is
      T : constant Integer := A (I);
   begin
      A (I) := A (J);
      A (J) := T;
   end Swap;

   --  ⌊log₂ N⌋ for N ≥ 1 (returns 0 when N = 0 or 1).
   function Floor_Log2 (N : Natural) return Natural is
      X : Natural := N;
      L : Natural := 0;
   begin
      while X > 1 loop
         X := X / 2;
         L := L + 1;
      end loop;
      return L;
   end Floor_Log2;

   --  Insertion sort on inclusive Lo .. Hi (used for MoM groups of ≤ 5).
   procedure Sort_Range (A : in out Element_Array; Lo, Hi : Natural) is
      Key : Integer;
      J   : Natural;
   begin
      if Hi <= Lo then
         return;
      end if;
      for I in Lo + 1 .. Hi loop
         Key := A (I);
         J   := I;
         while J > Lo and then Key < A (J - 1) loop
            A (J) := A (J - 1);
            J     := J - 1;
         end loop;
         A (J) := Key;
      end loop;
   end Sort_Range;

   --  Median-of-three: place the median of A(Lo), A(Mid), A(Hi) at Hi
   --  so Lomuto can use A(Hi) as the pivot (deterministic, random-free).
   procedure Median_Of_Three_To_Hi
     (A : in out Element_Array; Lo, Hi : Natural)
   is
      Mid : constant Natural := Lo + (Hi - Lo) / 2;
   begin
      if A (Mid) < A (Lo) then
         Swap (A, Lo, Mid);
      end if;
      if A (Hi) < A (Lo) then
         Swap (A, Lo, Hi);
      end if;
      if A (Hi) < A (Mid) then
         Swap (A, Mid, Hi);
      end if;
   end Median_Of_Three_To_Hi;

   --  Lomuto partition on A(Lo .. Hi) using A(Hi) as pivot.
   --  Returns the final index of the pivot. Elements in Lo .. P-1 are
   --  ≤ pivot; elements in P+1 .. Hi are ≥ pivot.
   function Partition_Lomuto
     (A : in out Element_Array; Lo, Hi : Natural) return Natural
   is
      Pivot : constant Integer := A (Hi);
      I     : Natural := Lo;
   begin
      for J in Lo .. Hi - 1 loop
         if A (J) <= Pivot then
            Swap (A, I, J);
            I := I + 1;
         end if;
      end loop;
      Swap (A, I, Hi);
      return I;
   end Partition_Lomuto;

   ---------------------------------------------------------------------------
   -- BFPRT median of medians (groups of 5) — returns an index in Lo .. Hi
   -- of a pivot guaranteed to be a "good" approximate median.
   ---------------------------------------------------------------------------

   function Median_Of_Medians_Index
     (A : in out Element_Array; Lo, Hi : Natural) return Natural
   is
      N           : constant Natural := Hi - Lo + 1;
      Num_Medians : Natural := 0;
      I           : Natural := Lo;
      Group_Hi    : Natural;
      Mid         : Natural;
   begin
      if N <= 5 then
         Sort_Range (A, Lo, Hi);
         return Lo + (N - 1) / 2;
      end if;

      --  Sort each group of up to 5; move each group's median to the
      --  front of A(Lo .. Hi) so medians occupy A(Lo .. Lo+Num_Medians-1).
      loop
         if I + 4 <= Hi then
            Group_Hi := I + 4;
         else
            Group_Hi := Hi;
         end if;
         Sort_Range (A, I, Group_Hi);
         Mid := I + (Group_Hi - I) / 2;
         Swap (A, Lo + Num_Medians, Mid);
         Num_Medians := Num_Medians + 1;
         exit when Group_Hi = Hi;
         I := Group_Hi + 1;
      end loop;

      --  Recursively select the median of the medians.
      return Median_Of_Medians_Index (A, Lo, Lo + Num_Medians - 1);
   end Median_Of_Medians_Index;

   ---------------------------------------------------------------------------
   -- Public API
   ---------------------------------------------------------------------------

   procedure Select_Kth (A : in out Element_Array; K : Positive) is
      Target        : Natural;
      Lo            : Natural;
      Hi            : Natural;
      P             : Natural;
      Mom           : Natural;
      Depth         : Natural;
      Used_Fallback : Boolean;
   begin
      Check_Args (A, K);

      Target := A'First + (K - 1);
      Lo     := A'First;
      Hi     := A'Last;

      --  maxdepth ← 2 × ⌊log₂ n⌋  (Musser introsort / introselect analogue)
      Depth := 2 * Floor_Log2 (A'Length);

      loop
         if Lo = Hi then
            return;
         end if;

         Used_Fallback := False;

         if Depth = 0 then
            --  Introspective fallback: BFPRT median-of-medians pivot.
            Mom := Median_Of_Medians_Index (A, Lo, Hi);
            Swap (A, Mom, Hi);
            Used_Fallback := True;
         else
            if Hi - Lo >= 2 then
               Median_Of_Three_To_Hi (A, Lo, Hi);
            end if;
            Depth := Depth - 1;
         end if;

         P := Partition_Lomuto (A, Lo, Hi);

         if P = Target then
            return;
         elsif P > Target then
            Hi := P - 1;
         else
            Lo := P + 1;
         end if;

         --  After a MoM pivot, restore a fresh Quickselect depth budget on
         --  the remaining subproblem (constant-fraction shrink guaranteed).
         if Used_Fallback and then Lo < Hi then
            Depth := 2 * Floor_Log2 (Hi - Lo + 1);
         end if;
      end loop;
   end Select_Kth;

   function Select_Kth_Copy (A : Element_Array; K : Positive) return Integer is
      Copy : Element_Array := A;
   begin
      Select_Kth (Copy, K);
      return Copy (Copy'First + (K - 1));
   end Select_Kth_Copy;

   function Median (A : in out Element_Array) return Integer is
      N : constant Natural := A'Length;
      K : Positive;
   begin
      if N = 0 then
         raise Invalid_Argument with "empty array";
      end if;
      if N > Max_N then
         raise Invalid_Argument with "array length exceeds Max_N";
      end if;

      --  Odd n: K = (n + 1) / 2. Even n: lower middle K = n / 2.
      if N rem 2 = 1 then
         K := (N + 1) / 2;
      else
         K := N / 2;
      end if;

      Select_Kth (A, K);
      return A (A'First + (K - 1));
   end Median;

end Introselect;
