pragma Ada_2022;

--  Integer square root over Natural by the bit-by-bit (digit-by-digit)
--  method: the root of a 31-bit value has at most 16 bits; try each bit
--  from 2 ** 15 down to 2 ** 0 and keep it when the square stays <= N.
package Sqrt_Integer with SPARK_Mode => On is
   subtype Number is Natural;
   --  46_340 ** 2 = 2_147_395_600 <= Natural'Last < 46_341 ** 2.
   subtype Root is Natural range 0 .. 46_340;
   subtype Step_Count is Natural range 0 .. 16;

   type Sqrt_Result is record
      Root  : Sqrt_Integer.Root;   --  floor of the square root
      Steps : Step_Count;          --  trial bits (one comparison each)
   end record;

   --  Squares in a wider type, so the contract itself cannot overflow.
   subtype Wide is Long_Long_Integer range 0 .. 2 ** 40;

   function Is_Floor_Sqrt (N : Number; R : Root) return Boolean is
     (Wide (R) * Wide (R) <= Wide (N)
      and then Wide (N) < (Wide (R) + 1) * (Wide (R) + 1));

   function Sqrt (N : Number) return Sqrt_Result
   with
     Global => null,
     Post   => Is_Floor_Sqrt (N, Sqrt'Result.Root) and then Sqrt'Result.Steps = 16;

   function Floor_Sqrt (N : Number) return Root is (Sqrt (N).Root)
   with
     Global => null,
     Post   => Is_Floor_Sqrt (N, Floor_Sqrt'Result);
end Sqrt_Integer;
