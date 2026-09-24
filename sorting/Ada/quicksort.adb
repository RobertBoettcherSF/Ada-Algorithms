--  Quicksort body — median-of-three pivot + Hoare partition.

pragma Ada_2022;

package body Quicksort
  with SPARK_Mode => Off
is

   procedure Check_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument
           with "array length exceeds Max_N";
      end if;
   end Check_Bounds;

   procedure Swap (A : in out Element_Array; I, J : Natural) is
      T : Integer;
   begin
      if I = J then
         return;
      end if;
      T := A (I);
      A (I) := A (J);
      A (J) := T;
   end Swap;

   ---------------------------------------------------------------------------
   -- Median-of-three + Hoare partition on Lo .. Hi
   -- Returns an index P such that every A(Lo .. P) ≤ every A(P+1 .. Hi)
   -- (classic Hoare; pivot value itself may sit on either side).
   ---------------------------------------------------------------------------

   procedure Median_Of_Three
     (A : in out Element_Array; Lo, Hi : Natural)
   is
      Mid : constant Natural := Lo + (Hi - Lo) / 2;
   begin
      --  Order A(Lo), A(Mid), A(Hi) so A(Mid) is the median; then swap
      --  median to Lo for a stable pivot value during Hoare scans.
      if A (Mid) < A (Lo) then
         Swap (A, Lo, Mid);
      end if;
      if A (Hi) < A (Lo) then
         Swap (A, Lo, Hi);
      end if;
      if A (Hi) < A (Mid) then
         Swap (A, Mid, Hi);
      end if;
      --  Now A(Lo) ≤ A(Mid) ≤ A(Hi); place median at Lo.
      Swap (A, Lo, Mid);
   end Median_Of_Three;

   function Partition_Hoare
     (A : in out Element_Array; Lo, Hi : Natural) return Natural
   is
      Pivot : Integer;
      I     : Integer;
      J     : Integer;
   begin
      Median_Of_Three (A, Lo, Hi);
      Pivot := A (Lo);
      I := Integer (Lo) - 1;
      J := Integer (Hi) + 1;

      loop
         loop
            I := I + 1;
            exit when A (I) >= Pivot;
         end loop;
         loop
            J := J - 1;
            exit when A (J) <= Pivot;
         end loop;
         exit when I >= J;
         Swap (A, Natural (I), Natural (J));
      end loop;
      return Natural (J);
   end Partition_Hoare;

   ---------------------------------------------------------------------------
   -- Recursive quicksort on inclusive Lo .. Hi
   ---------------------------------------------------------------------------

   procedure Quick_Sort_Rec
     (A : in out Element_Array; Lo, Hi : Natural)
   is
      N : Natural;
      P : Natural;
   begin
      if Hi < Lo then
         return;
      end if;

      N := Hi - Lo + 1;
      if N <= 1 then
         return;
      end if;

      P := Partition_Hoare (A, Lo, Hi);
      --  Hoare: recurse on Lo .. P and P+1 .. Hi.
      if P > Lo then
         Quick_Sort_Rec (A, Lo, P);
      end if;
      if P < Hi then
         Quick_Sort_Rec (A, P + 1, Hi);
      end if;
   end Quick_Sort_Rec;

   ---------------------------------------------------------------------------
   -- Public API
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array) is
   begin
      Check_Bounds (A);
      if A'Length <= 1 then
         return;
      end if;
      Quick_Sort_Rec (A, A'First, A'Last);
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

end Quicksort;
