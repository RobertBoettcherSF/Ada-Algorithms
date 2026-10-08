pragma Ada_2022;
package Line_Reflection with SPARK_Mode => On is
   subtype Coordinate is Integer range -10 .. 10;
   function Is_Reflection
     (Axis, X1, Y1, X2, Y2 : Coordinate) return Boolean
     with Global => null;
end Line_Reflection;
