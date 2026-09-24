pragma SPARK_Mode (On);

package Bulb_Switcher_Stub is
   subtype Bulbs is Natural range 0 .. 1_000_000_000;
   subtype On_Bulbs is Natural range 0 .. 31_623;

   function On_Count (Value : Bulbs) return On_Bulbs
     with Global => null;
end Bulb_Switcher_Stub;
