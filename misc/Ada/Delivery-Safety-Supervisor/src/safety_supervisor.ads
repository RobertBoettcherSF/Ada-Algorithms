-- Clean-room educational safety supervisor (not Rivr proprietary).
pragma SPARK_Mode (On);

package Safety_Supervisor
  with SPARK_Mode => On
is
   subtype Speed_Cm_S is Natural range 0 .. 500;
   subtype Coord_Cm is Integer range -100_000 .. 100_000;
   type Time_Ms is mod 2**32;

   type Trip_Reason is
     (None, Overspeed, Outside_Geofence, Teleop_Timeout, E_Stop_Active);

   type Geofence_Kind is (AABB, Radius);

   type Geofence is record
      Kind   : Geofence_Kind := AABB;
      X_Min  : Coord_Cm := -5_000;
      X_Max  : Coord_Cm := 5_000;
      Y_Min  : Coord_Cm := -5_000;
      Y_Max  : Coord_Cm := 5_000;
      CX, CY : Coord_Cm := 0;
      R_Cm   : Natural := 5_000;
   end record;

   type Supervisor is private;

   procedure Init
     (S           : out Supervisor;
      Max_Speed   : Speed_Cm_S;
      Fence       : Geofence;
      Teleop_Ms   : Time_Ms)
     with Global => null,
          Post   => Get_Trip (S) = None;

   procedure Set_Speed_Command (S : in out Supervisor; Cmd : Speed_Cm_S)
     with Global => null;

   procedure Set_Position (S : in out Supervisor; X, Y : Coord_Cm)
     with Global => null;

   procedure Set_E_Stop (S : in out Supervisor; Active : Boolean)
     with Global => null;

   procedure Clear_Trip (S : in out Supervisor)
     with Global => null;

   procedure Tick (S : in out Supervisor; Now : Time_Ms)
     with Global => null;

   function Is_Motion_Allowed (S : Supervisor) return Boolean
     with Global => null;

   function Get_Trip (S : Supervisor) return Trip_Reason
     with Global => null;

   function Effective_Speed (S : Supervisor) return Speed_Cm_S
     with Global => null;

private
   type Supervisor is record
      Max_Speed     : Speed_Cm_S := 100;
      Fence         : Geofence;
      Teleop_Limit  : Time_Ms := 5_000;
      Last_Teleop   : Time_Ms := 0;
      Now           : Time_Ms := 0;
      Cmd_Speed     : Speed_Cm_S := 0;
      Pos_X, Pos_Y  : Coord_Cm := 0;
      E_Stop        : Boolean := False;
      Trip          : Trip_Reason := None;
      Armed         : Boolean := True;
   end record;

   function Get_Trip (S : Supervisor) return Trip_Reason is (S.Trip);

   function Is_Motion_Allowed (S : Supervisor) return Boolean is
     (S.Armed and then S.Trip = None and then not S.E_Stop);

   function Effective_Speed (S : Supervisor) return Speed_Cm_S is
     (if Is_Motion_Allowed (S) then
         (if S.Cmd_Speed <= S.Max_Speed then S.Cmd_Speed else 0)
      else 0);

end Safety_Supervisor;
