--  exponential_backoff.ads
--  
--  Package specification for Exponential Backoff algorithm and its variants.
--  
--  This package implements the following variants:
--  1. Deterministic Exponential Backoff
--  2. Randomized Exponential Backoff (for collision avoidance)
--  3. Truncated Exponential Backoff (with max retry limit)
--  4. Binary Exponential Backoff (base = 2)
--  5. Adaptive Backoff (Heuristic Retransmission Control Procedure)
--  6. Expected Backoff Calculation
--  7. Recovery Mechanism (reset after cooling-off period)
--  
--  Author: Vibe Code (Mistral AI)
--  Date: 2025

with Ada.Numerics.Discrete_Random;

package Exponential_Backoff is

   --  === Custom Types ===

   --  Base type for the multiplicative factor (e.g., 2 for binary exponential backoff)
   type Base_Type is range 2 .. 100;

   --  Maximum number of retries (for truncated backoff)
   type Max_Retries_Type is range 1 .. 100;

   --  Delay type (in milliseconds or slot times)
   type Delay_Type is range 0 .. 2**31 - 1;

   --  Collision count (number of adverse events)
   type Collision_Count_Type is range 0 .. 100;

   --  Configuration for backoff algorithms
   type Backoff_Config is record
      Base          : Base_Type := 2;       --  Multiplicative factor (default: 2 for BEB)
      Max_Retries   : Max_Retries_Type := 10; --  Maximum retry attempts (for truncated)
      Initial_Delay : Delay_Type := 1;     --  Initial delay (e.g., 1 slot time)
      Slot_Time     : Delay_Type := 512;   --  Slot time (e.g., 51.2 µs in Ethernet, scaled to 512 for simplicity)
   end record;

   --  Default configuration for Binary Exponential Backoff (BEB)
   Default_BEB_Config : constant Backoff_Config := 
     (Base => 2, Max_Retries => 10, Initial_Delay => 1, Slot_Time => 512);

   --  === Exceptions ===

   --  Raised when the number of retries exceeds Max_Retries
   Retry_Limit_Exceeded : exception;

   --  Raised when the base is invalid (e.g., < 2)
   Invalid_Base : exception;

   --  Raised when the collision count is negative
   Invalid_Collision_Count : exception;

   --  === Deterministic Exponential Backoff ===
   --  Computes delay as t = Base^Collision_Count * Initial_Delay
   --  Parameters:
   --    Config         : Backoff configuration (Base, Initial_Delay)
   --    Collision_Count: Number of adverse events (collisions/retries)
   --  Returns:
   --    Delay_Type: Computed delay
   function Deterministic_Backoff (
      Config         : Backoff_Config;
      Collision_Count : Collision_Count_Type
   ) return Delay_Type;

   --  === Randomized Exponential Backoff ===
   --  Computes a random delay in [0, Base^Collision_Count - 1] * Slot_Time
   --  Used for collision avoidance (e.g., Ethernet CSMA/CD)
   --  Parameters:
   --    Config         : Backoff configuration
   --    Collision_Count: Number of adverse events
   --  Returns:
   --    Delay_Type: Random delay
   function Randomized_Backoff (
      Config         : Backoff_Config;
      Collision_Count : Collision_Count_Type
   ) return Delay_Type;

   --  === Truncated Exponential Backoff ===
   --  Caps the collision count at Max_Retries
   --  Parameters:
   --    Config         : Backoff configuration (includes Max_Retries)
   --    Collision_Count: Number of adverse events
   --  Returns:
   --    Delay_Type: Computed delay (capped at Max_Retries)
   function Truncated_Backoff (
      Config         : Backoff_Config;
      Collision_Count : Collision_Count_Type
   ) return Delay_Type;

   --  === Binary Exponential Backoff (BEB) ===
   --  Special case of deterministic backoff with Base = 2
   --  Parameters:
   --    Collision_Count: Number of adverse events
   --    Slot_Time      : Slot time (default: 512)
   --  Returns:
   --    Delay_Type: Computed delay (2^Collision_Count * Slot_Time)
   function Binary_Exponential_Backoff (
      Collision_Count : Collision_Count_Type;
      Slot_Time       : Delay_Type := 512
   ) return Delay_Type;

   --  === Adaptive Backoff (Heuristic RCP) ===
   --  Implements Lam's Heuristic Retransmission Control Procedure
   --  K(m) increases with collisions (e.g., K(0)=1, K(1)=10, K(2)=100, K(3)=200, ...)
   --  Parameters:
   --    Collision_Count: Number of adverse events
   --  Returns:
   --    Delay_Type: Adaptive delay
   function Adaptive_Backoff (
      Collision_Count : Collision_Count_Type
   ) return Delay_Type;

   --  === Expected Backoff ===
   --  Computes the expected delay for randomized backoff
   --  For binary exponential backoff, E(c) = (2^c - 1) / 2
   --  Parameters:
   --    Collision_Count: Number of adverse events
   --    Base           : Multiplicative factor (default: 2)
   --  Returns:
   --    Delay_Type: Expected delay
   function Expected_Backoff (
      Collision_Count : Collision_Count_Type;
      Base            : Base_Type := 2
   ) return Delay_Type;

   --  === Recovery Mechanism ===
   --  Resets the collision count after a cooling-off period
   --  Parameters:
   --    Current_Count: Current collision count
   --    Cooling_Off  : Whether the cooling-off period has elapsed
   --  Returns:
   --    Collision_Count_Type: Reset count (0 if cooling-off, else unchanged)
   function Reset_Backoff (
      Current_Count : Collision_Count_Type;
      Cooling_Off    : Boolean
   ) return Collision_Count_Type;

   --  === Helper Functions ===

   --  Computes Base^Exponent (for deterministic backoff)
   function Compute_Power (
      Base     : Base_Type;
      Exponent : Collision_Count_Type
   ) return Delay_Type;

   --  Validates the backoff configuration
   --  Raises Invalid_Base if Base < 2
   procedure Validate_Config (Config : Backoff_Config);

   --  Generates a random number in [0, Max_Value]
   --  Used for randomized backoff
   function Random_Delay (Max_Value : Delay_Type) return Delay_Type;

end Exponential_Backoff;
