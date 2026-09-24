--  Selection_Sort body — classic min-selection (and max for descending).

pragma Ada_2022;

package body Selection_Sort
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

   procedure Sort (A : in out Element_Array) is
      Min_Index : Natural;
   begin
      Check_Length (A);
      if A'Length <= 1 then
         return;
      end if;

      --  For each prefix position I, place the minimum of A(I .. Last).
      for I in A'First .. A'Last - 1 loop
         Min_Index := I;
         for J in I + 1 .. A'Last loop
            if A (J) < A (Min_Index) then
               Min_Index := J;
            end if;
         end loop;
         Swap (A, I, Min_Index);
      end loop;
   end Sort;

   procedure Sort_Descending (A : in out Element_Array) is
      Max_Index : Natural;
   begin
      Check_Length (A);
      if A'Length <= 1 then
         return;
      end if;

      for I in A'First .. A'Last - 1 loop
         Max_Index := I;
         for J in I + 1 .. A'Last loop
            if A (J) > A (Max_Index) then
               Max_Index := J;
            end if;
         end loop;
         Swap (A, I, Max_Index);
      end loop;
   end Sort_Descending;

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

   function Is_Sorted_Descending (A : Element_Array) return Boolean is
   begin
      if A'Length <= 1 then
         return True;
      end if;
      for I in A'First + 1 .. A'Last loop
         if A (I - 1) < A (I) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted_Descending;

end Selection_Sort;
