-- luhn_mod_n.ads
-- Specification for the Luhn Mod N Algorithm

package Luhn_Mod_N is

   -- Custom Exceptions for Robustness
   Invalid_Alphabet  : exception;
   Invalid_Character : exception;
   Empty_Input       : exception;

   -- We use strong typing by encapsulating the alphabet mapping inside a Codec type.
   -- This allows us to validate the alphabet once and perform fast O(1) lookups.
   type Codec is private;

   -- Creates and validates a Codec from a given alphabet string.
   -- Raises Invalid_Alphabet if length < 2 or if there are duplicate characters.
   function Create_Codec (Mapping : String) return Codec;

   -- Generates the check character for a given input string (Variant: Generation).
   -- Raises Empty_Input if the string is empty.
   -- Raises Invalid_Character if the string contains characters not in the Codec.
   function Generate_Check_Character (C : Codec; Input : String) return Character;

   -- Validates a string that already contains a check character at the end (Variant: Validation).
   -- Returns True if valid, False otherwise.
   function Validate (C : Codec; Input : String) return Boolean;

   -- Helper function to generate and append the check character to the input string.
   function Append_Check_Character (C : Codec; Input : String) return String;

private
   -- O(1) lookup table for character code points. -1 indicates "not in alphabet".
   type Code_Point_Array is array (Character) of Integer;

   type Codec is record
      Alphabet_Length : Natural := 0;
      Alphabet        : String (1 .. 256) := (others => ASCII.NUL);
      Map             : Code_Point_Array := (others => -1);
   end record;

end Luhn_Mod_N;
