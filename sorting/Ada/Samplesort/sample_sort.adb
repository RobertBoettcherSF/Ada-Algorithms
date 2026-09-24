-- sample_sort.adb
-- Body of the Samplesort algorithm variants.

package body Sample_Sort is

   ---------------------------------------------------------------------------
   -- Helper: Quick_Sort (Base case sorting for buckets and samples)
   ---------------------------------------------------------------------------
   procedure Quick_Sort (Data : in out Data_Array) is
      Pivot : Data_Element;
      Left  : Integer;
      Right : Integer;
      Temp  : Data_Element;
   begin
      if Data'Length <= 1 then
         return;
      end if;

      Pivot := Data(Data'First + Data'Length / 2);
      Left  := Data'First;
      Right := Data'Last;

      loop
         while Data(Left) < Pivot loop
            Left := Left + 1;
         end loop;
         while Data(Right) > Pivot loop
            Right := Right - 1;
         end loop;

         if Left <= Right then
            Temp := Data(Left);
            Data(Left) := Data(Right);
            Data(Right) := Temp;
            
            Left := Left + 1;
            Right := Right - 1;
         end if;

         exit when Left > Right;
      end loop;

      if Data'First < Right then
         Quick_Sort (Data(Data'First .. Right));
      end if;
      if Left < Data'Last then
         Quick_Sort (Data(Left .. Data'Last));
      end if;
   end Quick_Sort;

   ---------------------------------------------------------------------------
   -- Helper: Find_Bucket
   ---------------------------------------------------------------------------
   function Find_Bucket (Item : Data_Element; Pivots : Data_Array) return Positive is
   begin
      for I in Pivots'Range loop
         if Item <= Pivots(I) then
            return I - Pivots'First + 1;
         end if;
      end loop;
      return Pivots'Length + 1;
   end Find_Bucket;

   ---------------------------------------------------------------------------
   -- Variant 1: Sequential Sample Sort
   ---------------------------------------------------------------------------
   procedure Sequential_Sample_Sort (Data : in out Data_Array; Num_Buckets : Integer) is
   begin
      if Num_Buckets < 1 then
         raise Invalid_Bucket_Count;
      end if;

      -- Base case: not enough elements to bucket efficiently
      if Data'Length <= 1 or else Data'Length < Num_Buckets or else Num_Buckets = 1 then
         Quick_Sort (Data);
         return;
      end if;

      declare
         Pivots : Data_Array (1 .. Num_Buckets - 1);
         Stride : constant Natural := Data'Length / Num_Buckets;
         type Count_Array is array (1 .. Num_Buckets) of Natural;
         Counts : Count_Array := (others => 0);
         Starts : Count_Array := (others => 0);
         Curr   : Natural := Data'First;
         Temp   : Data_Array (Data'Range);
         Indices: Count_Array;
      begin
         -- 1. Sample Selection (Evenly spaced)
         for I in 1 .. Num_Buckets - 1 loop
            Pivots(I) := Data(Data'First + I * Stride);
         end loop;
         Quick_Sort (Pivots);

         -- 2. Count Bucket Sizes
         for I in Data'Range loop
            declare
               B : constant Positive := Find_Bucket (Data(I), Pivots);
            begin
               Counts(B) := Counts(B) + 1;
            end;
         end loop;

         -- 3. Calculate Prefix Sums for Bucket Starting Indices
         for I in 1 .. Num_Buckets loop
            Starts(I) := Curr;
            Curr := Curr + Counts(I);
         end loop;
         Indices := Starts;

         -- 4. Move Data to Temporary Array (Out-of-place partitioning)
         for I in Data'Range loop
            declare
               B : constant Positive := Find_Bucket (Data(I), Pivots);
            begin
               Temp(Indices(B)) := Data(I);
               Indices(B) := Indices(B) + 1;
            end;
         end loop;

         -- 5. Sort Each Bucket
         for I in 1 .. Num_Buckets loop
            if Counts(I) > 0 then
               Quick_Sort (Temp(Starts(I) .. Starts(I) + Counts(I) - 1));
            end if;
         end loop;

         -- 6. Copy back
         Data := Temp;
      end;
   end Sequential_Sample_Sort;

   ---------------------------------------------------------------------------
   -- Variant 2: Parallel Sample Sort (Task-Based Shared Memory)
   ---------------------------------------------------------------------------
   procedure Parallel_Sample_Sort (Data : in out Data_Array; Num_Buckets : Integer) is
   begin
      if Num_Buckets < 1 then
         raise Invalid_Bucket_Count;
      end if;

      if Data'Length <= 1 or else Data'Length < Num_Buckets or else Num_Buckets = 1 then
         Quick_Sort (Data);
         return;
      end if;

      declare
         Pivots : Data_Array (1 .. Num_Buckets - 1);
         Stride : constant Natural := Data'Length / Num_Buckets;
         type Count_Array is array (1 .. Num_Buckets) of Natural;
         Counts : Count_Array := (others => 0);
         Starts : Count_Array := (others => 0);
         Curr   : Natural := Data'First;
         Temp   : Data_Array (Data'Range);
         Indices: Count_Array;

         -- Define Worker Task for Concurrent Sorting
         task type Sorter_Task is
            entry Start (L, R : Natural);
            entry Done;
         end Sorter_Task;

         Workers : array (1 .. Num_Buckets) of Sorter_Task;

         task body Sorter_Task is
            My_L, My_R : Natural;
         begin
            accept Start (L, R : Natural) do
               My_L := L; My_R := R;
            end Start;
            
            if My_L <= My_R then
               Quick_Sort (Temp(My_L .. My_R));
            end if;
            
            accept Done;
         end Sorter_Task;

      begin
         -- 1 & 2. Sample, Sort, Count
         for I in 1 .. Num_Buckets - 1 loop
            Pivots(I) := Data(Data'First + I * Stride);
         end loop;
         Quick_Sort (Pivots);

         for I in Data'Range loop
            declare
               B : constant Positive := Find_Bucket (Data(I), Pivots);
            begin
               Counts(B) := Counts(B) + 1;
            end;
         end loop;

         for I in 1 .. Num_Buckets loop
            Starts(I) := Curr;
            Curr := Curr + Counts(I);
         end loop;
         Indices := Starts;

         -- Partitioning
         for I in Data'Range loop
            declare
               B : constant Positive := Find_Bucket (Data(I), Pivots);
            begin
               Temp(Indices(B)) := Data(I);
               Indices(B) := Indices(B) + 1;
            end;
         end loop;

         -- Trigger Parallel Sorting
         for I in 1 .. Num_Buckets loop
            if Counts(I) > 0 then
               Workers(I).Start (Starts(I), Starts(I) + Counts(I) - 1);
            else
               Workers(I).Start (1, 0); -- Null range, will skip
            end if;
         end loop;

         -- Await Completion
         for I in 1 .. Num_Buckets loop
            Workers(I).Done;
         end loop;

         Data := Temp;
      end;
   end Parallel_Sample_Sort;

   ---------------------------------------------------------------------------
   -- Variant 3: Oversampling Sample Sort
   ---------------------------------------------------------------------------
   procedure Oversampling_Sample_Sort (Data : in out Data_Array; Num_Buckets : Integer; Oversample_Factor : Integer) is
   begin
      if Num_Buckets < 1 then
         raise Invalid_Bucket_Count;
      end if;
      if Oversample_Factor < 1 then
         raise Invalid_Oversample_Factor;
      end if;

      if Data'Length <= 1 or else Data'Length < Num_Buckets or else Num_Buckets = 1 then
         Quick_Sort (Data);
         return;
      end if;

      declare
         Sample_Size : constant Positive := Num_Buckets * Oversample_Factor;
         Samples     : Data_Array (1 .. Sample_Size);
         Pivots      : Data_Array (1 .. Num_Buckets - 1);
         
         type Count_Array is array (1 .. Num_Buckets) of Natural;
         Counts      : Count_Array := (others => 0);
         Starts      : Count_Array := (others => 0);
         Curr        : Natural := Data'First;
         Temp        : Data_Array (Data'Range);
         Indices     : Count_Array;
      begin
         -- 1. Oversampling
         if Sample_Size >= Data'Length then
            -- Fallback if oversampling requires more elements than exist
            Sequential_Sample_Sort (Data, Num_Buckets);
            return;
         end if;

         for I in 1 .. Sample_Size loop
            -- Simplified selection: evenly spaced over entire array
            Samples(I) := Data(Data'First + (I * Data'Length / Sample_Size) - 1);
         end loop;
         
         Quick_Sort (Samples);

         -- Pick Pivots from oversampled set
         for I in 1 .. Num_Buckets - 1 loop
            Pivots(I) := Samples(I * Oversample_Factor);
         end loop;

         -- 2 & 3. Count & Prefix Sums
         for I in Data'Range loop
            declare
               B : constant Positive := Find_Bucket (Data(I), Pivots);
            begin
               Counts(B) := Counts(B) + 1;
            end;
         end loop;

         for I in 1 .. Num_Buckets loop
            Starts(I) := Curr;
            Curr := Curr + Counts(I);
         end loop;
         Indices := Starts;

         -- Partitioning
         for I in Data'Range loop
            declare
               B : constant Positive := Find_Bucket (Data(I), Pivots);
            begin
               Temp(Indices(B)) := Data(I);
               Indices(B) := Indices(B) + 1;
            end;
         end loop;

         -- Sequential sorting of buckets
         for I in 1 .. Num_Buckets loop
            if Counts(I) > 0 then
               Quick_Sort (Temp(Starts(I) .. Starts(I) + Counts(I) - 1));
            end if;
         end loop;

         Data := Temp;
      end;
   end Oversampling_Sample_Sort;

end Sample_Sort;
