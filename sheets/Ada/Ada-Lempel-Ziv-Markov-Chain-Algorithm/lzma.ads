-- lzma.ads
-- Specification for the Lempel-Ziv-Markov chain algorithm (LZMA) state machine and tokenization.
-- This package implements the core dictionary matching and the specific 12-state Markov chain
-- used to encode sequence probabilities, as described in the algorithm's specification.

package LZMA is

   -- LZMA properties constraints (lc, lp, pb) as defined by the format specification
   subtype LC_Range is Integer range 0 .. 8;  -- Literal context bits
   subtype LP_Range is Integer range 0 .. 4;  -- Literal position bits
   subtype PB_Range is Integer range 0 .. 4;  -- Position bits

   type LZMA_Config is record
      Lc        : LC_Range := 3;
      Lp        : LP_Range := 0;
      Pb        : PB_Range := 2;
      Dict_Size : Positive := 2 ** 16;
   end record;

   -- LZMA uses a 12-state Markov model to determine encoding probabilities
   type LZMA_State is range 0 .. 11;

   -- The four fundamental packet/token types in LZMA
   type Packet_Kind is (LIT, MATCH, SHORTREP, LONGREP);

   -- Token representation (abstracts away the binary range encoder for algorithmic clarity)
   type Token is record
      Kind     : Packet_Kind;
      Literal  : Character;
      Distance : Natural;
      Length   : Natural;
   end record;

   type Token_Array is array (Positive range <>) of Token;
   
   -- We use an unconstrained array wrapper to allow returning dynamically sized arrays
   type Token_List (Max_Len : Natural) is record
      Len  : Natural := 0;
      Data : Token_Array (1 .. Max_Len);
   end record;

   -- Exceptions
   LZMA_Error : exception;

   -- Subprograms

   -- Updates the Markov state machine based on the token emitted/received
   procedure Update_State (State : in out LZMA_State; Kind : Packet_Kind);

   -- Compresses a string into LZMA tokens (using Greedy LZ77 matching)
   function Compress (Input : String; Config : LZMA_Config) return Token_List;

   -- Decompresses LZMA tokens back into a string
   function Decompress (Tokens : Token_Array; Config : LZMA_Config) return String;

end LZMA;
