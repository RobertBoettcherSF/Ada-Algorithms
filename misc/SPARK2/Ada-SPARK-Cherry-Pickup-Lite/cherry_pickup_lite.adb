pragma Ada_2022;
package body Cherry_Pickup_Lite with SPARK_Mode => On is
   function Max_Cherries (Steps : Step_Count) return Cherry_Count is
   begin
      return Steps;
   end Max_Cherries;
end Cherry_Pickup_Lite;
