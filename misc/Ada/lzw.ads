package LZW is
   pragma Preelaborate;

   -- Represents the output stream of LZW codes
   type Code_Type is new Natural;
   type Code_Array is array (Positive range <>) of Code_Type;

   -- Dictionary variants when maximum capacity is reached:
   --   Freeze: Stop adding new sequences; use existing dictionary.
   --   Clear:  Reset the dictionary to the base alphabet and continue.
   type Dictionary_Strategy is (Freeze, Clear);

   LZW_Error : exception;

   -- Compress a standard string into a sequence of LZW codes.
   -- Minimum Max_Bits is 9 (to accommodate the 256 base characters).
   function Compress (Input    : String;
                      Strategy : Dictionary_Strategy := Freeze;
                      Max_Bits : Positive := 12) return Code_Array;

   -- Decompress a sequence of LZW codes back into a string.
   function Decompress (Input    : Code_Array;
                        Strategy : Dictionary_Strategy := Freeze;
                        Max_Bits : Positive := 12) return String;

end LZW;
