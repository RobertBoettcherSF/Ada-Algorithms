pragma Ada_2022;
package body Triangle with SPARK_Mode => On is
   function Minimum_Path (Rows : Row_Count) return Path_Cost is
   begin
      return Rows;
   end Minimum_Path;
end Triangle;
