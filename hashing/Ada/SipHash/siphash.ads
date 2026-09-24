with Interfaces;

package SipHash with SPARK_Mode => On is

   -- Strong typing for algorithm-specific data domains
   type Byte is new Interfaces.Unsigned_8;
   type Word64 is new Interfaces.Unsigned_64;

   -- Unconstrained array for arbitrary length messages
   type Byte_Array is array (Natural range <>) of Byte;

   -- SipHash keys are strictly 128-bit (16 bytes)
   subtype Key_Type is Byte_Array (0 .. 15);

   -- 128-bit MAC output variant container
   type Tag_128 is record
      Low  : Word64;
      High : Word64;
   end record;

   -- Constants for the standard SipHash-2-4 round configuration
   Default_C : constant Positive := 2;
   Default_D : constant Positive := 4;

   -- Computes the standard 64-bit SipHash MAC (SipHash-c-d)
   -- C defines the number of compression rounds per message block.
   -- D defines the number of finalization rounds.
   function Hash_64
     (Key     : Key_Type;
      Message : Byte_Array;
      C       : Positive := Default_C;
      D       : Positive := Default_D) return Word64
     with Global => null;

   -- Computes the 128-bit SipHash MAC (SipHash128-c-d)
   -- Uses the same compression rounds but alters initialization and finalization
   -- to extract a 128-bit tag.
   function Hash_128
     (Key     : Key_Type;
      Message : Byte_Array;
      C       : Positive := Default_C;
      D       : Positive := Default_D) return Tag_128
     with Global => null;

end SipHash;
