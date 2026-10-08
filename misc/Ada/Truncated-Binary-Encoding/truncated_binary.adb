package body Truncated_Binary is

   -- Helper Function: Calculates algorithmic parameters K and U
   -- K = floor(log2(N)), U = 2^(K+1) - N
   procedure Get_Parameters(N : in Alphabet_Size; K : out Natural; U : out Natural) is
      Temp : Natural := 1;
      Log2 : Natural := 0;
   begin
      -- Handle edge case where Alphabet Size is 1 (0 bits required)
      if N = 1 then
         K := 0;
         U := 1;
         return;
      end if;

      -- Calculate log2 floor
      while Temp * 2 <= Natural(N) loop
         Temp := Temp * 2;
         Log2 := Log2 + 1;
      end loop;
      
      K := Log2;
      U := (2 ** (K + 1)) - Natural(N);
   end Get_Parameters;

   -- Helper Function: Converts a Natural to a zero-padded binary string of exact length
   function To_Binary_String(Val : Natural; Bits_Count : Natural) return String is
      Result : String(1 .. Bits_Count);
      Temp   : Natural := Val;
   begin
      for I in reverse 1 .. Bits_Count loop
         if Temp mod 2 = 1 then
            Result(I) := '1';
         else
            Result(I) := '0';
         end if;
         Temp := Temp / 2;
      end loop;
      return Result;
   end To_Binary_String;


   -- 1. Encode Variant
   function Encode (X : Symbol_Value; N : Alphabet_Size) return String is
      K, U : Natural;
   begin
      -- A valid symbol must be less than the alphabet size
      if Natural(X) >= Natural(N) then
         raise Invalid_Symbol_Error with "Symbol must be less than alphabet size.";
      end if;

      Get_Parameters(N, K, U);

      -- Core Algorithm Logic:
      -- If x < u: encode as standard K-bit binary
      if Natural(X) < U then
         return To_Binary_String(Natural(X), K);
      else
         -- If x >= u: encode (x + u) as K+1 bit binary
         return To_Binary_String(Natural(X) + U, K + 1);
      end if;
   end Encode;


   -- 2. Decode Stream Variant
   function Decode (Bits : String; N : Alphabet_Size; Consumed : out Natural) return Symbol_Value is
      K, U : Natural;
      V    : Natural := 0;
      Idx  : Positive := Bits'First;
   begin
      Get_Parameters(N, K, U);
      Consumed := 0;

      -- Edge case N = 1: Alphabet has only symbol 0, takes 0 bits
      if K = 0 then
         return 0; 
      end if;

      -- Validate we have at least K bits to read
      if Bits'Length < K then
         raise Decoding_Error with "Input string too short for minimum K bits.";
      end if;

      -- Read the first K bits
      for I in 1 .. K loop
         if Bits(Idx) = '1' then
            V := V * 2 + 1;
         elsif Bits(Idx) = '0' then
            V := V * 2;
         else
            raise Decoding_Error with "Invalid character in bit string (not 0 or 1).";
         end if;
         Idx := Idx + 1;
         Consumed := Consumed + 1;
      end loop;

      -- Core Decicion Logic
      if V < U then
         return Symbol_Value(V);
      else
         -- Must read one additional bit
         if Consumed >= Bits'Length then
            raise Decoding_Error with "Input string truncated, expected K+1 bits.";
         end if;
         
         if Bits(Idx) = '1' then
            V := V * 2 + 1;
         elsif Bits(Idx) = '0' then
            V := V * 2;
         else
            raise Decoding_Error with "Invalid character in bit string (not 0 or 1).";
         end if;
         
         Consumed := Consumed + 1;
         return Symbol_Value(V - U);
      end if;
   end Decode;


   -- 3. Decode Exact Variant
   function Decode_Exact (Bits : String; N : Alphabet_Size) return Symbol_Value is
      Consumed : Natural;
      Result   : Symbol_Value;
   begin
      Result := Decode(Bits, N, Consumed);
      
      -- Validate that NO extra bits are leftover
      if Consumed /= Bits'Length then
         raise Decoding_Error with "String contains trailing garbage bits.";
      end if;
      
      return Result;
   end Decode_Exact;

end Truncated_Binary;
