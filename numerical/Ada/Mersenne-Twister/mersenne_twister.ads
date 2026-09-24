with Interfaces; use Interfaces;

package Mersenne_Twister is
   pragma Preelaborate;

   -- =========================================================================
   -- MT19937 (32-bit Mersenne Twister)
   -- =========================================================================
   
   N_32 : constant := 624;
   
   type MT19937_Array is array (0 .. N_32 - 1) of Unsigned_32;
   
   -- State record for the 32-bit generator. 
   -- Index is initialized > N_32 to trigger auto-initialization if used unseeded.
   type MT19937_State is record
      MT    : MT19937_Array := (others => 0);
      Index : Integer := N_32 + 1; 
   end record;

   -- Initializes the generator with a specific 32-bit seed
   procedure Init (State : out MT19937_State; Seed : in Unsigned_32);
   
   -- Extracts the next 32-bit random number, mutating the state
   function Random (State : in out MT19937_State) return Unsigned_32;


   -- =========================================================================
   -- MT19937-64 (64-bit Mersenne Twister)
   -- =========================================================================
   
   N_64 : constant := 312;
   
   type MT19937_64_Array is array (0 .. N_64 - 1) of Unsigned_64;
   
   -- State record for the 64-bit generator.
   type MT19937_64_State is record
      MT    : MT19937_64_Array := (others => 0);
      Index : Integer := N_64 + 1;
   end record;

   -- Initializes the generator with a specific 64-bit seed
   procedure Init (State : out MT19937_64_State; Seed : in Unsigned_64);
   
   -- Extracts the next 64-bit random number, mutating the state
   function Random (State : in out MT19937_64_State) return Unsigned_64;

private
   -- Helper procedures to perform the "Twist" transformation on the state arrays
   procedure Twist_32 (State : in out MT19937_State);
   procedure Twist_64 (State : in out MT19937_64_State);
end Mersenne_Twister;
