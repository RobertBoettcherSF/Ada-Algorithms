with Ada.Numerics.Elementary_Functions;

package body Rover_Control is

   package EF renames Ada.Numerics.Elementary_Functions;

   function Acceleration
     (X_Star : Float;
      Y_Star : Float;
      Ka     : Float := Default_Ka) return Float
   is
      Norm : constant Float := EF.Sqrt (X_Star * X_Star + Y_Star * Y_Star);
      Clipped : Float;
   begin
      if Norm < 1.0 then
         Clipped := Norm;
      else
         Clipped := 1.0;
      end if;
      return Ka * Clipped;
   end Acceleration;

   function Steer
     (X_Star : Float;
      Y_Star : Float;
      Q      : Float;
      Kp     : Float := Default_Kp) return Float
   is
      Desired : constant Float := EF.Arctan (Y => -X_Star, X => Y_Star);
   begin
      return Kp * (Desired - Q);
   end Steer;

end Rover_Control;
