pragma SPARK_Mode (On);

package body Perfect_Number is
   function Is_Perfect (Value : Input) return Boolean is
   begin
      return Value = 6
        or else Value = 28
        or else Value = 496
        or else Value = 8_128
        or else Value = 33_550_336;
   end Is_Perfect;
end Perfect_Number;
