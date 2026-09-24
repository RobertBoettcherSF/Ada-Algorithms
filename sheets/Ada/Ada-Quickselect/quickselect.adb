--  Quickselect body — in-place Quickselect with median-of-three pivot
--  and Lomuto partition (iterative; average O(n), worst O(n²)).

pragma Ada_2022;

package body Quickselect
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

   --  Median-of-three: place the median of A(Lo), A(Mid), A(Hi) at Hi
   --  so Lomuto can use A(Hi) as the pivot (deterministic, random-free).
   procedure Median_Of_Three_To_Hi
     (A : in out Element_Array; Lo, Hi : Natural)
   is
      Mid : constant Natural := Lo + (Hi - Lo) / 2;
   begin
      --  Order Lo, Mid, Hi so A(Lo) ≤ A(Mid) ≤ A(Hi), then leave median at Hi.
      if A (Mid) < A (Lo) then
         Swap (A, Lo, Mid);
      end if;
      if A (Hi) < A (Lo) then
         Swap (A, Lo, Hi);
      end if;
      if A (Hi) < A (Mid) then
         Swap (A, Mid, Hi);
      end if;
      --  A(Hi) is now the median of the three.
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

   procedure Select_Kth (A : in out Element_Array; K : Positive) is
      --  Target absolute index for the K-th smallest (1-based rank).
      Target : Natural;
      Lo     : Natural;
      Hi     : Natural;
      P      : Natural;
   begin
      Check_Args (A, K);

      Target := A'First + (K - 1);
      Lo     := A'First;
      Hi     := A'Last;

      --  Iterative Quickselect: partition and shrink to the side that
      --  contains Target. Average O(n) comparisons; worst O(n²).
      loop
         if Lo = Hi then
            return;
         end if;

         if Hi - Lo >= 2 then
            Median_Of_Three_To_Hi (A, Lo, Hi);
         end if;

         P := Partition_Lomuto (A, Lo, Hi);

         if P = Target then
            return;
         elsif P > Target then
            Hi := P - 1;
         else
            Lo := P + 1;
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

end Quickselect;
