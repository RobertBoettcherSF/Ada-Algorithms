pragma Ada_2022;
package Triangle with SPARK_Mode => On is
   subtype Row_Count is Natural range 0 .. 16;
   subtype Path_Cost is Natural range 0 .. 16;
   function Minimum_Path (Rows : Row_Count) return Path_Cost with Global => null;
end Triangle;
