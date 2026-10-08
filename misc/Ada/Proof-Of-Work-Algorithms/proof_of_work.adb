with Ada.Strings.Fixed;
with Ada.Strings;

package body Proof_Of_Work is

   -- Helper: Remove leading spaces from integer image
   function Trimmed_Image (Item : Nonce_Type) return String is
      Img : constant String := Nonce_Type'Image (Item);
   begin
      return Ada.Strings.Fixed.Trim (Img, Ada.Strings.Left);
   end Trimmed_Image;

   function Trimmed_Image_Nat (Item : Natural) return String is
      Img : constant String := Natural'Image (Item);
   begin
      return Ada.Strings.Fixed.Trim (Img, Ada.Strings.Left);
   end Trimmed_Image_Nat;

   -- Helper: Verify leading zeros
   function Has_Leading_Zeros (Hash : String; Zeros : Difficulty_Level) return Boolean is
   begin
      for I in 1 .. Natural (Zeros) loop
         if Hash (Hash'First + I - 1) /= '0' then
            return False;
         end if;
      end loop;
      return True;
   end Has_Leading_Zeros;

   -- =========================================================================
   -- VARIANT 1: CPU-Bound (Hashcash)
   -- =========================================================================
   procedure Generate_Hashcash 
     (Data        : in String; 
      Difficulty  : in Difficulty_Level; 
      Nonce       : out Nonce_Type; 
      Hash_Result : out String) 
   is
      Current_Nonce : Nonce_Type := 0;
      Digest        : String (1 .. 64);
   begin
      if Difficulty = 0 then
         Nonce := 0;
         Hash_Result := GNAT.SHA256.Digest (Data & Trimmed_Image (0));
         return;
      end if;

      loop
         Digest := GNAT.SHA256.Digest (Data & Trimmed_Image (Current_Nonce));
         
         if Has_Leading_Zeros (Digest, Difficulty) then
            Nonce := Current_Nonce;
            Hash_Result := Digest;
            return;
         end if;
         
         if Current_Nonce = Nonce_Type'Last then
            raise PoW_Error with "Nonce overflow: Could not find valid hash.";
         end if;
         
         Current_Nonce := Current_Nonce + 1;
      end loop;
   end Generate_Hashcash;

   function Verify_Hashcash 
     (Data       : in String; 
      Difficulty : in Difficulty_Level; 
      Nonce      : in Nonce_Type) return Boolean 
   is
      Digest : constant String := GNAT.SHA256.Digest (Data & Trimmed_Image (Nonce));
   begin
      return Has_Leading_Zeros (Digest, Difficulty);
   end Verify_Hashcash;

   -- =========================================================================
   -- VARIANT 2: Time-Bound (Hash Chain)
   -- =========================================================================
   procedure Generate_Hash_Chain 
     (Seed       : in String; 
      Iterations : in Iteration_Count; 
      Final_Hash : out String) 
   is
      Current_Hash : String (1 .. 64) := GNAT.SHA256.Digest (Seed);
   begin
      for I in 2 .. Natural (Iterations) loop
         Current_Hash := GNAT.SHA256.Digest (Current_Hash);
      end loop;
      Final_Hash := Current_Hash;
   end Generate_Hash_Chain;

   function Verify_Hash_Chain 
     (Seed          : in String; 
      Iterations    : in Iteration_Count; 
      Expected_Hash : in String) return Boolean 
   is
      Calculated_Hash : String (1 .. 64);
   begin
      Generate_Hash_Chain (Seed, Iterations, Calculated_Hash);
      return Calculated_Hash = Expected_Hash;
   end Verify_Hash_Chain;

   -- =========================================================================
   -- VARIANT 3: Memory-Bound (Simulated Client Puzzle)
   -- =========================================================================
   procedure Solve_Memory_Puzzle 
     (Seed        : in String; 
      Size        : in Memory_Size; 
      Target_Char : in Character; 
      Found_Index : out Natural) 
   is
      -- Simulating a memory pool mapping where you must find a hash 
      -- ending in the Target_Char within a bounded memory space.
   begin
      for I in 1 .. Natural (Size) loop
         declare
            Current_Hash : constant String := GNAT.SHA256.Digest (Seed & Trimmed_Image_Nat (I));
         begin
            if Current_Hash (Current_Hash'Last) = Target_Char then
               Found_Index := I;
               return;
            end if;
         end;
      end loop;
      
      raise PoW_Error with "Target character not found in given memory bound space.";
   end Solve_Memory_Puzzle;

   function Verify_Memory_Puzzle 
     (Seed        : in String; 
      Target_Char : in Character; 
      Index       : in Natural) return Boolean 
   is
      Hash : constant String := GNAT.SHA256.Digest (Seed & Trimmed_Image_Nat (Index));
   begin
      return Hash (Hash'Last) = Target_Char;
   end Verify_Memory_Puzzle;

end Proof_Of_Work;
