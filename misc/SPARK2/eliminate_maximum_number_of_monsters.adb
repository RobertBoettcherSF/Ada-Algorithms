pragma Ada_2022;
pragma SPARK_Mode (On);
package body Eliminate_Maximum_Number_Of_Monsters is
   function Can_Eliminate (Monsters, Eliminations_Per_Turn, Turns : Count) return Boolean is
   begin
      return Eliminations_Per_Turn * Turns >= Monsters;
   end Can_Eliminate;
end Eliminate_Maximum_Number_Of_Monsters;
