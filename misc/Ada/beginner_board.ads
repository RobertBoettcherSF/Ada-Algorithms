pragma Ada_2022;
pragma SPARK_Mode (On);
pragma Unevaluated_Use_Of_Old (Allow);

--  Single public package: Arduino-like beginner digital I/O API.
--  This body is a host simulator; a future board target would swap the body.
--  Educational only — not a full ADL/HAL. Not affiliated with Arduino/Qualcomm.

package Beginner_Board
  with Abstract_State => Board_State,
       Initializes    => Board_State
is

   type Pin is range 0 .. 31;

   type Pin_Mode_Kind is (Input, Output, Input_Pullup);

   type Pin_Level is (Low, High);

   function Current_Mode (P : Pin) return Pin_Mode_Kind
     with Global => (Input => Board_State);

   function Digital_Read (P : Pin) return Pin_Level
     with Global => (Input => Board_State);

   function Millis return Natural
     with Global => (Input => Board_State);
   --  Simulated millisecond tick counter (host tests). Not wall-clock time.

   procedure Pin_Mode (P : Pin; Mode : Pin_Mode_Kind)
     with Global => (In_Out => Board_State),
          Post   => Current_Mode (P) = Mode
            and then (if Mode = Input_Pullup then Digital_Read (P) = High)
            and then (if Mode = Input then Digital_Read (P) = Low)
            and then (if Mode = Output then Digital_Read (P) = Low)
            and then Millis = Millis'Old;

   procedure Digital_Write (P : Pin; Level : Pin_Level)
     with Global => (In_Out => Board_State),
          Pre    => Current_Mode (P) = Output,
          Post   => Current_Mode (P) = Output
            and then Digital_Read (P) = Level
            and then Millis = Millis'Old;

   procedure Delay_Ms (Ms : Natural)
     with Global => (In_Out => Board_State),
          Pre    => Ms <= Natural'Last - Millis,
          Post   => Millis = Millis'Old + Ms;
   --  Host simulation: advances Millis only (no real sleep). Documented stub.

   procedure Simulate_External (P : Pin; Level : Pin_Level)
     with Global => (In_Out => Board_State),
          Pre    => Current_Mode (P) in Input | Input_Pullup,
          Post   => Current_Mode (P) = Current_Mode (P)'Old
            and then Digital_Read (P) = Level
            and then Millis = Millis'Old;
   --  Test/simulator helper: drive an input pin as if from outside hardware.

   procedure Reset
     with Global => (Output => Board_State),
          Post   => Millis = 0
            and then (for all P in Pin =>
                        Current_Mode (P) = Input
                        and then Digital_Read (P) = Low);
   --  Clear simulator state for deterministic V&V tests.

end Beginner_Board;
