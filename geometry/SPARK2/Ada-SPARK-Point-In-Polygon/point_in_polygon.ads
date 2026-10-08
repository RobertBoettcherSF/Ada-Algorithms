pragma Ada_2022;
package Point_In_Polygon with SPARK_Mode => On is
   Max_Vertices : constant := 4;
   subtype Coordinate is Integer range -100 .. 100;
   subtype Index is Integer range 1 .. Max_Vertices;
   subtype Count is Index;
   type Point is record
      X : Coordinate;
      Y : Coordinate;
   end record;
   type Polygon is array (Index) of Point;

   function Contains (Shape : Polygon; Number_Of_Vertices : Count;
                      Query : Point) return Boolean with Global => null;
end Point_In_Polygon;
