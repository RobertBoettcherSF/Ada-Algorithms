with GNAT.SHA256;
with Ada.Exceptions;

package Proof_Of_Work is

   -- Custom types for algorithm-specific data
   type Difficulty_Level is new Natural range 0 .. 64; 
   type Nonce_Type is new Natural;
   type Iteration_Count is new Positive;
   type Memory_Size is new Positive range 1 .. 100_000;

   PoW_Error : exception;

   -- =========================================================================
   -- VARIANT 1: CPU-Bound (Hashcash / Partial Hash Inversion)
   -- Used in systems like Bitcoin. Finds a nonce such that the SHA256 hash 
   -- of (Data & Nonce) has a specified number of leading zero hex characters.
   -- =========================================================================
   procedure Generate_Hashcash 
     (Data        : in String; 
      Difficulty  : in Difficulty_Level; 
      Nonce       : out Nonce_Type; 
      Hash_Result : out String);

   function Verify_Hashcash 
     (Data       : in String; 
      Difficulty : in Difficulty_Level; 
      Nonce      : in Nonce_Type) return Boolean;

   -- =========================================================================
   -- VARIANT 2: Time-Bound (Hash Chain / Sequential PoW)
   -- Proves that a certain amount of sequential time was spent by repeatedly 
   -- hashing the data. Cannot be parallelized easily.
   -- =========================================================================
   procedure Generate_Hash_Chain 
     (Seed       : in String; 
      Iterations : in Iteration_Count; 
      Final_Hash : out String);

   function Verify_Hash_Chain 
     (Seed          : in String; 
      Iterations    : in Iteration_Count; 
      Expected_Hash : in String) return Boolean;

   -- =========================================================================
   -- VARIANT 3: Memory-Bound (Simulated Client Puzzle)
   -- Requires allocating and interacting with a space of deterministic hashes. 
   -- Proves memory allocation and lookup capacity.
   -- =========================================================================
   procedure Solve_Memory_Puzzle 
     (Seed        : in String; 
      Size        : in Memory_Size; 
      Target_Char : in Character; 
      Found_Index : out Natural);

   function Verify_Memory_Puzzle 
     (Seed        : in String; 
      Target_Char : in Character; 
      Index       : in Natural) return Boolean;

private
   function Trimmed_Image (Item : Nonce_Type) return String;
   function Trimmed_Image_Nat (Item : Natural) return String;

end Proof_Of_Work;
