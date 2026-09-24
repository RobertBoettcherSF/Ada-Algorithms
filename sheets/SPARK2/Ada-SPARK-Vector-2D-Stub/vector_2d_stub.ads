pragma SPARK_Mode (On);
package Vector_2D_Stub is
   subtype Coordinate is Integer range -10 .. 10;
   subtype Result is Integer range -200 .. 200;
   type Vector is record X, Y : Coordinate := 0; end record;
   function Add (Left, Right : Vector) return Vector with Global => null, Pre => Left.X + Right.X in Coordinate and then Left.Y + Right.Y in Coordinate;
   function Subtract (Left, Right : Vector) return Vector with Global => null, Pre => Left.X - Right.X in Coordinate and then Left.Y - Right.Y in Coordinate;
   function Scale (V : Vector; Factor : Coordinate) return Vector with Global => null, Pre => V.X * Factor in Coordinate and then V.Y * Factor in Coordinate;
   function Dot (Left, Right : Vector) return Result with Global => null;
   function Cross (Left, Right : Vector) return Result with Global => null;
   function Equal (Left, Right : Vector) return Boolean with Global => null;
end Vector_2D_Stub;
