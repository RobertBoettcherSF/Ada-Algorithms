pragma Ada_2022;

--  Integer square root by the Babylonian (Newton) method: start above
--  the root and replace X by (X + N / X) / 2 while that gets smaller.
package Babylonian_Sqrt with SPARK_Mode => On is
   subtype Input is Integer range 0 .. 10_000;
   subtype Root is Natural range 0 .. 100;

   --  Proved: X falls on every step but the last, so at most 101 steps.
   --  The tests check the real bound (at most 8 on 0 .. 10,000).
   subtype Step_Count is Natural range 0 .. 101;
   type Sqrt_Result is record
      Root  : Babylonian_Sqrt.Root;   --  floor of the square root
      Steps : Step_Count;             --  refinement steps (one division each)
   end record;

   function Sqrt (N : Input) return Sqrt_Result
   with
     Global => null,
     Post   => Sqrt'Result.Root * Sqrt'Result.Root <= N
               and then N < (Sqrt'Result.Root + 1) * (Sqrt'Result.Root + 1);
end Babylonian_Sqrt;
