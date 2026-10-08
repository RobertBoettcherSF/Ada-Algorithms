-- unicode_collation.ads
-- Specification for the Unicode Collation Algorithm (UCA)
package Unicode_Collation is

   -- UCA uses 16-bit weight levels.
   type Weight_Level is mod 2**16;

   -- A collation element consists of Primary, Secondary, and Tertiary weights.
   type Collation_Weight is record
      Primary   : Weight_Level;
      Secondary : Weight_Level;
      Tertiary  : Weight_Level;
   end record;

   type Weight_Array is array (Positive range <>) of Collation_Weight;
   type Level_Array is array (Positive range <>) of Weight_Level;

   type Collation_Result is (Less, Equal, Greater);

   -- Maps characters to their collation weights.
   -- NOTE: In a full UCA implementation, this requires parsing the external DUCET file.
   -- Here, it acts as a placeholder for the external DUCET data structure.
   type Character_Table is array (Character) of Collation_Weight;

   -- Generates a default mocked DUCET table for standard ASCII to demonstrate the algorithm.
   function Get_Default_Table return Character_Table;

   -- UCA Variant 1: Standard multi-level comparison.
   -- Compares Primary weights, then Secondary (if Primary equal), then Tertiary.
   function Compare_Standard (Left, Right : String; Table : Character_Table) return Collation_Result;

   -- UCA Variant 2: Variable Weighting (Ignore Punctuation).
   -- Treats punctuation characters as completely ignorable (Weight = 0) at all levels.
   function Compare_Ignore_Punctuation (Left, Right : String; Table : Character_Table) return Collation_Result;

   -- UCA Variant 3: Tailoring.
   -- Applies a custom patch/override to the weight table for locale-specific sorting,
   -- then performs a standard comparison.
   function Apply_Tailoring (Base_Table : Character_Table; 
                             Target     : Character; 
                             New_Weight : Collation_Weight) return Character_Table;

   -- Exceptions
   Null_String_Error : exception;

private

   -- Helper to extract non-zero weights for a specific level (core UCA mechanic)
   function Extract_Level_Weights (Weights : Weight_Array; Level : Integer) return Level_Array;

   -- Helper to convert a string to its collation elements based on the table
   function Get_Weights (Str : String; Table : Character_Table) return Weight_Array;

end Unicode_Collation;
