pragma Ada_2022;

package Yarrow is
   -- Strong typing for data elements
   type Byte is mod 2**8;
   type Byte_Array is array (Natural range <>) of Byte;

   -- Entropy sources identified by an ID (e.g., keyboard, mouse, disk timing)
   type Entropy_Source_ID is new Natural range 0 .. 15;

   -- Exception for operational boundary violations
   Yarrow_Error : exception;

   -- 256-bit block size (32 bytes) typical of Yarrow-256 (AES-256 / SHA-256)
   Block_Size : constant Natural := 32;

   -- Opaque context storing the complete PRNG state
   type Context is private;

   -- Initializes the Yarrow context
   procedure Initialize (Ctx : out Context)
     with Post => Is_Initialized (Ctx);

   -- Injects entropy from a given source. The algorithm alternately directs this 
   -- to the fast pool and slow pool to accumulate entropy over time.
   procedure Input_Entropy
     (Ctx              : in out Context;
      Source           : Entropy_Source_ID;
      Data             : Byte_Array;
      Entropy_Estimate : Natural)
     with Pre => Is_Initialized (Ctx);

   -- Generates pseudorandom output based on the current key and counter. 
   -- Will invoke the Gatekeeper to mutate the key if generation limit is reached.
   procedure Generate
     (Ctx    : in out Context;
      Output : out Byte_Array)
     with Pre => Is_Initialized (Ctx);

   -- VARIANT: Manually force a fast reseed (typically internal, exposed for variants)
   -- Uses the fast pool to generate a new key and resets the counter.
   procedure Fast_Reseed (Ctx : in out Context)
     with Pre => Is_Initialized (Ctx);

   -- VARIANT: Manually force a slow reseed.
   -- Uses both fast and slow pools to provide a highly conservative key reset.
   procedure Slow_Reseed (Ctx : in out Context)
     with Pre => Is_Initialized (Ctx);

   -- Status / Inspection functions (Useful for invariant checking and tests)
   function Is_Initialized (Ctx : Context) return Boolean;
   function Get_Fast_Entropy (Ctx : Context; Source : Entropy_Source_ID) return Natural;
   function Get_Slow_Entropy (Ctx : Context; Source : Entropy_Source_ID) return Natural;
   function Get_Block_Buffer_Index (Ctx : Context) return Natural;
   function Get_Generator_Count (Ctx : Context) return Natural;

private
   subtype Block_Type is Byte_Array (1 .. Block_Size);

   type Entropy_Count_Array is array (Entropy_Source_ID) of Natural;
   type Flip_Flop_Array is array (Entropy_Source_ID) of Boolean;

   type Context is record
      Initialized      : Boolean := False;
      
      -- Generation Mechanism State
      Key              : Block_Type := [others => 0];
      Counter          : Block_Type := [others => 0];

      -- Entropy Accumulator Pools
      Fast_Pool        : Block_Type := [others => 16#AA#];
      Slow_Pool        : Block_Type := [others => 16#55#];

      -- Entropy Estimates Tracking
      Fast_Entropy     : Entropy_Count_Array := [others => 0];
      Slow_Entropy     : Entropy_Count_Array := [others => 0];
      
      -- Alternator state for entropy distribution
      Pool_Selector    : Flip_Flop_Array := [others => True];

      -- Reseed Control / Gatekeeper
      Generator_Count  : Natural := 0;

      -- Output Buffering
      Block_Buffer     : Block_Type := [others => 0];
      Buffer_Index     : Natural := 0; -- 0 indicates buffer is currently empty
   end record;

end Yarrow;
