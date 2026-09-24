--  truncated_binary_exponential_backoff.ads
--  
--  Package specification for Truncated Binary Exponential Backoff (TBEB) algorithm.
--  Implements all variants: deterministic, randomized, truncated, static/dynamic ceiling.
--  
--  Author: Vibe Code (Mistral AI)
--  Date: 2025
--
--  Description:
--  This package provides types and subprograms for implementing the Truncated Binary
--  Exponential Backoff (TBEB) algorithm and its variants. The algorithm is used in
--  network protocols (e.g., Ethernet CSMA/CD) to avoid collisions by exponentially
--  increasing the delay between retransmission attempts after each failure, up to a
--  maximum limit (ceiling).
--
--  Key Concepts:
--  - Binary Exponential Backoff (BEB): Doubles delay after each collision (base = 2).
--  - Truncated BEB: Limits the exponent to a ceiling to avoid unbounded delays.
--  - Randomized BEB: Delay is a random value in [0, 2^c - 1] slot times.
--  - Deterministic BEB: Delay is exactly 2^c slot times.
--
--  References:
--  - Wikipedia: https://en.wikipedia.org/wiki/Truncated_binary_exponential_backoff
--  - IEEE 802.3 CSMA/CD standard (ceiling = 10, max delay = 1023 slot times).

with Ada.Numerics.Discrete_Random;

package Truncated_Binary_Exponential_Backoff is

   --  ========================================================================
   --  Custom Types
   --  ========================================================================

   --  Type for slot time (e.g., microseconds, milliseconds, or abstract units).
   type Slot_Time_Type is range 0 .. Integer'Last;

   --  Type for delay values (in slot times or absolute time units).
   type Delay_Type is range 0 .. Integer'Last;

   --  Type for collision count (non-negative integer).
   type Collision_Count_Type is range 0 .. Integer'Last;

   --  Type for the base of the exponential backoff (must be >= 2).
   type Base_Type is range 2 .. Integer'Last;

   --  Type for the ceiling (maximum exponent value).
   type Ceiling_Type is range 0 .. Integer'Last;

   --  Configuration for the backoff algorithm.
   type Backoff_Config is record
      Base      : Base_Type;
      Ceiling   : Ceiling_Type;
      Slot_Time : Slot_Time_Type;
   end record;

   Default_Config : constant Backoff_Config := (
      Base      => 2,
      Ceiling   => 10,
      Slot_Time => 512
   );

   --  State of the backoff algorithm (tracks current collision count).
   type Backoff_State is record
      Collision_Count : Collision_Count_Type;
      Current_Delay   : Delay_Type;
   end record;

   --  ========================================================================
   --  Exceptions
   --  ========================================================================

   Invalid_Config : exception;
   Invalid_Collision_Count : exception;
   Invalid_Ceiling : exception;

   --  ========================================================================
   --  Subprogram Declarations
   --  ========================================================================

   --  Core Delay Calculation Functions
   function Deterministic_Delay (
      Config : Backoff_Config;
      C      : Collision_Count_Type
   ) return Delay_Type;

   function Randomized_Delay (
      Config : Backoff_Config;
      C      : Collision_Count_Type
   ) return Delay_Type;

   --  Truncated Variants
   function Truncated_Deterministic_Delay (
      Config : Backoff_Config;
      C      : Collision_Count_Type
   ) return Delay_Type;

   function Truncated_Randomized_Delay (
      Config : Backoff_Config;
      C      : Collision_Count_Type
   ) return Delay_Type;

   --  State Management
   procedure Initialize_State (State : out Backoff_State);
   procedure Reset_State (State : in out Backoff_State);
   procedure Increment_Collision (
      State      : in out Backoff_State;
      Config     : Backoff_Config;
      Use_Random : Boolean := True
   );

   --  Expected Delay Calculation
   function Expected_Delay (
      Config : Backoff_Config;
      C      : Collision_Count_Type
   ) return Delay_Type;

   function Truncated_Expected_Delay (
      Config : Backoff_Config;
      C      : Collision_Count_Type
   ) return Delay_Type;

   --  Validation
   procedure Validate_Config (Config : Backoff_Config);
   procedure Validate_Ceiling (Ceiling : Ceiling_Type);

   --  Helper Functions
   function Power_Of_Two (C : Collision_Count_Type) return Integer;
   function Clamp_Collision_Count (
      C       : Collision_Count_Type;
      Ceiling : Ceiling_Type
   ) return Collision_Count_Type;

   --  Array Type for Simulations
   type Delay_Array is array (Positive range <>) of Delay_Type;

end Truncated_Binary_Exponential_Backoff;
