--  Comb_Sort body — bubble sort with shrinking gap (shrink ≈ 1.3).
--  gap := max(1, gap * 10 / 13); continue until gap = 1 and no swaps.

pragma Ada_2022;

package body Comb_Sort
  with SPARK_Mode => Off
is

   --  Shrink factor k ≈ 1.3: floor(gap / 1.3) = floor(gap * 10 / 13).
   Shrink_Num : constant := 10;
   Shrink_Den : constant := 13;

   procedure Check_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument
           with "array length exceeds Max_N";
      end if;
   end Check_Bounds;

   procedure Sort (A : in out Element_Array) is
      N       : constant Natural := A'Length;
      Gap     : Natural;
      Swapped : Boolean;
      Next    : Natural;

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

      --  Gap starts at n; first pass uses floor(n / 1.3).
      Gap := N;
      loop
         --  Shrink: gap := max(1, floor(gap / 1.3)).
         Next := (Gap * Shrink_Num) / Shrink_Den;
         if Next < 1 then
            Gap := 1;
         else
            Gap := Next;
         end if;

         Swapped := False;
         --  One comb pass: compare A(i) with A(i+gap).
         for I in A'First .. A'Last - Gap loop
            if A (I) > A (I + Gap) then
               Swap (I, I + Gap);
               Swapped := True;
            end if;
         end loop;

         --  Done when the final bubble pass (gap = 1) makes no swaps.
         exit when Gap = 1 and then not Swapped;
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

end Comb_Sort;
