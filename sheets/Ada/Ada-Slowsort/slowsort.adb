--  Slowsort body — multiply-and-surrender recursion on A(I .. J).

pragma Ada_2022;

package body Slowsort
  with SPARK_Mode => Off
is

   procedure Check_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument
           with "array length exceeds Max_N";
      end if;
   end Check_Bounds;

   procedure Slowsort_Range (A : in out Element_Array; I, J : Natural) is
      M   : Natural;
      Tmp : Integer;
   begin
      if I >= J then
         return;
      end if;

      M := (I + J) / 2;
      Slowsort_Range (A, I, M);
      Slowsort_Range (A, M + 1, J);

      if A (M) > A (J) then
         Tmp := A (M);
         A (M) := A (J);
         A (J) := Tmp;
      end if;

      Slowsort_Range (A, I, J - 1);
   end Slowsort_Range;

   procedure Sort (A : in out Element_Array) is
   begin
      Check_Bounds (A);

      if A'Length <= 1 then
         return;
      end if;

      Slowsort_Range (A, A'First, A'Last);
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

end Slowsort;
