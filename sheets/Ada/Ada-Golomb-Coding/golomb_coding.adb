-- golomb_coding.adb
-- Implementation of the Golomb coding algorithms.

package body Golomb_Coding is

   ----------------------------------------------------------------------------
   -- Private Helpers
   ----------------------------------------------------------------------------

   function Ceiling_Log2 (Value : Positive) return Natural is
      Result : Natural := 0;
      Temp   : Positive := 1;
   begin
      while Temp < Value loop
         Result := Result + 1;
         Temp := Temp * 2;
      end loop;
      return Result;
   end Ceiling_Log2;

   function Int_To_Binary_String (Value : Natural; Bits : Natural) return String is
      Result : String (1 .. Bits) := (others => '0');
      Temp   : Natural := Value;
   begin
      for I in reverse 1 .. Bits loop
         if Temp mod 2 = 1 then
            Result (I) := '1';
         end if;
         Temp := Temp / 2;
      end loop;
      return Result;
   end Int_To_Binary_String;

   function Binary_String_To_Int (Bits : String) return Natural is
      Result : Natural := 0;
   begin
      for I in Bits'Range loop
         Result := Result * 2;
         if Bits (I) = '1' then
            Result := Result + 1;
         elsif Bits (I) /= '0' then
            raise Invalid_Bit_String;
         end if;
      end loop;
      return Result;
   end Binary_String_To_Int;

   function Encode_Truncated_Binary (Value : Natural; M : Positive) return String is
      B      : constant Natural := Ceiling_Log2 (M);
      Cutoff : constant Natural := (2 ** B) - M;
   begin
      if B = 0 then
         return "";
      end if;
      
      if Value < Cutoff then
         return Int_To_Binary_String (Value, B - 1);
      else
         return Int_To_Binary_String (Value + Cutoff, B);
      end if;
   end Encode_Truncated_Binary;

   function Decode_Truncated_Binary (Bits : String; M : Positive; Consumed : out Natural) return Natural is
      B      : constant Natural := Ceiling_Log2 (M);
      Cutoff : constant Natural := (2 ** B) - M;
      Val    : Natural;
   begin
      if B = 0 then
         Consumed := 0;
         return 0;
      end if;

      if Bits'Length < B - 1 then
         raise Invalid_Bit_String;
      end if;

      Val := Binary_String_To_Int (Bits (Bits'First .. Bits'First + B - 2));
      
      if Val < Cutoff then
         Consumed := B - 1;
         return Val;
      else
         if Bits'Length < B then
            raise Invalid_Bit_String;
         end if;
         Val := Binary_String_To_Int (Bits (Bits'First .. Bits'First + B - 1));
         Consumed := B;
         return Val - Cutoff;
      end if;
   end Decode_Truncated_Binary;

   ----------------------------------------------------------------------------
   -- 1. Standard Golomb Coding
   ----------------------------------------------------------------------------

   function Encode_Golomb (N : Natural; M : Positive) return String is
      Q     : constant Natural := N / M;
      R     : constant Natural := N mod M;
      Unary : String (1 .. Q + 1) := (others => '1');
   begin
      Unary (Q + 1) := '0'; -- Stop bit for quotient
      return Unary & Encode_Truncated_Binary (R, M);
   end Encode_Golomb;

   function Decode_Golomb (Bits : String; M : Positive; Consumed : out Natural) return Natural is
      Q            : Natural := 0;
      Idx          : Positive := Bits'First;
      Rem_Consumed : Natural := 0;
      R            : Natural;
   begin
      -- Count 1s to determine quotient
      while Idx <= Bits'Last and then Bits (Idx) = '1' loop
         Q := Q + 1;
         Idx := Idx + 1;
      end loop;

      if Idx > Bits'Last or else Bits (Idx) /= '0' then
         raise Invalid_Bit_String;
      end if;

      Idx := Idx + 1; -- Skip the '0' stop bit

      if M > 1 then
         R := Decode_Truncated_Binary (Bits (Idx .. Bits'Last), M, Rem_Consumed);
      else
         R := 0;
         Rem_Consumed := 0;
      end if;

      Consumed := Q + 1 + Rem_Consumed;
      return Q * M + R;
   end Decode_Golomb;

   function Decode_Golomb_Exact (Bits : String; M : Positive) return Natural is
      Consumed : Natural;
      Result   : Natural;
   begin
      Result := Decode_Golomb (Bits, M, Consumed);
      if Consumed /= Bits'Length then
         raise Invalid_Bit_String;
      end if;
      return Result;
   end Decode_Golomb_Exact;

   ----------------------------------------------------------------------------
   -- 2. Rice Coding
   ----------------------------------------------------------------------------

   function Encode_Rice (N : Natural; K : Natural) return String is
   begin
      return Encode_Golomb (N, 2 ** K);
   end Encode_Rice;

   function Decode_Rice (Bits : String; K : Natural; Consumed : out Natural) return Natural is
   begin
      return Decode_Golomb (Bits, 2 ** K, Consumed);
   end Decode_Rice;

   function Decode_Rice_Exact (Bits : String; K : Natural) return Natural is
   begin
      return Decode_Golomb_Exact (Bits, 2 ** K);
   end Decode_Rice_Exact;

   ----------------------------------------------------------------------------
   -- 3. Signed Golomb Coding
   ----------------------------------------------------------------------------
   
   -- Zig-Zag maps numbers: 0->0, -1->1, 1->2, -2->3, 2->4...
   function Encode_Signed_Golomb (N : Integer; M : Positive) return String is
      Mapped_N : Natural;
   begin
      if N >= 0 then
         Mapped_N := 2 * N;
      else
         Mapped_N := 2 * (-N) - 1;
      end if;
      return Encode_Golomb (Mapped_N, M);
   end Encode_Signed_Golomb;

   function Decode_Signed_Golomb (Bits : String; M : Positive; Consumed : out Natural) return Integer is
      Mapped_N : constant Natural := Decode_Golomb (Bits, M, Consumed);
   begin
      if Mapped_N mod 2 = 0 then
         return Mapped_N / 2;
      else
         return -((Mapped_N + 1) / 2);
      end if;
   end Decode_Signed_Golomb;

   function Decode_Signed_Golomb_Exact (Bits : String; M : Positive) return Integer is
      Consumed : Natural;
      Result   : Integer;
   begin
      Result := Decode_Signed_Golomb (Bits, M, Consumed);
      if Consumed /= Bits'Length then
         raise Invalid_Bit_String;
      end if;
      return Result;
   end Decode_Signed_Golomb_Exact;

end Golomb_Coding;
