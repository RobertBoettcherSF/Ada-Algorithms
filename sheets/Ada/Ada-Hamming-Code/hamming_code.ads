package Hamming_Code is

   --  A single bit, forming the foundation of our encoded data
   type Bit is mod 2;

   --  An unconstrained array of bits. 
   --  Indices must be positive to align with mathematical Hamming logic.
   type Bit_Array is array (Positive range <>) of Bit;

   --  The possible outcomes of a decoding operation
   type Error_Status is
     (No_Error,
      Single_Error_Corrected,
      Double_Error_Detected,
      Uncorrectable_Error);

   --  Exception raised when a functional decode encounters multiple errors
   Hamming_Error : exception;

   --  Calculates how many parity bits are required to encode Data_Length bits.
   --  Uses the Hamming bound equation: 2^m >= Data_Length + m + 1
   function Required_Parity_Bits (Data_Length : Positive) return Natural
     with Post => Required_Parity_Bits'Result > 0;

   --  Calculates the total length of a standard Hamming code
   function Encoded_Length (Data_Length : Positive) return Positive;

   --  Calculates the total length of an Extended Hamming code (SECDED)
   function Extended_Encoded_Length (Data_Length : Positive) return Positive;


   -----------------------------------------------------------------------------
   --  Standard Hamming Code Variants
   -----------------------------------------------------------------------------

   --  Encodes the provided data using standard Hamming error correction.
   --  Parity bits are stored at power-of-two indices (1, 2, 4, 8...).
   function Encode (Data : Bit_Array) return Bit_Array
     with Pre  => Data'Length > 0,
          Post => Encode'Result'Length = Encoded_Length (Data'Length);

   --  Decodes the provided standard Hamming code, extracting the original data.
   --  Reports error status in the out parameter. 
   procedure Decode
     (Code        : in  Bit_Array;
      Data_Length : in  Positive;
      Data        : out Bit_Array;
      Status      : out Error_Status)
     with Pre => Code'Length = Encoded_Length (Data_Length) and then
                 Data'Length = Data_Length;

   --  Functional decode that raises Hamming_Error if multiple errors are detected.
   --  Ideal for contexts where error-correction failure is an exceptional state.
   function Decode (Code : Bit_Array; Data_Length : Positive) return Bit_Array
     with Pre => Code'Length = Encoded_Length (Data_Length);


   -----------------------------------------------------------------------------
   --  Extended Hamming Code (SECDED) Variants
   -----------------------------------------------------------------------------

   --  Encodes the provided data using Extended Hamming error correction.
   --  Adds an overall parity bit at the very end of the encoded block.
   function Encode_Extended (Data : Bit_Array) return Bit_Array
     with Pre  => Data'Length > 0,
          Post => Encode_Extended'Result'Length = Extended_Encoded_Length (Data'Length);

   --  Decodes an Extended Hamming code. Capable of detecting up to two errors,
   --  and correcting single errors (SECDED).
   procedure Decode_Extended
     (Code        : in  Bit_Array;
      Data_Length : in  Positive;
      Data        : out Bit_Array;
      Status      : out Error_Status)
     with Pre => Code'Length = Extended_Encoded_Length (Data_Length) and then
                 Data'Length = Data_Length;

   --  Functional Extended decode that raises Hamming_Error if errors cannot be corrected.
   function Decode_Extended (Code : Bit_Array; Data_Length : Positive) return Bit_Array
     with Pre => Code'Length = Extended_Encoded_Length (Data_Length);

end Hamming_Code;
