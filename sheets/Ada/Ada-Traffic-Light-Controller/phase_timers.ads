--  Phase_Timers
--  Discrete tick timers for min-green, yellow, and all-red holds.
--  Advance is gated until the required tick count elapses.

package Phase_Timers is

   type Tick_Count is range 0 .. 10_000;

   type Phase_Kind is (Min_Green, Yellow, All_Red);

   type Config is record
      Min_Green_Ticks : Tick_Count := 5;
      Yellow_Ticks    : Tick_Count := 2;
      All_Red_Ticks   : Tick_Count := 1;
   end record;

   type Timer is private;

   function Make
     (Cfg     : Config;
      Initial : Phase_Kind := Min_Green) return Timer;

   function Current_Phase (T : Timer) return Phase_Kind;
   function Elapsed (T : Timer) return Tick_Count;
   function Required (T : Timer) return Tick_Count;
   function Can_Advance (T : Timer) return Boolean;
   --  True iff Elapsed >= Required for the active phase.

   procedure Tick (T : in out Timer);

   procedure Advance
     (T    : in out Timer;
      Next : Phase_Kind;
      Ok   : out Boolean);
   --  If Can_Advance, switch to Next and reset elapsed; else Ok = False
   --  and state unchanged (timer gate).

   procedure Force_Phase
     (T     : in out Timer;
      Phase : Phase_Kind);
   --  Unconditional phase switch (used on fault / reset); elapsed := 0.

private

   type Timer is record
      Cfg            : Config;
      Phase          : Phase_Kind := Min_Green;
      Ticks_Elapsed  : Tick_Count := 0;
   end record;

end Phase_Timers;
