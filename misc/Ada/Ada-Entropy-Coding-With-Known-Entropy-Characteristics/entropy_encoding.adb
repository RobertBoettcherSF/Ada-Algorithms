with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Entropy_Encoding is

   -- Custom Exceptions for Robustness
   Empty_Input_Error  : exception;
   Invalid_Data_Error : exception;

   -- Strong typing for algorithm-specific data
   type Frequency_Map is array (Character) of Natural;

   type Code_Record is record
      Is_Valid : Boolean := False;
      Code     : Unbounded_String;
   end record;

   type Dictionary is array (Character) of Code_Record;

   -- Helper: Calculates frequencies of symbols from an input string
   function Calculate_Frequencies (Text : String) return Frequency_Map;

   -- Variant 1: Shannon-Fano Coding (Top-Down Approach)
   -- Splits probabilities recursively.
   function Generate_Shannon_Fano (Freqs : Frequency_Map) return Dictionary;

   -- Variant 2: Huffman Coding (Bottom-Up Approach)
   -- Builds an optimal prefix tree by merging lowest probabilities.
   function Generate_Huffman (Freqs : Frequency_Map) return Dictionary;

   -- Helper: Encodes a string using the generated Dictionary
   function Encode (Text : String; Dict : Dictionary) return String;

end Entropy_Encoding;
