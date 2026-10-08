pragma Ada_2022;
package Excel_Sheet_Column with SPARK_Mode => On is
   subtype Column is Positive range 1 .. 26;
   function Column_Number (Letter : Character) return Column with Global => null;
end Excel_Sheet_Column;
