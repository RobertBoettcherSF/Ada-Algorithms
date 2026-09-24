package body Blum_Blum_Shub is

   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_128;

   -------------------------------------------------------------------------
   -- Is_Prime
   -------------------------------------------------------------------------
   function Is_Prime (N : Interfaces.Unsigned_64) return Boolean is
      D : Interfaces.Unsigned_64;
   begin
      if N < 2 then
         return False;
      end if;
      if N = 2 or N = 3 then
         return True;
      end if;
      if N mod 2 = 0 or N mod 3 = 0 then
         return False;
      end if;

      D := 5;
      while D * D <= N loop
         if N mod D = 0 or N mod (D + 2) = 0 then
            return False;
         end if;
         if D > Interfaces.Unsigned_64'Last - 6 then
            exit;
         end if;
         D := D + 6;
      end loop;
      return True;
   end Is_Prime;

   -------------------------------------------------------------------------
   -- Is_Blum_Prime
   -------------------------------------------------------------------------
   function Is_Blum_Prime (N : Interfaces.Unsigned_64) return Boolean is
   begin
      return Is_Prime (N) and then (N mod 4 = 3);
   end Is_Blum_Prime;

   -------------------------------------------------------------------------
   -- Compute_GCD
   -------------------------------------------------------------------------
   function Compute_GCD (A, B : Interfaces.Unsigned_64) return Interfaces.Unsigned_64 is
      X : Interfaces.Unsigned_64 := A;
      Y : Interfaces.Unsigned_64 := B;
      Temp : Interfaces.Unsigned_64;
   begin
      while Y /= 0 loop
         Temp := Y;
         Y := X mod Y;
         X := Temp;
      end loop;
      return X;
   end Compute_GCD;

   -------------------------------------------------------------------------
   -- Initialize
   -------------------------------------------------------------------------
   procedure Initialize 
     (Gen  : out Generator; 
      P    : in  Prime_Type; 
      Q    : in  Prime_Type; 
      Seed : in  Seed_Type) 
   is
      Calculated_M : Interfaces.Unsigned_64;
   begin
      -- Validate that both P and Q are Blum primes (prime and congruent to 3 mod 4)
      if not Is_Blum_Prime (P) or not Is_Blum_Prime (Q) then
         raise Invalid_Parameters;
      end if;

      Calculated_M := P * Q;

      -- Validate seed: must be within (1, M) and coprime to M (GCD(seed, M) == 1)
      if Seed <= 1 or else Seed >= Calculated_M then
         raise Invalid_Seed;
      end if;

      if Compute_GCD (Seed, Calculated_M) /= 1 then
         raise Invalid_Seed;
      end if;

      Gen.P     := P;
      Gen.Q     := Q;
      Gen.M     := Calculated_M;
      -- Initial state is seed^2 mod M
      declare
         Full_Square : constant Interfaces.Unsigned_128 :=
            Interfaces.Unsigned_128 (Seed) * Interfaces.Unsigned_128 (Seed);
      begin
         Gen.State := Interfaces.Unsigned_64 (Full_Square mod Interfaces.Unsigned_128 (Calculated_M));
      end;
   end Initialize;

   -------------------------------------------------------------------------
   -- Next_Bit
   -------------------------------------------------------------------------
   function Next_Bit (Gen : in out Generator) return Boolean is
      Full_Square : constant Interfaces.Unsigned_128 :=
         Interfaces.Unsigned_128 (Gen.State) * Interfaces.Unsigned_128 (Gen.State);
   begin
      Gen.State := Interfaces.Unsigned_64 (Full_Square mod Interfaces.Unsigned_128 (Gen.M));
      -- The output bit is the parity (least significant bit) of the new state
      return (Gen.State mod 2) /= 0;
   end Next_Bit;

   -------------------------------------------------------------------------
   -- Next_Byte
   -------------------------------------------------------------------------
   function Next_Byte (Gen : in out Generator) return Interfaces.Unsigned_8 is
      Result : Interfaces.Unsigned_8 := 0;
   begin
      for I in 1 .. 8 loop
         Result := Interfaces.Shift_Left (Result, 1);
         if Next_Bit (Gen) then
            Result := Result or 1;
         end if;
      end loop;
      return Result;
   end Next_Byte;

   -------------------------------------------------------------------------
   -- Next_Bits
   -------------------------------------------------------------------------
   function Next_Bits (Gen : in out Generator; Count : Positive) return Interfaces.Unsigned_64 is
      Result       : Interfaces.Unsigned_64 := 0;
      Actual_Count : constant Positive := (if Count > 64 then 64 else Count);
   begin
      for I in 1 .. Actual_Count loop
         Result := Interfaces.Shift_Left (Result, 1);
         if Next_Bit (Gen) then
            Result := Result or 1;
         end if;
      end loop;
      return Result;
   end Next_Bits;

   -------------------------------------------------------------------------
   -- Peek_State
   -------------------------------------------------------------------------
   function Peek_State (Gen : Generator) return Modulus_Type is
   begin
      return Gen.State;
   end Peek_State;

end Blum_Blum_Shub;
