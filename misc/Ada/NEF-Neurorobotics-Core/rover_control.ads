--  White-box rover acceleration and steering laws from
--  DeWolf, Jaworski, Eliasmith, arXiv:2007.10227v2 §3.3 (eqs. 1–2).
--  Clean-room Ada implementation of the published equations only;
--  no ABR/nengo Python was copied.

package Rover_Control is
   pragma Pure;

   --  Default gains (paper leaves Ka, Kp as free parameters).
   Default_Ka : constant Float := 1.0;
   Default_Kp : constant Float := 1.0;

   --  Eq. (1): u_acceleration = Ka * min(||(x*, y*)||, 1.0)
   function Acceleration
     (X_Star : Float;
      Y_Star : Float;
      Ka     : Float := Default_Ka) return Float;

   --  Eq. (2): u_steer = Kp * (Arctan2(-x*, y*) - q)
   --  Ada Arctan (Y, X) matches atan2(Y, X); so Y := -X_Star, X := Y_Star.
   function Steer
     (X_Star : Float;
      Y_Star : Float;
      Q      : Float;
      Kp     : Float := Default_Kp) return Float;

end Rover_Control;
