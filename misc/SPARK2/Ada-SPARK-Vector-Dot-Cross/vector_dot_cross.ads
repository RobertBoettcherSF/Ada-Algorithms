pragma Ada_2022;
package Vector_Dot_Cross with SPARK_Mode => On is
   subtype Coordinate is Integer range -1_000 .. 1_000;
   type Vector is record
      X : Coordinate;
      Y : Coordinate;
   end record;

   function Dot (Left, Right : Vector) return Long_Long_Integer
     with Global => null;
   function Cross (Left, Right : Vector) return Long_Long_Integer
     with Global => null;
end Vector_Dot_Cross;
