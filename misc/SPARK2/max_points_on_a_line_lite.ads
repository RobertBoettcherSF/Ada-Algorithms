pragma Ada_2022;
package Max_Points_On_A_Line_Lite with SPARK_Mode => On is
   subtype Coordinate is Integer range 0 .. 10;
   type Point is record
      X, Y : Coordinate;
   end record;
   subtype Point_Count is Natural range 1 .. 3;
   function Max_Collinear (A, B, C : Point) return Point_Count
     with Global => null;
end Max_Points_On_A_Line_Lite;
