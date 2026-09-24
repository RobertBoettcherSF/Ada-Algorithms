with Interfaces;

package body Hamming_Code is

   -----------------------------------------------------------------------------
   --  Internal Helpers
   -----------------------------------------------------------------------------

   --  Determines if a given positive integer is a power of two
   function Is_Power_Of_Two (N : Positive) return Boolean is
      use Interfaces;
      U : constant Unsigned_32 := Unsigned_32 (N);
   begin
      return (U and (U - 1)) = 0;
   end Is_Power_Of_Two;


   -----------------------------------------------------------------------------
   --  Length Calculations
   -----------------------------------------------------------------------------

   function Required_Parity_Bits (Data_Length : Positive) return Natural is
      M : Natural := 1;
   begin
      --  Find the minimum number of parity bits 'm' satisfying the Hamming bound
      while 2**M < Data_Length + M + 1 loop
         M := M + 1;
      end loop;
      return M;
   end Required_Parity_Bits;

   function Encoded_Length (Data_Length : Positive) return Positive is
   begin
      return Data_Length + Required_Parity_Bits (Data_Length);
   end Encoded_Length;

   function Extended_Encoded_Length (Data_Length : Positive) return Positive is
   begin
      return Encoded_Length (Data_Length) + 1;
   end Extended_Encoded_Length;


   -----------------------------------------------------------------------------
   --  Standard Hamming Code Implementation
   -----------------------------------------------------------------------------

   function Encode (Data : Bit_Array) return Bit_Array is
      N      : constant Positive := Encoded_Length (Data'Length);
      Result : Bit_Array (1 .. N) := [others => 0];
      D_Idx  : Positive := Data'First;
      use Interfaces;
   begin
      --  Place the actual data bits into non-power-of-two positions
      for I in 1 .. N loop
         if not Is_Power_Of_Two (I) then
            Result (I) := Data (D_Idx);
            D_Idx      := D_Idx + 1;
         end if;
      end loop;

      --  Calculate and place the parity bits in power-of-two positions
      for I in 1 .. N loop
         if Is_Power_Of_Two (I) then
            declare
               Parity : Bit := 0;
               UI     : constant Unsigned_32 := Unsigned_32 (I);
            begin
               for J in I + 1 .. N loop
                  --  A parity bit 'I' covers index 'J' if the I'th bit of J is 1
                  if (Unsigned_32 (J) and UI) = UI then
                     Parity := Parity xor Result (J);
                  end if;
               end loop;
               Result (I) := Parity;
            end;
         end if;
      end loop;

      return Result;
   end Encode;

   procedure Decode
     (Code        : in  Bit_Array;
      Data_Length : in  Positive;
      Data        : out Bit_Array;
      Status      : out Error_Status)
   is
      pragma Unreferenced (Data_Length);
      N        : constant Positive := Code'Length;
      Syndrome : Interfaces.Unsigned_32 := 0;
      Working  : Bit_Array (1 .. N);
      D_Idx    : Positive := Data'First;
      use Interfaces;
   begin
      --  Copy to a 1-based working array for standard indexing math
      for I in 1 .. N loop
         Working (I) := Code (Code'First + I - 1);
      end loop;

      --  Calculate Syndrome: XOR sum of 1-based indices of all bits that are 1
      for I in 1 .. N loop
         if Working (I) = 1 then
            Syndrome := Syndrome xor Unsigned_32 (I);
         end if;
      end loop;

      --  Evaluate Syndrome to determine error status and perform corrections
      if Syndrome = 0 then
         Status := No_Error;
      elsif Syndrome <= Unsigned_32 (N) then
         Status := Single_Error_Corrected;
         Working (Positive (Syndrome)) := Working (Positive (Syndrome)) xor 1;
      else
         --  Syndrome points out of bounds, indicating uncorrectable corruption
         Status := Uncorrectable_Error;
      end if;

      --  Extract corrected data bits, skipping the parity positions
      for I in 1 .. N loop
         if not Is_Power_Of_Two (I) then
            Data (D_Idx) := Working (I);
            D_Idx        := D_Idx + 1;
         end if;
      end loop;
   end Decode;

   function Decode (Code : Bit_Array; Data_Length : Positive) return Bit_Array is
      Status : Error_Status;
      Data   : Bit_Array (1 .. Data_Length);
   begin
      Decode (Code, Data_Length, Data, Status);
      if Status = Uncorrectable_Error then
         raise Hamming_Error with "Multiple errors detected, uncorrectable by standard Hamming";
      end if;
      return Data;
   end Decode;


   -----------------------------------------------------------------------------
   --  Extended Hamming Code Implementation (SECDED)
   -----------------------------------------------------------------------------

   function Encode_Extended (Data : Bit_Array) return Bit_Array is
      Standard : constant Bit_Array := Encode (Data);
      Result   : Bit_Array (1 .. Standard'Length + 1);
      Parity   : Bit := 0;
   begin
      --  Copy standard code bits and calculate overall parity
      for I in Standard'Range loop
         Result (I - Standard'First + 1) := Standard (I);
         Parity := Parity xor Standard (I);
      end loop;

      --  Append the overall parity bit to the very end
      Result (Result'Last) := Parity;
      return Result;
   end Encode_Extended;

   procedure Decode_Extended
     (Code        : in  Bit_Array;
      Data_Length : in  Positive;
      Data        : out Bit_Array;
      Status      : out Error_Status)
   is
      N               : constant Positive := Code'Length - 1;
      Standard_Code   : constant Bit_Array (1 .. N) := Code (Code'First .. Code'Last - 1);
      Received_Parity : constant Bit := Code (Code'Last);
      Overall_Parity  : Bit := 0;
      Standard_Status : Error_Status;
   begin
      --  Calculate overall parity of the received standard segment
      for I in Standard_Code'Range loop
         Overall_Parity := Overall_Parity xor Standard_Code (I);
      end loop;
      
      --  Overall_Parity should equal the received parity if there are zero errors
      --  So their XOR sum should be 0.
      Overall_Parity := Overall_Parity xor Received_Parity; 

      --  Decode standard portion
      Decode (Standard_Code, Data_Length, Data, Standard_Status);

      --  Determine holistic SECDED error state
      if Overall_Parity = 0 then
         if Standard_Status = No_Error then
            Status := No_Error;
         else
            --  Standard syndrome is non-zero, but overall parity is even.
            --  This mathematically implies an even number of errors (>= 2).
            Status := Double_Error_Detected;
         end if;
      else
         --  Overall parity is odd, indicating an odd number of errors (assume 1).
         if Standard_Status = No_Error then
            --  The data is fine, but overall parity bit itself was flipped.
            Status := Single_Error_Corrected;
         elsif Standard_Status = Single_Error_Corrected then
            --  Standard decode corrected the single data error.
            Status := Single_Error_Corrected;
         else
            --  Fallback for highly corrupted states bypassing standard bounds
            Status := Uncorrectable_Error;
         end if;
      end if;
   end Decode_Extended;

   function Decode_Extended (Code : Bit_Array; Data_Length : Positive) return Bit_Array is
      Status : Error_Status;
      Data   : Bit_Array (1 .. Data_Length);
   begin
      Decode_Extended (Code, Data_Length, Data, Status);
      if Status = Double_Error_Detected or Status = Uncorrectable_Error then
         raise Hamming_Error with "Double error detected, uncorrectable by SECDED";
      end if;
      return Data;
   end Decode_Extended;

end Hamming_Code;
