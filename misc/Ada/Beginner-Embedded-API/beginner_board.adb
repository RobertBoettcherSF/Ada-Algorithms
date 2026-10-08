pragma Ada_2022;
pragma SPARK_Mode (On);

package body Beginner_Board
  with Refined_State => (Board_State => (Modes, Levels, Tick))
is

   type Mode_Array is array (Pin) of Pin_Mode_Kind;
   type Level_Array is array (Pin) of Pin_Level;

   Modes  : Mode_Array  := [others => Input];
   Levels : Level_Array := [others => Low];
   Tick   : Natural     := 0;

   function Current_Mode (P : Pin) return Pin_Mode_Kind is (Modes (P))
     with Refined_Global => (Input => Modes);

   function Digital_Read (P : Pin) return Pin_Level is (Levels (P))
     with Refined_Global => (Input => Levels);

   function Millis return Natural is (Tick)
     with Refined_Global => (Input => Tick);

   procedure Pin_Mode (P : Pin; Mode : Pin_Mode_Kind)
     with Refined_Global => (In_Out  => (Modes, Levels),
                             Proof_In => Tick)
   is
   begin
      Modes (P) := Mode;
      case Mode is
         when Input_Pullup =>
            Levels (P) := High;
         when Input | Output =>
            Levels (P) := Low;
      end case;
   end Pin_Mode;

   procedure Digital_Write (P : Pin; Level : Pin_Level)
     with Refined_Global => (In_Out  => Levels,
                             Proof_In => (Modes, Tick))
   is
   begin
      Levels (P) := Level;
   end Digital_Write;

   procedure Delay_Ms (Ms : Natural)
     with Refined_Global => (In_Out => Tick),
          Refined_Post   => Tick = Tick'Old + Ms
   is
   begin
      Tick := Tick + Ms;
   end Delay_Ms;

   procedure Simulate_External (P : Pin; Level : Pin_Level)
     with Refined_Global => (In_Out  => Levels,
                             Proof_In => (Modes, Tick))
   is
   begin
      Levels (P) := Level;
   end Simulate_External;

   procedure Reset
     with Refined_Global => (Output => (Modes, Levels, Tick)),
          Refined_Post   => Tick = 0
            and then (for all P in Pin =>
                        Modes (P) = Input and then Levels (P) = Low)
   is
   begin
      Modes  := [others => Input];
      Levels := [others => Low];
      Tick   := 0;
   end Reset;

end Beginner_Board;
