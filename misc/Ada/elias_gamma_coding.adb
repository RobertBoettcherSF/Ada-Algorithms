package body Elias_Gamma_Coding is

   -----------------------------------------------------------------------------
   -- Helper Functions
   -----------------------------------------------------------------------------
   function To_Stream (S : String) return Elias_Bit_Stream is
   begin
      -- Validate that string contains only binary characters '0' and '1'
      for Char of S loop
         if Char /= '0' and Char /= '1' then
            raise Invalid_Bit_Stream with "Stream must contain only '0' or '1'";
         end if;
      end loop;
      return (Data => To_Unbounded_String(S));
   end To_Stream;

   function To_String (Stream : Elias_Bit_Stream) return String is
   begin
      return To_String (Stream.Data);
   end To_String;

   -----------------------------------------------------------------------------
   -- Variant 1: Standard Positive Elias Gamma Coding
   -----------------------------------------------------------------------------
   function Encode_Positive (Value : Positive) return Elias_Bit_Stream is
      Temp       : Natural := Value;
      Binary_Str : Unbounded_String := Null_Unbounded_String;
      Zeros_Str  : Unbounded_String := Null_Unbounded_String;
      N          : Natural := 0;
   begin
      -- 1. Convert to binary representation
      while Temp > 0 loop
         if Temp mod 2 = 0 then
            Binary_Str := "0" & Binary_Str;
         else
            Binary_Str := "1" & Binary_Str;
         end if;
         Temp := Temp / 2;
         N := N + 1;
      end loop;

      -- 2. Prepend N - 1 zeros
      for I in 1 .. N - 1 loop
         Zeros_Str := Zeros_Str & "0";
      end loop;

      return (Data => Zeros_Str & Binary_Str);
   end Encode_Positive;

   function Decode_Positive (Stream : Elias_Bit_Stream) return Positive is
      S      : constant String := To_String (Stream.Data);
      N      : Natural := 0;
      Idx    : Positive := 1;
      Result : Natural := 0;
   begin
      if S'Length = 0 then
         raise Invalid_Bit_Stream with "Stream is empty";
      end if;

      -- 1. Count leading zeros to determine N
      while Idx <= S'Length and then S(Idx) = '0' loop
         N := N + 1;
         Idx := Idx + 1;
      end loop;

      -- Validate leading '1' exists
      if Idx > S'Length or else S(Idx) /= '1' then
         raise Invalid_Bit_Stream with "No leading '1' found after zeros";
      end if;

      -- Validate we have exactly enough bits left for the payload
      -- (Length - Idx + 1) is the remaining string length, need (N + 1) bits
      if S'Length - Idx + 1 < N + 1 then
         raise Invalid_Bit_Stream with "Stream truncated, missing bits";
      end if;

      -- 2. Read the binary number of length N + 1
      for I in Idx .. Idx + N loop
         Result := Result * 2;
         if S(I) = '1' then
            Result := Result + 1;
         elsif S(I) /= '0' then
            raise Invalid_Bit_Stream with "Invalid character in bitstream";
         end if;
      end loop;

      return Result;
   end Decode_Positive;

   -----------------------------------------------------------------------------
   -- Variant 2: Zero-extended Elias Gamma Coding
   -----------------------------------------------------------------------------
   function Encode_Non_Negative (Value : Natural) return Elias_Bit_Stream is
   begin
      return Encode_Positive (Value + 1);
   end Encode_Non_Negative;

   function Decode_Non_Negative (Stream : Elias_Bit_Stream) return Natural is
   begin
      return Decode_Positive (Stream) - 1;
   end Decode_Non_Negative;

   -----------------------------------------------------------------------------
   -- Variant 3: Integer Elias Gamma Coding (Bijection Mapping)
   -----------------------------------------------------------------------------
   function Encode_Integer (Value : Integer) return Elias_Bit_Stream is
      Mapped : Long_Integer;
   begin
      -- Map 0->1, positives->evens, negatives->odds
      if Value > 0 then
         Mapped := 2 * Long_Integer (Value);
      else
         Mapped := -2 * Long_Integer (Value) + 1;
      end if;
      
      -- Convert to positive type and encode, trap overflow cleanly
      return Encode_Positive (Positive (Mapped));
   exception
      when Constraint_Error =>
         raise Overflow_Error with "Value mapped outside of Positive bounds";
   end Encode_Integer;

   function Decode_Integer (Stream : Elias_Bit_Stream) return Integer is
      Mapped : constant Positive := Decode_Positive (Stream);
   begin
      if Mapped mod 2 = 0 then
         return Mapped / 2;
      else
         return (- (Mapped - 1)) / 2;
      end if;
   end Decode_Integer;

end Elias_Gamma_Coding;
