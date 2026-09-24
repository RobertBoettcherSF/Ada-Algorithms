--  Counting_Sort body — count, prefix sums, stable right-to-left place.

pragma Ada_2022;

package body Counting_Sort
  with SPARK_Mode => Off
is

   procedure Check_Length (A : Element_Array) is
   begin
      if A'Length > Max_Length then
         raise Invalid_Argument
           with "array length exceeds Max_Length";
      end if;
   end Check_Length;

   procedure Sort (A : in out Element_Array) is
      Min_Val, Max_Val : Integer;
      Range_Size       : Long_Long_Integer;
   begin
      Check_Length (A);

      if A'Length <= 1 then
         return;
      end if;

      Min_Val := A (A'First);
      Max_Val := A (A'First);
      for I in A'First + 1 .. A'Last loop
         if A (I) < Min_Val then
            Min_Val := A (I);
         elsif A (I) > Max_Val then
            Max_Val := A (I);
         end if;
      end loop;

      --  Use Long_Long_Integer so Integer'First .. Integer'Last cannot wrap.
      Range_Size :=
        Long_Long_Integer (Max_Val) - Long_Long_Integer (Min_Val) + 1;

      if Range_Size > Long_Long_Integer (Max_Range) then
         raise Invalid_Argument
           with "key range exceeds Max_Range";
      end if;

      declare
         subtype Key_Index is Natural range 0 .. Natural (Range_Size - 1);
         Count  : array (Key_Index) of Natural := (others => 0);
         Output : Element_Array (A'Range);
         K      : Key_Index;
         Dest   : Natural;
         Running : Natural := 0;
         C       : Natural;
      begin
         --  Histogram: occurrences of each key.
         for I in A'Range loop
            K := Key_Index (Long_Long_Integer (A (I))
                            - Long_Long_Integer (Min_Val));
            Count (K) := Count (K) + 1;
         end loop;

         --  Inclusive prefix sums: Count (K) becomes the number of elements
         --  with key <= K (0-based exclusive end offset from A'First).
         for K in Count'Range loop
            C := Count (K);
            Running := Running + C;
            Count (K) := Running;
         end loop;

         --  Stable placement: scan right-to-left so earlier equals keep
         --  their relative order (Wikipedia / CLRS form).
         for I in reverse A'Range loop
            K := Key_Index (Long_Long_Integer (A (I))
                            - Long_Long_Integer (Min_Val));
            Count (K) := Count (K) - 1;
            Dest := A'First + Count (K);
            Output (Dest) := A (I);
         end loop;

         A := Output;
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

end Counting_Sort;
