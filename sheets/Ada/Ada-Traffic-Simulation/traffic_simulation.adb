--  Traffic_Simulation.adb
--  Implementation of the microscopic, macroscopic, and mesoscopic models.

package body Traffic_Simulation is

   -----------------------------------------------------------------------------
   --  Advance_Microscopic
   -----------------------------------------------------------------------------
   procedure Advance_Microscopic
     (State         : in out Microscopic_State;
      Behavior      : in     Driver_Behavior;
      Gap_To_Leader : in     Meters;
      Leader_Speed  : in     Meters_Per_Second;
      Time_Step     : in     Positive_Seconds)
   is
      Gap_Diff        : Float;
      Safe_Speed      : Meters_Per_Second;
      Commanded_Speed : Meters_Per_Second;
      Accel_Needed    : Float;
      Actual_Accel    : Float;
      New_Speed_Float : Float;
   begin
      --  Check for collision condition
      if Gap_To_Leader < Behavior.Minimum_Gap then
         raise Collision_Error;
      end if;

      Gap_Diff := Float (Gap_To_Leader) - Float (Behavior.Minimum_Gap);
      
      --  Safe speed ensures the vehicle maintains the safe time headway
      Safe_Speed := Leader_Speed + Meters_Per_Second (Gap_Diff / Float (Behavior.Safe_Time_Headway));
      
      --  Commanded speed bounds to desired speed
      Commanded_Speed := Meters_Per_Second'Min (Behavior.Desired_Speed, Safe_Speed);
      
      --  Determine needed acceleration (kinematics)
      Accel_Needed := (Float (Commanded_Speed) - Float (State.Speed)) / Float (Time_Step);
      
      --  Clamp acceleration within vehicle/driver capabilities
      if Accel_Needed > 0.0 then
         Actual_Accel := Float'Min (Accel_Needed, Float (Behavior.Max_Acceleration));
      else
         Actual_Accel := Float'Max (Accel_Needed, -Float (Behavior.Max_Deceleration));
      end if;

      --  Euler integration for speed (cannot drop below 0.0)
      New_Speed_Float := Float (State.Speed) + (Actual_Accel * Float (Time_Step));
      State.Speed := Meters_Per_Second (Float'Max (0.0, New_Speed_Float));
      
      --  Euler integration for position
      State.Position := State.Position + Meters (Float (State.Speed) * Float (Time_Step));
   end Advance_Microscopic;

   -----------------------------------------------------------------------------
   --  Calculate_Macroscopic_State
   -----------------------------------------------------------------------------
   procedure Calculate_Macroscopic_State
     (Density          : in  Vehicles_Per_Kilometer;
      Free_Flow_Speed  : in  Meters_Per_Second;
      Jam_Density      : in  Vehicles_Per_Kilometer;
      Resulting_Flow   : out Vehicles_Per_Hour;
      Resulting_Speed  : out Meters_Per_Second)
   is
      Density_Ratio : Float;
      Speed_Float   : Float;
   begin
      if Density >= Jam_Density then
         --  Jam state: no movement
         Resulting_Speed := 0.0;
         Resulting_Flow  := 0.0;
      else
         --  Greenshields linear model
         Density_Ratio := Float (Density) / Float (Jam_Density);
         Speed_Float   := Float (Free_Flow_Speed) * (1.0 - Density_Ratio);
         
         Resulting_Speed := Meters_Per_Second (Float'Max (0.0, Speed_Float));
         
         --  Flow = Density * Speed (adjusted for units: m/s -> km/h requires * 3.6)
         Resulting_Flow := Vehicles_Per_Hour 
           (Float (Density) * Float (Resulting_Speed) * 3.6);
      end if;
   end Calculate_Macroscopic_State;

   -----------------------------------------------------------------------------
   --  Advance_Mesoscopic_Platoon
   -----------------------------------------------------------------------------
   procedure Advance_Mesoscopic_Platoon
     (P                : in out Platoon;
      Link_Capacity    : in     Vehicles_Per_Hour;
      Time_Step        : in     Positive_Seconds;
      Discharged_Count : out    Vehicle_Volume)
   is
      Capacity_Per_Sec : Float;
      Max_Discharge    : Float;
      Actual_Discharge : Float;
   begin
      case P.State is
         when Moving =>
            if P.Time_To_Node <= Seconds (Time_Step) then
               --  Platoon reaches the end of the link
               P.Time_To_Node := 0.0;
               P.State := Queued;
               Discharged_Count := 0.0;
            else
               --  Platoon continues moving
               P.Time_To_Node := P.Time_To_Node - Seconds (Time_Step);
               Discharged_Count := 0.0;
            end if;

         when Queued =>
            --  Discharge based on bottleneck capacity
            Capacity_Per_Sec := Float (Link_Capacity) / 3600.0;
            Max_Discharge    := Capacity_Per_Sec * Float (Time_Step);
            
            Actual_Discharge := Float'Min (Float (P.Size), Max_Discharge);
            Discharged_Count := Vehicle_Volume (Actual_Discharge);
            
            P.Size := P.Size - Discharged_Count;
            
            --  Check for full discharge (allowing for small float inaccuracies)
            if Float (P.Size) <= 0.000_1 then
               P.Size := 0.0;
               P.State := Discharged;
            end if;

         when Discharged =>
            --  No remaining vehicles to process
            Discharged_Count := 0.0;
      end case;
   end Advance_Mesoscopic_Platoon;

end Traffic_Simulation;
