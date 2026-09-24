with Interfaces;
use type Interfaces.Unsigned_64;

package Linear_Feedback_Shift_Register is
   pragma Preelaborate;

   -- Custom types representing the domain of the LFSR algorithm
   type Register_Length is range 2 .. 64;
   type Register_Value is new Interfaces.Unsigned_64;
   type Tap_Mask is new Register_Value;
   type Bit is mod 2;

   -- Supported LFSR operational variants
   type LFSR_Variant is (Fibonacci, Galois);

   -- Exception raised on invalid setup that evades preconditions or in environments without assertions
   Invalid_State_Error : exception;

   -- The core LFSR Engine (private to strictly enforce state validity constraints)
   type LFSR_Engine is private;

   -- Helper: Determine if a given value fits within the specified bit length
   function In_Bounds (Value : Register_Value; Length : Register_Length) return Boolean
     is (Length = 64 or else Interfaces.Unsigned_64 (Value) < Interfaces.Shift_Left (1, Natural (Length)))
     with Global => null;

   -- Helper: Calculate parity (XOR sum) of all bits in a Register_Value
   function Parity (Value : Register_Value) return Bit
     with Global => null;

   -- Initializes the LFSR with a specific variant, length, starting seed, and tap mask.
   procedure Initialize
     (Engine  : out LFSR_Engine;
      Variant : LFSR_Variant;
      Length  : Register_Length;
      Seed    : Register_Value;
      Taps    : Tap_Mask)
     with Pre => Seed /= 0 and then
                 In_Bounds (Seed, Length) and then
                 In_Bounds (Register_Value (Taps), Length),
          Post => Get_Variant (Engine) = Variant and
                  Get_Length (Engine) = Length and
                  Get_State (Engine) = Seed and
                  Get_Taps (Engine) = Taps;

   -- Executes a single bit-shift according to the Fibonacci variant rules
   procedure Step_Fibonacci (Engine : in out LFSR_Engine; Output : out Bit)
     with Pre => Get_Variant (Engine) = Fibonacci and Get_State (Engine) /= 0;

   -- Executes a single bit-shift according to the Galois variant rules
   procedure Step_Galois (Engine : in out LFSR_Engine; Output : out Bit)
     with Pre => Get_Variant (Engine) = Galois and Get_State (Engine) /= 0;

   -- Dispatches to the correct step function based on the initialized variant
   procedure Next_Bit (Engine : in out LFSR_Engine; Output : out Bit)
     with Pre => Get_State (Engine) /= 0;

   -- Extracts a sequence of up to 64 bits by repeatedly stepping the engine
   function Next_Bits (Engine : in out LFSR_Engine; Count : Positive) return Register_Value
     with Pre => Get_State (Engine) /= 0 and Count <= 64;

   -- Accessors for the private state
   function Get_Variant (Engine : LFSR_Engine) return LFSR_Variant
     with Global => null;
   function Get_Length  (Engine : LFSR_Engine) return Register_Length
     with Global => null;
   function Get_State   (Engine : LFSR_Engine) return Register_Value
     with Global => null;
   function Get_Taps    (Engine : LFSR_Engine) return Tap_Mask
     with Global => null;

private
   type LFSR_Engine is record
      Variant : LFSR_Variant;
      Length  : Register_Length;
      State   : Register_Value;
      Taps    : Tap_Mask;
   end record;
end Linear_Feedback_Shift_Register;
