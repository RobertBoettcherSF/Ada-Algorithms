pragma Ada_2022;
pragma SPARK_Mode (On);
package body Jump_Game is
   function Can_Jump (A : Steps; N : Count) return Boolean is
   begin
      return A (Index (N)) > 0;
   end Can_Jump;
end Jump_Game;
