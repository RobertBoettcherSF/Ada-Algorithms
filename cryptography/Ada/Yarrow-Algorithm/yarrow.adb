package body Yarrow is

   -- Internal cryptographic thresholds
   Fast_Threshold : constant Natural := 100;
   Slow_Threshold : constant Natural := 160;
   Pg_Max         : constant Natural := 10; -- Gatekeeper limit per key

   -----------------------------------------------------------------------------
   -- Cryptographic Primitives (Structural Stand-ins)
   -----------------------------------------------------------------------------
   -- Yarrow requires a hashing function and a block cipher. 
   -- These are standalone, deterministic ARX (Add-Rotate-Xor) primitives that 
   -- emulate SHA-256 and AES-256 structurally to ensure compilability and 
   -- proper state manipulation without enormous dependencies.
   
   function Hash_Function (Data : Byte_Array) return Block_Type is
      Result : Block_Type := [others => 16#5A#];
      Idx    : Positive;
   begin
      -- Ingestion pass
      for I in Data'Range loop
         Idx := ((I - Data'First) mod Block_Size) + 1;
         Result (Idx) := Result (Idx) xor Data (I);
         Result (Idx) := Result (Idx) + 13;
      end loop;

      -- Mixing pass for diffusion
      for I in 1 .. 4 loop
         for J in 1 .. Block_Size loop
            if J < Block_Size then
               Result (J + 1) := Result (J + 1) + Result (J);
            else
               Result (1) := Result (1) + Result (J);
            end if;
         end loop;
      end loop;
      return Result;
   end Hash_Function;

   function Encrypt_Block (K, C : Block_Type) return Block_Type is
      Result : Block_Type := C;
   begin
      -- Minimal Substitution-Permutation simulation
      for I in 1 .. 8 loop
         for J in 1 .. Block_Size loop
            Result (J) := Result (J) xor K (J);
            if J < Block_Size then
               Result (J + 1) := Result (J + 1) + Result (J);
            else
               Result (1) := Result (1) + Result (J);
            end if;
         end loop;
      end loop;
      return Result;
   end Encrypt_Block;

   -----------------------------------------------------------------------------
   -- Helper Functions
   -----------------------------------------------------------------------------

   procedure Increment_Counter (Counter : in out Block_Type) is
      Carry : Natural := 1;
      Sum   : Natural;
   begin
      -- Big-endian increment
      for I in reverse Counter'Range loop
         Sum := Natural (Counter (I)) + Carry;
         Counter (I) := Byte (Sum mod 256);
         Carry := Sum / 256;
         exit when Carry = 0;
      end loop;
   end Increment_Counter;

   -----------------------------------------------------------------------------
   -- Yarrow Reseed Mechanisms
   -----------------------------------------------------------------------------

   procedure Fast_Reseed (Ctx : in out Context) is
   begin
      if not Ctx.Initialized then
         raise Yarrow_Error with "Context not initialized";
      end if;
      
      -- New key derived from fast pool and old key
      Ctx.Key := Hash_Function (Ctx.Fast_Pool & Ctx.Key);
      Ctx.Counter := [others => 0];
      Ctx.Fast_Entropy := [others => 0];
      
      -- Mix pool into itself to prepare for next accumulation phase
      Ctx.Fast_Pool := Hash_Function (Ctx.Fast_Pool);
      
      Ctx.Generator_Count := 0;
      Ctx.Buffer_Index := 0;
   end Fast_Reseed;

   procedure Slow_Reseed (Ctx : in out Context) is
   begin
      if not Ctx.Initialized then
         raise Yarrow_Error with "Context not initialized";
      end if;
      
      -- Highly conservative reset utilizing both pools
      Ctx.Key := Hash_Function (Ctx.Slow_Pool & Ctx.Fast_Pool & Ctx.Key);
      Ctx.Counter := [others => 0];
      
      -- Both pools lose their entropy metric since they have been consumed
      Ctx.Slow_Entropy := [others => 0];
      Ctx.Fast_Entropy := [others => 0];
      
      Ctx.Fast_Pool := Hash_Function (Ctx.Fast_Pool);
      Ctx.Slow_Pool := Hash_Function (Ctx.Slow_Pool);
      
      Ctx.Generator_Count := 0;
      Ctx.Buffer_Index := 0;
   end Slow_Reseed;

   -----------------------------------------------------------------------------
   -- Core Operational Logic
   -----------------------------------------------------------------------------

   procedure Initialize (Ctx : out Context) is
      Empty : Context;
   begin
      Ctx := Empty;
      Ctx.Initialized := True;
   end Initialize;

   procedure Input_Entropy
     (Ctx              : in out Context;
      Source           : Entropy_Source_ID;
      Data             : Byte_Array;
      Entropy_Estimate : Natural)
   is
   begin
      if not Ctx.Initialized then
         raise Yarrow_Error with "Context not initialized";
      end if;

      if Data'Length = 0 then
         raise Yarrow_Error with "Empty entropy data provided";
      end if;

      -- Alternating Entropy Accumulator Pattern
      if Ctx.Pool_Selector (Source) then
         Ctx.Fast_Pool := Hash_Function (Ctx.Fast_Pool & Data);
         Ctx.Fast_Entropy (Source) := Ctx.Fast_Entropy (Source) + Entropy_Estimate;
      else
         Ctx.Slow_Pool := Hash_Function (Ctx.Slow_Pool & Data);
         Ctx.Slow_Entropy (Source) := Ctx.Slow_Entropy (Source) + Entropy_Estimate;
      end if;

      -- Toggle distribution flag for next ingestion
      Ctx.Pool_Selector (Source) := not Ctx.Pool_Selector (Source);

      -- Check and trigger reseed variants
      if Ctx.Fast_Entropy (Source) >= Fast_Threshold then
         Fast_Reseed (Ctx);
      end if;

      if Ctx.Slow_Entropy (Source) >= Slow_Threshold then
         Slow_Reseed (Ctx);
      end if;
   end Input_Entropy;

   procedure Generate
     (Ctx    : in out Context;
      Output : out Byte_Array)
   is
      Out_Index : Natural := Output'First;
      Remaining : Natural := Output'Length;
      Take      : Natural;
   begin
      if not Ctx.Initialized then
         raise Yarrow_Error with "Context not initialized";
      end if;

      if Remaining = 0 then
         raise Yarrow_Error with "Requested output length is zero";
      end if;

      while Remaining > 0 loop
         if Ctx.Buffer_Index = 0 then
            
            -- Gatekeeper Reseed Control
            if Ctx.Generator_Count >= Pg_Max then
               Ctx.Key := Hash_Function (Ctx.Key & Ctx.Counter);
               Ctx.Counter := [others => 0];
               Ctx.Generator_Count := 0;
            end if;

            Increment_Counter (Ctx.Counter);
            Ctx.Block_Buffer := Encrypt_Block (Ctx.Key, Ctx.Counter);
            Ctx.Buffer_Index := 1;
            Ctx.Generator_Count := Ctx.Generator_Count + 1;
         end if;

         Take := Natural'Min (Remaining, Block_Size - Ctx.Buffer_Index + 1);
         Output (Out_Index .. Out_Index + Take - 1) :=
           Ctx.Block_Buffer (Ctx.Buffer_Index .. Ctx.Buffer_Index + Take - 1);

         Out_Index := Out_Index + Take;
         Remaining := Remaining - Take;
         Ctx.Buffer_Index := Ctx.Buffer_Index + Take;

         if Ctx.Buffer_Index > Block_Size then
            Ctx.Buffer_Index := 0; -- Mark buffer as entirely consumed
         end if;
      end loop;
   end Generate;

   -----------------------------------------------------------------------------
   -- Status / Inspection Functions
   -----------------------------------------------------------------------------
   function Is_Initialized (Ctx : Context) return Boolean is
   begin
      return Ctx.Initialized;
   end Is_Initialized;

   function Get_Fast_Entropy (Ctx : Context; Source : Entropy_Source_ID) return Natural is
   begin
      return Ctx.Fast_Entropy (Source);
   end Get_Fast_Entropy;

   function Get_Slow_Entropy (Ctx : Context; Source : Entropy_Source_ID) return Natural is
   begin
      return Ctx.Slow_Entropy (Source);
   end Get_Slow_Entropy;

   function Get_Block_Buffer_Index (Ctx : Context) return Natural is
   begin
      return Ctx.Buffer_Index;
   end Get_Block_Buffer_Index;
   
   function Get_Generator_Count (Ctx : Context) return Natural is
   begin
      return Ctx.Generator_Count;
   end Get_Generator_Count;

end Yarrow;
