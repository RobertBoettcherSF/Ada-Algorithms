package body CBTC is

   function Braking_Distance (Speed : Speed_MPS; 
                              Decel : Deceleration_MPS2) return Distance_M is
      S : constant Float := Float (Speed);
      D : constant Float := Float (Decel);
      Res : Float;
   begin
      -- Standard kinematics: v^2 = u^2 + 2as. Since v=0, s = -u^2 / (2a)
      if Speed = 0.0 then
         return 0.0;
      end if;

      Res := -(S * S) / (2.0 * D);
      
      -- Ensure positive distance despite possible float precision fluctuations
      if Res < 0.0 then
         Res := 0.0;
      end if;
      
      return Distance_M (Res);
   end Braking_Distance;


   function Moving_Block_Authority (Leader_Tail : Distance_M;
                                    Follower_Head : Distance_M;
                                    Margin : Distance_M) return Distance_M is
   begin
      if Follower_Head > Leader_Tail then
         raise Collision_Error with "Follower has passed Leader train";
      end if;

      -- If the leader is closer to the start of the track than the safety margin,
      -- the follower gets zero authority.
      if Leader_Tail < Margin then
         return 0.0;
      end if;

      return Leader_Tail - Margin;
   end Moving_Block_Authority;


   function Fixed_Block_Authority (Leader_Block : Block_ID;
                                   Follower_Block : Block_ID;
                                   Block_Length : Distance_M) return Distance_M is
   begin
      if Follower_Block >= Leader_Block then
         raise Collision_Error with "Follower is in the same or ahead block as Leader";
      end if;

      -- The absolute track position of the start of the leader's block.
      -- The follower is authorized up to the boundary preceding the leader.
      return Distance_M (Float (Leader_Block) * Float (Block_Length));
   end Fixed_Block_Authority;


   function ATP_Is_Safe (Speed : Speed_MPS;
                         Limit : Speed_MPS;
                         Position : Distance_M;
                         Authority : Distance_M;
                         Emergency_Decel : Deceleration_MPS2) return Boolean is
      Req_Distance : Distance_M;
   begin
      -- 1. Overspeed check
      if Speed > Limit then
         return False;
      end if;

      Req_Distance := Braking_Distance (Speed, Emergency_Decel);

      -- 2. Authority curve check (using subtraction to avoid constraint overflow)
      -- Changed to <= to ensure that touching the exact limit is considered an unsafe edge boundary.
      if Authority - Position <= Req_Distance then
         return False;
      end if;

      return True;
   end ATP_Is_Safe;


   function ATO_Command (Current_Speed : Speed_MPS;
                         Target_Speed : Speed_MPS;
                         Position : Distance_M;
                         Authority : Distance_M;
                         Service_Decel : Deceleration_MPS2;
                         Max_Accel : Acceleration_MPS2) return Acceleration_MPS2 is
      Braking_Needed : Distance_M;
      Distance_To_Limit : Distance_M;
   begin
      Braking_Needed := Braking_Distance (Current_Speed, Service_Decel);
      Distance_To_Limit := Authority - Position;

      -- Determine if we are at or past the point of mandatory service braking
      if Distance_To_Limit <= Braking_Needed then
         return Acceleration_MPS2 (Service_Decel);
      end if;

      -- If safe, try to match the target speed profile
      if Current_Speed < Target_Speed then
         return Max_Accel;
      elsif Current_Speed > Target_Speed then
         return Acceleration_MPS2 (Service_Decel);
      else
         return 0.0; -- Maintain speed / coast
      end if;
   end ATO_Command;


   function ATS_Safe_Departure (Last_Departure : Time_Sec;
                                Current_Time : Time_Sec;
                                Min_Headway : Time_Sec) return Boolean is
   begin
      return (Current_Time - Last_Departure) >= Min_Headway;
   end ATS_Safe_Departure;

end CBTC;
