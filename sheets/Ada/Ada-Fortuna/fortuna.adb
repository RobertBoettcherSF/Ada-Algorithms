pragma Ada_2022;

package body Fortuna is
   use Interfaces;
   use type Interfaces.Unsigned_32;

   -- =========================================================================
   -- Internal Cryptographic Primitives
   -- =========================================================================

   procedure Update_Hash (Ctx : in out Hash_Context; Data : Byte_Array) is
      Idx : Positive;
      Val : Byte;
   begin
      -- Mixes data into the 256-bit hash state
      for B of Data loop
         Idx := 1 + (Ctx.Count mod 32);
         Val := Ctx.State (Idx);
         Ctx.State (Idx) := (Shift_Left (Val, 1) or Shift_Right (Val, 7)) xor B;
         Ctx.Count := Ctx.Count + 1;
      end loop;
   end Update_Hash;

   function Finalize_Hash (Ctx : Hash_Context) return Key_Type is
   begin
      return Ctx.State;
   end Finalize_Hash;

   procedure Encrypt_Block (Key : Key_Type; Counter : Block_Type; Result : out Block_Type) is
   begin
      -- Simulates block encryption (CTR mode component)
      for I in Block_Type'Range loop
         Result (I) := Counter (I) xor Key (I) xor Key (I + 16);
         Result (I) := Result (I) + Byte ((I * 17) mod 256);
      end loop;
   end Encrypt_Block;

   procedure Increment_Counter (Counter : in out Block_Type) is
   begin
      -- 128-bit big-endian counter increment
      for I in reverse Counter'Range loop
         if Counter (I) = Byte'Last then
            Counter (I) := 0;
         else
            Counter (I) := Counter (I) + 1;
            exit; -- Carry resolved
         end if;
      end loop;
   end Increment_Counter;

   -- =========================================================================
   -- API Implementation
   -- =========================================================================

   procedure Initialize (State : out Fortuna_State) is
   begin
      State := (Key          => [others => 0],
                Counter      => [others => 0],
                Seeded       => False,
                Pools        => [others => (State => [others => 0], Count => 0)],
                Reseed_Count => 0);
   end Initialize;

   function Is_Seeded (State : Fortuna_State) return Boolean is
   begin
      return State.Seeded;
   end Is_Seeded;

   procedure Reseed (State : in out Fortuna_State; Seed : Byte_Array) is
      Ctx : Hash_Context := (State => [others => 0], Count => 0);
   begin
      -- Fortuna reseed: Hash(Key || Seed)
      Update_Hash (Ctx, State.Key);
      Update_Hash (Ctx, Seed);
      State.Key := Finalize_Hash (Ctx);
      
      Increment_Counter (State.Counter);
      State.Seeded := True;
   end Reseed;

   procedure Generate_Random_Data (State  : in out Fortuna_State;
                                   Length : Request_Size;
                                   Result : out Byte_Array) is
      Block         : Block_Type;
      Idx           : Natural := Result'First;
      Blocks_Needed : Natural;
      New_Key       : Key_Type := [others => 0];
      Key_Idx       : Natural;
   begin
      if not State.Seeded then
         raise Generator_Not_Seeded with "Fortuna generator is not seeded";
      end if;
      
      if Length = 0 then
         return;
      end if;

      Blocks_Needed := (Length + 15) / 16;

      -- Fulfill the pseudo-random data request
      for Ignore in 1 .. Blocks_Needed loop
         pragma Unreferenced (Ignore);
         Encrypt_Block (State.Key, State.Counter, Block);
         Increment_Counter (State.Counter);
         for J in Block'Range loop
            if Idx <= Result'Last then
               Result (Idx) := Block (J);
               Idx := Idx + 1;
            end if;
         end loop;
      end loop;

      -- Forward Secrecy: Rekey the generator immediately
      Key_Idx := New_Key'First;
      for Ignore in 1 .. 2 loop
         pragma Unreferenced (Ignore);
         Encrypt_Block (State.Key, State.Counter, Block);
         Increment_Counter (State.Counter);
         for J in Block'Range loop
            New_Key (Key_Idx) := Block (J);
            Key_Idx := Key_Idx + 1;
         end loop;
      end loop;
      
      State.Key := New_Key;
   end Generate_Random_Data;

   procedure Add_Random_Event (State  : in out Fortuna_State;
                               Source : Source_Index;
                               Pool   : Pool_Index;
                               Data   : Byte_Array) is
      Header : Byte_Array (1 .. 2);
   begin
      -- Append Source ID and Length, then Data
      Header (1) := Byte (Source);
      Header (2) := Byte (Data'Length);
      
      Update_Hash (State.Pools (Pool), Header);
      Update_Hash (State.Pools (Pool), Data);
   end Add_Random_Event;

   procedure Auto_Reseed (State : in out Fortuna_State) is
      Seed_Material : Byte_Array (1 .. 32 * 32) := [others => 0]; 
      Seed_Len      : Natural := 0;
      Pool_Hash     : Key_Type;
      Mask          : Unsigned_32;
   begin
      if State.Pools (0).Count >= Min_Pool_Size then
         State.Reseed_Count := State.Reseed_Count + 1;

         -- Iteratively collect hashes from eligible pools
         for I in Pool_Index'Range loop
            Mask := Shift_Left (1, Natural (I)) - 1;
            if (State.Reseed_Count and Mask) = 0 then
               Pool_Hash := Finalize_Hash (State.Pools (I));
               Seed_Material (Seed_Len + 1 .. Seed_Len + 32) := Pool_Hash;
               Seed_Len := Seed_Len + 32;
               
               -- Reset consumed pool
               State.Pools (I) := (State => [others => 0], Count => 0);
            end if;
         end loop;

         Reseed (State, Seed_Material (1 .. Seed_Len));
      end if;
   end Auto_Reseed;

   procedure Write_Seed_File (State     : in out Fortuna_State;
                              File_Data : out Byte_Array) is
   begin
      Generate_Random_Data (State, 64, File_Data);
   end Write_Seed_File;

   procedure Read_Seed_File (State     : in out Fortuna_State;
                             File_Data : Byte_Array) is
   begin
      Reseed (State, File_Data);
   end Read_Seed_File;

end Fortuna;
