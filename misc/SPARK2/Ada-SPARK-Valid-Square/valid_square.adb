pragma Ada_2022;
package body Valid_Square with SPARK_Mode => On is
   function Is_Valid_Square (Side : Side_Length) return Boolean is
      Result : constant Boolean := Side > 0;
   begin
      pragma Assert (Result = (Side > 0));
      return Result;
   end Is_Valid_Square;
end Valid_Square;
