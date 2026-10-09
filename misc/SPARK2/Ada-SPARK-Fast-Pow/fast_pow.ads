pragma SPARK_Mode (On);

--  Failing-test scaffold: Power_Mod is declared so the new test compiles;
--  the body is still the small case table.
package Fast_Pow is
   subtype Base is Natural range 0 .. 5;
   subtype Exponent is Natural range 0 .. 12;
   subtype Result is Natural range 0 .. 244_140_625;

   function Power (Value : Base; Exp : Exponent) return Result
     with Global => null;

   type Pow_Result is record
      Value : Natural;
      Steps : Natural;
   end record;

   function Power_Mod (B : Natural; E : Natural; M : Positive) return Pow_Result
     with Global => null;
end Fast_Pow;
