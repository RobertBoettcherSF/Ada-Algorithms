pragma Ada_2022;
package Out_Of_Boundary_Paths_Lite with SPARK_Mode => On is
   subtype Coordinate is Positive range 1 .. 4;
   subtype Exit_Count is Natural range 0 .. 4;
   function Immediate_Exits (Row, Col : Coordinate) return Exit_Count with Global => null;
end Out_Of_Boundary_Paths_Lite;
