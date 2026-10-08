pragma Ada_2022;
package Line_Intersection with SPARK_Mode => On is
   subtype Coordinate is Integer range -1_000 .. 1_000;
   type Point is record
      X : Coordinate;
      Y : Coordinate;
   end record;

   function Intersects (A, B, C, D : Point) return Boolean
     with Global => null;
end Line_Intersection;
