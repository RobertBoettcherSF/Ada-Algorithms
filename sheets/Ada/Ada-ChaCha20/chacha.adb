package body Chacha is
   use Interfaces;

   --  ChaCha Constants ("expand 32-byte k" in ASCII)
   Sigma_0 : constant Word := 16#61707865#;
   Sigma_1 : constant Word := 16#3320646e#;
   Sigma_2 : constant Word := 16#79622d32#;
   Sigma_3 : constant Word := 16#6b206574#;

   --  Converts 4 bytes in little-endian order to a 32-bit Word
   function Bytes_To_Word (B : Bytes) return Word
     with Pre => B'Length = 4
   is
   begin
      return Word (B (B'First)) or
             Word (Shift_Left (Unsigned_32 (B (B'First + 1)), 8)) or
             Word (Shift_Left (Unsigned_32 (B (B'First + 2)), 16)) or
             Word (Shift_Left (Unsigned_32 (B (B'First + 3)), 24));
   end Bytes_To_Word;

   --  Converts a 32-bit Word to 4 bytes in little-endian order
   procedure Word_To_Bytes (W : in Word; B : out Bytes)
     with Pre => B'Length = 4
   is
   begin
      B (B'First)     := Unsigned_8 (W and 16#FF#);
      B (B'First + 1) := Unsigned_8 (Shift_Right (Unsigned_32 (W), 8) and 16#FF#);
      B (B'First + 2) := Unsigned_8 (Shift_Right (Unsigned_32 (W), 16) and 16#FF#);
      B (B'First + 3) := Unsigned_8 (Shift_Right (Unsigned_32 (W), 24) and 16#FF#);
   end Word_To_Bytes;

   --  The core ChaCha quarter round mixing operation
   procedure Quarter_Round (A, B, C, D : in out Word) is
   begin
      A := A + B; D := Word (Rotate_Left (Unsigned_32 (D xor A), 16));
      C := C + D; B := Word (Rotate_Left (Unsigned_32 (B xor C), 12));
      A := A + B; D := Word (Rotate_Left (Unsigned_32 (D xor A), 8));
      C := C + D; B := Word (Rotate_Left (Unsigned_32 (B xor C), 7));
   end Quarter_Round;

   --  Maps the variant enum to the literal number of rounds
   function Num_Rounds (Variant : Rounds) return Positive is
     (case Variant is
         when ChaCha8  => 8,
         when ChaCha12 => 12,
         when ChaCha20 => 20);

   --  Generates a 64-byte keystream block using the selected round count
   procedure Generate_Block
     (Initial_State : in     State_Array;
      Variant       : in     Rounds;
      Block         :    out Block_Type)
   is
      State : State_Array := Initial_State;
   begin
      --  Run the inner block mixing loop
      for I in 1 .. Num_Rounds (Variant) / 2 loop
         --  Odd round: columns
         Quarter_Round (State (0), State (4), State (8),  State (12));
         Quarter_Round (State (1), State (5), State (9),  State (13));
         Quarter_Round (State (2), State (6), State (10), State (14));
         Quarter_Round (State (3), State (7), State (11), State (15));
         --  Even round: diagonals
         Quarter_Round (State (0), State (5), State (10), State (15));
         Quarter_Round (State (1), State (6), State (11), State (12));
         Quarter_Round (State (2), State (7), State (8),  State (13));
         Quarter_Round (State (3), State (4), State (9),  State (14));
      end loop;

      --  Add the mixed state to the initial state and serialize to bytes
      for I in State_Array'Range loop
         State (I) := State (I) + Initial_State (I);
         Word_To_Bytes (State (I), Block (Block'First + I * 4 .. Block'First + I * 4 + 3));
      end loop;
   end Generate_Block;

   --  Encrypts/Decrypts data in-place using the IETF RFC 7539 variant
   procedure Encrypt_IETF
     (Key     : in     Key_256;
      Nonce   : in     Nonce_96;
      Counter : in     Word;
      Data    : in out Bytes;
      Variant : in     Rounds := ChaCha20)
   is
      Init_State      : State_Array;
      Current_Block   : Block_Type;
      Current_Counter : Word := Counter;
      Remaining       : Natural := Data'Length;
      Data_Index      : Natural := Data'First;
      Chunk_Length    : Natural;
   begin
      if Remaining = 0 then
         return;
      end if;

      Init_State (0) := Sigma_0;
      Init_State (1) := Sigma_1;
      Init_State (2) := Sigma_2;
      Init_State (3) := Sigma_3;

      for I in 0 .. 7 loop
         Init_State (4 + I) := Bytes_To_Word (Key (Key'First + I * 4 .. Key'First + I * 4 + 3));
      end loop;

      for I in 0 .. 2 loop
         Init_State (13 + I) := Bytes_To_Word (Nonce (Nonce'First + I * 4 .. Nonce'First + I * 4 + 3));
      end loop;

      while Remaining > 0 loop
         Init_State (12) := Current_Counter;
         Generate_Block (Init_State, Variant, Current_Block);

         Chunk_Length := Natural'Min (64, Remaining);
         for I in 0 .. Chunk_Length - 1 loop
            Data (Data_Index + I) := Data (Data_Index + I) xor Current_Block (Current_Block'First + I);
         end loop;

         Remaining := Remaining - Chunk_Length;
         if Remaining > 0 then
            Data_Index := Data_Index + Chunk_Length;
         end if;
         Current_Counter := Current_Counter + 1;
      end loop;
   end Encrypt_IETF;

   --  Encrypts/Decrypts data in-place using the original Bernstein variant
   procedure Encrypt_Original
     (Key     : in     Key_256;
      Nonce   : in     Nonce_64;
      Counter : in     Interfaces.Unsigned_64;
      Data    : in out Bytes;
      Variant : in     Rounds := ChaCha20)
   is
      Init_State      : State_Array;
      Current_Block   : Block_Type;
      Current_Counter : Unsigned_64 := Counter;
      Remaining       : Natural := Data'Length;
      Data_Index      : Natural := Data'First;
      Chunk_Length    : Natural;
   begin
      if Remaining = 0 then
         return;
      end if;

      Init_State (0) := Sigma_0;
      Init_State (1) := Sigma_1;
      Init_State (2) := Sigma_2;
      Init_State (3) := Sigma_3;

      for I in 0 .. 7 loop
         Init_State (4 + I) := Bytes_To_Word (Key (Key'First + I * 4 .. Key'First + I * 4 + 3));
      end loop;

      for I in 0 .. 1 loop
         Init_State (14 + I) := Bytes_To_Word (Nonce (Nonce'First + I * 4 .. Nonce'First + I * 4 + 3));
      end loop;

      while Remaining > 0 loop
         Init_State (12) := Word (Current_Counter and 16#FFFF_FFFF#);
         Init_State (13) := Word (Shift_Right (Current_Counter, 32) and 16#FFFF_FFFF#);

         Generate_Block (Init_State, Variant, Current_Block);

         Chunk_Length := Natural'Min (64, Remaining);
         for I in 0 .. Chunk_Length - 1 loop
            Data (Data_Index + I) := Data (Data_Index + I) xor Current_Block (Current_Block'First + I);
         end loop;

         Remaining := Remaining - Chunk_Length;
         if Remaining > 0 then
            Data_Index := Data_Index + Chunk_Length;
         end if;
         Current_Counter := Current_Counter + 1;
      end loop;
   end Encrypt_Original;

end Chacha;
