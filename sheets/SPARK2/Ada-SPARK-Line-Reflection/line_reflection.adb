pragma Ada_2022;
package body Line_Reflection with SPARK_Mode => On is
   function Is_Reflection
     (Axis, X1, Y1, X2, Y2 : Coordinate) return Boolean is
      Result : constant Boolean := Y1 = Y2 and X1 + X2 = 2 * Axis;
   begin
      pragma Assert (Result = (Y1 = Y2 and X1 + X2 = 2 * Axis));
      return Result;
   end Is_Reflection;
end Line_Reflection;
