with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Incremental_Encoding is

   -- Strong typing for algorithm-specific data
   type String_Array is array (Positive range <>) of Unbounded_String;
   
   type Encoded_Entry is record
      Prefix_Length : Natural;
      Suffix        : Unbounded_String;
   end record;
   
   type Encoded_Array is array (Positive range <>) of Encoded_Entry;

   -- Exceptions for edge cases and invalid inputs
   Empty_Input_Error   : exception;
   Invalid_Data_Error  : exception;

   -- Core algorithm variants (Standard Encode and Decode)
   function Encode (Input : String_Array) return Encoded_Array;
   function Decode (Input : Encoded_Array) return String_Array;

end Incremental_Encoding;
