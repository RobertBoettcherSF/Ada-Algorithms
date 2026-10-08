package body AES is

   -----------------------------------------------------------------------------
   -- Finite Field (GF) Mathematics & Constant Initialization
   -----------------------------------------------------------------------------

   -- Multiplies two numbers in the Galois Field GF(2^8)
   function GF_Mult (A, B : Byte) return Byte is
      P  : Byte := 0;
      AA : Byte := A;
      BB : Byte := B;
   begin
      for I in 1 .. 8 loop
         if (BB and 1) /= 0 then
            P := P xor AA;
         end if;
         declare
            High_Bit_Set : constant Boolean := (AA and 16#80#) /= 0;
         begin
            AA := Byte (Interfaces.Shift_Left (Interfaces.Unsigned_8 (AA), 1));
            if High_Bit_Set then
               AA := AA xor 16#1B#;
            end if;
         end;
         BB := Byte (Interfaces.Shift_Right (Interfaces.Unsigned_8 (BB), 1));
      end loop;
      return P;
   end GF_Mult;

   -- Calculates the multiplicative inverse of A in GF(2^8) (i.e. A**254)
   function GF_Inv (A : Byte) return Byte is
      Result : Byte := A;
   begin
      if A = 0 then 
         return 0; 
      end if;
      for I in 1 .. 253 loop
         Result := GF_Mult (Result, A);
      end loop;
      return Result;
   end GF_Inv;

   -- Applies the AES Affine Transformation to a byte
   function Affine_Transform (B : Byte) return Byte is
      B1 : constant Byte := Byte (Interfaces.Rotate_Left (Interfaces.Unsigned_8 (B), 1));
      B2 : constant Byte := Byte (Interfaces.Rotate_Left (Interfaces.Unsigned_8 (B), 2));
      B3 : constant Byte := Byte (Interfaces.Rotate_Left (Interfaces.Unsigned_8 (B), 3));
      B4 : constant Byte := Byte (Interfaces.Rotate_Left (Interfaces.Unsigned_8 (B), 4));
   begin
      return B xor B1 xor B2 xor B3 xor B4 xor 16#63#;
   end Affine_Transform;

   type Table_Type is array (Byte) of Byte;
   type Rcon_Type  is array (1 .. 14) of Byte;

   -- Generates the forward S-Box algorithmically
   function Init_S_Box return Table_Type is
      T : Table_Type;
   begin
      for I in Byte'Range loop
         T (I) := Affine_Transform (GF_Inv (I));
      end loop;
      return T;
   end Init_S_Box;

   -- Generates the inverse S-Box based on the forward S-Box
   function Init_Inv_S_Box (S : Table_Type) return Table_Type is
      T : Table_Type;
   begin
      for I in Byte'Range loop
         T (S (I)) := I;
      end loop;
      return T;
   end Init_Inv_S_Box;

   -- Generates the Round Constant (Rcon) values
   function Init_Rcon return Rcon_Type is
      R : Rcon_Type := [others => 0];
   begin
      R (1) := 16#01#;
      for I in 2 .. 14 loop
         R (I) := GF_Mult (R (I - 1), 16#02#);
      end loop;
      return R;
   end Init_Rcon;

   -- Constant Lookup Tables defined at elaboration
   S_Box     : constant Table_Type := Init_S_Box;
   Inv_S_Box : constant Table_Type := Init_Inv_S_Box (S_Box);
   Rcon      : constant Rcon_Type  := Init_Rcon;

   -----------------------------------------------------------------------------
   -- AES Internal State & Types
   -----------------------------------------------------------------------------

   -- 4x4 Column-Major Matrix
   type State_Array is array (0 .. 3, 0 .. 3) of Byte;
   
   type Word is array (0 .. 3) of Byte;
   type Word_Array is array (Natural range <>) of Word;
   subtype Round_Key is Word_Array (0 .. 3);

   -----------------------------------------------------------------------------
   -- AES Round Operations
   -----------------------------------------------------------------------------

   procedure Sub_Bytes (S : in out State_Array) is
   begin
      for C in 0 .. 3 loop
         for R in 0 .. 3 loop
            S (R, C) := S_Box (S (R, C));
         end loop;
      end loop;
   end Sub_Bytes;

   procedure Inv_Sub_Bytes (S : in out State_Array) is
   begin
      for C in 0 .. 3 loop
         for R in 0 .. 3 loop
            S (R, C) := Inv_S_Box (S (R, C));
         end loop;
      end loop;
   end Inv_Sub_Bytes;

   procedure Shift_Rows (S : in out State_Array) is
      T : Byte;
   begin
      -- Row 1: Shift Left 1
      T := S (1, 0); S (1, 0) := S (1, 1); S (1, 1) := S (1, 2); S (1, 2) := S (1, 3); S (1, 3) := T;
      -- Row 2: Shift Left 2
      T := S (2, 0); S (2, 0) := S (2, 2); S (2, 2) := T;
      T := S (2, 1); S (2, 1) := S (2, 3); S (2, 3) := T;
      -- Row 3: Shift Left 3 (equivalent to Shift Right 1)
      T := S (3, 3); S (3, 3) := S (3, 2); S (3, 2) := S (3, 1); S (3, 1) := S (3, 0); S (3, 0) := T;
   end Shift_Rows;

   procedure Inv_Shift_Rows (S : in out State_Array) is
      T : Byte;
   begin
      -- Row 1: Shift Right 1
      T := S (1, 3); S (1, 3) := S (1, 2); S (1, 2) := S (1, 1); S (1, 1) := S (1, 0); S (1, 0) := T;
      -- Row 2: Shift Right 2 (equivalent to Shift Left 2)
      T := S (2, 0); S (2, 0) := S (2, 2); S (2, 2) := T;
      T := S (2, 1); S (2, 1) := S (2, 3); S (2, 3) := T;
      -- Row 3: Shift Right 3 (equivalent to Shift Left 1)
      T := S (3, 0); S (3, 0) := S (3, 1); S (3, 1) := S (3, 2); S (3, 2) := S (3, 3); S (3, 3) := T;
   end Inv_Shift_Rows;

   procedure Mix_Columns (S : in out State_Array) is
      Col : array (0 .. 3) of Byte;
   begin
      for C in 0 .. 3 loop
         Col(0) := S(0, C); Col(1) := S(1, C); Col(2) := S(2, C); Col(3) := S(3, C);
         S (0, C) := GF_Mult (16#02#, Col(0)) xor GF_Mult (16#03#, Col(1)) xor Col(2) xor Col(3);
         S (1, C) := Col(0) xor GF_Mult (16#02#, Col(1)) xor GF_Mult (16#03#, Col(2)) xor Col(3);
         S (2, C) := Col(0) xor Col(1) xor GF_Mult (16#02#, Col(2)) xor GF_Mult (16#03#, Col(3));
         S (3, C) := GF_Mult (16#03#, Col(0)) xor Col(1) xor Col(2) xor GF_Mult (16#02#, Col(3));
      end loop;
   end Mix_Columns;

   procedure Inv_Mix_Columns (S : in out State_Array) is
      Col : array (0 .. 3) of Byte;
   begin
      for C in 0 .. 3 loop
         Col(0) := S(0, C); Col(1) := S(1, C); Col(2) := S(2, C); Col(3) := S(3, C);
         S (0, C) := GF_Mult (16#0E#, Col(0)) xor GF_Mult (16#0B#, Col(1)) xor GF_Mult (16#0D#, Col(2)) xor GF_Mult (16#09#, Col(3));
         S (1, C) := GF_Mult (16#09#, Col(0)) xor GF_Mult (16#0E#, Col(1)) xor GF_Mult (16#0B#, Col(2)) xor GF_Mult (16#0D#, Col(3));
         S (2, C) := GF_Mult (16#0D#, Col(0)) xor GF_Mult (16#09#, Col(1)) xor GF_Mult (16#0E#, Col(2)) xor GF_Mult (16#0B#, Col(3));
         S (3, C) := GF_Mult (16#0B#, Col(0)) xor GF_Mult (16#0D#, Col(1)) xor GF_Mult (16#09#, Col(2)) xor GF_Mult (16#0E#, Col(3));
      end loop;
   end Inv_Mix_Columns;

   procedure Add_Round_Key (S : in out State_Array; RK : Round_Key) is
   begin
      for C in 0 .. 3 loop
         S (0, C) := S (0, C) xor RK (RK'First + C)(0);
         S (1, C) := S (1, C) xor RK (RK'First + C)(1);
         S (2, C) := S (2, C) xor RK (RK'First + C)(2);
         S (3, C) := S (3, C) xor RK (RK'First + C)(3);
      end loop;
   end Add_Round_Key;

   -----------------------------------------------------------------------------
   -- Key Expansion
   -----------------------------------------------------------------------------

   function Sub_Word (W : Word) return Word is
   begin
      return [S_Box (W(0)), S_Box (W(1)), S_Box (W(2)), S_Box (W(3))];
   end Sub_Word;

   function Rot_Word (W : Word) return Word is
   begin
      return [W(1), W(2), W(3), W(0)];
   end Rot_Word;

   function Xor_Word (A, B : Word) return Word is
   begin
      return [A(0) xor B(0), A(1) xor B(1), A(2) xor B(2), A(3) xor B(3)];
   end Xor_Word;

   procedure Expand_Key (Key : Byte_Array; W : out Word_Array) is
      Nk   : constant Natural := Key'Length / 4;
      Temp : Word;
   begin
      for I in 0 .. Nk - 1 loop
         W (I) := [Key (Key'First + I * 4), 
                   Key (Key'First + I * 4 + 1), 
                   Key (Key'First + I * 4 + 2), 
                   Key (Key'First + I * 4 + 3)];
      end loop;

      for I in Nk .. W'Last loop
         Temp := W (I - 1);
         if I mod Nk = 0 then
            Temp := Sub_Word (Rot_Word (Temp));
            Temp(0) := Temp(0) xor Rcon (I / Nk);
         elsif Nk > 6 and then I mod Nk = 4 then
            Temp := Sub_Word (Temp);
         end if;
         W (I) := Xor_Word (W (I - Nk), Temp);
      end loop;
   end Expand_Key;

   -----------------------------------------------------------------------------
   -- Main Cipher / Inverse Cipher Logic
   -----------------------------------------------------------------------------

   procedure Cipher (Input : Block; Output : out Block; W : Word_Array; Nr : Natural) is
      State : State_Array;
   begin
      for C in 0 .. 3 loop
         for R in 0 .. 3 loop
            State (R, C) := Input (C * 4 + R);
         end loop;
      end loop;

      Add_Round_Key (State, W (0 .. 3));

      for Round in 1 .. Nr - 1 loop
         Sub_Bytes (State);
         Shift_Rows (State);
         Mix_Columns (State);
         Add_Round_Key (State, W (Round * 4 .. Round * 4 + 3));
      end loop;

      Sub_Bytes (State);
      Shift_Rows (State);
      Add_Round_Key (State, W (Nr * 4 .. Nr * 4 + 3));

      for C in 0 .. 3 loop
         for R in 0 .. 3 loop
            Output (C * 4 + R) := State (R, C);
         end loop;
      end loop;
   end Cipher;

   procedure Inv_Cipher (Input : Block; Output : out Block; W : Word_Array; Nr : Natural) is
      State : State_Array;
   begin
      for C in 0 .. 3 loop
         for R in 0 .. 3 loop
            State (R, C) := Input (C * 4 + R);
         end loop;
      end loop;

      Add_Round_Key (State, W (Nr * 4 .. Nr * 4 + 3));

      for Round in reverse 1 .. Nr - 1 loop
         Inv_Shift_Rows (State);
         Inv_Sub_Bytes (State);
         Add_Round_Key (State, W (Round * 4 .. Round * 4 + 3));
         Inv_Mix_Columns (State);
      end loop;

      Inv_Shift_Rows (State);
      Inv_Sub_Bytes (State);
      Add_Round_Key (State, W (0 .. 3));

      for C in 0 .. 3 loop
         for R in 0 .. 3 loop
            Output (C * 4 + R) := State (R, C);
         end loop;
      end loop;
   end Inv_Cipher;

   -----------------------------------------------------------------------------
   -- Public API Implementation
   -----------------------------------------------------------------------------

   procedure Encrypt_Block_128 (Input : in Block; Key : in Key_128; Output : out Block) is
      W : Word_Array (0 .. 43);
   begin
      Expand_Key (Byte_Array (Key), W);
      Cipher (Input, Output, W, 10);
   end Encrypt_Block_128;

   procedure Decrypt_Block_128 (Input : in Block; Key : in Key_128; Output : out Block) is
      W : Word_Array (0 .. 43);
   begin
      Expand_Key (Byte_Array (Key), W);
      Inv_Cipher (Input, Output, W, 10);
   end Decrypt_Block_128;

   procedure Encrypt_Block_192 (Input : in Block; Key : in Key_192; Output : out Block) is
      W : Word_Array (0 .. 51);
   begin
      Expand_Key (Byte_Array (Key), W);
      Cipher (Input, Output, W, 12);
   end Encrypt_Block_192;

   procedure Decrypt_Block_192 (Input : in Block; Key : in Key_192; Output : out Block) is
      W : Word_Array (0 .. 51);
   begin
      Expand_Key (Byte_Array (Key), W);
      Inv_Cipher (Input, Output, W, 12);
   end Decrypt_Block_192;

   procedure Encrypt_Block_256 (Input : in Block; Key : in Key_256; Output : out Block) is
      W : Word_Array (0 .. 59);
   begin
      Expand_Key (Byte_Array (Key), W);
      Cipher (Input, Output, W, 14);
   end Encrypt_Block_256;

   procedure Decrypt_Block_256 (Input : in Block; Key : in Key_256; Output : out Block) is
      W : Word_Array (0 .. 59);
   begin
      Expand_Key (Byte_Array (Key), W);
      Inv_Cipher (Input, Output, W, 14);
   end Decrypt_Block_256;

   -----------------------------------------------------------------------------
   -- Multi-Block Mode Implementations (ECB)
   -----------------------------------------------------------------------------
   -- Helper procedure to apply operation across dynamic sizes

   procedure Process_ECB (Input : in Byte_Array; 
                          Output : out Byte_Array; 
                          Is_Encrypt : Boolean; 
                          Key_Size : Natural; 
                          Key_Data : Byte_Array) is
      Blocks : constant Natural := Input'Length / 16;
      In_Block, Out_Block : Block;
   begin
      if Input'Length mod 16 /= 0 or else Output'Length < Input'Length then
         raise Invalid_Length;
      end if;

      for I in 0 .. Blocks - 1 loop
         for J in 0 .. 15 loop
            In_Block(J) := Input(Input'First + I * 16 + J);
         end loop;
         
         if Is_Encrypt then
            case Key_Size is
               when 128 => Encrypt_Block_128 (In_Block, Key_128 (Key_Data), Out_Block);
               when 192 => Encrypt_Block_192 (In_Block, Key_192 (Key_Data), Out_Block);
               when 256 => Encrypt_Block_256 (In_Block, Key_256 (Key_Data), Out_Block);
               when others => null;
            end case;
         else
            case Key_Size is
               when 128 => Decrypt_Block_128 (In_Block, Key_128 (Key_Data), Out_Block);
               when 192 => Decrypt_Block_192 (In_Block, Key_192 (Key_Data), Out_Block);
               when 256 => Decrypt_Block_256 (In_Block, Key_256 (Key_Data), Out_Block);
               when others => null;
            end case;
         end if;
         
         for J in 0 .. 15 loop
            Output(Output'First + I * 16 + J) := Out_Block(J);
         end loop;
      end loop;
   end Process_ECB;

   procedure Encrypt_ECB_128 (Input : in Byte_Array; Key : in Key_128; Output : out Byte_Array) is
   begin
      Process_ECB (Input, Output, True, 128, Byte_Array (Key));
   end Encrypt_ECB_128;

   procedure Decrypt_ECB_128 (Input : in Byte_Array; Key : in Key_128; Output : out Byte_Array) is
   begin
      Process_ECB (Input, Output, False, 128, Byte_Array (Key));
   end Decrypt_ECB_128;

   procedure Encrypt_ECB_192 (Input : in Byte_Array; Key : in Key_192; Output : out Byte_Array) is
   begin
      Process_ECB (Input, Output, True, 192, Byte_Array (Key));
   end Encrypt_ECB_192;

   procedure Decrypt_ECB_192 (Input : in Byte_Array; Key : in Key_192; Output : out Byte_Array) is
   begin
      Process_ECB (Input, Output, False, 192, Byte_Array (Key));
   end Decrypt_ECB_192;

   procedure Encrypt_ECB_256 (Input : in Byte_Array; Key : in Key_256; Output : out Byte_Array) is
   begin
      Process_ECB (Input, Output, True, 256, Byte_Array (Key));
   end Encrypt_ECB_256;

   procedure Decrypt_ECB_256 (Input : in Byte_Array; Key : in Key_256; Output : out Byte_Array) is
   begin
      Process_ECB (Input, Output, False, 256, Byte_Array (Key));
   end Decrypt_ECB_256;

end AES;
