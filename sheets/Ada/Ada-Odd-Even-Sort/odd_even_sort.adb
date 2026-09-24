--  Odd_Even_Sort body — sequential odd–even / brick sort.
--  Wikipedia 0-based convention: odd-indexed pairs, then even-indexed
--  pairs, repeating until a full cycle performs no swaps.

pragma Ada_2022;

package body Odd_Even_Sort
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
      N : constant Natural := A'Length;

      procedure Swap (I, J : Natural) is
         T : constant Integer := A (I);
      begin
         A (I) := A (J);
         A (J) := T;
      end Swap;

      Swapped : Boolean;
      Idx     : Natural;
   begin
      Check_Bounds (A);

      if N <= 1 then
         return;
      end if;

      loop
         Swapped := False;

         --  Odd phase (Wikipedia 0-based): offsets 1, 3, 5, …
         Idx := A'First + 1;
         while Idx < A'Last loop
            if A (Idx) > A (Idx + 1) then
               Swap (Idx, Idx + 1);
               Swapped := True;
            end if;
            exit when A'Last - Idx < 2;
            Idx := Idx + 2;
         end loop;

         --  Even phase: offsets 0, 2, 4, …
         Idx := A'First;
         while Idx < A'Last loop
            if A (Idx) > A (Idx + 1) then
               Swap (Idx, Idx + 1);
               Swapped := True;
            end if;
            exit when A'Last - Idx < 2;
            Idx := Idx + 2;
         end loop;

         exit when not Swapped;
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

end Odd_Even_Sort;
