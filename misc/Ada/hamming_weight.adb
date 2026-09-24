-- hamming_weight.adb
-- Implementation body for the Hamming Weight algorithms.
package body Hamming_Weight is

   ---------------------------------------------------------------------------
   -- Naive Implementation
   ---------------------------------------------------------------------------
   function Naive_Count (Value : Word_32) return Bit_Count is
      Count : Bit_Count := 0;
      Temp  : Word_32 := Value;
   begin
      -- Edge case handler: Loop stops early if Temp is 0
      while Temp > 0 loop
         if (Temp and 1) = 1 then
            Count := Count + 1;
         end if;
         Temp := Temp / 2; -- Equivalent to logical shift right
      end loop;
      return Count;
   end Naive_Count;

   ---------------------------------------------------------------------------
   -- Brian Kernighan's / Wegner's Algorithm
   ---------------------------------------------------------------------------
   function Kernighan_Count (Value : Word_32) return Bit_Count is
      Count : Bit_Count := 0;
      Temp  : Word_32 := Value;
   begin
      while Temp > 0 loop
         -- Clears the lowest set bit (e.g., 1010 becomes 1000)
         Temp := Temp and (Temp - 1);
         Count := Count + 1;
      end loop;
      return Count;
   end Kernighan_Count;

   ---------------------------------------------------------------------------
   -- Parallel (SWAR) Algorithm
   ---------------------------------------------------------------------------
   function SWAR_Count (Value : Word_32) return Bit_Count is
      Temp : Word_32 := Value;
   begin
      -- Step 1: Count bits set in each 2-bit field
      Temp := Temp - ((Temp / 2) and 16#5555_5555#);
      -- Step 2: Sum 2-bit fields into 4-bit fields
      Temp := (Temp and 16#3333_3333#) + ((Temp / 4) and 16#3333_3333#);
      -- Step 3: Sum 4-bit fields into 8-bit fields
      Temp := (Temp + (Temp / 16)) and 16#0F0F_0F0F#;
      -- Step 4: Sum 8-bit fields into 16-bit fields
      Temp := Temp + (Temp / 256);
      -- Step 5: Sum 16-bit fields into 32-bit fields
      Temp := Temp + (Temp / 65536);
      
      -- Mask out the garbage bits (only the lower 6 bits are needed for up to 32)
      return Bit_Count (Temp and 16#0000_003F#);
   end SWAR_Count;

   ---------------------------------------------------------------------------
   -- SWAR with Multiplication Trick
   ---------------------------------------------------------------------------
   function SWAR_Multiply_Count (Value : Word_32) return Bit_Count is
      Temp : Word_32 := Value;
   begin
      -- Reduce down to 8-bit counts
      Temp := Temp - ((Temp / 2) and 16#5555_5555#);
      Temp := (Temp and 16#3333_3333#) + ((Temp / 4) and 16#3333_3333#);
      Temp := (Temp + (Temp / 16)) and 16#0F0F_0F0F#;
      
      -- Multiply by 0x01010101 to sum all 8-bit bytes into the top byte.
      -- The modular type automatically safely wraps (overflows) like C.
      Temp := Temp * 16#0101_0101#;
      
      -- Shift right 24 bits (divide by 2^24) to get the accumulated top byte
      return Bit_Count (Temp / 16#0100_0000#);
   end SWAR_Multiply_Count;

   ---------------------------------------------------------------------------
   -- Lookup Table Initialization Helper
   ---------------------------------------------------------------------------
   -- Placed inside the body so it can safely call Naive_Count after elaboration
   function Build_Lookup_Table return Lookup_Array is
      Result : Lookup_Array;
   begin
      for I in Byte loop
         -- Using our Naive function to precalculate counts during initialization
         Result (I) := Naive_Count (Word_32 (I));
      end loop;
      return Result;
   end Build_Lookup_Table;

   ---------------------------------------------------------------------------
   -- The Static Precomputed Table
   ---------------------------------------------------------------------------
   -- Instantiated here to avoid the "Access Before Elaboration" Program_Error
   Popcount_Table : constant Lookup_Array := Build_Lookup_Table;

   ---------------------------------------------------------------------------
   -- Precomputed Lookup Table Algorithm
   ---------------------------------------------------------------------------
   function Lookup_Table_Count (Value : Word_32) return Bit_Count is
      Total : Bit_Count := 0;
      Temp  : Word_32 := Value;
   begin
      -- Process 32 bits as four 8-bit chunks
      for I in 1 .. 4 loop
         Total := Total + Popcount_Table (Byte (Temp and 16#FF#));
         Temp := Temp / 256; -- Shift right 8 bits to expose the next chunk
      end loop;
      return Total;
   end Lookup_Table_Count;

end Hamming_Weight;
