-- universal_codes.adb
-- Implementation of Universal Codes

package body Universal_Codes is

   -----------------------
   -- Helper Functions --
   -----------------------

   -- Converts a Positive integer to its native binary Bit_Array representation
   function To_Binary (N : Positive) return Bit_Array is
      Temp   : Natural := N;
      Length : Natural := 0;
   begin
      -- Determine bit length
      while Temp > 0 loop
         Length := Length + 1;
         Temp := Temp / 2;
      end loop;

      declare
         Result : Bit_Array (1 .. Length);
         T      : Natural := N;
      begin
         for I in reverse 1 .. Length loop
            Result (I) := Bit (T mod 2);
            T := T / 2;
         end loop;
         return Result;
      end;
   end To_Binary;

   -- Converts a Bit_Array back to a Natural integer
   function To_Natural (Bits : Bit_Array) return Natural is
      Result : Natural := 0;
   begin
      for I in Bits'Range loop
         Result := Result * 2 + Natural (Bits (I));
      end loop;
      return Result;
   end To_Natural;

   function To_Bits (S : String) return Bit_Array is
      B : Bit_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         if S (I) = '1' then
            B (I - S'First + 1) := 1;
         elsif S (I) = '0' then
            B (I - S'First + 1) := 0;
         else
            raise Invalid_Input_Error with "String must contain only '0' and '1'";
         end if;
      end loop;
      return B;
   end To_Bits;

   ------------------
   -- Unary Coding --
   ------------------

   function Encode_Unary (N : Positive) return Bit_Array is
      Result : Bit_Array (1 .. N) := (others => 1);
   begin
      Result (N) := 0;
      return Result;
   end Encode_Unary;

   function Decode_Unary (Bits : Bit_Array) return Positive is
      Count : Natural := 0;
   begin
      for I in Bits'Range loop
         Count := Count + 1;
         if Bits (I) = 0 then
            return Count;
         end if;
      end loop;
      raise Decoding_Error with "Missing terminating 0 in Unary sequence";
   end Decode_Unary;

   ------------------------
   -- Elias Gamma Coding --
   ------------------------

   function Encode_Elias_Gamma (N : Positive) return Bit_Array is
      Bin   : constant Bit_Array := To_Binary (N);
      Zeros : constant Bit_Array (1 .. Bin'Length - 1) := (others => 0);
   begin
      return Zeros & Bin;
   end Encode_Elias_Gamma;

   function Decode_Elias_Gamma (Bits : Bit_Array) return Positive is
      L   : Natural := 0;
      Idx : Positive := Bits'First;
   begin
      -- Count leading zeros
      while Idx <= Bits'Last and then Bits (Idx) = 0 loop
         L := L + 1;
         Idx := Idx + 1;
      end loop;

      if Idx + L > Bits'Last + 1 then
         raise Decoding_Error with "Incomplete Elias Gamma sequence";
      end if;

      return To_Natural (Bits (Idx .. Idx + L));
   end Decode_Elias_Gamma;

   ------------------------
   -- Elias Delta Coding --
   ------------------------

   function Encode_Elias_Delta (N : Positive) return Bit_Array is
      Bin        : constant Bit_Array := To_Binary (N);
      L          : constant Natural   := Bin'Length - 1;
      Gamma_Part : constant Bit_Array := Encode_Elias_Gamma (L + 1);
   begin
      if L = 0 then
         return Gamma_Part;
      else
         return Gamma_Part & Bin (Bin'First + 1 .. Bin'Last);
      end if;
   end Encode_Elias_Delta;

   function Decode_Elias_Delta (Bits : Bit_Array) return Positive is
      L_Zeros : Natural := 0;
      Idx     : Positive := Bits'First;
   begin
      -- First decode Elias Gamma prefix to get L+1
      while Idx <= Bits'Last and then Bits (Idx) = 0 loop
         L_Zeros := L_Zeros + 1;
         Idx := Idx + 1;
      end loop;

      if Idx + L_Zeros > Bits'Last + 1 then
         raise Decoding_Error with "Incomplete Elias Delta prefix sequence";
      end if;

      declare
         L_Plus_1 : constant Natural := To_Natural (Bits (Idx .. Idx + L_Zeros));
         L        : constant Natural := L_Plus_1 - 1;
         Next_Idx : constant Positive := Idx + L_Zeros + 1;
      begin
         if L = 0 then
            return 1;
         end if;

         if Next_Idx + L - 1 > Bits'Last then
            raise Decoding_Error with "Incomplete Elias Delta payload sequence";
         end if;

         declare
            Result_Bits : Bit_Array (1 .. L + 1);
         begin
            Result_Bits (1) := 1;
            for I in 0 .. L - 1 loop
               Result_Bits (2 + I) := Bits (Next_Idx + I);
            end loop;
            return To_Natural (Result_Bits);
         end;
      end;
   end Decode_Elias_Delta;

   ------------------------
   -- Elias Omega Coding --
   ------------------------

   function Encode_Elias_Omega (N : Positive) return Bit_Array is
      -- Recursively constructs Elias Omega string to avoid constrained array assignments
      function Recursive_Encode (Val : Positive) return Bit_Array is
         Bin : constant Bit_Array := To_Binary (Val);
      begin
         if Val = 1 then
            -- Base case: stop here, no prepend
            declare
               Empty : constant Bit_Array (1 .. 0) := (others => 0);
            begin
               return Empty;
            end;
         else
            return Recursive_Encode (Bin'Length - 1) & Bin;
         end if;
      end Recursive_Encode;
      
      Zero : constant Bit_Array (1 .. 1) := (1 => 0);
   begin
      -- Prepend recursively constructed groups with the terminating '0'
      return Recursive_Encode (N) & Zero;
   end Encode_Elias_Omega;

   function Decode_Elias_Omega (Bits : Bit_Array) return Positive is
      N   : Positive := 1;
      Idx : Positive := Bits'First;
   begin
      while Idx <= Bits'Last loop
         if Bits (Idx) = 0 then
            return N;
         elsif Bits (Idx) = 1 then
            if Idx + N > Bits'Last then
               raise Decoding_Error with "Incomplete Elias Omega sequence";
            end if;
            declare
               Old_N : constant Positive := N;
            begin
               N := To_Natural (Bits (Idx .. Idx + Old_N));
               Idx := Idx + Old_N + 1;
            end;
         end if;
      end loop;
      raise Decoding_Error with "Missing terminating 0 in Elias Omega sequence";
   end Decode_Elias_Omega;

   ----------------------
   -- Fibonacci Coding --
   ----------------------

   function Encode_Fibonacci (N : Positive) return Bit_Array is
      Fibs   : array (1 .. 45) of Positive;
      Temp_N : Natural := N;
      Max_K  : Natural := 1;
   begin
      Fibs (1) := 1;
      Fibs (2) := 2;
      for I in 3 .. 45 loop
         Fibs (I) := Fibs (I - 1) + Fibs (I - 2);
      end loop;

      -- Find max index k such that F(k) <= N
      for I in 1 .. 45 loop
         if Fibs (I) <= N then
            Max_K := I;
         else
            exit;
         end if;
      end loop;

      declare
         Result : Bit_Array (1 .. Max_K + 1) := (others => 0);
      begin
         Result (Max_K + 1) := 1; -- Appended terminating 1
         
         while Temp_N > 0 loop
            for I in reverse 1 .. Max_K loop
               if Fibs (I) <= Temp_N then
                  Result (I) := 1;
                  Temp_N := Temp_N - Fibs (I);
                  exit;
               end if;
            end loop;
         end loop;
         return Result;
      end;
   end Encode_Fibonacci;

   function Decode_Fibonacci (Bits : Bit_Array) return Positive is
      Fibs : array (1 .. 45) of Positive;
      Sum  : Natural := 0;
      Idx  : Positive := Bits'First;
   begin
      Fibs (1) := 1;
      Fibs (2) := 2;
      for I in 3 .. 45 loop
         Fibs (I) := Fibs (I - 1) + Fibs (I - 2);
      end loop;

      while Idx < Bits'Last loop
         if Bits (Idx) = 1 then
            Sum := Sum + Fibs (Idx - Bits'First + 1);
            if Bits (Idx + 1) = 1 then
               return Sum; -- Consecutive 1s found, end of payload
            end if;
         end if;
         Idx := Idx + 1;
      end loop;
      raise Decoding_Error with "Missing consecutive 1s in Fibonacci sequence";
   end Decode_Fibonacci;

end Universal_Codes;
