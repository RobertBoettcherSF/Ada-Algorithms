pragma SPARK_Mode (On);

package body Safety_Supervisor
  with SPARK_Mode => On
is
   function Inside_Fence (S : Supervisor) return Boolean is
      DX : Integer;
      DY : Integer;
   begin
      case S.Fence.Kind is
         when AABB =>
            return S.Pos_X >= S.Fence.X_Min
              and then S.Pos_X <= S.Fence.X_Max
              and then S.Pos_Y >= S.Fence.Y_Min
              and then S.Pos_Y <= S.Fence.Y_Max;
         when Radius =>
            DX := S.Pos_X - S.Fence.CX;
            DY := S.Pos_Y - S.Fence.CY;
            -- Compare squared distance to avoid floats (bounded coords).
            return (DX * DX + DY * DY) <= Integer (S.Fence.R_Cm) * Integer (S.Fence.R_Cm);
      end case;
   end Inside_Fence;

   procedure Init
     (S           : out Supervisor;
      Max_Speed   : Speed_Cm_S;
      Fence       : Geofence;
      Teleop_Ms   : Time_Ms)
   is
   begin
      S := (Max_Speed    => Max_Speed,
            Fence        => Fence,
            Teleop_Limit => Teleop_Ms,
            Last_Teleop  => 0,
            Now          => 0,
            Cmd_Speed    => 0,
            Pos_X        => 0,
            Pos_Y        => 0,
            E_Stop       => False,
            Trip         => None,
            Armed        => True);
   end Init;

   procedure Set_Speed_Command (S : in out Supervisor; Cmd : Speed_Cm_S) is
   begin
      S.Cmd_Speed := Cmd;
      S.Last_Teleop := S.Now;
      if Cmd > S.Max_Speed then
         S.Trip := Overspeed;
         S.Armed := False;
         S.Cmd_Speed := 0;
      end if;
   end Set_Speed_Command;

   procedure Set_Position (S : in out Supervisor; X, Y : Coord_Cm) is
   begin
      S.Pos_X := X;
      S.Pos_Y := Y;
   end Set_Position;

   procedure Set_E_Stop (S : in out Supervisor; Active : Boolean) is
   begin
      S.E_Stop := Active;
      if Active then
         S.Trip := E_Stop_Active;
         S.Armed := False;
         S.Cmd_Speed := 0;
      end if;
   end Set_E_Stop;

   procedure Clear_Trip (S : in out Supervisor) is
   begin
      if not S.E_Stop and then Inside_Fence (S) then
         S.Trip := None;
         S.Armed := True;
      end if;
   end Clear_Trip;

   procedure Tick (S : in out Supervisor; Now : Time_Ms) is
      Elapsed : Time_Ms;
   begin
      S.Now := Now;
      if not Inside_Fence (S) then
         S.Trip := Outside_Geofence;
         S.Armed := False;
         S.Cmd_Speed := 0;
         return;
      end if;
      if S.Teleop_Limit > 0 then
         Elapsed := Now - S.Last_Teleop;
         if Elapsed > S.Teleop_Limit and then S.Cmd_Speed > 0 then
            S.Trip := Teleop_Timeout;
            S.Armed := False;
            S.Cmd_Speed := 0;
         end if;
      end if;
   end Tick;

end Safety_Supervisor;
