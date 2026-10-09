pragma Ada_2022;

--  Integer square root over Natural by Newton's (Heron's) iteration
--  X := (X + N / X) / 2, from the fixed start X = 46_340 (the floor of
--  the square root of Natural'Last), while a step still lowers X.
package Sqrt_X with SPARK_Mode => On is
   subtype Number is Natural;
   --  46_340 ** 2 = 2_147_395_600 <= Natural'Last < 46_341 ** 2.
   subtype Root is Natural range 0 .. 46_340;

   --  Proved: X falls on every step but the last, so Steps + Root <=
   --  46_340. The tests check the real worst case, 16 steps (N = 0).
   subtype Step_Count is Natural range 0 .. 46_340;

   type Sqrt_Result is record
      Root  : Sqrt_X.Root;   --  floor of the square root
      Steps : Step_Count;    --  Newton steps (one division each)
   end record;

   --  Squares in a wider type, so the contract itself cannot overflow.
   subtype Wide is Long_Long_Integer range 0 .. 2 ** 40;

   function Is_Floor_Sqrt (N : Number; R : Root) return Boolean is
     (Wide (R) * Wide (R) <= Wide (N)
      and then Wide (N) < (Wide (R) + 1) * (Wide (R) + 1));

   function Sqrt (N : Number) return Sqrt_Result
   with
     Global => null,
     Post   => Is_Floor_Sqrt (N, Sqrt'Result.Root);

   function Floor_Sqrt (N : Number) return Root is (Sqrt (N).Root)
   with
     Global => null,
     Post   => Is_Floor_Sqrt (N, Floor_Sqrt'Result);
end Sqrt_X;
