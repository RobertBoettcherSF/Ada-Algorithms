package Berlekamp_Massey is
   pragma Pure;

   -- We define a binary field type (GF2) and an array for it.
   type Bit is mod 2;
   type Bit_Array is array (Natural range <>) of Bit;

   -- We define a real type for arbitrary field simulation (floating point).
   type Real is new Long_Float;
   type Real_Array is array (Natural range <>) of Real;

   -- Exception raised when array bounds are invalid for the operation.
   Size_Error : exception;

   -- Computes the shortest Linear Feedback Shift Register (LFSR) for a binary sequence.
   -- The Sequence is the input sequence of bits.
   -- The Polynomial array must have space for at least Sequence'Length + 1 elements.
   -- On return, Polynomial contains the connection polynomial C(x), where Polynomial(First) is 1.
   -- LFSR_Length contains the length of the shift register.
   procedure Compute_LFSR_GF2
     (Sequence    : in  Bit_Array;
      Polynomial  : out Bit_Array;
      LFSR_Length : out Natural)
     with Global => null,
          Post   => LFSR_Length <= Sequence'Length;

   -- Validates if the given polynomial and length correctly generate the input binary sequence.
   function Is_Valid_LFSR_GF2
     (Sequence    : in Bit_Array;
      Polynomial  : in Bit_Array;
      LFSR_Length : in Natural) return Boolean
     with Global => null;

   -- Computes the shortest LFSR for a real-valued sequence (arbitrary field variant).
   -- Polynomial must have space for at least Sequence'Length + 1 elements.
   procedure Compute_LFSR_Real
     (Sequence    : in  Real_Array;
      Polynomial  : out Real_Array;
      LFSR_Length : out Natural)
     with Global => null,
          Post   => LFSR_Length <= Sequence'Length;

   -- Validates if the given polynomial and length correctly generate the input real sequence.
   function Is_Valid_LFSR_Real
     (Sequence    : in Real_Array;
      Polynomial  : in Real_Array;
      LFSR_Length : in Natural) return Boolean
     with Global => null;

end Berlekamp_Massey;
