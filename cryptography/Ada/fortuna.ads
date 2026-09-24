pragma Ada_2022;
with Interfaces;

package Fortuna is
   -- Cryptographic types and parameters for Fortuna
   subtype Byte is Interfaces.Unsigned_8;
   type Byte_Array is array (Natural range <>) of Byte;

   subtype Key_Length is Natural range 32 .. 32;
   subtype Key_Type is Byte_Array (1 .. 32);

   subtype Block_Length is Natural range 16 .. 16;
   subtype Block_Type is Byte_Array (1 .. 16);

   type Pool_Index is range 0 .. 31;
   type Source_Index is range 0 .. 255;

   -- Fortuna strictly bounds requests to 1 MB to ensure keys are rotated frequently
   Max_Request_Size : constant := 1_048_576; 
   subtype Request_Size is Natural range 0 .. Max_Request_Size;

   -- A pool must accumulate enough entropy before it triggers a reseed
   Min_Pool_Size : constant := 64; 

   -- Events are bounded to 255 bytes per Fortuna specification
   subtype Event_Size is Natural range 0 .. 255;

   Generator_Not_Seeded : exception;

   -- Fortuna PRNG State
   type Fortuna_State is tagged private;

   -- =========================================================================
   -- 1. Generator Operations
   -- =========================================================================
   procedure Initialize (State : out Fortuna_State)
      with Post => not Is_Seeded (State);

   function Is_Seeded (State : Fortuna_State) return Boolean;

   -- Reseeds the generator by hashing the existing key and the new seed material.
   procedure Reseed (State : in out Fortuna_State; Seed : Byte_Array)
      with Pre  => Seed'Length > 0,
           Post => Is_Seeded (State);

   -- Generates random bytes and automatically performs the Fortuna forward-secrecy re-key.
   procedure Generate_Random_Data (State  : in out Fortuna_State;
                                   Length : Request_Size;
                                   Result : out Byte_Array)
      with Pre => Result'Length = Length;

   -- =========================================================================
   -- 2. Accumulator Operations
   -- =========================================================================
   -- Adds external entropy to a specific pool.
   procedure Add_Random_Event (State  : in out Fortuna_State;
                               Source : Source_Index;
                               Pool   : Pool_Index;
                               Data   : Byte_Array)
      with Pre => Data'Length in Event_Size;

   -- Evaluates pool lengths and reseed counters to determine if a reseed is required.
   -- Automatically consumes the required pools if conditions are met.
   procedure Auto_Reseed (State : in out Fortuna_State);

   -- =========================================================================
   -- 3. Seed File Management Operations
   -- =========================================================================
   -- Writes 64 bytes of random data to ensure entropy persists across system restarts.
   procedure Write_Seed_File (State     : in out Fortuna_State;
                              File_Data : out Byte_Array)
      with Pre => File_Data'Length = 64;

   -- Restores entropy from a previously saved seed file.
   procedure Read_Seed_File (State     : in out Fortuna_State;
                             File_Data : Byte_Array)
      with Pre => File_Data'Length = 64;

private
   -- Represents a hash context accumulating entropy for a pool.
   type Hash_Context is record
      State : Key_Type := [others => 0];
      Count : Natural := 0;
   end record;

   type Pool_Array is array (Pool_Index) of Hash_Context;

   type Fortuna_State is tagged record
      -- Generator state
      Key          : Key_Type := [others => 0];
      Counter      : Block_Type := [others => 0];
      Seeded       : Boolean := False;

      -- Accumulator state
      Pools        : Pool_Array := [others => (State => [others => 0], Count => 0)];
      Reseed_Count : Interfaces.Unsigned_32 := 0;
   end record;

end Fortuna;
