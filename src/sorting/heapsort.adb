--  Heapsort body — Floyd heapify + sift-down extract-max.

pragma Ada_2022;

package body Heapsort
  with SPARK_Mode => Off
is

   procedure Check_Length (A : Element_Array) is
   begin
      if A'Length > Max_Length then
         raise Invalid_Argument
           with "array length exceeds Max_Length";
      end if;
   end Check_Length;

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

   --  Absolute left-child index using First-relative (logical 0-based) math:
   --  Left = First + 2*(I - First) + 1
   function Left_Child (A : Element_Array; I : Natural) return Natural is
   begin
      return A'First + 2 * (I - A'First) + 1;
   end Left_Child;

   procedure Sift_Down
     (A         : in out Element_Array;
      Root      : Natural;
      Heap_Last : Natural)
   is
      R     : Natural := Root;
      Child : Natural;
   begin
      --  While R has at least a left child inside the heap.
      loop
         Child := Left_Child (A, R);
         exit when Child > Heap_Last;

         --  Prefer the greater of the two children when both exist.
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
   end Sift_Down;

   procedure Heapify (A : in out Element_Array) is
      Start : Natural;
   begin
      Check_Length (A);
      if A'Length <= 1 then
         return;
      end if;

      --  Parent of last element (logical 0-based):
      --  Parent_Abs = First + ((Last - First) - 1) / 2
      --             = First + (Length - 2) / 2
      Start := A'First + (A'Length - 2) / 2;

      loop
         Sift_Down (A, Start, A'Last);
         exit when Start = A'First;
         Start := Start - 1;
      end loop;
   end Heapify;

   procedure Sort (A : in out Element_Array) is
      Heap_Last : Natural;
   begin
      Check_Length (A);
      if A'Length <= 1 then
         return;
      end if;

      Heapify (A);

      --  Extract-max: move root to the growing sorted suffix.
      Heap_Last := A'Last;
      while Heap_Last > A'First loop
         Swap (A, A'First, Heap_Last);
         Heap_Last := Heap_Last - 1;
         Sift_Down (A, A'First, Heap_Last);
      end loop;
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

end Heapsort;
