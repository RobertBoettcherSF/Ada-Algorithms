--  ===========================================================================
--  Package: BCH_Codes
--  Description: Binary BCH Code (15, 7, 2) implementation over GF(2^4).
--  ===========================================================================

package BCH_Codes is
   pragma Pure;

   -- Code parameters: n = 15, k = 7, t = 2 (corrects up to 2 errors)
   N : constant := 15;
   K : constant := 7;
   T : constant := 2;

   type Bit is mod 2;
   type Message_Type is array (1 .. K) of Bit;
   type Codeword_Type is array (1 .. N) of Bit;
   
   -- Elements of GF(2^4) represented as integers 0 .. 15
   type GF_Element is mod 16;
   type Syndrome_Array is array (1 .. 2 * T) of GF_Element;

   -- Exceptions
   Invalid_Message_Length_Error : exception;
   Decoding_Failed_Error        : exception;

   -- Public subprograms
   function Encode (Msg : Message_Type) return Codeword_Type
     with Post => (for all I in Message_Type'Range => Encode'Result (I) = Msg (I));

   function Is_Valid_Codeword (CW : Codeword_Type) return Boolean;

   function Compute_Syndromes (CW : Codeword_Type) return Syndrome_Array;

   function Decode (Received : Codeword_Type) return Codeword_Type
     with Post => Is_Valid_Codeword (Decode'Result);

end BCH_Codes;
