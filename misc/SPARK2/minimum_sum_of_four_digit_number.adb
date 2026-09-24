pragma SPARK_Mode (On);

package body Minimum_Sum_Of_Four_Digit_Number is
   function Minimum_Sum
     (A, B, C, D : Digit) return Sum is
      X : Digit := A;
      Y : Digit := B;
      Z : Digit := C;
      W : Digit := D;
      T : Digit;
   begin
      if X > Y then T := X; X := Y; Y := T; end if;
      if Z > W then T := Z; Z := W; W := T; end if;
      if X > Z then T := X; X := Z; Z := T; end if;
      if Y > W then T := Y; Y := W; W := T; end if;
      if Y > Z then T := Y; Y := Z; Z := T; end if;
      return 10 * (X + Y) + Z + W;
   end Minimum_Sum;
end Minimum_Sum_Of_Four_Digit_Number;
