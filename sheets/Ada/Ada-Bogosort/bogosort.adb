--  Bogosort body — deterministic next-permutation generate-and-test.

pragma Ada_2022;

package body Bogosort
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
      Tmp : constant Integer := A (I);
   begin
      A (I) := A (J);
      A (J) := Tmp;
   end Swap;

   procedure Reverse_Range (A : in out Element_Array; Lo, Hi : Natural) is
      I : Natural := Lo;
      J : Natural := Hi;
   begin
      while I < J loop
         Swap (A, I, J);
         I := I + 1;
         J := J - 1;
      end loop;
   end Reverse_Range;

   --  Advance A to the next lexicographic permutation of its multiset.
   --  When A is already the last permutation, wrap to the first (fully
   --  reverse the array) and return False; otherwise return True.
   function Next_Permutation (A : in out Element_Array) return Boolean is
      I, J : Natural;
   begin
      if A'Length <= 1 then
         return False;
      end if;

      --  Find rightmost ascent: largest I with A(I) < A(I+1).
      I := A'Last - 1;
      while I > A'First and then A (I) >= A (I + 1) loop
         I := I - 1;
      end loop;

      if A (I) >= A (I + 1) then
         --  Entirely nonincreasing: last permutation → wrap to first.
         Reverse_Range (A, A'First, A'Last);
         return False;
      end if;

      --  Find rightmost successor of A(I) to its right.
      J := A'Last;
      while A (J) <= A (I) loop
         J := J - 1;
      end loop;

      Swap (A, I, J);
      Reverse_Range (A, I + 1, A'Last);
      return True;
   end Next_Permutation;

   procedure Sort (A : in out Element_Array) is
      Dummy : Boolean;
      pragma Unreferenced (Dummy);
   begin
      Check_Bounds (A);

      if A'Length <= 1 then
         return;
      end if;

      while not Is_Sorted (A) loop
         Dummy := Next_Permutation (A);
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

end Bogosort;
