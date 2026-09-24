pragma Ada_2022;

package body Asteroid_Collision with SPARK_Mode => On is
   function Resolve_Pair (Left, Right : Asteroid) return Asteroid is
   begin
      if Left > 0 and Right < 0 then
         if Left > -Right then
            return Left;
         elsif Left < -Right then
            return Right;
         else
            return 0;
         end if;
      else
         return Right;
      end if;
   end Resolve_Pair;
end Asteroid_Collision;
