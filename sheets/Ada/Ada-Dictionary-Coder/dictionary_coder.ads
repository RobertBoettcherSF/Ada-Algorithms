-- dictionary_coder.ads
-- Package specification for Dictionary Coder algorithms.
-- Implements both Static (fixed pre-defined) and Dynamic (LZW adaptive) dictionary algorithms.

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Indefinite_Ordered_Maps;

package Dictionary_Coder is

   -- Custom Types for algorithm-specific data to ensure strong typing
   type Code_Type is new Natural;
   type Code_Array is array (Positive range <>) of Code_Type;

   -- Exceptions for edge cases and invalid data
   Dictionary_Error : exception;
   Encode_Error     : exception;
   Decode_Error     : exception;

   -- Type definitions for the Static Dictionary Maps
   package String_Code_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => String,
      Element_Type => Code_Type);
      
   package Code_String_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (Key_Type     => Code_Type,
      Element_Type => String);

   -- Structure to hold a static dictionary configuration
   type Static_Dictionary is record
      Encoder_Map : String_Code_Maps.Map;
      Decoder_Map : Code_String_Maps.Map;
      Next_Code   : Code_Type := 1;
   end record;

   -------------------------------------------------------------------------
   -- VARIANT 1: Static Dictionary Coder
   -- Uses a pre-defined dictionary. Words must be added manually before use.
   -------------------------------------------------------------------------
   
   -- Helper procedure to populate the static dictionary
   procedure Add_To_Dictionary (Dict : in out Static_Dictionary; Word : String);
   
   -- Encodes a space-separated string of words into an array of codes
   function Encode_Static (Dict : Static_Dictionary; Text : String) return Code_Array;
   
   -- Decodes an array of codes back into a space-separated string
   function Decode_Static (Dict : Static_Dictionary; Codes : Code_Array) return String;


   -------------------------------------------------------------------------
   -- VARIANT 2: Dynamic Dictionary Coder (LZW - Lempel-Ziv-Welch)
   -- Builds the dictionary adaptively as data is processed.
   -------------------------------------------------------------------------
   
   -- Encodes a raw string using the LZW adaptive dictionary algorithm
   function LZW_Encode (Text : String) return Code_Array;
   
   -- Decodes an array of LZW codes back into the original string
   function LZW_Decode (Codes : Code_Array) return String;

end Dictionary_Coder;
