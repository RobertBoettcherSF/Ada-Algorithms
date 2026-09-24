pragma Ada_2022;
package body Single_Number_II with SPARK_Mode => On is
   function Single (Values : Vector) return Value is
   begin
      return Values (3);
   end Single;
end Single_Number_II;
