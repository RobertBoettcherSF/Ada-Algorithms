pragma Ada_2022;

--  Minimum number of days to make M bouquets: flower I blooms on day
--  Bloom_Days (I). A bouquet takes Size flowers that stand next to each
--  other and have all bloomed; a flower goes into at most one bouquet.
--  Find the first day on which Bouquets bouquets can be made, if any.
package Minimum_Number_Of_Days_To_Make_M_Bouquets with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Prefix is Natural range 0 .. Length;
   subtype Day is Positive range 1 .. 1_000;
   subtype Bouquet_Size is Positive range 1 .. Length;
   subtype Bouquet_Count is Positive range 1 .. Length;
   type Bloom_Array is array (Index) of Day;

   --  State of a left-to-right scan that cuts a bouquet as soon as Size
   --  bloomed flowers stand in a row.
   type Progress is record
      Made : Prefix;   --  bouquets cut so far
      Run  : Prefix;   --  bloomed flowers in a row since the last cut or gap
   end record;

   function Step
     (S : Progress; Bloomed : Boolean; Size : Bouquet_Size) return Progress
   is (if not Bloomed then (Made => S.Made, Run => 0)
       elsif S.Run + 1 = Size then (Made => S.Made + 1, Run => 0)
       else (Made => S.Made, Run => S.Run + 1))
   with Pre => S.Run < Size and then S.Made * Size + S.Run < Length;

   --  The scan over flowers 1 .. I on day D.
   function Scan
     (Bloom_Days : Bloom_Array; D : Day; Size : Bouquet_Size; I : Prefix)
      return Progress
   with
     Subprogram_Variant => (Decreases => I),
     Post => Scan'Result.Run < Size
             and then Scan'Result.Made * Size + Scan'Result.Run <= I;

   --  Bouquets that can be made on day D. Cutting as early as possible
   --  is optimal: an earlier cut never leaves fewer flowers for the rest.
   function Count
     (Bloom_Days : Bloom_Array; D : Day; Size : Bouquet_Size) return Prefix
   is (Scan (Bloom_Days, D, Size, Length).Made);

   --  Later days never give fewer bouquets.
   procedure Lemma_Monotone
     (Bloom_Days : Bloom_Array; D1, D2 : Day; Size : Bouquet_Size)
   with
     Ghost,
     Global => null,
     Pre    => D1 <= D2,
     Post   => Count (Bloom_Days, D1, Size) <= Count (Bloom_Days, D2, Size);

   type Day_Result is record
      Possible  : Boolean;   --  Bouquets * Size <= Length
      First_Day : Day;       --  first day that works (Day'Last if none)
   end record;

   --  Possible says whether any day works; then First_Day works and the
   --  day before it does not. By Lemma_Monotone no earlier day works
   --  either, and when nothing is possible no day at all works.
   function Minimum_Day
     (Bloom_Days : Bloom_Array;
      Bouquets   : Bouquet_Count;
      Size       : Bouquet_Size) return Day_Result
   with
     Global => null,
     Post   =>
       Minimum_Day'Result.Possible = (Bouquets * Size <= Length)
       and then
       (if Minimum_Day'Result.Possible then
          Count (Bloom_Days, Minimum_Day'Result.First_Day, Size) >= Bouquets
          and then (Minimum_Day'Result.First_Day = Day'First
                    or else Count (Bloom_Days, Minimum_Day'Result.First_Day - 1, Size) < Bouquets)
        else
          Minimum_Day'Result.First_Day = Day'Last
          and then Count (Bloom_Days, Day'Last, Size) < Bouquets);

private
   function Scan
     (Bloom_Days : Bloom_Array; D : Day; Size : Bouquet_Size; I : Prefix)
      return Progress
   is (if I = 0 then (Made => 0, Run => 0)
       else Step (Scan (Bloom_Days, D, Size, I - 1), Bloom_Days (I) <= D, Size));
end Minimum_Number_Of_Days_To_Make_M_Bouquets;
