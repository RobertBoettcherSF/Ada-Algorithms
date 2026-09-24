with Interfaces;

package MD5 is
   pragma Preelaborate;

   -- Domain types for strong typing
   subtype Byte is Interfaces.Unsigned_8;
   subtype Word is Interfaces.Unsigned_32;

   type Byte_Array is array (Natural range <>) of Byte;
   type Digest_Type is array (0 .. 15) of Byte;
   subtype Hex_String is String (1 .. 32);

   -- Exception for invalid operations (e.g., updating a finalized hash)
   MD5_Error : exception;

   type Context_Status is (Open, Closed);

   -- Context for incremental processing, explicitly made private to encapsulate state
   type Context is private;

   -- Incremental processing subprograms
   procedure Init (Ctx : out Context)
     with Global => null,
          Post   => Is_Open (Ctx);

   procedure Update (Ctx  : in out Context;
                     Data : in Byte_Array)
     with Global => null,
          Pre    => Is_Open (Ctx);

   procedure Update (Ctx  : in out Context;
                     Data : in String)
     with Global => null,
          Pre    => Is_Open (Ctx);

   procedure Final (Ctx    : in out Context;
                    Digest : out Digest_Type)
     with Global => null,
          Pre    => Is_Open (Ctx),
          Post   => not Is_Open (Ctx);

   -- One-shot processing subprograms
   function Hash (Message : Byte_Array) return Digest_Type
     with Global => null;

   function Hash (Message : String) return Hex_String
     with Global => null;

   -- Utility conversions
   function To_Hex (Digest : Digest_Type) return Hex_String
     with Global => null;

   function To_Bytes (S : String) return Byte_Array
     with Global => null;

   -- Helper for state verification
   function Is_Open (Ctx : Context) return Boolean
     with Global => null;

private
   subtype Block_Type is Byte_Array (0 .. 63);
   type State_Type is array (0 .. 3) of Word;

   -- Internal state representing the MD5 context
   type Context is record
      Status : Context_Status := Closed;
      State  : State_Type := [16#67452301#, 16#EFCDAB89#, 16#98BADCFE#, 16#10325476#];
      Count  : Interfaces.Unsigned_64 := 0; -- Total processed bits
      Buffer : Block_Type := [others => 0]; -- 64-byte processing buffer
   end record;

end MD5;
