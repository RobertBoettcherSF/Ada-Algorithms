pragma Ada_2022;
package Soup_Servings_Lite with SPARK_Mode => On is
   subtype Unit_Count is Natural range 0 .. 16;
   function First_Empties_First (Units : Unit_Count) return Boolean with Global => null;
end Soup_Servings_Lite;
