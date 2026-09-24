package Bcrypt with Preelaborate is

   --  Strong typing for domain-specific parameters
   type Cost_Factor is new Integer range 4 .. 31;
   
   --  Bcrypt algorithm variants as described in the specification
   type Version_Type is (V_2a, V_2b, V_2y);

   --  A standard Bcrypt hash is exactly 60 characters long.
   --  Format: $version$cost$salt(22)hash(31)
   subtype Hash_String is String (1 .. 60);

   --  Salt strings are exactly 22 Base64 characters representing 16 raw bytes.
   subtype Salt_String is String (1 .. 22);

   --  Exceptions for error handling
   Invalid_Hash  : exception;
   Invalid_Salt  : exception;

   --  Encode raw bytes into a valid Bcrypt Base64 salt string
   function Encode_Salt (Raw_Salt : in String) return Salt_String
     with Pre    => Raw_Salt'Length = 16,
          Global => null;

   --  Generate a full Bcrypt hash from a password, salt, and cost
   function Hash
     (Password : in String;
      Salt     : in Salt_String;
      Cost     : in Cost_Factor := 12;
      Version  : in Version_Type := V_2b) return Hash_String
     with Pre    => Password'Length <= 72,
          Global => null;

   --  Verify a password against a provided Bcrypt hash string
   function Verify
     (Password : in String;
      Hash_Val : in Hash_String) return Boolean
     with Pre    => Password'Length <= 72,
          Global => null;

end Bcrypt;
