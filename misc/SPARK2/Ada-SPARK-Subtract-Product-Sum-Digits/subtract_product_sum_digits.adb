pragma SPARK_Mode (On);

package body Subtract_Product_Sum_Digits is
   function Difference (Value : Input) return Answer is
      Work : Long_Long_Integer := Long_Long_Integer (Value);
      Product : Long_Long_Integer := 1;
      Sum : Long_Long_Integer := 0;
      Digit : Long_Long_Integer;
   begin
      if Value = 0 then
         return 0;
      end if;
      for Position in 1 .. 10 loop
         pragma Loop_Invariant (Work >= 0);
         pragma Loop_Invariant (Work <= Long_Long_Integer (Value));
         pragma Loop_Invariant (Product >= 0);
         pragma Loop_Invariant (Sum >= 0);
         pragma Loop_Invariant (Sum <= 90);
         if Work > 0 then
            Digit := Work mod 10;
            if Digit = 0 then
               Product := 0;
            elsif Product <= 3_486_784_401 / Digit then
               Product := Product * Digit;
            else
               Product := 3_486_784_401;
            end if;
            if Sum <= 81 then
               Sum := Sum + Digit;
            else
               Sum := 90;
            end if;
            Work := Work / 10;
         end if;
      end loop;
      return Product - Sum;
   end Difference;
end Subtract_Product_Sum_Digits;
