--  Introsort body — quicksort + depth-limited heapsort + insertion sort.

pragma Ada_2022;

package body Introsort
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

   ---------------------------------------------------------------------------
   -- Insertion sort on inclusive subrange Lo .. Hi
   ---------------------------------------------------------------------------

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

   ---------------------------------------------------------------------------
   -- Heapsort on inclusive subrange Lo .. Hi (First-relative to Lo)
   ---------------------------------------------------------------------------

   function Left_Child_Of (Lo, I : Natural) return Natural is
   begin
      --  Logical 0-based relative to Lo: Left = Lo + 2*(I - Lo) + 1
      return Lo + 2 * (I - Lo) + 1;
   end Left_Child_Of;

   procedure Sift_Down_Range
     (A         : in out Element_Array;
      Lo        : Natural;
      Root      : Natural;
      Heap_Last : Natural)
   is
      R     : Natural := Root;
      Child : Natural;
   begin
      loop
         Child := Left_Child_Of (Lo, R);
         exit when Child > Heap_Last;

         if Child < Heap_Last and then A (Child) < A (Child + 1) then
            Child := Child + 1;
         end if;

         if A (R) < A (Child) then
            Swap (A, R, Child);
            R := Child;
         else
            return;
         end if;
      end loop;
   end Sift_Down_Range;

   procedure Heapsort_Range
     (A : in out Element_Array; Lo, Hi : Natural)
   is
      Len       : Natural;
      Start     : Natural;
      Heap_Last : Natural;
   begin
      if Hi <= Lo then
         return;
      end if;

      Len := Hi - Lo + 1;
      if Len <= 1 then
         return;
      end if;

      --  Floyd bottom-up heapify on Lo .. Hi.
      Start := Lo + (Len - 2) / 2;
      loop
         Sift_Down_Range (A, Lo, Start, Hi);
         exit when Start = Lo;
         Start := Start - 1;
      end loop;

      Heap_Last := Hi;
      while Heap_Last > Lo loop
         Swap (A, Lo, Heap_Last);
         Heap_Last := Heap_Last - 1;
         Sift_Down_Range (A, Lo, Lo, Heap_Last);
      end loop;
   end Heapsort_Range;

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
   -- Recursive introsort on inclusive Lo .. Hi
   ---------------------------------------------------------------------------

   procedure Intro_Sort_Rec
     (A : in out Element_Array; Lo, Hi : Natural; Depth : Natural)
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

      if N <= Insertion_Threshold then
         Insertion_Sort_Range (A, Lo, Hi);
      elsif Depth = 0 then
         Heapsort_Range (A, Lo, Hi);
      else
         P := Partition_Hoare (A, Lo, Hi);
         --  Hoare: recurse on Lo .. P and P+1 .. Hi (both nonempty when N>1).
         if P > Lo then
            Intro_Sort_Rec (A, Lo, P, Depth - 1);
         end if;
         if P < Hi then
            Intro_Sort_Rec (A, P + 1, Hi, Depth - 1);
         end if;
      end if;
   end Intro_Sort_Rec;

   ---------------------------------------------------------------------------
   -- Public API
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array) is
      Depth : Natural;
   begin
      Check_Bounds (A);
      if A'Length <= 1 then
         return;
      end if;

      --  maxdepth ← 2 × ⌊log₂ n⌋  (Musser / Wikipedia / libstdc++)
      Depth := 2 * Floor_Log2 (A'Length);
      Intro_Sort_Rec (A, A'First, A'Last, Depth);
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

end Introsort;
