pragma Ada_2022;
package Triangle_Min_Path with SPARK_Mode => On is
   subtype Row is Positive range 1 .. 4;
   subtype Column is Positive range 1 .. 4;
   subtype Cell_Value is Natural range 0 .. 9;
   type Triangle is array (Row, Column) of Cell_Value;
   subtype Path_Sum is Natural range 0 .. 36;
   function Minimum (T : Triangle) return Path_Sum with Global => null;
end Triangle_Min_Path;
