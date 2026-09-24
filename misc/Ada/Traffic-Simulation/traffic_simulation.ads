--  Traffic_Simulation.ads
--  Provides types and subprograms for Macroscopic, Microscopic, and Mesoscopic
--  traffic simulation models based on standard traffic flow theory.

package Traffic_Simulation
  with SPARK_Mode => On
is
   --  Strongly typed physical quantities
   type Meters is new Float range 0.0 .. 1_000_000.0;
   type Meters_Per_Second is new Float range 0.0 .. 1_000.0;
   type Meters_Per_Second_Squared is new Float range 0.0 .. 100.0;
   type Seconds is new Float range 0.0 .. 86_400.0;
   
   type Vehicles_Per_Kilometer is new Float range 0.0 .. 2_000.0;
   type Vehicles_Per_Hour is new Float range 0.0 .. 20_000.0;
   type Vehicle_Volume is new Float range 0.0 .. 1_000_000.0;

   --  Subtypes for safe parameters
   subtype Positive_Seconds is Seconds range 0.001 .. Seconds'Last;
   subtype Positive_Headway is Seconds range 0.1 .. 100.0;

   --  Exceptions
   Collision_Error : exception;

   -----------------------------------------------------------------------------
   --  MICROSCOPIC MODEL (Car-Following)
   --  Models individual vehicles using a kinematic intelligent braking model.
   -----------------------------------------------------------------------------
   type Microscopic_State is record
      Position : Meters;
      Speed    : Meters_Per_Second;
   end record;

   type Driver_Behavior is record
      Desired_Speed      : Meters_Per_Second;
      Safe_Time_Headway  : Positive_Headway;
      Max_Acceleration   : Meters_Per_Second_Squared;
      Max_Deceleration   : Meters_Per_Second_Squared;
      Minimum_Gap        : Meters;
   end record;

   --  Advances the microscopic state of a following vehicle for a single time step.
   --  Raises Collision_Error if the gap is smaller than the Minimum_Gap.
   procedure Advance_Microscopic
     (State         : in out Microscopic_State;
      Behavior      : in     Driver_Behavior;
      Gap_To_Leader : in     Meters;
      Leader_Speed  : in     Meters_Per_Second;
      Time_Step     : in     Positive_Seconds)
   with Pre => Gap_To_Leader >= 0.0;

   -----------------------------------------------------------------------------
   --  MACROSCOPIC MODEL (Greenshields / Kinematic Wave)
   --  Models aggregate traffic flow and density based on the fundamental diagram.
   -----------------------------------------------------------------------------
   
   --  Calculates flow and speed from current density using the Greenshields model.
   procedure Calculate_Macroscopic_State
     (Density          : in  Vehicles_Per_Kilometer;
      Free_Flow_Speed  : in  Meters_Per_Second;
      Jam_Density      : in  Vehicles_Per_Kilometer;
      Resulting_Flow   : out Vehicles_Per_Hour;
      Resulting_Speed  : out Meters_Per_Second)
   with Pre => Jam_Density > 0.0 and Free_Flow_Speed > 0.0;

   -----------------------------------------------------------------------------
   --  MESOSCOPIC MODEL (Platoons and Link Queues)
   --  Models groups of vehicles (platoons) moving through links and discharging.
   -----------------------------------------------------------------------------
   type Platoon_State is (Moving, Queued, Discharged);

   type Platoon is record
      Size         : Vehicle_Volume;
      State        : Platoon_State;
      Time_To_Node : Seconds;
   end record;

   --  Advances a mesoscopic platoon along a link and updates its discharge.
   procedure Advance_Mesoscopic_Platoon
     (P                : in out Platoon;
      Link_Capacity    : in     Vehicles_Per_Hour;
      Time_Step        : in     Positive_Seconds;
      Discharged_Count : out    Vehicle_Volume)
   with Post => P.Size <= P'Old.Size;

end Traffic_Simulation;
