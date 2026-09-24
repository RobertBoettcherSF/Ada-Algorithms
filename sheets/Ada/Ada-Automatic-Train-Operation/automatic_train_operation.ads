pragma Ada_2022;
pragma Assertion_Policy (Pre => Check, Post => Check);

package Automatic_Train_Operation is

   -- Domain-specific strong types mapping to real-world physics
   type Speed_Mps is new Float range 0.0 .. 150.0;
   type Distance_M is new Float range -1000.0 .. 1_000_000.0;
   type Acceleration_Mps2 is new Float range -20.0 .. 10.0;

   -- Grades of Automation (GoA) as defined in ATO specifications
   type GoA_Level is (GoA_1, GoA_2, GoA_3, GoA_4);
   
   -- Possible actions the train control can dictate
   type Train_Action is (Accelerate, Coast, Service_Brake, Emergency_Brake, Stopped);
   
   -- State of the train doors
   type Door_State is (Open, Closed);

   -- 1. Automatic Train Protection (ATP) 
   -- Calculates the maximum safe speed to ensure the train can stop before a hazard.
   function Calculate_ATP_Safe_Speed
     (Track_Limit       : Speed_Mps;
      Distance_To_Stop  : Distance_M;
      Max_Deceleration  : Acceleration_Mps2) return Speed_Mps
     with Global => null,
          Pre  => Max_Deceleration < 0.0,
          Post => Calculate_ATP_Safe_Speed'Result <= Track_Limit;

   -- 2. ATO Speed Regulation
   -- Maintains target speed without exceeding it (used during standard driving).
   function Determine_Drive_Action
     (Current_Speed : Speed_Mps;
      Target_Speed  : Speed_Mps) return Train_Action
     with Global => null,
          Post => Determine_Drive_Action'Result /= Emergency_Brake;

   -- 3. Precision Station Stop
   -- Calculates exact action to bring the train to a precise halt at a station platform.
   function Precision_Station_Stop
     (Current_Speed     : Speed_Mps;
      Distance_To_Mark  : Distance_M;
      Comfort_Decel     : Acceleration_Mps2) return Train_Action
     with Global => null,
          Pre => Comfort_Decel < 0.0;

   -- 4. Automatic Door Control
   -- Opens and closes doors based on safe conditions and Grade of Automation.
   procedure Control_Doors
     (Current_Speed     : Speed_Mps;
      Alignment_Error   : Distance_M;
      Current_GoA       : GoA_Level;
      Doors             : in out Door_State)
     with Global => null;

   -- 5. Unattended Train Operation (UTO) Obstacle Handling
   -- Evaluates and reacts to obstacles dynamically for GoA 4 unattended operations.
   function Handle_Obstacle
     (Obstacle_Detected : Boolean;
      Distance_To_Obs   : Distance_M;
      Current_GoA       : GoA_Level) return Train_Action
     with Global => null,
          Pre => Current_GoA = GoA_4;

end Automatic_Train_Operation;
