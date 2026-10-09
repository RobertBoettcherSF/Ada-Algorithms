pragma Ada_2022;
package Sqrt_Integer with SPARK_Mode => On is
   subtype Number is Natural range 0 .. 100;
   subtype Root is Natural range 0 .. 10;
   function Floor_Sqrt (N : Number) return Root with Global => null;

   --  Failing-test scaffold: the table with a step counter (it takes no
   --  steps). The rewrite replaces it.
   type Sqrt_Result is record
      Root  : Sqrt_Integer.Root;
      Steps : Natural;
   end record;
   function Sqrt (N : Number) return Sqrt_Result
   is ((Root => Floor_Sqrt (N), Steps => 0))
   with Global => null;
end Sqrt_Integer;
