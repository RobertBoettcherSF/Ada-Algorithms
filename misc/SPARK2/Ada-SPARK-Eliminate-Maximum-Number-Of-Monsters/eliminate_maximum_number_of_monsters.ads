pragma Ada_2022;
pragma SPARK_Mode (On);
package Eliminate_Maximum_Number_Of_Monsters is
   subtype Count is Natural range 0 .. 32;
   function Can_Eliminate (Monsters, Eliminations_Per_Turn, Turns : Count) return Boolean
     with Global => null;
end Eliminate_Maximum_Number_Of_Monsters;
