-- elias_omega.adb
-- Implementation of Elias Omega Coding and variants in Ada.

package body Elias_Omega is

   -- Helper: Get binary representation of a positive integer (MSB first)
   function To_Binary (N : Positive) return Bit_Array is
      Temp : Natural := N; 
      Len  : Natural := 0;
   begin
      while Temp > 0 loop
         Len := Len + 1;
         Temp := Temp / 2;
      end loop;

      declare
         Result : Bit_Array (1 .. Len);
         Val    : Natural := N; 
      begin
         for I in reverse 1 .. Len loop
            if Val mod 2 = 1 then
               Result (I) := One;
            else
               Result (I) := Zero;
            end if;
            Val := Val / 2;
         end loop;
         return Result;
      end;
   end To_Binary;

   -- Helper: Concatenate two bit arrays robustly
   function Concat (Left, Right : Bit_Array) return Bit_Array is
      Res : Bit_Array (1 .. Left'Length + Right'Length);
      Idx : Positive := 1;
   begin
      -- Copy using iteration to prevent any bound sliding / length issues
      for I in Left'Range loop
         Res (Idx) := Left (I);
         Idx := Idx + 1;
      end loop;
      for I in Right'Range loop
         Res (Idx) := Right (I);
         Idx := Idx + 1;
      end loop;
      return Res;
   end Concat;

   ---------------------------------------------------------------------------
   -- Variant 1: Standard Positive Integer Encoding
   ---------------------------------------------------------------------------
   function Encode (N : Positive) return Bit_Array is
      
      -- Recursive helper to build the prefix groups (avoids constraining errors)
      function Encode_Groups (Val : Positive) return Bit_Array is
         Empty : constant Bit_Array (1 .. 0) := (others => Zero);
      begin
         if Val = 1 then
            return Empty;
         else
            declare
               Bin : constant Bit_Array := To_Binary (Val);
            begin
               -- Elias Omega recursively prefixes the binary representation of N 
               -- with the encoding of the (length of Bin - 1).
               return Concat (Encode_Groups (Bin'Length - 1), Bin);
            end;
         end if;
      end Encode_Groups;
      
   begin
      -- The full encoding terminates with a '0'
      return Concat (Encode_Groups (N), (1 => Zero));
   end Encode;

   ---------------------------------------------------------------------------
   -- Variant 1: Standard Positive Integer Decoding
   ---------------------------------------------------------------------------
   function Decode (Bits : Bit_Array; Index : in out Positive) return Positive is
      N : Positive := 1;
   begin
      while Index <= Bits'Last loop
         if Bits (Index) = Zero then
            Index := Index + 1;
            return N;
         elsif Bits (Index) = One then
            if Index + N > Bits'Last then
               raise Decoding_Error with "Unexpected end of bit stream during decoding.";
            end if;

            declare
               New_N : Natural := 0; 
            begin
               for I in Index .. Index + N loop
                  New_N := New_N * 2;
                  if Bits (I) = One then
                     New_N := New_N + 1;
                  end if;
               end loop;
               Index := Index + N + 1;
               N := New_N;
            end;
         else
            raise Decoding_Error with "Invalid bit encountered.";
         end if;
      end loop;
      raise Decoding_Error with "Stream ended without termination zero.";
   end Decode;

   ---------------------------------------------------------------------------
   -- Variant 2: Non-Negative Integer Encoding (N >= 0)
   ---------------------------------------------------------------------------
   function Encode_Non_Negative (N : Natural) return Bit_Array is
   begin
      return Encode (N + 1);
   end Encode_Non_Negative;

   function Decode_Non_Negative (Bits : Bit_Array; Index : in out Positive) return Natural is
      Decoded_Pos : constant Positive := Decode (Bits, Index);
   begin
      return Decoded_Pos - 1;
   end Decode_Non_Negative;

   ---------------------------------------------------------------------------
   -- Variant 3: Signed Integer Encoding (Bijection mapping to positives)
   ---------------------------------------------------------------------------
   function Encode_Signed (N : Integer) return Bit_Array is
      Mapped : Positive;
   begin
      if N >= 0 then
         Mapped := Positive (2 * N + 1);
      else
         Mapped := Positive (-2 * N);
      end if;
      return Encode (Mapped);
   end Encode_Signed;

   function Decode_Signed (Bits : Bit_Array; Index : in out Positive) return Integer is
      Mapped : constant Positive := Decode (Bits, Index);
   begin
      if Mapped mod 2 = 1 then
         return Integer ((Mapped - 1) / 2);
      else
         -- Replaced unary minus with multiplication to satisfy GNAT warning safely
         return (-1) * Integer (Mapped / 2);
      end if;
   end Decode_Signed;

   ---------------------------------------------------------------------------
   -- Helper: To_String
   ---------------------------------------------------------------------------
   function To_String (Bits : Bit_Array) return String is
      Res : String (1 .. Bits'Length);
   begin
      for I in Bits'Range loop
         if Bits (I) = Zero then
            Res (I - Bits'First + 1) := '0';
         else
            Res (I - Bits'First + 1) := '1';
         end if;
      end loop;
      return Res;
   end To_String;

end Elias_Omega;
