package body Double_Dabble is

   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;

   ------------------------------------------------------------
   -- Forward Double Dabble Logic
   ------------------------------------------------------------

   function Add_3_Module (Nibble : BCD_Digit) return BCD_Digit is
   begin
      if Nibble >= 5 then
         return Nibble + 3;
      end if;
      return Nibble;
   end Add_3_Module;

   function Normalize_BCD (Arr : BCD_Array) return BCD_Array is
      Start_Idx : Positive := Arr'First;
   begin
      -- Find first non-zero digit
      while Start_Idx < Arr'Last and then Arr(Start_Idx) = 0 loop
         Start_Idx := Start_Idx + 1;
      end loop;
      
      declare
         Result : BCD_Array (1 .. Arr'Last - Start_Idx + 1);
      begin
         for I in Result'Range loop
            Result(I) := Arr(Start_Idx + I - 1);
         end loop;
         return Result;
      end;
   end Normalize_BCD;

   function To_BCD (Bits : Bit_Array) return BCD_Array is
      Max_Digits : constant Positive := (Bits'Length / 3) + 2; 
      Work_BCD   : BCD_Array (1 .. Max_Digits) := (others => 0);
      Carry      : Boolean;
      Next_Carry : Boolean;
   begin
      if Bits'Length = 0 then
         raise Invalid_Input with "Bit array cannot be empty";
      end if;

      for I in Bits'Range loop
         -- Step 1: Add 3 to digits >= 5
         for J in Work_BCD'Range loop
            Work_BCD(J) := Add_3_Module(Work_BCD(J));
         end loop;

         -- Step 2: Shift Left 1 bit across the entire BCD array
         Carry := Bits(I); -- Shift in the current bit at the LSB
         for J in reverse Work_BCD'Range loop
            Next_Carry  := Work_BCD(J) >= 8;
            -- BCD_Digit is a modular type (mod 16), so * 2 implicitly wraps around.
            Work_BCD(J) := Work_BCD(J) * 2; 
            if Carry then
               Work_BCD(J) := Work_BCD(J) + 1;
            end if;
            Carry := Next_Carry;
         end loop;
      end loop;

      return Normalize_BCD(Work_BCD);
   end To_BCD;

   function To_BCD (Value : Interfaces.Unsigned_8) return BCD_Array is
      Bits : Bit_Array (1 .. 8);
      Temp : Interfaces.Unsigned_8 := Value;
   begin
      for I in reverse 1 .. 8 loop
         Bits(I) := (Temp and 1) = 1;
         Temp := Temp / 2;
      end loop;
      return To_BCD (Bits);
   end To_BCD;

   function To_BCD (Value : Interfaces.Unsigned_16) return BCD_Array is
      Bits : Bit_Array (1 .. 16);
      Temp : Interfaces.Unsigned_16 := Value;
   begin
      for I in reverse 1 .. 16 loop
         Bits(I) := (Temp and 1) = 1;
         Temp := Temp / 2;
      end loop;
      return To_BCD (Bits);
   end To_BCD;

   function To_BCD (Value : Interfaces.Unsigned_32) return BCD_Array is
      Bits : Bit_Array (1 .. 32);
      Temp : Interfaces.Unsigned_32 := Value;
   begin
      for I in reverse 1 .. 32 loop
         Bits(I) := (Temp and 1) = 1;
         Temp := Temp / 2;
      end loop;
      return To_BCD (Bits);
   end To_BCD;

   ------------------------------------------------------------
   -- Reverse Double Dabble Logic
   ------------------------------------------------------------

   function To_Binary (BCD : BCD_Array; Bit_Length : Positive) return Bit_Array is
      Work_BCD    : BCD_Array (1 .. BCD'Length) := BCD;
      Result_Bits : Bit_Array (1 .. Bit_Length);
      Carry       : Boolean;
      Next_Carry  : Boolean;
   begin
      if BCD'Length = 0 then
         raise Invalid_Input with "BCD array cannot be empty";
      end if;

      -- Validate BCD encoding
      for I in BCD'Range loop
         if BCD(I) > 9 then
            raise Conversion_Error with "Invalid BCD digit detected";
         end if;
      end loop;

      -- Process from LSB of Binary to MSB
      for I in reverse 1 .. Bit_Length loop
         -- Step 1: Shift Right 1 bit across the entire BCD array
         Carry := False;
         for J in Work_BCD'Range loop
            Next_Carry  := (Work_BCD(J) and 1) = 1;
            Work_BCD(J) := Work_BCD(J) / 2;
            if Carry then
               Work_BCD(J) := Work_BCD(J) + 8;
            end if;
            Carry := Next_Carry;
         end loop;
         Result_Bits(I) := Carry; -- The bit that fell off the LSD

         -- Step 2: Subtract 3 if digit >= 8
         for J in Work_BCD'Range loop
            if Work_BCD(J) >= 8 then
               Work_BCD(J) := Work_BCD(J) - 3;
            end if;
         end loop;
      end loop;

      return Result_Bits;
   end To_Binary;

   function To_Unsigned_8 (BCD : BCD_Array) return Interfaces.Unsigned_8 is
      Bits : constant Bit_Array := To_Binary(BCD, 8);
      Result : Interfaces.Unsigned_8 := 0;
   begin
      for I in Bits'Range loop
         Result := Result * 2;
         if Bits(I) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end To_Unsigned_8;

   function To_Unsigned_16 (BCD : BCD_Array) return Interfaces.Unsigned_16 is
      Bits : constant Bit_Array := To_Binary(BCD, 16);
      Result : Interfaces.Unsigned_16 := 0;
   begin
      for I in Bits'Range loop
         Result := Result * 2;
         if Bits(I) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end To_Unsigned_16;

   function To_Unsigned_32 (BCD : BCD_Array) return Interfaces.Unsigned_32 is
      Bits : constant Bit_Array := To_Binary(BCD, 32);
      Result : Interfaces.Unsigned_32 := 0;
   begin
      for I in Bits'Range loop
         Result := Result * 2;
         if Bits(I) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end To_Unsigned_32;

end Double_Dabble;
