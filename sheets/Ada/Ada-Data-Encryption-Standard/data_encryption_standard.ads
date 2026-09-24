pragma Ada_2022;

package Data_Encryption_Standard
  with Pure
is
   --  DES operates on strictly 64-bit blocks. We use tightly packed boolean arrays.
   --  This provides strong typing, native XOR capabilities, and guarantees size.
   type Block_Type is array (1 .. 64) of Boolean with Pack, Size => 64;
   type Key_Type   is array (1 .. 64) of Boolean with Pack, Size => 64;
   
   --  Type for Triple DES which utilizes 3 distinct keys
   type Key_3_Type is array (1 .. 3) of Key_Type;

   --  Exception raised when a key fails odd parity validation
   Parity_Error : exception;

   --  Basic Single DES Variants
   function Encrypt (Data : Block_Type; Key : Key_Type) return Block_Type
     with Global => null;

   function Decrypt (Data : Block_Type; Key : Key_Type) return Block_Type
     with Global => null;

   --  Triple DES (3DES) Variants (Encrypt-Decrypt-Encrypt sequence)
   function Triple_DES_Encrypt (Data : Block_Type; Keys : Key_3_Type) return Block_Type
     with Global => null;

   function Triple_DES_Decrypt (Data : Block_Type; Keys : Key_3_Type) return Block_Type
     with Global => null;

   --  Utilities
   --  Checks if a given key is one of the known DES weak keys
   function Is_Weak_Key (Key : Key_Type) return Boolean
     with Global => null;

   --  Adjusts the 8th bit of every byte in the key to ensure odd parity
   function Adjust_Parity (Key : Key_Type) return Key_Type
     with Global => null;
     
   --  Validates if a key possesses correct odd parity, raises Parity_Error if not
   function Assert_Valid_Parity (Key : Key_Type) return Boolean
     with Global => null;

end Data_Encryption_Standard;
