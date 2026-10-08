package Reed_Solomon is

   -- We use GF(2^8) elements, standard for Reed-Solomon bytes
   type Symbol is mod 256;
   
   -- Polynomials are represented such that Polynomial(I) is the coefficient for x^I
   type Polynomial is array (Natural range <>) of Symbol;

   -- Raised when the error locator finds an uncorrectable condition
   Decoding_Error : exception;

   -- Galois Field Arithmetic in GF(2^8)
   function "+" (Left, Right : Symbol) return Symbol
     with Post => "+"'Result = (Left xor Right);

   function "*" (Left, Right : Symbol) return Symbol;
   
   function "/" (Left, Right : Symbol) return Symbol
     with Pre => Right /= 0;

   -- Polynomial Arithmetic
   function Poly_Add (Left, Right : Polynomial) return Polynomial;
   function Poly_Mult (Left, Right : Polynomial) return Polynomial;
   function Poly_Eval (Poly : Polynomial; X : Symbol) return Symbol;

   -----------------------------------------------------------------------------
   -- VARIANT 1: Original View
   -----------------------------------------------------------------------------
   -- In the original view, a message is treated as a polynomial of degree K-1
   -- and evaluated at N successive points to generate the codeword.
   function Encode_Original_View (Message : Polynomial; N : Positive) return Polynomial
     with Pre => Message'Length > 0 and then N >= Message'Length,
          Post => Encode_Original_View'Result'Length = N;

   -----------------------------------------------------------------------------
   -- VARIANT 2: BCH View (Systematic)
   -----------------------------------------------------------------------------
   -- Generates the standardized Generator Polynomial with roots \alpha^0 .. \alpha^{ECC-1}
   function Generate_Polynomial (ECC_Count : Natural) return Polynomial
     with Pre => ECC_Count > 0,
          Post => Generate_Polynomial'Result'Length = ECC_Count + 1;

   -- Encodes systematically: shifts Message by ECC_Count, divides by Generator,
   -- and appends the remainder to the lower powers.
   function Encode_BCH (Message : Polynomial; ECC_Count : Natural) return Polynomial
     with Pre => Message'Length > 0 and then ECC_Count > 0,
          Post => Encode_BCH'Result'Length = Message'Length + ECC_Count;

   -- Calculates the syndromes S_0 ... S_{ECC-1} for a given codeword
   function Calculate_Syndromes (Codeword : Polynomial; ECC_Count : Natural) return Polynomial
     with Pre => Codeword'Length > ECC_Count and then ECC_Count > 0,
          Post => Calculate_Syndromes'Result'Length = ECC_Count;

   -----------------------------------------------------------------------------
   -- VARIANT 3: Error Correction / Decoding (Berlekamp-Massey, Chien, Forney)
   -----------------------------------------------------------------------------
   -- Detects and corrects errors up to Floor(ECC_Count / 2). Returns the original
   -- message (Codeword stripped of parity). Raises Decoding_Error if uncorrectable.
   function Decode_BCH (Codeword : Polynomial; ECC_Count : Natural) return Polynomial
     with Pre => Codeword'Length > ECC_Count and then ECC_Count > 0,
          Post => Decode_BCH'Result'Length = Codeword'Length - ECC_Count;

end Reed_Solomon;
