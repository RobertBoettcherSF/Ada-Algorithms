package body Linear_Feedback_Shift_Register is

   -----------------------------------------------------------------------------
   -- Parity: Computes the XOR sum of all bits in the value.
   -----------------------------------------------------------------------------
   function Parity (Value : Register_Value) return Bit is
      V : Interfaces.Unsigned_64 := Interfaces.Unsigned_64 (Value);
      P : Bit := 0;
   begin
      while V > 0 loop
         P := P xor Bit (V and 1);
         V := Interfaces.Shift_Right (V, 1);
      end loop;
      return P;
   end Parity;

   -----------------------------------------------------------------------------
   -- Initialize: Sets up the LFSR and enforces strict domain invariants.
   -----------------------------------------------------------------------------
   procedure Initialize
     (Engine  : out LFSR_Engine;
      Variant : LFSR_Variant;
      Length  : Register_Length;
      Seed    : Register_Value;
      Taps    : Tap_Mask)
   is
   begin
      -- While Preconditions cover this, explicit checks ensure safety even if
      -- compiled without assertions (a defense-in-depth approach).
      if Seed = 0 then
         raise Invalid_State_Error with "LFSR seed cannot be zero";
      end if;

      if not In_Bounds (Seed, Length) then
         raise Invalid_State_Error with "Seed exceeds specified register length";
      end if;

      if not In_Bounds (Register_Value (Taps), Length) then
         raise Invalid_State_Error with "Taps mask exceeds specified register length";
      end if;

      Engine.Variant := Variant;
      Engine.Length  := Length;
      Engine.State   := Seed;
      Engine.Taps    := Taps;
   end Initialize;

   -----------------------------------------------------------------------------
   -- Step_Fibonacci: Implements the standard Fibonacci LFSR logic.
   -- 1. Output is the LSB.
   -- 2. Feedback is the parity of the current state masked with the taps.
   -- 3. State shifts right by 1, and feedback bit is inserted at the MSB.
   -----------------------------------------------------------------------------
   procedure Step_Fibonacci (Engine : in out LFSR_Engine; Output : out Bit) is
      Feedback_Bit  : Bit;
      Current_State : Interfaces.Unsigned_64 := Interfaces.Unsigned_64 (Engine.State);
   begin
      Output := Bit (Current_State and 1);
      Feedback_Bit := Parity (Engine.State and Register_Value (Engine.Taps));

      Current_State := Interfaces.Shift_Right (Current_State, 1);

      if Feedback_Bit = 1 then
         Current_State := Current_State or Interfaces.Shift_Left (1, Natural (Engine.Length) - 1);
      end if;

      Engine.State := Register_Value (Current_State);
   end Step_Fibonacci;

   -----------------------------------------------------------------------------
   -- Step_Galois: Implements the Galois LFSR logic.
   -- 1. Output is the LSB.
   -- 2. State shifts right by 1.
   -- 3. If output was 1, XOR the new state with the tap mask.
   -----------------------------------------------------------------------------
   procedure Step_Galois (Engine : in out LFSR_Engine; Output : out Bit) is
      Current_State : Interfaces.Unsigned_64 := Interfaces.Unsigned_64 (Engine.State);
      Feedback      : constant Boolean := (Current_State and 1) = 1;
   begin
      Output := Bit (Current_State and 1);
      Current_State := Interfaces.Shift_Right (Current_State, 1);

      if Feedback then
         Current_State := Current_State xor Interfaces.Unsigned_64 (Engine.Taps);
      end if;

      Engine.State := Register_Value (Current_State);
   end Step_Galois;

   -----------------------------------------------------------------------------
   -- Next_Bit: Polymorphic step function.
   -----------------------------------------------------------------------------
   procedure Next_Bit (Engine : in out LFSR_Engine; Output : out Bit) is
   begin
      case Engine.Variant is
         when Fibonacci =>
            Step_Fibonacci (Engine, Output);
         when Galois =>
            Step_Galois (Engine, Output);
      end case;
   end Next_Bit;

   -----------------------------------------------------------------------------
   -- Next_Bits: Combines consecutive Next_Bit calls into a single Register_Value.
   -- The first generated bit becomes the LSB of the result.
   -----------------------------------------------------------------------------
   function Next_Bits (Engine : in out LFSR_Engine; Count : Positive) return Register_Value is
      Result      : Interfaces.Unsigned_64 := 0;
      Current_Bit : Bit;
   begin
      for I in 0 .. Count - 1 loop
         Next_Bit (Engine, Current_Bit);
         if Current_Bit = 1 then
            Result := Result or Interfaces.Shift_Left (1, I);
         end if;
      end loop;
      return Register_Value (Result);
   end Next_Bits;

   -----------------------------------------------------------------------------
   -- Accessors
   -----------------------------------------------------------------------------
   function Get_Variant (Engine : LFSR_Engine) return LFSR_Variant is (Engine.Variant);
   function Get_Length  (Engine : LFSR_Engine) return Register_Length is (Engine.Length);
   function Get_State   (Engine : LFSR_Engine) return Register_Value is (Engine.State);
   function Get_Taps    (Engine : LFSR_Engine) return Tap_Mask is (Engine.Taps);

end Linear_Feedback_Shift_Register;
