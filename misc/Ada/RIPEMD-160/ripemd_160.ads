package Ripemd_160 is
   pragma Preelaborate;

   type Byte is mod 256;
   type Byte_Array is array (Natural range <>) of Byte;

   type Digest_Type is array (0 .. 19) of Byte;

   -- Raised when attempting to Update or Finalize an uninitialized context
   State_Error : exception;

   -- Convert a standard Ada String to a Byte_Array
   function To_Bytes (Message : String) return Byte_Array;

   -- Variant 1: Single-shot hashing (Static/Non-preemptive concept)
   -- Hashes a Byte_Array directly and returns the 160-bit digest.
   function Hash (Message : Byte_Array) return Digest_Type;

   -- Variant 2: Single-shot hashing of a String
   function Hash (Message : String) return Digest_Type;

   -- Variant 3: Incremental API (Dynamic/Chunked processing concept)
   -- Used for streaming large data or chunked processing.
   type Context is private;

   -- Initializes or resets the hashing context
   procedure Init (Ctx : out Context)
     with Post => Is_Initialized (Ctx);

   -- Updates the hashing state with a Byte_Array chunk
   --  An uninitialized context raises State_Error (no Pre: the exception
   --  is the contract).
   procedure Update (Ctx : in out Context; Data : Byte_Array);

   -- Updates the hashing state with a String chunk
   procedure Update (Ctx : in out Context; Data : String);

   -- Finalizes the hash, outputs the digest, and deactivates the context
   procedure Finalize (Ctx : in out Context; Digest : out Digest_Type)
     with Post => not Is_Initialized (Ctx);

   -- Validation helper for contracts
   function Is_Initialized (Ctx : Context) return Boolean;

private
   type Word is mod 2**32;
   type State_Array is array (0 .. 4) of Word;
   type Block_Type is array (0 .. 15) of Word;
   type Block_Buffer is array (0 .. 63) of Byte;
   type Byte_Count is mod 2**64;

   type Context is record
      State       : State_Array;
      Buffer      : Block_Buffer;
      Buffer_Len  : Natural range 0 .. 64;
      Total_Bytes : Byte_Count;
      Initialized : Boolean := False;
   end record;

   function Is_Initialized (Ctx : Context) return Boolean is (Ctx.Initialized);

end Ripemd_160;
