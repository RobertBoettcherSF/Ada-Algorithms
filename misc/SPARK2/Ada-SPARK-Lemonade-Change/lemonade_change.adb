pragma Ada_2022;
pragma SPARK_Mode (On);
package body Lemonade_Change is
   function Can_Make_Change (Fives, Tens, Twenties : Bill_Count) return Boolean is
   begin
      return Fives >= Tens + 3 * Twenties;
   end Can_Make_Change;
end Lemonade_Change;
