pragma Ada_2022;
package body Largest_Number with SPARK_Mode => On is
   function Largest_Concatenation (Left, Right : Digit)
     return Two_Digit_Number is
   begin
      if Left >= Right then
         return 10 * Left + Right;
      else
         return 10 * Right + Left;
      end if;
   end Largest_Concatenation;
end Largest_Number;
