--  Merge_Sort body — top-down recursive split, stable merge via temp.

pragma Ada_2022;

package body Merge_Sort
  with SPARK_Mode => Off
is

   procedure Check_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument
           with "array length exceeds Max_N";
      end if;
   end Check_Bounds;

   --  Merge sorted runs A(Lo .. Mid) and A(Mid+1 .. Hi) into Temp, then
   --  copy back. Prefer Left when Left <= Right so equal keys keep order.
   procedure Merge
     (A    : in out Element_Array;
      Temp : in out Element_Array;
      Lo, Mid, Hi : Natural)
   is
      I : Natural := Lo;
      J : Natural := Mid + 1;
      K : Natural := Lo;
   begin
      while I <= Mid and then J <= Hi loop
         if A (I) <= A (J) then
            Temp (K) := A (I);
            I := I + 1;
         else
            Temp (K) := A (J);
            J := J + 1;
         end if;
         K := K + 1;
      end loop;

      while I <= Mid loop
         Temp (K) := A (I);
         I := I + 1;
         K := K + 1;
      end loop;

      while J <= Hi loop
         Temp (K) := A (J);
         J := J + 1;
         K := K + 1;
      end loop;

      for X in Lo .. Hi loop
         A (X) := Temp (X);
      end loop;
   end Merge;

   procedure Sort_Range
     (A    : in out Element_Array;
      Temp : in out Element_Array;
      Lo, Hi : Natural)
   is
      Mid : Natural;
   begin
      if Lo >= Hi then
         return;
      end if;

      Mid := Lo + (Hi - Lo) / 2;
      Sort_Range (A, Temp, Lo, Mid);
      Sort_Range (A, Temp, Mid + 1, Hi);
      Merge (A, Temp, Lo, Mid, Hi);
   end Sort_Range;

   procedure Sort (A : in out Element_Array) is
   begin
      Check_Bounds (A);

      if A'Length <= 1 then
         return;
      end if;

      declare
         Temp : Element_Array (A'Range);
      begin
         Sort_Range (A, Temp, A'First, A'Last);
      end;
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

end Merge_Sort;
