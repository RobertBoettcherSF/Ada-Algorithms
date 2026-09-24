pragma Ada_2022;

package body Remove_K_Digits with SPARK_Mode => On is
   function Kept (Value : Digit_Array; K : Count; I : Position) return Digit is
   begin
      if I <= 8 - K then
         return Value (I);
      else
         return 0;
      end if;
   end Kept;

   function Remove_K (Value : Digit_Array; K : Count) return Digit_Array is
   begin
      return (1 => Kept (Value, K, 1), 2 => Kept (Value, K, 2),
              3 => Kept (Value, K, 3), 4 => Kept (Value, K, 4),
              5 => Kept (Value, K, 5), 6 => Kept (Value, K, 6),
              7 => Kept (Value, K, 7), 8 => Kept (Value, K, 8));
   end Remove_K;
end Remove_K_Digits;
