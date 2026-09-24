pragma SPARK_Mode (On);

package Bulb_Switcher is
   subtype Bulbs is Natural range 0 .. 1_000_000_000;
   subtype On_Count is Natural range 0 .. 31_623;

   function Switched_On (Value : Bulbs) return On_Count
     with Global => null;
end Bulb_Switcher;
