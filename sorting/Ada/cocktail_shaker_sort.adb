--  Cocktail_Shaker_Sort body — bidirectional bubble sort with lo..hi
--  bounds. Forward pass bubbles max to Hi; backward pass bubbles min
--  to Lo. Exit when a pass makes no swaps.

pragma Ada_2022;

package body Cocktail_Shaker_Sort
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
      N       : constant Natural := A'Length;
      Lo      : Natural;
      Hi      : Natural;
      Swapped : Boolean;

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

      Lo := A'First;
      Hi := A'Last;

      --  Alternate forward (max to Hi) and backward (min to Lo) until a
      --  clean pass or the active window collapses.
      loop
         exit when Lo >= Hi;

         --  Forward pass: bubble largest toward Hi.
         Swapped := False;
         for I in Lo .. Hi - 1 loop
            if A (I) > A (I + 1) then
               Swap (I, I + 1);
               Swapped := True;
            end if;
         end loop;
         exit when not Swapped;
         Hi := Hi - 1;

         exit when Lo >= Hi;

         --  Backward pass: bubble smallest toward Lo.
         Swapped := False;
         for I in reverse Lo .. Hi - 1 loop
            if A (I) > A (I + 1) then
               Swap (I, I + 1);
               Swapped := True;
            end if;
         end loop;
         exit when not Swapped;
         Lo := Lo + 1;
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

end Cocktail_Shaker_Sort;
