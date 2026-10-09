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
      --  Logical 0-based relative to Lo: Left = Lo + 2*(I - Lo) + 1.
      --  Long_Integer so Lo near Natural'Last does not overflow.
      Off : constant Long_Integer :=
        2 * (Long_Integer (I) - Long_Integer (Lo)) + 1;
   begin
      return Natural (Long_Integer (Lo) + Off);
   end Left_Child_Of;

   function Has_Left (Lo, Heap_Last, I : Natural) return Boolean is
      --  I has a left child inside Lo .. Heap_Last iff
      --  I - Lo <= (Heap_Last - Lo - 1) / 2. Checked before Left_Child.
   begin
      if Heap_Last <= Lo then
         return False;
      end if;
      return Long_Integer (I) - Long_Integer (Lo)
        <= (Long_Integer (Heap_Last) - Long_Integer (Lo) - 1) / 2;
   end Has_Left;

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
         exit when not Has_Left (Lo, Heap_Last, R);
         Child := Left_Child_Of (Lo, R);

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
      Start := Natural (Long_Integer (Lo)
                        + (Long_Integer (Len) - 2) / 2);
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
      Mid : constant Natural :=
        Natural (Long_Integer (Lo)
                 + (Long_Integer (Hi) - Long_Integer (Lo)) / 2);
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
   begin
      Median_Of_Three (A, Lo, Hi);
      Pivot := A (Lo);
      --  Sentinels just outside the slice; Long_Integer so Lo = 0 and
      --  Hi = Natural'Last are legal (Natural'Last + 1 would overflow).
      declare
         LI : Long_Integer := Long_Integer (Lo) - 1;
         LJ : Long_Integer := Long_Integer (Hi) + 1;
      begin
         loop
            loop
               LI := LI + 1;
               exit when A (Natural (LI)) >= Pivot;
            end loop;
            loop
               LJ := LJ - 1;
               exit when A (Natural (LJ)) <= Pivot;
            end loop;
            exit when LI >= LJ;
            Swap (A, Natural (LI), Natural (LJ));
         end loop;
         return Natural (LJ);
      end;
   end Partition_Hoare;

   ---------------------------------------------------------------------------
   -- Recursive introsort on inclusive Lo .. Hi
   ---------------------------------------------------------------------------

   procedure Intro_Sort_Rec
     (A     : in out Element_Array;
      Lo, Hi : Natural;
      Depth : Natural;
      Heaps : in out Natural)
   is
      N : Natural;
      P : Natural;
   begin
      if Hi < Lo then
         return;
      end if;

      N := Natural (Long_Integer (Hi) - Long_Integer (Lo) + 1);
      if N <= 1 then
         return;
      end if;

      if N <= Insertion_Threshold then
         Insertion_Sort_Range (A, Lo, Hi);
      elsif Depth = 0 then
         Heapsort_Range (A, Lo, Hi);
         Heaps := Heaps + 1;
      else
         P := Partition_Hoare (A, Lo, Hi);
         --  Hoare: recurse on Lo .. P and P+1 .. Hi (both nonempty when N>1).
         if P > Lo then
            Intro_Sort_Rec (A, Lo, P, Depth - 1, Heaps);
         end if;
         if P < Hi then
            Intro_Sort_Rec (A, P + 1, Hi, Depth - 1, Heaps);
         end if;
      end if;
   end Intro_Sort_Rec;

   ---------------------------------------------------------------------------
   -- Public API
   ---------------------------------------------------------------------------

   function Depth_Budget (N : Natural) return Natural is
   begin
      if N = 0 then
         return 0;
      end if;
      return 2 * Floor_Log2 (N);
   end Depth_Budget;

   procedure Sort_Traced
     (A              : in out Element_Array;
      Max_Depth      : Natural;
      Heap_Fallbacks : out Natural)
   is
   begin
      Check_Bounds (A);
      Heap_Fallbacks := 0;
      if A'Length <= 1 then
         return;
      end if;
      Intro_Sort_Rec (A, A'First, A'Last, Max_Depth, Heap_Fallbacks);
   end Sort_Traced;

   procedure Sort (A : in out Element_Array) is
      Heap_Fallbacks : Natural;
   begin
      Sort_Traced (A, Depth_Budget (A'Length), Heap_Fallbacks);
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
