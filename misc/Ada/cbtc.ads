package CBTC is
   pragma Pure;

   -- Domain-specific types for strongly-typed kinematics
   type Distance_M is digits 6 range 0.0 .. 1_000_000.0;
   type Speed_MPS is digits 6 range 0.0 .. 200.0;
   type Acceleration_MPS2 is digits 6 range -20.0 .. 20.0;
   type Time_Sec is digits 6 range 0.0 .. 86_400.0;

   subtype Deceleration_MPS2 is Acceleration_MPS2 range -20.0 .. -0.001;
   subtype Block_ID is Natural;

   Collision_Error : exception;
   Configuration_Error : exception;

   -- Calculates the absolute minimum braking distance required to stop from the current speed.
   function Braking_Distance (Speed : Speed_MPS; 
                              Decel : Deceleration_MPS2) return Distance_M
     with Pre => Decel < 0.0,
          Post => Braking_Distance'Result >= 0.0;

   -- Moving Block Authority: Calculates the dynamic absolute track position movement limit 
   -- based on the exact telemetry of the leading train.
   function Moving_Block_Authority (Leader_Tail : Distance_M;
                                    Follower_Head : Distance_M;
                                    Margin : Distance_M) return Distance_M
     with Post => Moving_Block_Authority'Result >= 0.0;

   -- Fixed Block Authority: Calculates the discrete absolute track position movement limit
   -- based strictly on pre-defined block occupancies.
   function Fixed_Block_Authority (Leader_Block : Block_ID;
                                   Follower_Block : Block_ID;
                                   Block_Length : Distance_M) return Distance_M
     with Post => Fixed_Block_Authority'Result >= 0.0;

   -- Automatic Train Protection (ATP): Safety system check. Returns True if the train
   -- is operating safely within its speed limit and authority curve.
   function ATP_Is_Safe (Speed : Speed_MPS;
                         Limit : Speed_MPS;
                         Position : Distance_M;
                         Authority : Distance_M;
                         Emergency_Decel : Deceleration_MPS2) return Boolean
     with Pre => Position <= Authority;

   -- Automatic Train Operation (ATO): Determines the optimal control command 
   -- (acceleration or deceleration) for driving the train automatically.
   function ATO_Command (Current_Speed : Speed_MPS;
                         Target_Speed : Speed_MPS;
                         Position : Distance_M;
                         Authority : Distance_M;
                         Service_Decel : Deceleration_MPS2;
                         Max_Accel : Acceleration_MPS2) return Acceleration_MPS2
     with Pre => Position <= Authority and Max_Accel > 0.0;

   -- Automatic Train Supervision (ATS): Validates high-level dispatch instructions
   -- such as minimum headway times between train departures.
   function ATS_Safe_Departure (Last_Departure : Time_Sec;
                                Current_Time : Time_Sec;
                                Min_Headway : Time_Sec) return Boolean
     with Pre => Current_Time >= Last_Departure;

end CBTC;
