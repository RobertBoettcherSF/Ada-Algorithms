with Interfaces;

package Poly1305 with Preelaborate is
   
   --  Basic cryptographic types for bytes and variable-length byte arrays.
   type Byte is new Interfaces.Unsigned_8;
   type Byte_Array is array (Natural range <>) of Byte;
   
   --  Poly1305 uses a strict 32-byte key (256 bits).
   subtype Key_Type is Byte_Array (0 .. 31);
   
   --  Poly1305 always produces a 16-byte MAC (128 bits).
   subtype MAC_Type is Byte_Array (0 .. 15);
   
   --  Opaque context state for incremental evaluation.
   type Context is private;
   
   --  Exception raised when context state is used incorrectly.
   State_Error : exception;
   
   --  ========================================================================
   --  Static Variant (Single-Shot)
   --  ========================================================================
   
   --  Generate a Poly1305 MAC over a full message in a single operation.
   function Generate_MAC (Message : Byte_Array; Key : Key_Type) return MAC_Type
     with Global => null;
     
   --  ========================================================================
   --  Dynamic Variant (Incremental/Streaming)
   --  ========================================================================
   
   --  Initialize the context with the given key.
   procedure Init (Ctx : out Context; Key : Key_Type)
     with Global => null,
          Post => Is_Initialized (Ctx);
          
   --  Add data to the context buffer.
   procedure Update (Ctx : in out Context; Message : Byte_Array)
     with Global => null;
          
   --  Finalize the computation and return the MAC. This clears the context.
   procedure Final (Ctx : in out Context; MAC : out MAC_Type)
     with Global => null,
          Post => not Is_Initialized (Ctx);
          
   --  Determine if the context is currently active/initialized.
   function Is_Initialized (Ctx : Context) return Boolean
     with Global => null;
     
private

   --  The Poly1305 context maintains internal accumulators and key data.
   --  Uses base-2^26 representation (h0..h4) to fit comfortably within 64-bit 
   --  unsigned integers during multiplications, preventing overflow without 
   --  requireing 128-bit types.
   type Context is record
      Initialized : Boolean := False;
      
      --  Accumulator (base 2^26)
      h0, h1, h2, h3, h4 : Interfaces.Unsigned_64 := 0;
      
      --  Clamped key parts 'r' (base 2^26)
      r0, r1, r2, r3, r4 : Interfaces.Unsigned_64 := 0;
      
      --  Precomputed scaled key parts 's' = r * 5
      s1, s2, s3, s4     : Interfaces.Unsigned_64 := 0;
      
      --  The second half of the 32-byte key ('s' in the spec), used during finalization
      S_Key              : Byte_Array (0 .. 15) := [others => 0];
      
      --  Buffer for leftover bytes not yet forming a complete 16-byte block
      Buffer             : Byte_Array (0 .. 15) := [others => 0];
      Leftover           : Natural := 0;
   end record;

end Poly1305;
