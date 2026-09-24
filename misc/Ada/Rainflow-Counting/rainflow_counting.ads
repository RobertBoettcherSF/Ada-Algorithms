--  Rainflow_Counting — Ada 2023 educational package for Wikipedia
--  "Rainflow-counting algorithm" (Endo & Matsuishi 1968; four-point /
--  ASTM-style cycle extraction for fatigue analysis). Converts a varying
--  load/stress history into constant-amplitude reversals with equivalent
--  fatigue damage (compatible with stress–strain hysteresis loops).
--  Primary API: turning-point reduction + four-point rainflow. Optional
--  closed/wrap mode for repeated load blocks. Simple Miner's-rule damage
--  helper with power-law S–N life.

pragma Ada_2022;

package Rainflow_Counting
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 15 for double-precision-like educational numerics.
   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_N : constant Positive := 4_096;
   subtype Sample_Count is Natural range 0 .. Max_N;
   subtype Sample_Index is Positive range 1 .. Max_N;
   subtype Cycle_Count is Natural range 0 .. Max_N;
   subtype Cycle_Index is Positive range 1 .. Max_N;

   type Real_Array is array (Sample_Index range <>) of Real;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Range_Of (X, Y : Real) return Non_Negative
     with Global => null;
   --  r(X,Y) = |X - Y|.

   ---------------------------------------------------------------------------
   -- Cycle record (one full cycle or residual half-cycle)
   ---------------------------------------------------------------------------

   type Cycle is record
      From_Level : Real := 0.0;           --  start extremum of the reversal
      To_Level   : Real := 0.0;           --  end extremum
      Range_Val  : Non_Negative := 0.0;   --  |To - From|
      Amplitude  : Non_Negative := 0.0;   --  Range_Val / 2
      Mean       : Real := 0.0;           --  (From + To) / 2
      Count      : Non_Negative := 1.0;   --  1.0 full; 0.5 residual half
   end record;

   type Cycle_Array is array (Cycle_Index range <>) of Cycle;

   type Cycle_Result is record
      Length : Cycle_Count := 0;
      Items  : Cycle_Array (1 .. Max_N);
   end record;

   ---------------------------------------------------------------------------
   -- Turning points
   ---------------------------------------------------------------------------

   --  Collapse consecutive equals, then keep local extrema (peaks/valleys)
   --  plus the first and last samples of the reduced series. Plateaus become
   --  a single value; interior non-extrema on a monotone run are dropped.

   function Extract_Turning_Points (History : Real_Array) return Real_Array
     with Global => null;
   --  Result'Length <= History'Length. Empty / singleton / flat inputs
   --  yield correspondingly short sequences. Raises Capacity_Exceeded if
   --  the output would exceed Max_N (only possible if History already does
   --  not; History must fit Max_N).

   ---------------------------------------------------------------------------
   -- Four-point rainflow (primary)
   ---------------------------------------------------------------------------

   --  For adjacent turning points A-B-C-D: if interval [min(B,C), max(B,C)]
   --  is contained in [min(A,D), max(A,D)] (equivalently range(B,C) <=
   --  range(A,D) with B,C between A and D), count full cycle B-C, remove B
   --  and C, restart from the beginning of the remaining sequence. When no
   --  more such pairs exist, optionally emit residual consecutive pairs as
   --  half-cycles (Count = 0.5).

   procedure Count_Cycles_Four_Point
     (Turning_Points : Real_Array;
      Result         : out Cycle_Result;
      Include_Residuals : Boolean := True)
     with Global => null;
   --  Turning_Points should already be extrema (use Extract_Turning_Points).
   --  Raises Invalid_Argument if Length > Max_N capacity for working buffer.

   procedure Count_Cycles
     (History           : Real_Array;
      Result            : out Cycle_Result;
      Include_Residuals : Boolean := True;
      Closed            : Boolean := False)
     with Global => null;
   --  Convenience: extract turning points, then four-point count.
   --  If Closed, rotate so the sequence starts at the largest peak and
   --  wrap the history as a repeated load block (largest peak duplicated
   --  at the end) before counting — yields a closed set of full cycles
   --  when the block is periodic.

   ---------------------------------------------------------------------------
   -- Miner's rule damage helper
   ---------------------------------------------------------------------------

   --  Power-law S–N: N(S) = C / S^m for S > 0 (amplitude or stress range
   --  per caller convention). Damage D = sum_i n_i / N_i.

   function Power_Law_Life
     (Amplitude : Positive_Real;
      C_Const   : Positive_Real;
      M_Exp     : Positive_Real) return Positive_Real
     with Global => null;
   --  N = C / Amplitude^m.

   function Total_Damage
     (Cycles  : Cycle_Result;
      C_Const : Positive_Real;
      M_Exp   : Positive_Real) return Non_Negative
     with Global => null;
   --  Miner's D using Power_Law_Life on each cycle's Amplitude.
   --  Cycles with Amplitude = 0 contribute 0. Uses Count as n_i.

   function Total_Damage_With
     (Cycles : Cycle_Result;
      Life   : not null access function
                   (Amplitude : Positive_Real) return Positive_Real)
      return Non_Negative;
   --  Same with a caller-supplied N(S) callback (anonymous access).

   ---------------------------------------------------------------------------
   -- Convenience queries
   ---------------------------------------------------------------------------

   function Full_Cycle_Count (Result : Cycle_Result) return Non_Negative
     with Global => null;
   --  Sum of Count over items with Count >= 1.0 (typically all 1.0 entries).

   function Half_Cycle_Count (Result : Cycle_Result) return Non_Negative
     with Global => null;
   --  Sum of Count over residual half-cycles (Count = 0.5).

   function Equivalent_Full_Cycles (Result : Cycle_Result) return Non_Negative
     with Global => null;
   --  Sum of all Count values (full + half).

end Rainflow_Counting;
