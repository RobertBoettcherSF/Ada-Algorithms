pragma Ada_2022;
package body Find_The_Difference with SPARK_Mode => On is
   use type Byte;
   function Difference (Original, Changed : Byte) return Byte is
   begin
      return Original xor Changed;
   end Difference;
end Find_The_Difference;
