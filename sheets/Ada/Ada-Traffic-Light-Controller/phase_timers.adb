package body Phase_Timers is

   function Required_For (Cfg : Config; Phase : Phase_Kind) return Tick_Count is
   begin
      case Phase is
         when Min_Green =>
            return Cfg.Min_Green_Ticks;
         when Yellow =>
            return Cfg.Yellow_Ticks;
         when All_Red =>
            return Cfg.All_Red_Ticks;
      end case;
   end Required_For;

   function Make
     (Cfg     : Config;
      Initial : Phase_Kind := Min_Green) return Timer
   is
   begin
      return (Cfg => Cfg, Phase => Initial, Ticks_Elapsed => 0);
   end Make;

   function Current_Phase (T : Timer) return Phase_Kind is
   begin
      return T.Phase;
   end Current_Phase;

   function Elapsed (T : Timer) return Tick_Count is
   begin
      return T.Ticks_Elapsed;
   end Elapsed;

   function Required (T : Timer) return Tick_Count is
   begin
      return Required_For (T.Cfg, T.Phase);
   end Required;

   function Can_Advance (T : Timer) return Boolean is
   begin
      return T.Ticks_Elapsed >= Required_For (T.Cfg, T.Phase);
   end Can_Advance;

   procedure Tick (T : in out Timer) is
   begin
      if T.Ticks_Elapsed < Tick_Count'Last then
         T.Ticks_Elapsed := T.Ticks_Elapsed + 1;
      end if;
   end Tick;

   procedure Advance
     (T    : in out Timer;
      Next : Phase_Kind;
      Ok   : out Boolean)
   is
   begin
      if Can_Advance (T) then
         T.Phase         := Next;
         T.Ticks_Elapsed := 0;
         Ok              := True;
      else
         Ok := False;
      end if;
   end Advance;

   procedure Force_Phase
     (T     : in out Timer;
      Phase : Phase_Kind)
   is
   begin
      T.Phase         := Phase;
      T.Ticks_Elapsed := 0;
   end Force_Phase;

end Phase_Timers;
