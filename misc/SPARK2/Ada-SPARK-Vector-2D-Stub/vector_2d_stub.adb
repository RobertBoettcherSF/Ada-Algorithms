pragma SPARK_Mode (On);
package body Vector_2D_Stub is
   function Add (Left, Right : Vector) return Vector is
   begin return (X => Left.X + Right.X, Y => Left.Y + Right.Y); end Add;
   function Subtract (Left, Right : Vector) return Vector is
   begin return (X => Left.X - Right.X, Y => Left.Y - Right.Y); end Subtract;
   function Scale (V : Vector; Factor : Coordinate) return Vector is
   begin return (X => V.X * Factor, Y => V.Y * Factor); end Scale;
   function Dot (Left, Right : Vector) return Result is
   begin return Left.X * Right.X + Left.Y * Right.Y; end Dot;
   function Cross (Left, Right : Vector) return Result is
   begin return Left.X * Right.Y - Left.Y * Right.X; end Cross;
   function Equal (Left, Right : Vector) return Boolean is
   begin return Left.X = Right.X and then Left.Y = Right.Y; end Equal;
end Vector_2D_Stub;
