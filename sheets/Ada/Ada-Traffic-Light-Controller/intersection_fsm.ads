--  Intersection_FSM
--  Two-axis (NS/EW) traffic intersection finite-state machine.
--  Safety: never both axes Green; all-red clearance between serves;
--  Fault forces All_Red on both axes.
--  Clean-room educational design — not copied from Foundry demos.

with Traffic_Phases;

package Intersection_FSM is

   use Traffic_Phases;

   type Axis is (North_South, East_West);

   type Intersection is private;

   function Create return Intersection;
   --  Initial: both axes Red, not faulted, no active serve.

   function Color_Of (I : Intersection; A : Axis) return Signal_Color;
   function Pedestrian_Of
     (I : Intersection; A : Axis) return Pedestrian_Indication;

   function Is_Faulted (I : Intersection) return Boolean;
   function In_All_Red (I : Intersection) return Boolean;
   function Active_Axis (I : Intersection) return Axis;
   --  Axis currently holding Green or Yellow (meaningless if All_Red).

   function Is_Safe (I : Intersection) return Boolean;
   --  True when vehicle colors do not conflict (never both Green, etc.).

   procedure Grant_Green
     (I        : in out Intersection;
      For_Axis : Axis;
      Accepted : out Boolean);
   --  Accepted only from All_Red (or initial) when not faulted.
   --  Rejected if the other axis is Green/Yellow (conflict path).

   procedure Enter_Yellow
     (I        : in out Intersection;
      Accepted : out Boolean);
   --  Active Green axis → Yellow; other stays Red.

   procedure Enter_All_Red
     (I        : in out Intersection;
      Accepted : out Boolean);
   --  Clearance: both Red. Accepted from Yellow (or already All_Red).

   procedure Raise_Fault (I : in out Intersection);
   --  Fault → both Red (All_Red), faulted flag set.

   procedure Clear_Fault (I : in out Intersection);
   --  Clears faulted flag; remains All_Red until next Grant_Green.

private

   type Signal_Pair is array (Axis) of Signal_Color;

   type Intersection is record
      Signals  : Signal_Pair := [others => Red];
      Faulted  : Boolean     := False;
      Serving  : Axis        := North_South;
      Has_Serve : Boolean    := False;
   end record;

end Intersection_FSM;
