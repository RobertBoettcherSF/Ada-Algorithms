package body Exponential_Golomb is

   -- Helper Function: Converts a Natural to a binary Bit_String of at least Min_Width
   function To_Binary_String (Value : Natural; Min_Width : Natural := 1) return Bit_String is
      Temp   : Natural := Value;
      Result : Bit_String (1 .. 64) := (others => '0'); -- Arbitrary max size for safe algorithms
      Len    : Natural := 0;
   begin
      if Value = 0 then
         Len := 1;
         Result (64) := '0';
      else
         while Temp > 0 loop
            Len := Len + 1;
            if Temp mod 2 = 1 then
               Result (64 - Len + 1) := '1';
            else
               Result (64 - Len + 1) := '0';
            end if;
            Temp := Temp / 2;
         end loop;
      end if;

      -- Pad with zeros if necessary to meet Min_Width
      while Len < Min_Width loop
         Len := Len + 1;
         Result (64 - Len + 1) := '0';
      end loop;

      return Result (64 - Len + 1 .. 64);
   end To_Binary_String;

   -- Helper Function: Converts a binary Bit_String back to a Natural
   function From_Binary_String (Bits : Bit_String) return Natural is
      Result : Natural := 0;
   begin
      for I in Bits'Range loop
         Result := Result * 2;
         if Bits (I) = '1' then
            Result := Result + 1;
         elsif Bits (I) /= '0' then
            raise Decoding_Error with "Invalid character in bit string";
         end if;
      end loop;
      return Result;
   end From_Binary_String;

   -- =========================================================
   -- Variant 1: Order-0 Unsigned Implementation
   -- =========================================================
   function Encode_Order_0_Unsigned (Value : Natural) return Bit_String is
      X       : constant Natural := Value + 1;
      Bin_Str : constant Bit_String := To_Binary_String (X);
      Zeros   : constant Bit_String (1 .. Bin_Str'Length - 1) := (others => '0');
   begin
      -- Standard Exp-Golomb format: [N zeros] [1] [N binary bits]
      return Zeros & Bin_Str;
   end Encode_Order_0_Unsigned;

   function Decode_Order_0_Unsigned (Bits : Bit_String; Consumed : out Natural) return Natural is
      Zeros : Natural := 0;
      Idx   : Integer := Bits'First;
   begin
      if Bits'Length = 0 then
         raise Decoding_Error with "Empty bit string";
      end if;

      -- Count leading zeros
      while Idx <= Bits'Last and then Bits (Idx) = '0' loop
         Zeros := Zeros + 1;
         Idx := Idx + 1;
      end loop;

      if Idx > Bits'Last or else Bits (Idx) /= '1' then
         raise Decoding_Error with "Missing terminating 1";
      end if;

      -- Verify we have enough bits left to read the value
      if Idx + Zeros > Bits'Last + 1 then
         raise Decoding_Error with "Bit string too short for value";
      end if;

      Consumed := Zeros * 2 + 1;
      return From_Binary_String (Bits (Idx .. Idx + Zeros)) - 1;
   end Decode_Order_0_Unsigned;

   -- =========================================================
   -- Variant 2: Order-k Unsigned Implementation
   -- =========================================================
   function Encode_Order_K_Unsigned (Value : Natural; K : Natural) return Bit_String is
      Q     : constant Natural := Value / (2**K);
      R     : constant Natural := Value mod (2**K);
      Q_Str : constant Bit_String := Encode_Order_0_Unsigned (Q);
   begin
      if K = 0 then
         return Q_Str;
      else
         return Q_Str & To_Binary_String (R, K);
      end if;
   end Encode_Order_K_Unsigned;

   function Decode_Order_K_Unsigned (Bits : Bit_String; K : Natural; Consumed : out Natural) return Natural is
      Q_Consumed : Natural;
      Q          : Natural;
      R          : Natural := 0;
   begin
      Q := Decode_Order_0_Unsigned (Bits, Q_Consumed);
      
      if K > 0 then
         -- Verify bounds for the remainder string
         if Bits'First + Q_Consumed + K - 1 > Bits'Last then
            raise Decoding_Error with "Bit string too short for remainder";
         end if;
         R := From_Binary_String (Bits (Bits'First + Q_Consumed .. Bits'First + Q_Consumed + K - 1));
      end if;
      
      Consumed := Q_Consumed + K;
      return Q * (2**K) + R;
   end Decode_Order_K_Unsigned;

   -- =========================================================
   -- Variant 3: Order-0 Signed Implementation
   -- =========================================================
   function Encode_Order_0_Signed (Value : Integer) return Bit_String is
      Mapped : Natural;
   begin
      -- Standard Signed Mapping: 0->0, 1->1, -1->2, 2->3, -2->4
      if Value <= 0 then
         Mapped := Natural (-2 * Value);
      else
         Mapped := Natural (2 * Value - 1);
      end if;
      return Encode_Order_0_Unsigned (Mapped);
   end Encode_Order_0_Signed;

   function Decode_Order_0_Signed (Bits : Bit_String; Consumed : out Natural) return Integer is
      Mapped : constant Natural := Decode_Order_0_Unsigned (Bits, Consumed);
   begin
      if Mapped mod 2 = 0 then
         return 0 - (Mapped / 2);
      else
         return (Mapped + 1) / 2;
      end if;
   end Decode_Order_0_Signed;

   -- =========================================================
   -- Variant 4: Order-k Signed Implementation
   -- =========================================================
   function Encode_Order_K_Signed (Value : Integer; K : Natural) return Bit_String is
      Mapped : Natural;
   begin
      if Value <= 0 then
         Mapped := Natural (-2 * Value);
      else
         Mapped := Natural (2 * Value - 1);
      end if;
      return Encode_Order_K_Unsigned (Mapped, K);
   end Encode_Order_K_Signed;

   function Decode_Order_K_Signed (Bits : Bit_String; K : Natural; Consumed : out Natural) return Integer is
      Mapped : constant Natural := Decode_Order_K_Unsigned (Bits, K, Consumed);
   begin
      if Mapped mod 2 = 0 then
         return 0 - (Mapped / 2);
      else
         return (Mapped + 1) / 2;
      end if;
   end Decode_Order_K_Signed;

end Exponential_Golomb;
