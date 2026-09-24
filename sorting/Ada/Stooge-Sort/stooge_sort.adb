--  Stooge_Sort body — recursive 2/3–2/3–2/3 on A(I .. J).

pragma Ada_2022;

package body Stooge_Sort
  with SPARK_Mode => Off
is

   procedure Check_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument
           with "array length exceeds Max_N";
      end if;
   end Check_Bounds;

   procedure Stooge_Range (A : in out Element_Array; I, J : Natural) is
      L   : Natural;
      T   : Natural;
      Tmp : Integer;
   begin
      if A (I) > A (J) then
         Tmp := A (I);
         A (I) := A (J);
         A (J) := Tmp;
      end if;

      L := J - I + 1;
      if L > 2 then
         T := L / 3;
         Stooge_Range (A, I, J - T);
         Stooge_Range (A, I + T, J);
         Stooge_Range (A, I, J - T);
      end if;
   end Stooge_Range;

   procedure Sort (A : in out Element_Array) is
   begin
      Check_Bounds (A);

      if A'Length <= 1 then
         return;
      end if;

      Stooge_Range (A, A'First, A'Last);
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

end Stooge_Sort;
