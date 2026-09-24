pragma Ada_2022;
with Ada.Numerics.Elementary_Functions;

package body Automatic_Train_Operation is
   use Ada.Numerics.Elementary_Functions;

   function Calculate_ATP_Safe_Speed
     (Track_Limit       : Speed_Mps;
      Distance_To_Stop  : Distance_M;
      Max_Deceleration  : Acceleration_Mps2) return Speed_Mps
   is
      Raw_Limit  : Float;
      Calc_Speed : Speed_Mps;
   begin
      -- If the stop mark is reached or passed, train must be stopped
      if Distance_To_Stop <= 0.0 then
         return 0.0;
      end if;

      -- Kinematic equation: v = sqrt(u^2 - 2as) with final speed u = 0
      -- Therefore safe target speed v = sqrt(-2 * a * s)
      Raw_Limit := Sqrt (Float (-2.0) * Float (Max_Deceleration) * Float (Distance_To_Stop));

      if Raw_Limit >= Float (Track_Limit) then
         Calc_Speed := Track_Limit;
      elsif Raw_Limit >= Float (Speed_Mps'Last) then
         Calc_Speed := Speed_Mps'Last;
      else
         Calc_Speed := Speed_Mps (Raw_Limit);
      end if;

      return Calc_Speed;
   end Calculate_ATP_Safe_Speed;

   function Determine_Drive_Action
     (Current_Speed : Speed_Mps;
      Target_Speed  : Speed_Mps) return Train_Action
   is
      Cur : constant Float := Float (Current_Speed);
      Tgt : constant Float := Float (Target_Speed);
   begin
      if Cur <= 0.0 and then Tgt <= 0.0 then
         return Stopped;
      elsif Tgt <= 0.0 and then Cur > 0.0 then
         return Service_Brake;
      elsif Cur < Tgt - 0.5 then
         return Accelerate;
      elsif Cur > Tgt + 0.5 then
         return Service_Brake;
      else
         return Coast;
      end if;
   end Determine_Drive_Action;

   function Precision_Station_Stop
     (Current_Speed     : Speed_Mps;
      Distance_To_Mark  : Distance_M;
      Comfort_Decel     : Acceleration_Mps2) return Train_Action
   is
      Target_Speed : Speed_Mps;
      Dist         : constant Float := Float (Distance_To_Mark);
   begin
      -- Hard boundaries for position tolerances
      if Dist < -0.5 then
         return Emergency_Brake; -- Danger: train has overshot platform
      elsif Dist <= 0.5 then
         if Float (Current_Speed) > 0.0 then
            return Service_Brake; -- Final millimeter braking
         else
            return Stopped; -- Perfectly aligned within tolerance
         end if;
      end if;

      -- If far out, compute braking curve and drive to that target speed
      Target_Speed := Calculate_ATP_Safe_Speed (150.0, Distance_To_Mark, Comfort_Decel);
      return Determine_Drive_Action (Current_Speed, Target_Speed);
   end Precision_Station_Stop;

   procedure Control_Doors
     (Current_Speed     : Speed_Mps;
      Alignment_Error   : Distance_M;
      Current_GoA       : GoA_Level;
      Doors             : in out Door_State)
   is
   begin
      -- GoA 1 implies manual driver handles doors; auto system takes no action
      if Current_GoA = GoA_1 then
         return;
      end if;

      -- Doors only open automatically if effectively stopped and well aligned
      if Float (Current_Speed) <= 0.001 and then abs (Float (Alignment_Error)) <= 0.5 then
         Doors := Open;
      else
         Doors := Closed;
      end if;
   end Control_Doors;

   function Handle_Obstacle
     (Obstacle_Detected : Boolean;
      Distance_To_Obs   : Distance_M;
      Current_GoA       : GoA_Level) return Train_Action
   is
      pragma Warnings (Off, Current_GoA);
   begin
      -- Precondition guarantees GoA_4 here, so we evaluate unattended rules exclusively
      if not Obstacle_Detected then
         return Coast;
      end if;

      if Float (Distance_To_Obs) < 200.0 then
         return Emergency_Brake;
      else
         return Service_Brake;
      end if;
   end Handle_Obstacle;

end Automatic_Train_Operation;
