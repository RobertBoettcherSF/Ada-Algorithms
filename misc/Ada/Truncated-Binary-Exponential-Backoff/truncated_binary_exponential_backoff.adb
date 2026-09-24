--  truncated_binary_exponential_backoff.adb
--
--  Package body for Truncated Binary Exponential Backoff (TBEB) algorithm.
--  Implements all variants: deterministic, randomized, truncated, static/dynamic ceiling.
--
--  Author: Vibe Code (Mistral AI)
--  Date: 2025
--
--  Description:
--  This package body contains the implementation of the Truncated Binary Exponential
--  Backoff (TBEB) algorithm. It provides functions for calculating delays using
--  various BEB variants, managing state, and validating configurations.
--
--  The algorithm works as follows:
--  1. On each collision, increment the collision count
--  2. Calculate delay based on: base^c * slot_time (deterministic)
--     or random(0, base^c - 1) * slot_time (randomized)
--  3. If c > ceiling, clamp c to ceiling (truncated)
--
--  References:
--  - Wikipedia: https://en.wikipedia.org/wiki/Truncated_binary_exponential_backoff
--  - IEEE 802.3 CSMA/CD standard (ceiling = 10, max delay = 1023 slot times).

with Ada.Numerics.Discrete_Random;

package body Truncated_Binary_Exponential_Backoff is

   --  ========================================================================
   --  Random Number Generator for Randomized Delays
   --  ========================================================================

   --  Instantiate discrete random number generator for Integer type
   package Random_Int is new Ada.Numerics.Discrete_Random (Integer);
   Gen : Random_Int.Generator;

   --  ========================================================================
   --  Helper Functions
   --  ========================================================================

   --  Computes base^exponent using iterative multiplication.
   --  
   --  Parameters:
   --    Base     - The base of the exponentiation
   --    Exponent - The exponent (must be non-negative)
   --  
   --  Returns:
   --    Base raised to the power of Exponent
   --  
   --  Example: Power(2, 3) = 8, Power(3, 2) = 9
   function Power (Base, Exponent : Integer) return Integer is
      Result : Integer := 1;
   begin
      for I in 1 .. Exponent loop
         Result := Result * Base;
      end loop;
      return Result;
   end Power;

   --  Computes 2^c (binary exponential) using the general Power function.
   --  
   --  Parameters:
   --    C - The collision count (exponent)
   --  
   --  Returns:
   --    2 raised to the power of C
   --  
   --  Note: This is a convenience function for binary exponential backoff where base=2.
   function Power_Of_Two (C : Collision_Count_Type) return Integer is
   begin
      return Power (2, Integer(C));
   end Power_Of_Two;

   --  Clamps the collision count to the ceiling value.
   --  
   --  This ensures that the collision count never exceeds the configured ceiling,
   --  preventing unbounded delay growth in the truncated BEB variant.
   --  
   --  Parameters:
   --    C       - The current collision count
   --    Ceiling - The maximum allowed collision count
   --  
   --  Returns:
   --    C if C <= Ceiling, otherwise Ceiling
   --  
   --  Example: Clamp_Collision_Count(15, 10) returns 10
   function Clamp_Collision_Count (
      C       : Collision_Count_Type;
      Ceiling : Ceiling_Type
   ) return Collision_Count_Type is
   begin
      if C <= Collision_Count_Type(Ceiling) then
         return C;
      else
         return Collision_Count_Type(Ceiling);
      end if;
   end Clamp_Collision_Count;

   --  ========================================================================
   --  Validation Procedures
   --  ========================================================================

   --  Validates the backoff configuration.
   --  
   --  Checks that:
   --    - Base is at least 2 (required for exponential growth)
   --    - Slot_Time is positive (required for meaningful delays)
   --  
   --  Parameters:
   --    Config - The configuration to validate
   --  
   --  Raises:
   --    Invalid_Config - If any validation check fails
   procedure Validate_Config (Config : Backoff_Config) is
   begin
      if Config.Base < 2 then
         raise Invalid_Config with "Base must be >= 2 for exponential backoff.";
      end if;
      if Config.Slot_Time <= 0 then
         raise Invalid_Config with "Slot_Time must be > 0.";
      end if;
   end Validate_Config;

   --  Validates the ceiling value.
   --  
   --  Checks that the ceiling is non-negative.
   --  
   --  Parameters:
   --    Ceiling - The ceiling value to validate
   --  
   --  Raises:
   --    Invalid_Ceiling - If ceiling is negative
   procedure Validate_Ceiling (Ceiling : Ceiling_Type) is
   begin
      if Ceiling < 0 then
         raise Invalid_Ceiling with "Ceiling must be >= 0.";
      end if;
   end Validate_Ceiling;

   --  ========================================================================
   --  Core Delay Calculation Functions
   --  ========================================================================

   --  Calculates the deterministic delay for a given collision count.
   --  
   --  The deterministic delay is calculated as: base^c * slot_time
   --  
   --  This is the simplest form of BEB where the delay increases exponentially
   --  with each collision. The delay is predictable and repeatable for the same
   --  collision count.
   --  
   --  Parameters:
   --    Config - The backoff configuration
   --    C      - The collision count
   --  
   --  Returns:
   --    The calculated delay in time units
   --  
   --  Example: With base=2, slot_time=512, c=3: delay = 2^3 * 512 = 4096
   function Deterministic_Delay (
      Config : Backoff_Config;
      C      : Collision_Count_Type
   ) return Delay_Type is
      Exponent : Integer := Integer(C);
   begin
      Validate_Config (Config);
      return Delay_Type (Power (Integer(Config.Base), Exponent) * Integer(Config.Slot_Time));
   end Deterministic_Delay;

   --  Calculates a randomized delay for a given collision count.
   --  
   --  The randomized delay is a random value in the range [0, base^c - 1] * slot_time.
   --  This randomization helps avoid synchronization between multiple nodes
   --  attempting to retransmit, which could lead to repeated collisions.
   --  
   --  Parameters:
   --    Config - The backoff configuration
   --    C      - The collision count
   --  
   --  Returns:
   --    A random delay in the range [0, base^c - 1] * slot_time
   --  
   --  Example: With base=2, slot_time=512, c=2: delay is random in [0, 3] * 512
   function Randomized_Delay (
      Config : Backoff_Config;
      C      : Collision_Count_Type
   ) return Delay_Type is
      Max_Random : Integer := Power_Of_Two (C) - 1;
      Random_Value : Integer;
   begin
      Validate_Config (Config);
      if Max_Random <= 0 then
         return 0;
      end if;
      Random_Value := Random_Int.Random (Gen) mod (Max_Random + 1);
      return Delay_Type (Random_Value * Integer(Config.Slot_Time));
   end Randomized_Delay;

   --  ========================================================================
   --  Truncated Variants
   --  ========================================================================

   --  Calculates the deterministic delay with truncation at the ceiling.
   --  
   --  This variant clamps the collision count to the ceiling before calculating
   --  the delay, preventing unbounded growth. This is important in real-world
   --  scenarios where delays cannot grow indefinitely.
   --  
   --  Parameters:
   --    Config - The backoff configuration (includes ceiling)
   --    C      - The collision count
   --  
   --  Returns:
   --    The deterministic delay, truncated at the ceiling
   --  
   --  Example: With ceiling=5, c=10: delay = base^5 * slot_time (not base^10)
   function Truncated_Deterministic_Delay (
      Config : Backoff_Config;
      C      : Collision_Count_Type
   ) return Delay_Type is
      Clamped_C : Collision_Count_Type := Clamp_Collision_Count (C, Config.Ceiling);
   begin
      Validate_Config (Config);
      Validate_Ceiling (Config.Ceiling);
      return Deterministic_Delay (Config, Clamped_C);
   end Truncated_Deterministic_Delay;

   --  Calculates the randomized delay with truncation at the ceiling.
   --  
   --  Similar to Truncated_Deterministic_Delay but uses randomized delay calculation.
   --  The random value is chosen from [0, base^min(c,ceiling) - 1] * slot_time.
   --  
   --  Parameters:
   --    Config - The backoff configuration (includes ceiling)
   --    C      - The collision count
   --  
   --  Returns:
   --    A random delay, truncated at the ceiling
   --  
   --  Example: With ceiling=5, c=10: delay is random in [0, base^5 - 1] * slot_time
   function Truncated_Randomized_Delay (
      Config : Backoff_Config;
      C      : Collision_Count_Type
   ) return Delay_Type is
      Clamped_C : Collision_Count_Type := Clamp_Collision_Count (C, Config.Ceiling);
   begin
      Validate_Config (Config);
      Validate_Ceiling (Config.Ceiling);
      return Randomized_Delay (Config, Clamped_C);
   end Truncated_Randomized_Delay;

   --  ========================================================================
   --  State Management Procedures
   --  ========================================================================

   --  Initializes the backoff state to its default values.
   --  
   --  Sets both collision_count and current_delay to zero, representing
   --  the initial state before any collisions have occurred.
   --  
   --  Parameters:
   --    State - The state to initialize (out parameter)
   procedure Initialize_State (State : out Backoff_State) is
   begin
      State.Collision_Count := 0;
      State.Current_Delay := 0;
   end Initialize_State;

   --  Resets the backoff state to its default values.
   --  
   --  This is useful when you want to restart the backoff process, for example
   --  after a successful transmission or when starting a new operation.
   --  
   --  Parameters:
   --    State - The state to reset (in out parameter)
   procedure Reset_State (State : in out Backoff_State) is
   begin
      State.Collision_Count := 0;
      State.Current_Delay := 0;
   end Reset_State;

   --  Increments the collision count and calculates a new delay.
   --  
   --  This procedure should be called each time a collision is detected.
   --  It increments the collision count, then calculates a new delay based on
   --  the current count and configuration. The delay is stored in the state.
   --  
   --  Parameters:
   --    State      - The state to update (in out parameter)
   --    Config     - The backoff configuration to use
   --    Use_Random - If True, use randomized delay; if False, use deterministic
   --  
   --  Example:
   --    Initialize_State (My_State);
   --    Increment_Collision (My_State, My_Config, Use_Random => True);
   --    -- My_State.Current_Delay now contains the backoff delay
   procedure Increment_Collision (
      State      : in out Backoff_State;
      Config     : Backoff_Config;
      Use_Random : Boolean := True
   ) is
   begin
      Validate_Config (Config);
      State.Collision_Count := State.Collision_Count + 1;
      if Use_Random then
         State.Current_Delay := Truncated_Randomized_Delay (Config, State.Collision_Count);
      else
         State.Current_Delay := Truncated_Deterministic_Delay (Config, State.Collision_Count);
      end if;
   end Increment_Collision;

   --  ========================================================================
   --  Expected Delay Calculation
   --  ========================================================================

   --  Calculates the expected (average) delay for randomized BEB.
   --  
   --  For randomized BEB with range [0, base^c - 1] * slot_time, the expected
   --  value is (base^c - 1) / 2 * slot_time. This represents the average
   --  delay that would be experienced over many collisions.
   --  
   --  Parameters:
   --    Config - The backoff configuration
   --    C      - The collision count
   --  
   --  Returns:
   --    The expected (average) delay
   --  
   --  Note: Uses integer arithmetic with division by 2 at the end to maintain
   --  precision. For example, with c=1: (2^1 - 1)/2 * 512 = 0.5 * 512 = 256
   function Expected_Delay (
      Config : Backoff_Config;
      C      : Collision_Count_Type
   ) return Delay_Type is
      Max_Random : Integer := Power_Of_Two (C) - 1;
   begin
      Validate_Config (Config);
      if Max_Random <= 0 then
         return 0;
      end if;
      --  Use division with remainder for accurate average calculation
      return Delay_Type ((Max_Random * Integer(Config.Slot_Time)) / 2);
   end Expected_Delay;

   --  Calculates the expected delay with truncation at the ceiling.
   --  
   --  Similar to Expected_Delay but clamps the collision count to the ceiling
   --  before calculating the expected value.
   --  
   --  Parameters:
   --    Config - The backoff configuration (includes ceiling)
   --    C      - The collision count
   --  
   --  Returns:
   --    The expected delay, truncated at the ceiling
   function Truncated_Expected_Delay (
      Config : Backoff_Config;
      C      : Collision_Count_Type
   ) return Delay_Type is
      Clamped_C : Collision_Count_Type := Clamp_Collision_Count (C, Config.Ceiling);
   begin
      Validate_Config (Config);
      Validate_Ceiling (Config.Ceiling);
      return Expected_Delay (Config, Clamped_C);
   end Truncated_Expected_Delay;

begin
   --  Initialize the random number generator.
   --  This ensures that randomized delays are different each time the program runs.
   Random_Int.Reset (Gen);
end Truncated_Binary_Exponential_Backoff;
