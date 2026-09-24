pragma Ada_2022;
package Title_To_Number with SPARK_Mode => On is
   subtype Column is Positive range 1 .. 26;
   function Title_Number (Letter : Character) return Column with Global => null;
end Title_To_Number;
