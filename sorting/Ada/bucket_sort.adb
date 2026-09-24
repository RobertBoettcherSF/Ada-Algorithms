--  Bucket_Sort body — scatter into k buckets, insertion-sort, gather.

pragma Ada_2022;

package body Bucket_Sort
  with SPARK_Mode => Off
is

   procedure Check_Length (A : Element_Array) is
   begin
      if A'Length > Max_Length then
         raise Invalid_Argument
           with "array length exceeds Max_Length";
      end if;
   end Check_Length;

   --  Stable insertion sort on a contiguous segment of Work.
   procedure Insertion_Sort_Segment
     (Work  : in out Element_Array;
      First : Natural;
      Last  : Natural)
   is
   begin
      if Last <= First then
         return;
      end if;
      for I in First + 1 .. Last loop
         declare
            Key : constant Integer := Work (I);
            J   : Integer := Integer (I) - 1;
         begin
            while J >= Integer (First) and then Work (J) > Key loop
               Work (J + 1) := Work (J);
               J := J - 1;
            end loop;
            Work (J + 1) := Key;
         end;
      end loop;
   end Insertion_Sort_Segment;

   procedure Sort (A : in out Element_Array) is
      N                : constant Natural := A'Length;
      Min_Val, Max_Val : Integer;
      K                : Positive;
   begin
      Check_Length (A);

      if N <= 1 then
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

      --  All equal → already sorted.
      if Min_Val = Max_Val then
         return;
      end if;

      if N <= Max_Buckets then
         K := N;
      else
         K := Max_Buckets;
      end if;

      declare
         subtype Bucket_Index is Natural range 0 .. K - 1;
         Counts : array (Bucket_Index) of Natural := [others => 0];
         Starts : array (Bucket_Index) of Natural;
         Work   : Element_Array (A'Range);
         B      : Bucket_Index;
         Dest   : Natural;
         Span   : constant Long_Long_Integer :=
           Long_Long_Integer (Max_Val) - Long_Long_Integer (Min_Val);
         --  Span >= 1 because Min_Val /= Max_Val.
         Total  : Natural := 0;
         Seg_First, Seg_Last : Natural;

         function Bucket_Of (X : Integer) return Bucket_Index is
            --  Map Min → 0, Max → K-1 using 64-bit arithmetic.
            Num : constant Long_Long_Integer :=
              Long_Long_Integer (K - 1)
              * (Long_Long_Integer (X) - Long_Long_Integer (Min_Val));
         begin
            return Bucket_Index (Num / Span);
         end Bucket_Of;
      begin
         --  Histogram: how many keys land in each bucket.
         for I in A'Range loop
            B := Bucket_Of (A (I));
            Counts (B) := Counts (B) + 1;
         end loop;

         --  Exclusive prefix → starting 0-based offsets from A'First.
         for B in Counts'Range loop
            Starts (B) := Total;
            Total := Total + Counts (B);
         end loop;

         --  Stable scatter: left-to-right into each bucket segment.
         declare
            Next : array (Bucket_Index) of Natural;
         begin
            for B in Starts'Range loop
               Next (B) := Starts (B);
            end loop;
            for I in A'Range loop
               B := Bucket_Of (A (I));
               Dest := A'First + Next (B);
               Work (Dest) := A (I);
               Next (B) := Next (B) + 1;
            end loop;
         end;

         --  Insertion-sort each non-empty bucket segment in place.
         for B in Counts'Range loop
            if Counts (B) > 0 then
               Seg_First := A'First + Starts (B);
               Seg_Last  := Seg_First + Counts (B) - 1;
               Insertion_Sort_Segment (Work, Seg_First, Seg_Last);
            end if;
         end loop;

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

end Bucket_Sort;
