-- hamming_7_4.ads
-- Specification for the Hamming(7,4) Error Correction Code.
-- Includes both Systematic and Interleaved variants based on Wikipedia definitions.

package Hamming_7_4 is

   -- Strong typing for bits to prevent arbitrary integer assignments
   type Bit is mod 2;

   -- Custom arrays representing our input, output, and internal structures
   type Data_Word is array (1 .. 4) of Bit;
   type Code_Word is array (1 .. 7) of Bit;
   type Syndrome is array (1 .. 3) of Bit;

   -- Matrix types for generator (G) and parity-check (H) matrices
   type Matrix_G is array (1 .. 4, 1 .. 7) of Bit;
   type Matrix_H is array (1 .. 3, 1 .. 7) of Bit;

   -- Wikipedia describes two main layouts for Hamming(7,4)
   type Code_Variant is (Systematic, Interleaved);

   -- Generator and Parity-check Matrices (Constants)
   
   -- Systematic: Data bits at 1-4, Parity bits at 5-7.
   G_Systematic : constant Matrix_G :=
     ((1,0,0,0, 1,1,0),
      (0,1,0,0, 1,0,1),
      (0,0,1,0, 0,1,1),
      (0,0,0,1, 1,1,1));

   H_Systematic : constant Matrix_H :=
     ((1,1,0,1, 1,0,0),
      (1,0,1,1, 0,1,0),
      (0,1,1,1, 0,0,1));

   -- Interleaved: Parity bits at positions 1, 2, 4. Data at 3, 5, 6, 7.
   G_Interleaved : constant Matrix_G :=
     ((1,1,1,0, 0,0,0),
      (1,0,0,1, 1,0,0),
      (0,1,0,1, 0,1,0),
      (1,1,0,1, 0,0,1));

   H_Interleaved : constant Matrix_H :=
     ((1,0,1,0, 1,0,1),
      (0,1,1,0, 0,1,1),
      (0,0,0,1, 1,1,1));

   -- Core Subprograms

   -- Encodes a 4-bit Data_Word into a 7-bit Code_Word
   function Encode (Data    : Data_Word; 
                    Variant : Code_Variant := Interleaved) return Code_Word;

   -- Decodes a 7-bit Code_Word, corrects up to 1 bit error, and extracts Data_Word
   procedure Decode (Code        : in out Code_Word;
                     Data        : out Data_Word;
                     Error_Found : out Boolean;
                     Error_Pos   : out Natural;
                     Variant     : in Code_Variant := Interleaved);

   -- Helper Subprograms for internal calculations (exposed for testing/verification)
   function Multiply (Data : Data_Word; G : Matrix_G) return Code_Word;
   function Multiply (Code : Code_Word; H : Matrix_H) return Syndrome;
   function Syndrome_To_Int (S : Syndrome; Variant : Code_Variant) return Natural;

end Hamming_7_4;
