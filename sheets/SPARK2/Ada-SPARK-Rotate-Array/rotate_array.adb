pragma Ada_2022;

package body Rotate_Array with SPARK_Mode => On is
   function Rotate_Right (Input : Value_Array) return Value_Array is
   begin
      return [Input (5), Input (1), Input (2), Input (3), Input (4)];
   end Rotate_Right;
end Rotate_Array;
