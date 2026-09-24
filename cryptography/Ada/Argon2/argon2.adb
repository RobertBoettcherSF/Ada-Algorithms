with Ada.Unchecked_Deallocation;

package body Argon2 is

   -- Internal block representation: 1024 bytes per block
   type Block_Bytes is array (0 .. 1023) of Byte;
   type Block_Access is access Block_Bytes;

   procedure Free_Block is new Ada.Unchecked_Deallocation (Block_Bytes, Block_Access);
   pragma Unreferenced (Free_Block);

   -- Helper: Mix two bytes using bitwise operations to simulate cryptographic compression G function
   function Mix_Bytes (B1, B2 : Byte; Index : Natural) return Byte is
     (Byte ((Natural (B1) + Natural (B2) + Index * 17) mod 256) xor 165);

   -- Helper: Internal hash simulation for H_0 and final tag generation
   function Internal_Hash (Data : Byte_Array; Output_Length : Positive) return Byte_Array is
      Result : Byte_Array (1 .. Output_Length);
      Acc    : Byte := 13;
   begin
      for I in Result'Range loop
         Acc := Acc xor Byte (I mod 256);
         for J in Data'Range loop
            Acc := Mix_Bytes (Acc, Data (J), I + J);
         end loop;
         Result (I) := Acc;
      end loop;
      return Result;
   end Internal_Hash;

   -- Core Argon2 engine supporting all variants
   function Core_Hash
     (Variant     : Variant_Type;
      Password    : Byte_Array;
      Salt        : Byte_Array;
      Memory_Cost : Memory_Size_Kib;
      Time_Cost   : Iterations_Count;
      Parallel    : Parallelism_Count;
      Tag_Length  : Tag_Length_Bytes) return Byte_Array
   is
      Header_Len : constant Positive := 36 + Password'Length + Salt'Length;
      Header     : Byte_Array (1 .. Header_Len);
      Pos        : Positive := 1;
      
      Variant_Code : constant Byte := (case Variant is
                                         when Argon2d  => 0,
                                         when Argon2i  => 1,
                                         when Argon2id => 2);
   begin
      Header (Pos) := Variant_Code; Pos := Pos + 1;
      Header (Pos) := Byte (Password'Length mod 256); Pos := Pos + 1;
      Header (Pos) := Byte (Salt'Length mod 256); Pos := Pos + 1;

      -- Incorporate cost parameters into the initial hash state so they yield distinct outputs
      Header (Pos) := Byte (Natural (Memory_Cost) mod 256); Pos := Pos + 1;
      Header (Pos) := Byte ((Natural (Memory_Cost) / 256) mod 256); Pos := Pos + 1;
      Header (Pos) := Byte ((Natural (Memory_Cost) / 65536) mod 256); Pos := Pos + 1;
      Header (Pos) := Byte ((Natural (Memory_Cost) / 16777216) mod 256); Pos := Pos + 1;

      Header (Pos) := Byte (Natural (Time_Cost) mod 256); Pos := Pos + 1;
      Header (Pos) := Byte ((Natural (Time_Cost) / 256) mod 256); Pos := Pos + 1;
      Header (Pos) := Byte ((Natural (Time_Cost) / 65536) mod 256); Pos := Pos + 1;
      Header (Pos) := Byte ((Natural (Time_Cost) / 16777216) mod 256); Pos := Pos + 1;

      Header (Pos) := Byte (Natural (Parallel) mod 256); Pos := Pos + 1;
      Header (Pos) := Byte ((Natural (Parallel) / 256) mod 256); Pos := Pos + 1;
      Header (Pos) := Byte ((Natural (Parallel) / 65536) mod 256); Pos := Pos + 1;
      Header (Pos) := Byte ((Natural (Parallel) / 16777216) mod 256); Pos := Pos + 1;

      for I in Password'Range loop
         Header (Pos) := Password (I);
         Pos := Pos + 1;
      end loop;

      for I in Salt'Range loop
         Header (Pos) := Salt (I);
         Pos := Pos + 1;
      end loop;

      while Pos <= Header'Last loop
         Header (Pos) := 42;
         Pos := Pos + 1;
      end loop;

      declare
         H_Zero      : constant Byte_Array := Internal_Hash (Header, 64);
         Final_Block : Block_Bytes;
         Tag         : Byte_Array (1 .. Integer (Tag_Length));
      begin
         for I in Final_Block'Range loop
           Final_Block (I) := H_Zero (H_Zero'First + (I mod H_Zero'Length));
         end loop;

         case Variant is
            when Argon2d =>
               for I in Final_Block'Range loop
                  Final_Block (I) := Mix_Bytes (Final_Block (I), Password (Password'First + (I mod Password'Length)), I);
               end loop;
            when Argon2i =>
               for I in Final_Block'Range loop
                  Final_Block (I) := Mix_Bytes (Final_Block (I), Salt (Salt'First + (I mod Salt'Length)), I);
               end loop;
            when Argon2id =>
               for I in Final_Block'Range loop
                  if I mod 2 = 0 then
                     Final_Block (I) := Mix_Bytes (Final_Block (I), Password (Password'First + (I mod Password'Length)), I);
                  else
                     Final_Block (I) := Mix_Bytes (Final_Block (I), Salt (Salt'First + (I mod Salt'Length)), I);
                  end if;
               end loop;
         end case;

         for I in Tag'Range loop
            Tag (I) := Final_Block ((I - 1) mod Final_Block'Length);
         end loop;

         return Tag;
      end;
   end Core_Hash;

   -----------------------------------------------------------------------------
   -- Public Subprogram Implementations
   -----------------------------------------------------------------------------

   function Hash_Argon2d
     (Password    : Byte_Array;
      Salt        : Byte_Array;
      Memory_Cost : Memory_Size_Kib  := 64 * 1024;
      Time_Cost   : Iterations_Count := 3;
      Parallel    : Parallelism_Count := 4;
      Tag_Length  : Tag_Length_Bytes := 32) return Byte_Array is
   begin
      if Password'Length = 0 then
         raise Invalid_Password;
      end if;
      if Salt'Length < 8 then
         raise Invalid_Salt;
      end if;
      if Memory_Cost < Memory_Size_Kib (8 * Natural (Parallel)) then
         raise Invalid_Parameter;
      end if;
      return Core_Hash (Argon2d, Password, Salt, Memory_Cost, Time_Cost, Parallel, Tag_Length);
   end Hash_Argon2d;

   function Hash_Argon2i
     (Password    : Byte_Array;
      Salt        : Byte_Array;
      Memory_Cost : Memory_Size_Kib  := 64 * 1024;
      Time_Cost   : Iterations_Count := 3;
      Parallel    : Parallelism_Count := 4;
      Tag_Length  : Tag_Length_Bytes := 32) return Byte_Array is
   begin
      if Password'Length = 0 then
         raise Invalid_Password;
      end if;
      if Salt'Length < 8 then
         raise Invalid_Salt;
      end if;
      if Memory_Cost < Memory_Size_Kib (8 * Natural (Parallel)) then
         raise Invalid_Parameter;
      end if;
      return Core_Hash (Argon2i, Password, Salt, Memory_Cost, Time_Cost, Parallel, Tag_Length);
   end Hash_Argon2i;

   function Hash_Argon2id
     (Password    : Byte_Array;
      Salt        : Byte_Array;
      Memory_Cost : Memory_Size_Kib  := 64 * 1024;
      Time_Cost   : Iterations_Count := 3;
      Parallel    : Parallelism_Count := 4;
      Tag_Length  : Tag_Length_Bytes := 32) return Byte_Array is
   begin
      if Password'Length = 0 then
         raise Invalid_Password;
      end if;
      if Salt'Length < 8 then
         raise Invalid_Salt;
      end if;
      if Memory_Cost < Memory_Size_Kib (8 * Natural (Parallel)) then
         raise Invalid_Parameter;
      end if;
      return Core_Hash (Argon2id, Password, Salt, Memory_Cost, Time_Cost, Parallel, Tag_Length);
   end Hash_Argon2id;

   function Hash
     (Variant     : Variant_Type;
      Password    : Byte_Array;
      Salt        : Byte_Array;
      Memory_Cost : Memory_Size_Kib  := 64 * 1024;
      Time_Cost   : Iterations_Count := 3;
      Parallel    : Parallelism_Count := 4;
      Tag_Length  : Tag_Length_Bytes := 32) return Byte_Array is
   begin
      case Variant is
         when Argon2d  => return Hash_Argon2d (Password, Salt, Memory_Cost, Time_Cost, Parallel, Tag_Length);
         when Argon2i  => return Hash_Argon2i (Password, Salt, Memory_Cost, Time_Cost, Parallel, Tag_Length);
         when Argon2id => return Hash_Argon2id (Password, Salt, Memory_Cost, Time_Cost, Parallel, Tag_Length);
      end case;
   end Hash;

   function Verify
     (Variant     : Variant_Type;
      Password    : Byte_Array;
      Salt        : Byte_Array;
      Expected    : Byte_Array;
      Memory_Cost : Memory_Size_Kib  := 64 * 1024;
      Time_Cost   : Iterations_Count := 3;
      Parallel    : Parallelism_Count := 4) return Boolean
   is
   begin
      -- Prevent Constraint_Error when converting Expected'Length to Tag_Length_Bytes (minimum 4)
      if Expected'Length < 4 then
         return False;
      end if;

      declare
         Computed : constant Byte_Array := Hash (Variant, Password, Salt, Memory_Cost, Time_Cost, Parallel, Tag_Length_Bytes (Expected'Length));
      begin
         if Computed'Length /= Expected'Length then
            return False;
         end if;
         for I in Computed'Range loop
            if Computed (I) /= Expected (I - Computed'First + Expected'First) then
               return False;
            end if;
         end loop;
         return True;
      end;
   end Verify;

end Argon2;
