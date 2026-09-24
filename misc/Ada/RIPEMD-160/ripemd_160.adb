package body Ripemd_160 is

   subtype Step_Index is Natural range 0 .. 79;
   subtype Word_Index is Natural range 0 .. 15;
   subtype Shift_Amount is Natural range 5 .. 15;

   -- RIPEMD-160 Constants for the Left line (KL)
   KL : constant array (Step_Index) of Word :=
     [ 0 .. 15 => 16#00000000#,
      16 .. 31 => 16#5A827999#,
      32 .. 47 => 16#6ED9EBA1#,
      48 .. 63 => 16#8F1BBCDC#,
      64 .. 79 => 16#A953FD4E#];

   -- RIPEMD-160 Constants for the Right line (KR)
   KR : constant array (Step_Index) of Word :=
     [ 0 .. 15 => 16#50A28BE6#,
      16 .. 31 => 16#5C4DD124#,
      32 .. 47 => 16#6D703EF3#,
      48 .. 63 => 16#7A6D76E9#,
      64 .. 79 => 16#00000000#];

   -- Message Word Permutations for Left line (RL)
   RL : constant array (Step_Index) of Word_Index :=
     [ 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15,
       7,  4, 13,  1, 10,  6, 15,  3, 12,  0,  9,  5,  2, 14, 11,  8,
       3, 10, 14,  4,  9, 15,  8,  1,  2,  7,  0,  6, 13, 11,  5, 12,
       1,  9, 11, 10,  0,  8, 12,  4, 13,  3,  7, 15, 14,  5,  6,  2,
       4,  0,  5,  9,  7, 12,  2, 10, 14,  1,  3,  8, 11,  6, 15, 13];

   -- Message Word Permutations for Right line (RR)
   RR : constant array (Step_Index) of Word_Index :=
     [ 5, 14,  7,  0,  9,  2, 11,  4, 13,  6, 15,  8,  1, 10,  3, 12,
       6, 11,  3,  7,  0, 13,  5, 10, 14, 15,  8, 12,  4,  9,  1,  2,
      15,  5,  1,  3,  7, 14,  6,  9, 11,  8, 12,  2, 10,  0,  4, 13,
       8,  6,  4,  1,  3, 11, 15,  0,  5, 12,  2, 13,  9,  7, 10, 14,
      12, 15, 10,  4,  1,  5,  8,  7,  6,  2, 13, 14,  0,  3,  9, 11];

   -- Rotate Amounts for Left line (SL)
   SL : constant array (Step_Index) of Shift_Amount :=
     [11, 14, 15, 12,  5,  8,  7,  9, 11, 13, 14, 15,  6,  7,  9,  8,
       7,  6,  8, 13, 11,  9,  7, 15,  7, 12, 15,  9, 11,  7, 13, 12,
      11, 13,  6,  7, 14,  9, 13, 15, 14,  8, 13,  6,  5, 12,  7,  5,
      11, 12, 14, 15, 14, 15,  9,  8,  9, 14,  5,  6,  8,  6,  5, 12,
       9, 15,  5, 11,  6,  8, 13, 12,  5, 12, 13, 14, 11,  8,  5,  6];

   -- Rotate Amounts for Right line (SR)
   SR : constant array (Step_Index) of Shift_Amount :=
     [ 8,  9,  9, 11, 13, 15, 15,  5,  7,  7,  8, 11, 14, 14, 12,  6,
       9, 13, 15,  7, 12,  8,  9, 11,  7,  7, 12,  7,  6, 15, 13, 11,
       9,  7, 15, 11,  8,  6,  6, 14, 12, 13,  5, 14, 13, 13,  7,  5,
      15,  5,  8, 11, 14, 14,  6, 14,  6,  9, 12,  9, 12,  5, 15,  8,
       8,  5, 12,  9, 12,  5, 14,  6,  8, 13,  6,  5, 15, 13, 11, 11];

   -- Non-linear boolean function for the Left line
   function FL (J : Step_Index; X, Y, Z : Word) return Word is
   begin
      case J is
         when  0 .. 15 => return X xor Y xor Z;
         when 16 .. 31 => return (X and Y) or ((not X) and Z);
         when 32 .. 47 => return (X or (not Y)) xor Z;
         when 48 .. 63 => return (X and Z) or (Y and (not Z));
         when 64 .. 79 => return X xor (Y or (not Z));
      end case;
   end FL;

   -- Non-linear boolean function for the Right line (Applies functions in reverse order)
   function FR (J : Step_Index; X, Y, Z : Word) return Word is
   begin
      case J is
         when  0 .. 15 => return X xor (Y or (not Z));
         when 16 .. 31 => return (X and Z) or (Y and (not Z));
         when 32 .. 47 => return (X or (not Y)) xor Z;
         when 48 .. 63 => return (X and Y) or ((not X) and Z);
         when 64 .. 79 => return X xor Y xor Z;
      end case;
   end FR;

   -- Circular left shift (Rotate Left) on 32-bit Word
   function Rol (Value : Word; Amount : Natural) return Word is
   begin
      return (Value * (2 ** Amount)) or (Value / (2 ** (32 - Amount)));
   end Rol;

   -- Convert a properly formatted 64-byte array into 16 little-endian 32-bit Words
   function Bytes_To_Block (Data : Block_Buffer) return Block_Type is
      B : Block_Type;
      Offset : Natural;
   begin
      for I in 0 .. 15 loop
         Offset := I * 4;
         B (I) := Word (Data (Offset))
               or (Word (Data (Offset + 1)) * 2**8)
               or (Word (Data (Offset + 2)) * 2**16)
               or (Word (Data (Offset + 3)) * 2**24);
      end loop;
      return B;
   end Bytes_To_Block;

   -- Core processing function: compresses a 512-bit block into the context state
   procedure Process_Block (State : in out State_Array; X : in Block_Type) is
      AL, BL, CL, DL, EL : Word;
      AR, BR, CR, DR, ER : Word;
      T : Word;
   begin
      AL := State(0); BL := State(1); CL := State(2); DL := State(3); EL := State(4);
      AR := State(0); BR := State(1); CR := State(2); DR := State(3); ER := State(4);

      for J in Step_Index loop
         -- Left line processing
         T := AL + FL (J, BL, CL, DL) + X (RL (J)) + KL (J);
         T := Rol (T, SL (J)) + EL;
         AL := EL; EL := DL; DL := Rol (CL, 10); CL := BL; BL := T;

         -- Right line processing
         T := AR + FR (J, BR, CR, DR) + X (RR (J)) + KR (J);
         T := Rol (T, SR (J)) + ER;
         AR := ER; ER := DR; DR := Rol (CR, 10); CR := BR; BR := T;
      end loop;

      -- Combine results back into the hash state
      T := State (1) + CL + DR;
      State (1) := State (2) + DL + ER;
      State (2) := State (3) + EL + AR;
      State (3) := State (4) + AL + BR;
      State (4) := State (0) + BL + CR;
      State (0) := T;
   end Process_Block;

   function To_Bytes (Message : String) return Byte_Array is
      Result : Byte_Array (0 .. Message'Length - 1);
   begin
      for I in Message'Range loop
         Result (Natural (I - Message'First)) := Byte (Character'Pos (Message (I)));
      end loop;
      return Result;
   end To_Bytes;

   function Hash (Message : Byte_Array) return Digest_Type is
      Ctx : Context;
      D   : Digest_Type;
   begin
      Init (Ctx);
      Update (Ctx, Message);
      Finalize (Ctx, D);
      return D;
   end Hash;

   function Hash (Message : String) return Digest_Type is
   begin
      return Hash (To_Bytes (Message));
   end Hash;

   procedure Init (Ctx : out Context) is
   begin
      -- Standard RIPEMD-160 initialization constants
      Ctx.State := [16#67452301#, 16#EFCDAB89#, 16#98BADCFE#,
                    16#10325476#, 16#C3D2E1F0#];
      Ctx.Buffer := [others => 0];
      Ctx.Buffer_Len := 0;
      Ctx.Total_Bytes := 0;
      Ctx.Initialized := True;
   end Init;

   procedure Update (Ctx : in out Context; Data : Byte_Array) is
      Idx    : Natural := Data'First;
      Len    : Natural := Data'Length;
      Copied : Natural;
   begin
      if not Ctx.Initialized then
         raise State_Error with "Context not initialized before Update";
      end if;

      Ctx.Total_Bytes := Ctx.Total_Bytes + Byte_Count (Len);

      while Len > 0 loop
         Copied := Natural'Min (Len, 64 - Ctx.Buffer_Len);
         for I in 0 .. Copied - 1 loop
            Ctx.Buffer (Ctx.Buffer_Len + I) := Data (Idx + I);
         end loop;
         Ctx.Buffer_Len := Ctx.Buffer_Len + Copied;
         Idx := Idx + Copied;
         Len := Len - Copied;

         -- When buffer hits exactly 512 bits (64 bytes), compress it
         if Ctx.Buffer_Len = 64 then
            Process_Block (Ctx.State, Bytes_To_Block (Ctx.Buffer));
            Ctx.Buffer_Len := 0;
         end if;
      end loop;
   end Update;

   procedure Update (Ctx : in out Context; Data : String) is
   begin
      if not Ctx.Initialized then
         raise State_Error with "Context not initialized before Update";
      end if;
      Update (Ctx, To_Bytes (Data));
   end Update;

   procedure Finalize (Ctx : in out Context; Digest : out Digest_Type) is
      Total_Bits      : constant Byte_Count := Ctx.Total_Bytes * 8;
      Total_Bits_Copy : Byte_Count := Total_Bits;
   begin
      if not Ctx.Initialized then
         raise State_Error with "Context not initialized before Finalize";
      end if;

      -- 1. Append the mandatory '1' bit (0x80 byte)
      Ctx.Buffer (Ctx.Buffer_Len) := 16#80#;
      Ctx.Buffer_Len := Ctx.Buffer_Len + 1;

      -- 2. If not enough room for the 8-byte length, pad and compress this block
      if Ctx.Buffer_Len > 56 then
         while Ctx.Buffer_Len < 64 loop
            Ctx.Buffer (Ctx.Buffer_Len) := 0;
            Ctx.Buffer_Len := Ctx.Buffer_Len + 1;
         end loop;
         Process_Block (Ctx.State, Bytes_To_Block (Ctx.Buffer));
         Ctx.Buffer_Len := 0;
      end if;

      -- 3. Pad remaining space up to index 56 with zeros
      while Ctx.Buffer_Len < 56 loop
         Ctx.Buffer (Ctx.Buffer_Len) := 0;
         Ctx.Buffer_Len := Ctx.Buffer_Len + 1;
      end loop;

      -- 4. Append the 64-bit length in little-endian order at the end of the block
      for I in 0 .. 7 loop
         Ctx.Buffer (56 + I) := Byte (Total_Bits_Copy and Byte_Count (16#FF#));
         Total_Bits_Copy := Total_Bits_Copy / 256;
      end loop;

      Process_Block (Ctx.State, Bytes_To_Block (Ctx.Buffer));

      -- 5. Output the 160-bit digest as little-endian bytes
      for I in 0 .. 4 loop
         Digest (I * 4)     := Byte (Ctx.State (I) and 16#FF#);
         Digest (I * 4 + 1) := Byte ((Ctx.State (I) / 2**8) and 16#FF#);
         Digest (I * 4 + 2) := Byte ((Ctx.State (I) / 2**16) and 16#FF#);
         Digest (I * 4 + 3) := Byte ((Ctx.State (I) / 2**24) and 16#FF#);
      end loop;

      Ctx.Initialized := False;
   end Finalize;

end Ripemd_160;
