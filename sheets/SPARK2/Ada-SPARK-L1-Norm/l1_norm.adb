pragma Ada_2022;
package body L1_Norm with SPARK_Mode => On is
   function Norm (A : Vector) return Integer is
   begin
      return abs Integer (A (1)) + abs Integer (A (2)) + abs Integer (A (3));
   end Norm;
end L1_Norm;
