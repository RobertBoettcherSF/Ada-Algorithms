pragma Ada_2022;
package Paint_House_Lite with SPARK_Mode => On is
   subtype Cost is Natural range 0 .. 16;
   function Minimum (Red, Green, Blue : Cost) return Cost with Global => null;
end Paint_House_Lite;
