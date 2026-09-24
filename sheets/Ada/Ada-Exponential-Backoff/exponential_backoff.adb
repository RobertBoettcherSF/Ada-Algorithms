--  exponential_backoff.adb
--  
--  Package body for Exponential Backoff algorithm and its variants.
--  
--  This file implements all procedures and functions declared in exponential_backoff.ads.
--  
--  Author: Vibe Code (Mistral AI)
--  Date: 2025

with Ada.Numerics.Discrete_Random;

package body Exponential_Backoff is

   --  === Random Number Generator ===
   --  Used for randomized backoff
   package Random_Delay_Pkg is new Ada.Numerics.Discrete_Random (Delay_Type);
   Gen : Random_Delay_Pkg.Generator;

   --  === Helper Functions ===

   --  Computes Base^Exponent using iterative multiplication
   --  Parameters:
   --    Base     : Multiplicative factor (e.g., 2 for BEB)
   --    Exponent : Number of adverse events (collision count)
   --  Returns:
   --    Delay_Type: Base^Exponent
   function Compute_Power (
      Base     : Base_Type;
      Exponent : Collision_Count_Type
   ) return Delay_Type is
      Result : Delay_Type := 1;
      B : Integer := Integer(Base); -- Convert to Integer for multiplication
   begin
      -- Iteratively multiply to compute Base^Exponent
      for I in 1 .. Integer(Exponent) loop
         Result := Result * Delay_Type(B); -- Convert back to Delay_Type for each step
      end loop;
      return Result;
   end Compute_Power;

   --  Validates the backoff configuration
   --  Raises Invalid_Base if Base < 2
   procedure Validate_Config (Config : Backoff_Config) is
   begin
      if Integer(Config.Base) < 2 then
         raise Invalid_Base with "Base must be >= 2 for exponential backoff";
      end if;
   end Validate_Config;

   --  Generates a random delay in [0, Max_Value]
   --  Used for randomized backoff (collision avoidance)
   function Random_Delay (Max_Value : Delay_Type) return Delay_Type is
      Random_Value : Delay_Type;
   begin
      Random_Value := Random_Delay_Pkg.Random(Gen) mod (Max_Value + 1);
      return Random_Value;
   end Random_Delay;

   --  === Deterministic Exponential Backoff ===
   --  Computes delay as t = Base^Collision_Count * Initial_Delay
   --  Parameters:
   --    Config         : Backoff configuration (Base, Initial_Delay)
   --    Collision_Count: Number of adverse events
   --  Returns:
   --    Delay_Type: Computed delay
   function Deterministic_Backoff (
      Config         : Backoff_Config;
      Collision_Count : Collision_Count_Type
   ) return Delay_Type is
      Power_Value : Delay_Type;
   begin
      Validate_Config(Config);
      Power_Value := Compute_Power(Config.Base, Collision_Count);
      return Power_Value * Config.Initial_Delay;
   end Deterministic_Backoff;

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
   ) return Delay_Type is
      Max_Random : Delay_Type;
      Power_Value : Delay_Type;
      Random_Slots : Delay_Type;
   begin
      Validate_Config(Config);
      Power_Value := Compute_Power(Config.Base, Collision_Count);
      Max_Random := Power_Value - 1;
      Random_Slots := Random_Delay(Max_Random);
      return Random_Slots * Config.Slot_Time;
   end Randomized_Backoff;

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
   ) return Delay_Type is
      Effective_Count : Collision_Count_Type;
   begin
      Validate_Config(Config);
      -- Cap Collision_Count at Max_Retries to prevent excessively long delays
      if Integer(Collision_Count) > Integer(Config.Max_Retries) then
         Effective_Count := Collision_Count_Type(Config.Max_Retries); -- Type conversion required
      else
         Effective_Count := Collision_Count;
      end if;
      return Deterministic_Backoff(Config, Effective_Count);
   end Truncated_Backoff;

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
   ) return Delay_Type is
      Config : Backoff_Config := 
        (Base => 2, Max_Retries => 10, Initial_Delay => Slot_Time, Slot_Time => Slot_Time);
   begin
      return Deterministic_Backoff(Config, Collision_Count);
   end Binary_Exponential_Backoff;

   --  === Adaptive Backoff (Heuristic RCP) ===
   --  Implements Lam's Heuristic Retransmission Control Procedure
   --  K(m) increases with collisions (e.g., K(0)=1, K(1)=10, K(2)=100, K(3)=200, ...)
   --  Parameters:
   --    Collision_Count: Number of adverse events
   --  Returns:
   --    Delay_Type: Adaptive delay
   function Adaptive_Backoff (
      Collision_Count : Collision_Count_Type
   ) return Delay_Type is
      -- Lam's Heuristic RCP: K(0)=1, K(1)=10, K(2)=100, K(3)=200, K(m>=4)=200
      K : array (0 .. 10) of Delay_Type := 
        (1, 10, 100, 200, 200, 200, 200, 200, 200, 200, 200);
      Index : Integer := Integer(Collision_Count); -- Array indices must be Integer
   begin
      if Index <= 10 then
         return K(Index);
      else
         return K(10); --  Cap at K(10) = 200 (sufficient for stable systems)
      end if;
   end Adaptive_Backoff;

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
   ) return Delay_Type is
      Power_Value : Delay_Type;
      Max_Random  : Delay_Type;
   begin
      Power_Value := Compute_Power(Base, Collision_Count);
      Max_Random := Power_Value - 1;
      return Max_Random / 2;
   end Expected_Backoff;

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
   ) return Collision_Count_Type is
   begin
      if Cooling_Off then
         return 0;
      else
         return Current_Count;
      end if;
   end Reset_Backoff;

begin
   --  Initialize the random number generator
   Random_Delay_Pkg.Reset(Gen);
end Exponential_Backoff;
