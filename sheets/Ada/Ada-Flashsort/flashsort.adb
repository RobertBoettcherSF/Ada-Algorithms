--  Flashsort body — Neubert in-place histogram / cycle-following bucket sort.

pragma Ada_2022;

package body Flashsort
  with SPARK_Mode => Off
is

   procedure Check_Length (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument
           with "array length exceeds Max_N";
      end if;
   end Check_Length;

   --  Insertion sort on inclusive subrange Lo .. Hi.
   procedure Insertion_Sort_Range
     (A : in out Element_Array; Lo, Hi : Natural)
   is
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
   end Insertion_Sort_Range;

   --  m = max(2, n / 10). For n >= 2 this is automatically <= n, so the
   --  interpolation formula has at least two classes and at most one per item.
   function Class_Count (N : Natural) return Positive is
      M : constant Natural := N / Class_Divisor;
   begin
      if M < 2 then
         return 2;
      end if;
      return M;
   end Class_Count;

   procedure Sort (A : in out Element_Array) is
      N       : constant Natural := A'Length;
      Min_Val : Integer;
      Max_Val : Integer;
      M       : Positive;
   begin
      Check_Length (A);

      if N <= 1 then
         return;
      end if;

      Min_Val := A (A'First);
      Max_Val := A (A'First);
      for I in A'First + 1 .. A'Last loop
         if A (I) < Min_Val then
            Min_Val := A (I);
         elsif A (I) > Max_Val then
            Max_Val := A (I);
         end if;
      end loop;

      --  All equal: already sorted; the classification denominator would
      --  be zero.
      if Min_Val = Max_Val then
         return;
      end if;

      M := Class_Count (N);

      declare
         subtype Class_Index is Positive range 1 .. M;
         type Border_Array is array (Class_Index) of Natural;
         L     : Border_Array := [others => 0];
         Upper : Border_Array;

         --  K = 1 + floor((m-1)*(X-min)/(max-min)). Long_Long_Integer
         --  keeps (m-1)*(X-min) from overflowing 32-bit Integer (e.g.
         --  Integer'First .. Integer'Last with m ~ n/10).
         function Class_Of (X : Integer) return Class_Index is
            Num : constant Long_Long_Integer :=
              Long_Long_Integer (M - 1)
              * (Long_Long_Integer (X) - Long_Long_Integer (Min_Val));
            Den : constant Long_Long_Integer :=
              Long_Long_Integer (Max_Val) - Long_Long_Integer (Min_Val);
         begin
            return Class_Index (1 + Integer (Num / Den));
         end Class_Of;

         --  Convert a 1-based Neubert index to an A index (A'First-relative).
         function Index_1 (J : Natural) return Natural is
         begin
            return A'First + J - 1;
         end Index_1;

         I, J     : Natural;
         B        : Class_Index;
         T, Hold  : Integer;
         Lo_1     : Natural;
         Hi_1     : Natural;
      begin
         --  Histogram: count elements per class.
         for Idx in A'Range loop
            B := Class_Of (A (Idx));
            L (B) := L (B) + 1;
         end loop;

         --  Prefix-sum: L(K) is the inclusive 1-based upper border of class K
         --  (number of elements in classes 1 .. K). L(M) = n.
         for K in 2 .. M loop
            L (K) := L (K) + L (K - 1);
         end loop;
         Upper := L;

         --  In-place permutation by cycle-following (Neubert / Wikipedia).
         --  Classified items of class K occupy a suffix growing downward from
         --  Upper(K). With every position < I already classified, A at
         --  1-based I is unclassified iff I <= L(B) for B = class of that item.
         I := 1;
         while I <= N loop
            B := Class_Of (A (Index_1 (I)));
            if I <= L (B) then
               T := A (Index_1 (I));
               loop
                  B := Class_Of (T);
                  J := L (B);
                  Hold := A (Index_1 (J));
                  A (Index_1 (J)) := T;
                  T := Hold;
                  L (B) := L (B) - 1;
                  exit when J = I;
               end loop;
            end if;
            I := I + 1;
         end loop;

         --  Insertion-sort within each class (empty classes skipped).
         for K in 1 .. M loop
            Lo_1 := (if K = 1 then 1 else Upper (K - 1) + 1);
            Hi_1 := Upper (K);
            if Hi_1 >= Lo_1 then
               Insertion_Sort_Range (A, Index_1 (Lo_1), Index_1 (Hi_1));
            end if;
         end loop;
      end;
   end Sort;

   function Is_Sorted (A : Element_Array) return Boolean is
   begin
      if A'Length <= 1 then
         return True;
      end if;
      for I in A'First + 1 .. A'Last loop
         if A (I - 1) > A (I) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted;

end Flashsort;
