pragma Ada_2022;
package body L2_Norm_Squared with SPARK_Mode => On is
   function Norm_Squared (A : Vector) return Integer is
   begin
      return Integer (A (1)) * Integer (A (1))
        + Integer (A (2)) * Integer (A (2))
        + Integer (A (3)) * Integer (A (3));
   end Norm_Squared;
end L2_Norm_Squared;
