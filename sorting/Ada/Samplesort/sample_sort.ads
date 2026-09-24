-- sample_sort.ads
-- Specification for the Samplesort algorithm variants.

package Sample_Sort is

   -- Custom types for strong typing
   type Data_Element is new Integer;
   type Data_Array is array (Natural range <>) of Data_Element;

   -- Exceptions for edge cases and invalid input
   Invalid_Bucket_Count : exception;
   Invalid_Oversample_Factor : exception;

   -- Variant 1: Sequential Sample Sort (Standard out-of-place)
   -- Partitions the data into buckets sequentially and sorts each sequentially.
   procedure Sequential_Sample_Sort (Data : in out Data_Array; Num_Buckets : Integer);

   -- Variant 2: Parallel Sample Sort (Task-based)
   -- Partitions data, then uses Ada Tasks (shared memory) to sort buckets concurrently.
   procedure Parallel_Sample_Sort (Data : in out Data_Array; Num_Buckets : Integer);

   -- Variant 3: Oversampling Sample Sort
   -- Selects (Num_Buckets * Factor) elements to find statistically better pivots.
   procedure Oversampling_Sample_Sort (Data : in out Data_Array; Num_Buckets : Integer; Oversample_Factor : Integer);

   -- Helper function exposed for potential testing or manual override
   procedure Quick_Sort (Data : in out Data_Array);

end Sample_Sort;
