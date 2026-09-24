-- adler32.adb
-- Implementation of the Adler-32 checksum algorithm
with Interfaces;

package body Adler32 is
   use Interfaces; -- Makes the +, *, and mod operators directly visible

   ------------------------------------------------------------------
   -- Variant 1: Basic (Unoptimized byte-by-byte modulo)
   ------------------------------------------------------------------
   function Calculate_Basic (Data : Byte_Array) return Checksum is
      A : Interfaces.Unsigned_32 := 1;
      B : Interfaces.Unsigned_32 := 0;
   begin
      -- Edge case: Empty input array bypasses the loop, returning 1.
      for I in Data'Range loop
         A := (A + Interfaces.Unsigned_32 (Data (I))) mod Base;
         B := (B + A) mod Base;
      end loop;
      
      -- Combine B (upper 16 bits) and A (lower 16 bits)
      return Checksum (B * 65536 + A);
   end Calculate_Basic;

   ------------------------------------------------------------------
   -- Variant 2: Optimized (Deferred modulo operation)
   ------------------------------------------------------------------
   function Calculate_Optimized (Data : Byte_Array) return Checksum is
      A : Interfaces.Unsigned_32 := 1;
      B : Interfaces.Unsigned_32 := 0;
      
      -- 5552 is the "magic number". It is the largest n such that 
      -- 255 * n * (n+1) / 2 + (n+1) * 65521 < 2^32-1, preventing overflow.
      Block_Max     : constant Natural := 5552;
      
      Current_Index : Positive := Data'First;
      Remaining     : Natural := Data'Length;
      Process_Count : Natural;
   begin
      while Remaining > 0 loop
         -- Determine how many bytes we can safely process before modulo
         if Remaining > Block_Max then
            Process_Count := Block_Max;
         else
            Process_Count := Remaining;
         end if;

         -- Inner tight loop with NO modulo
         for I in 1 .. Process_Count loop
            A := A + Interfaces.Unsigned_32 (Data (Current_Index));
            B := B + A;
            Current_Index := Current_Index + 1;
         end loop;

         -- Apply modulo only at block boundaries to save CPU cycles
         A := A mod Base;
         B := B mod Base;
         Remaining := Remaining - Process_Count;
      end loop;

      return Checksum (B * 65536 + A);
   end Calculate_Optimized;

   ------------------------------------------------------------------
   -- Helper: String to Byte_Array Conversion
   ------------------------------------------------------------------
   function To_Byte_Array (Str : String) return Byte_Array is
      Result : Byte_Array (1 .. Str'Length);
   begin
      -- Edge case safely handled: Str'Length = 0 results in an empty array
      for I in Str'Range loop
         -- Map the exact character position safely to our 1-indexed output
         Result (I - Str'First + 1) := Byte (Character'Pos (Str (I)));
      end loop;
      return Result;
   end To_Byte_Array;

end Adler32;
