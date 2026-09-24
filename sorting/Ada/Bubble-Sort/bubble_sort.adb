--  Bubble_Sort body — classic adjacent bubble passes with last-swap
--  bound shrinkage and early exit when a pass makes no swaps.

pragma Ada_2022;

package body Bubble_Sort
  with SPARK_Mode => Off
is

   procedure Check_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument
           with "array length exceeds Max_N";
      end if;
   end Check_Bounds;

   procedure Sort (A : in out Element_Array) is
      N         : constant Natural := A'Length;
      Bound     : Natural;
      New_Bound : Natural;
      Swapped   : Boolean;

      procedure Swap (I, J : Natural) is
         T : constant Integer := A (I);
      begin
         A (I) := A (J);
         A (J) := T;
      end Swap;
   begin
      Check_Bounds (A);

      if N <= 1 then
         return;
      end if;

      --  Bound is the last index of the still-unsorted prefix.
      Bound := A'Last;

      loop
         exit when Bound <= A'First;

         Swapped   := False;
         New_Bound := A'First;

         --  One forward pass: bubble large keys toward Bound.
         for I in A'First .. Bound - 1 loop
            if A (I) > A (I + 1) then
               Swap (I, I + 1);
               Swapped   := True;
               New_Bound := I;
            end if;
         end loop;

         --  Early exit: a clean pass means the array is sorted.
         exit when not Swapped;

         --  Everything after the last swap is already in final place.
         Bound := New_Bound;
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

end Bubble_Sort;
