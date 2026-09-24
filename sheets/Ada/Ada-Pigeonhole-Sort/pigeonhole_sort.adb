--  Pigeonhole_Sort body — min/max, allocate holes, stable scatter, read back.

pragma Ada_2022;

package body Pigeonhole_Sort
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
         --  Counts per hole, then reused as write cursors (prefix).
         subtype Hole_Index is Natural range 0 .. Natural (Range_Size - 1);
         Counts : array (Hole_Index) of Natural := (others => 0);
         Work   : Element_Array (A'Range);
         Total  : Natural := 0;
         H      : Hole_Index;
         Dest   : Natural;
      begin
         --  Count how many items fall into each pigeonhole.
         for I in A'Range loop
            H := Hole_Index (Long_Long_Integer (A (I))
                             - Long_Long_Integer (Min_Val));
            Counts (H) := Counts (H) + 1;
         end loop;

         --  Convert counts into starting offsets (exclusive prefix).
         --  After this, Counts (H) is the next free slot index (0-based
         --  offset from A'First) for hole H in Work.
         for H in Counts'Range loop
            declare
               C : constant Natural := Counts (H);
            begin
               Counts (H) := Total;
               Total := Total + C;
            end;
         end loop;

         --  Stable scatter: place each item into its hole segment left-to-right.
         for I in A'Range loop
            H := Hole_Index (Long_Long_Integer (A (I))
                             - Long_Long_Integer (Min_Val));
            Dest := A'First + Counts (H);
            Work (Dest) := A (I);
            Counts (H) := Counts (H) + 1;
         end loop;

         --  Read contiguous hole segments back into A (already in key order).
         A := Work;
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

end Pigeonhole_Sort;
