pragma Ada_2022;
package body Soup_Servings_Lite with SPARK_Mode => On is
   function First_Empties_First (Units : Unit_Count) return Boolean is
   begin
      return Units = 0;
   end First_Empties_First;
end Soup_Servings_Lite;
