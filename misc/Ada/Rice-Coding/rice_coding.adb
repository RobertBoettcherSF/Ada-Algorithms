-- rice_coding.adb
-- Implementation of Rice and Golomb entropy encoding algorithms.
package body Rice_Coding is

   -----------------------
   -- Helper Functions --
   -----------------------

   function Ceil_Log2 (N : Golomb_Parameter) return Natural is
      Val   : Golomb_Parameter := 1;
      Count : Natural := 0;
   begin
      while Val < N loop
         Val := Val * 2;
         Count := Count + 1;
      end loop;
      return Count;
   end Ceil_Log2;

   function ZigZag_Encode (Value : Signed_Value) return Unsigned_Value is
   begin
      if Value >= 0 then
         return Unsigned_Value (Value) * 2;
      else
         return (Unsigned_Value (abs (Value)) * 2) - 1;
      end if;
   end ZigZag_Encode;

   function ZigZag_Decode (Value : Unsigned_Value) return Signed_Value is
   begin
      if Value mod 2 = 0 then
         return Signed_Value (Value / 2);
      else
         return -Signed_Value ((Value + 1) / 2);
      end if;
   end ZigZag_Decode;

   -- Creates a unary string of `Value` '1's followed by a '0' terminator.
   function To_Unary_String (Value : Unsigned_Value) return String is
      Result : String (1 .. Natural (Value) + 1) := (others => '1');
   begin
      Result (Result'Last) := '0';
      return Result;
   end To_Unary_String;

   function To_Binary_String (Value : Unsigned_Value; Bits : Natural) return String is
      Result : String (1 .. Bits) := (others => '0');
      Temp   : Unsigned_Value := Value;
   begin
      for I in reverse 1 .. Bits loop
         if Temp mod 2 = 1 then
            Result (I) := '1';
         end if;
         Temp := Temp / 2;
      end loop;
      return Result;
   end To_Binary_String;

   function Decode_Unary (Bits : Unbounded_String; Index : in out Positive) return Unsigned_Value is
      Count : Unsigned_Value := 0;
      S     : constant String := To_String (Bits);
   begin
      while Index <= S'Length and then S(Index) = '1' loop
         Count := Count + 1;
         Index := Index + 1;
      end loop;
      
      if Index > S'Length or else S(Index) /= '0' then
         raise Decoding_Error with "Missing unary terminator";
      end if;
      
      Index := Index + 1; -- Skip the '0' terminator
      return Count;
   end Decode_Unary;

   function Decode_Binary (Bits : String) return Unsigned_Value is
      Result : Unsigned_Value := 0;
   begin
      for I in Bits'Range loop
         Result := Result * 2;
         if Bits(I) = '1' then
            Result := Result + 1;
         elsif Bits(I) /= '0' then
            raise Decoding_Error with "Invalid character in binary stream";
         end if;
      end loop;
      return Result;
   end Decode_Binary;

   ---------------------------------------
   -- Variant 1: Standard Rice Coding  --
   ---------------------------------------

   function Encode_Rice (Value : Unsigned_Value; K : Rice_Parameter) return Unbounded_String is
      M           : constant Unsigned_Value := 2**Natural(K);
      Q           : constant Unsigned_Value := Value / M;
      R           : constant Unsigned_Value := Value mod M;
      Unary_Part  : constant String := To_Unary_String (Q);
      Binary_Part : constant String := To_Binary_String (R, Natural(K));
   begin
      return To_Unbounded_String (Unary_Part & Binary_Part);
   end Encode_Rice;

   function Decode_Rice (Bits : Unbounded_String; K : Rice_Parameter) return Unsigned_Value is
      Index       : Positive := 1;
      Q           : constant Unsigned_Value := Decode_Unary (Bits, Index);
      S           : constant String := To_String (Bits);
      Binary_Len  : constant Natural := Natural (K);
      R           : Unsigned_Value := 0;
   begin
      if Binary_Len > 0 then
         if Index + Binary_Len - 1 > S'Length then
            raise Decoding_Error with "Stream truncated during Rice remainder parsing";
         end if;
         R := Decode_Binary (S(Index .. Index + Binary_Len - 1));
      end if;
      return (Q * (2**Natural(K))) + R;
   end Decode_Rice;

   ---------------------------------------
   -- Variant 2: Signed Rice Coding    --
   ---------------------------------------

   function Encode_Signed_Rice (Value : Signed_Value; K : Rice_Parameter) return Unbounded_String is
   begin
      return Encode_Rice (ZigZag_Encode (Value), K);
   end Encode_Signed_Rice;

   function Decode_Signed_Rice (Bits : Unbounded_String; K : Rice_Parameter) return Signed_Value is
   begin
      return ZigZag_Decode (Decode_Rice (Bits, K));
   end Decode_Signed_Rice;

   ---------------------------------------
   -- Variant 3: Golomb Coding         --
   ---------------------------------------

   function Encode_Golomb (Value : Unsigned_Value; M : Golomb_Parameter) return Unbounded_String is
      Q          : constant Unsigned_Value := Value / Unsigned_Value (M);
      R          : constant Unsigned_Value := Value mod Unsigned_Value (M);
      C          : constant Natural := Ceil_Log2 (M);
      Cutoff     : constant Unsigned_Value := (2**C) - Unsigned_Value (M);
      Unary_Part : constant String := To_Unary_String (Q);
   begin
      -- Encode remainder using truncated binary encoding
      if R < Cutoff then
         return To_Unbounded_String (Unary_Part & To_Binary_String (R, C - 1));
      else
         return To_Unbounded_String (Unary_Part & To_Binary_String (R + Cutoff, C));
      end if;
   end Encode_Golomb;

   function Decode_Golomb (Bits : Unbounded_String; M : Golomb_Parameter) return Unsigned_Value is
      Index       : Positive := 1;
      Q           : constant Unsigned_Value := Decode_Unary (Bits, Index);
      C           : constant Natural := Ceil_Log2 (M);
      Cutoff      : constant Unsigned_Value := (2**C) - Unsigned_Value (M);
      S           : constant String := To_String (Bits);
      
      -- We initially read C-1 bits for the remainder
      Next_Idx    : Positive := Index + C - 1;
      R_Candidate : Unsigned_Value;
   begin
      -- Edge case: M=1 implies K=0 (no remainder bits)
      if M = 1 then
         return Q;
      end if;

      if Next_Idx - 1 > S'Length then
         raise Decoding_Error with "Stream truncated during Golomb initial remainder parsing";
      end if;
      
      R_Candidate := Decode_Binary (S(Index .. Next_Idx - 1));

      if R_Candidate < Cutoff then
         return (Q * Unsigned_Value (M)) + R_Candidate;
      else
         -- Remainder was expanded, read one more bit
         if Next_Idx > S'Length then
            raise Decoding_Error with "Stream truncated during Golomb extended remainder parsing";
         end if;
         
         R_Candidate := (R_Candidate * 2) + (if S(Next_Idx) = '1' then 1 else 0);
         return (Q * Unsigned_Value (M)) + (R_Candidate - Cutoff);
      end if;
   end Decode_Golomb;

end Rice_Coding;
