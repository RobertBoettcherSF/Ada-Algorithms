pragma Ada_2022;
package Newton_Raphson with SPARK_Mode => On is
   subtype Input is Integer range 1 .. 10_000;
   subtype Root is Integer range 1 .. 100;   --  integer square roots of Input

   --  Integer square root: the largest R with R * R <= N.
   function Sqrt (N : Input) return Root
     with Global => null,
          Post   => Sqrt'Result * Sqrt'Result <= N and then N < (Sqrt'Result + 1) * (Sqrt'Result + 1);
end Newton_Raphson;
