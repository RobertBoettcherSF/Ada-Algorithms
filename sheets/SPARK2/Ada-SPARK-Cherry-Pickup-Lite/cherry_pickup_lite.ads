pragma Ada_2022;
package Cherry_Pickup_Lite with SPARK_Mode => On is
   subtype Step_Count is Natural range 0 .. 16;
   subtype Cherry_Count is Natural range 0 .. 16;
   function Max_Cherries (Steps : Step_Count) return Cherry_Count with Global => null;
end Cherry_Pickup_Lite;
