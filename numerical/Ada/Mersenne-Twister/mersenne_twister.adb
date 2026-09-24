package body Mersenne_Twister is

   -- Default standard seed if generator is used without explicit initialization
   Default_Seed : constant := 5489;

   -- =========================================================================
   -- 32-Bit Implementation
   -- =========================================================================

   procedure Init (State : out MT19937_State; Seed : in Unsigned_32) is
   begin
      State.Index := N_32;
      State.MT(0) := Seed;
      for I in 1 .. N_32 - 1 loop
         -- MT[i] := f * (MT[i-1] xor (MT[i-1] >> (w-2))) + i
         State.MT(I) := 1812433253 * (State.MT(I - 1) xor Shift_Right(State.MT(I - 1), 30)) + Unsigned_32(I);
      end loop;
   end Init;

   procedure Twist_32 (State : in out MT19937_State) is
      Lower_Mask : constant Unsigned_32 := 16#7FFFFFFF#;
      Upper_Mask : constant Unsigned_32 := 16#80000000#;
      Mag01      : constant array(0..1) of Unsigned_32 := (0, 16#9908B0DF#);
      Y          : Unsigned_32;
   begin
      for I in 0 .. N_32 - 1 loop
         Y := (State.MT(I) and Upper_Mask) or (State.MT((I + 1) mod N_32) and Lower_Mask);
         State.MT(I) := State.MT((I + 397) mod N_32) xor Shift_Right(Y, 1) xor Mag01(Integer(Y and 1));
      end loop;
      State.Index := 0;
   end Twist_32;

   function Random (State : in out MT19937_State) return Unsigned_32 is
      Y : Unsigned_32;
   begin
      if State.Index >= N_32 then
         if State.Index > N_32 then
            Init(State, Default_Seed); -- Auto-seed if uninitialized
         end if;
         Twist_32(State);
      end if;

      Y := State.MT(State.Index);
      
      -- Tempering Phase
      Y := Y xor Shift_Right(Y, 11);
      Y := Y xor (Shift_Left(Y, 7) and 16#9D2C5680#);
      Y := Y xor (Shift_Left(Y, 15) and 16#EFC60000#);
      Y := Y xor Shift_Right(Y, 18);

      State.Index := State.Index + 1;
      return Y;
   end Random;

   -- =========================================================================
   -- 64-Bit Implementation
   -- =========================================================================

   procedure Init (State : out MT19937_64_State; Seed : in Unsigned_64) is
   begin
      State.Index := N_64;
      State.MT(0) := Seed;
      for I in 1 .. N_64 - 1 loop
         -- MT[i] := f * (MT[i-1] xor (MT[i-1] >> (w-2))) + i
         State.MT(I) := 6364136223846793005 * (State.MT(I - 1) xor Shift_Right(State.MT(I - 1), 62)) + Unsigned_64(I);
      end loop;
   end Init;

   procedure Twist_64 (State : in out MT19937_64_State) is
      Lower_Mask : constant Unsigned_64 := 16#7FFFFFFF#;
      Upper_Mask : constant Unsigned_64 := 16#FFFFFFFF80000000#;
      Mag01      : constant array(0..1) of Unsigned_64 := (0, 16#B5026F5AA96619E9#);
      Y          : Unsigned_64;
   begin
      for I in 0 .. N_64 - 1 loop
         Y := (State.MT(I) and Upper_Mask) or (State.MT((I + 1) mod N_64) and Lower_Mask);
         State.MT(I) := State.MT((I + 156) mod N_64) xor Shift_Right(Y, 1) xor Mag01(Integer(Y and 1));
      end loop;
      State.Index := 0;
   end Twist_64;

   function Random (State : in out MT19937_64_State) return Unsigned_64 is
      Y : Unsigned_64;
   begin
      if State.Index >= N_64 then
         if State.Index > N_64 then
            Init(State, Default_Seed); -- Auto-seed if uninitialized
         end if;
         Twist_64(State);
      end if;

      Y := State.MT(State.Index);
      
      -- Tempering Phase
      Y := Y xor (Shift_Right(Y, 29) and 16#5555555555555555#);
      Y := Y xor (Shift_Left(Y, 17) and 16#71D67FFFEDA60000#);
      Y := Y xor (Shift_Left(Y, 37) and 16#FFF7EEE000000000#);
      Y := Y xor Shift_Right(Y, 43);

      State.Index := State.Index + 1;
      return Y;
   end Random;

end Mersenne_Twister;
