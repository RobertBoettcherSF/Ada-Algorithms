-- unary_coding.adb
-- Package body containing implementations for all Unary Coding variants

package body Unary_Coding is

   ----------------------------------------------------------------------------
   -- Variant 1: Encode N ones followed by 1 zero
   ----------------------------------------------------------------------------
   function Encode_Ones_Zero (N : Unary_Value) return String is
      -- Allocate exact required string length (N characters + 1 terminator)
      Result : String (1 .. Integer(N) + 1);
   begin
      -- Fill with '1's
      for I in 1 .. Integer(N) loop
         Result(I) := '1';
      end loop;
      -- Terminate with '0'
      Result(Result'Last) := '0';
      
      return Result;
   end Encode_Ones_Zero;

   function Decode_Ones_Zero (Code : String) return Unary_Value is
      Count : Unary_Value := 0;
   begin
      if Code'Length = 0 then
         raise Invalid_Encoding with "Empty string cannot be decoded.";
      end if;

      for I in Code'Range loop
         if Code(I) = '1' then
            Count := Count + 1;
         elsif Code(I) = '0' then
            -- The zero MUST be the final character in the code
            if I /= Code'Last then
               raise Invalid_Encoding with "Terminator '0' found before end of string.";
            end if;
            return Count;
         else
            raise Invalid_Encoding with "Invalid character encountered. Expected '1' or '0'.";
         end if;
      end loop;
      
      -- If the loop finishes without returning, the string lacked a terminator
      raise Invalid_Encoding with "Missing terminator '0' at end of string.";
   end Decode_Ones_Zero;

   ----------------------------------------------------------------------------
   -- Variant 2: Encode N zeros followed by 1 one
   ----------------------------------------------------------------------------
   function Encode_Zeros_One (N : Unary_Value) return String is
      Result : String (1 .. Integer(N) + 1);
   begin
      for I in 1 .. Integer(N) loop
         Result(I) := '0';
      end loop;
      Result(Result'Last) := '1';
      
      return Result;
   end Encode_Zeros_One;

   function Decode_Zeros_One (Code : String) return Unary_Value is
      Count : Unary_Value := 0;
   begin
      if Code'Length = 0 then
         raise Invalid_Encoding with "Empty string cannot be decoded.";
      end if;

      for I in Code'Range loop
         if Code(I) = '0' then
            Count := Count + 1;
         elsif Code(I) = '1' then
            if I /= Code'Last then
               raise Invalid_Encoding with "Terminator '1' found before end of string.";
            end if;
            return Count;
         else
            raise Invalid_Encoding with "Invalid character encountered. Expected '0' or '1'.";
         end if;
      end loop;
      
      raise Invalid_Encoding with "Missing terminator '1' at end of string.";
   end Decode_Zeros_One;

   ----------------------------------------------------------------------------
   -- Variant 3: Positive Unary Coding (N >= 1) encoded as N-1 ones + 0
   ----------------------------------------------------------------------------
   function Encode_Positive_Ones (N : Positive) return String is
   begin
      -- Reuses the base logic but offset by 1
      return Encode_Ones_Zero (Unary_Value(N - 1));
   end Encode_Positive_Ones;

   function Decode_Positive_Ones (Code : String) return Positive is
      Base_Value : Unary_Value;
   begin
      Base_Value := Decode_Ones_Zero (Code);
      return Positive(Base_Value + 1);
   end Decode_Positive_Ones;

end Unary_Coding;
