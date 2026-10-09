pragma Ada_2022;
package Babylonian_Sqrt with SPARK_Mode => On is
   subtype Input is Integer range 0 .. 10_000;
   subtype Step_Count is Natural range 0 .. 101;
   type Sqrt_Result is record
      Root  : Integer;      --  floor of the square root
      Steps : Step_Count;   --  refinement steps
   end record;
   function Sqrt (N : Input) return Sqrt_Result with Global => null;
end Babylonian_Sqrt;
