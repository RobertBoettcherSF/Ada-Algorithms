pragma Ada_2022;

package Asteroid_Collision with SPARK_Mode => On is
   subtype Asteroid is Integer range -9 .. 9;
   function Resolve_Pair (Left, Right : Asteroid) return Asteroid
     with Global => null;
end Asteroid_Collision;
