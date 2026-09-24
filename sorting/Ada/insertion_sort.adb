--  Insertion_Sort body — classic stable in-place insertion sort.

pragma Ada_2022;

package body Insertion_Sort
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
      N   : constant Natural := A'Length;
      Key : Integer;
      J   : Natural;
   begin
      Check_Bounds (A);

      if N <= 1 then
         return;
      end if;

      --  Classic shifting form (Wikipedia): take A(I), shift strictly
      --  larger predecessors right with Key < A(J-1) (i.e. A(J-1) > Key),
      --  then insert. Strict `<` / `>` keeps equal-key order (stable).
      for I in A'First + 1 .. A'Last loop
         Key := A (I);
         J   := I;
         while J > A'First and then Key < A (J - 1) loop
            A (J) := A (J - 1);
            J     := J - 1;
         end loop;
         A (J) := Key;
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

end Insertion_Sort;
