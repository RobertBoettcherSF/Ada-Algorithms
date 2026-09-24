pragma Ada_2022;

package body Product_Except_Self with SPARK_Mode => On is
   function Compute (Input : Input_Array) return Result_Array is
   begin
      return [
         Input (2) * Input (3) * Input (4) * Input (5),
         Input (1) * Input (3) * Input (4) * Input (5),
         Input (1) * Input (2) * Input (4) * Input (5),
         Input (1) * Input (2) * Input (3) * Input (5),
         Input (1) * Input (2) * Input (3) * Input (4)];
   end Compute;
end Product_Except_Self;
