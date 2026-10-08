pragma Ada_2022;
pragma SPARK_Mode (On);
package body Broken_Calculator is
   function Minimum_Operations (Start, Target : Value) return Value is
   begin
      if Start >= Target then return Start - Target; else return Target - Start; end if;
   end Minimum_Operations;
end Broken_Calculator;
