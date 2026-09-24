pragma Ada_2022;
pragma SPARK_Mode (On);
package Lemonade_Change is
   subtype Bill_Count is Natural range 0 .. 32;
   function Can_Make_Change (Fives, Tens, Twenties : Bill_Count) return Boolean
     with Global => null;
end Lemonade_Change;
