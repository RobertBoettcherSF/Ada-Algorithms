pragma Ada_2022;
package body Vector_Dot_Cross with SPARK_Mode => On is
   function Dot (Left, Right : Vector) return Long_Long_Integer is
   begin
      return Long_Long_Integer (Left.X) * Long_Long_Integer (Right.X)
        + Long_Long_Integer (Left.Y) * Long_Long_Integer (Right.Y);
   end Dot;

   function Cross (Left, Right : Vector) return Long_Long_Integer is
   begin
      return Long_Long_Integer (Left.X) * Long_Long_Integer (Right.Y)
        - Long_Long_Integer (Left.Y) * Long_Long_Integer (Right.X);
   end Cross;
end Vector_Dot_Cross;
