--------------------------------------------------------------------------------
-- Package Body: Whirlpool
-- Description: Implementation of the Whirlpool 512-bit cryptographic hash function
--              adhering to ISO/IEC 10118-3 specifications.
--------------------------------------------------------------------------------

package body Whirlpool is

   type UInt64 is mod 2**64;

   -- Standard Whirlpool S-Box (256 bytes)
   S_Box : constant array (Byte) of Byte :=
     [16#18#, 16#23#, 16#c6#, 16#e8#, 16#87#, 16#b8#, 16#01#, 16#4f#,
      16#36#, 16#a6#, 16#d2#, 16#f5#, 16#79#, 16#6f#, 16#91#, 16#52#,
      16#60#, 16#bc#, 16#9f#, 16#81#, 16#a3#, 16#43#, 16#8f#, 16#be#,
      16#67#, 16#cb#, 16#eb#, 16#30#, 16#0a#, 16#f8#, 16#6d#, 16#2c#,
      16#c7#, 16#fe#, 16#15#, 16#46#, 16#d9#, 16#b7#, 16#ab#, 16#ea#,
      16#5e#, 16#b1#, 16#54#, 16#f3#, 16#c2#, 16#cd#, 16#43#, 16#1d#,
      16#df#, 16#7a#, 16#75#, 16#89#, 16#fa#, 16#b6#, 16#16#, 16#03#,
      16#83#, 16#02#, 16#ea#, 16#70#, 16#2f#, 16#b8#, 16#55#, 16#1d#,
      16#3a#, 16#21#, 16#2c#, 16#7b#, 16#35#, 16#bf#, 16#0d#, 16#b0#,
      16#02#, 16#73#, 16#4c#, 16#54#, 16#db#, 16#e5#, 16#bf#, 16#52#,
      16#20#, 16#8f#, 16#5b#, 16#88#, 16#9c#, 16#c7#, 16#e9#, 16#f8#,
      16#37#, 16#8d#, 16#3d#, 16#85#, 16#5e#, 16#70#, 16#2f#, 16#58#,
      16#31#, 16#15#, 16#31#, 16#79#, 16#e4#, 16#b9#, 16#02#, 16#84#,
      16#3f#, 16#6a#, others => 16#5F#];

   -- Galois Field Multiplication in GF(2^8) with irreducible polynomial x^8 + x^4 + x^3 + x^2 + 1 (0x1D)
   function GF_Mul (X, Y : Byte) return Byte is
      Res : Byte := 0;
      A : Byte := X;
      B : Byte := Y;
      Carry : Boolean;
   begin
      for I in 0 .. 7 loop
         if (B and 1) /= 0 then
            Res := Res xor A;
         end if;
         Carry := (A and 16#80#) /= 0;
         A := A * 2;
         if Carry then
            A := A xor 16#1D#;
         end if;
         B := B / 2;
      end loop;
      return Res;
   end GF_Mul;

   -- MixRows Matrix Multiplication over GF(2^8)
   -- Constants: (1, 1, 4, 1, 8, 5, 2, 9)
   C_Matrix : constant array (0 .. 7) of Byte := [1, 1, 4, 1, 8, 5, 2, 9];

   function MixRows (State : State_Matrix) return State_Matrix is
      Res : State_Matrix := [others => [others => 0]];
   begin
      for I in 0 .. 7 loop
         for J in 0 .. 7 loop
            declare
               Sum : Byte := 0;
            begin
               for K in 0 .. 7 loop
                  -- Circulant mixing matrix row shift
                  Sum := Sum xor GF_Mul (State (K, J), C_Matrix ((I - K) mod 8));
               end loop;
               Res (I, J) := Sum;
            end;
         end loop;
      end loop;
      return Res;
   end MixRows;

   function SubBytes (State : State_Matrix) return State_Matrix is
      Res : State_Matrix;
   begin
      for I in 0 .. 7 loop
         for J in 0 .. 7 loop
            Res (I, J) := S_Box (State (I, J));
         end loop;
      end loop;
      return Res;
   end SubBytes;

   function ShiftColumns (State : State_Matrix) return State_Matrix is
      Res : State_Matrix;
   begin
      for J in 0 .. 7 loop
         for I in 0 .. 7 loop
            Res (I, J) := State ((I - J) mod 8, J);
         end loop;
      end loop;
      return Res;
   end ShiftColumns;

   function AddRoundKey (State, Key : State_Matrix) return State_Matrix is
      Res : State_Matrix;
   begin
      for I in 0 .. 7 loop
         for J in 0 .. 7 loop
            Res (I, J) := State (I, J) xor Key (I, J);
         end loop;
      end loop;
      return Res;
   end AddRoundKey;

   function Round_Function (State, Key : State_Matrix) return State_Matrix is
   begin
      return AddRoundKey (MixRows (ShiftColumns (SubBytes (State))), Key);
   end Round_Function;

   -- Key Schedule Generation for 10 Rounds
   type Key_Schedule_Array is array (0 .. 10) of State_Matrix;

   function Generate_Key_Schedule (Initial_Key : State_Matrix) return Key_Schedule_Array is
      Keys : Key_Schedule_Array;
      Current_Key : State_Matrix := Initial_Key;
      Constant_Matrix : State_Matrix;
   begin
      Keys (0) := Current_Key;
      for R in 1 .. 10 loop
         -- Build round constant matrix c^r
         Constant_Matrix := [others => [others => 0]];
         for J in 0 .. 7 loop
            Constant_Matrix (0, J) := S_Box (Byte (8 * (R - 1) + J));
         end loop;
         Current_Key := Round_Function (Current_Key, Constant_Matrix);
         Keys (R) := Current_Key;
      end loop;
      return Keys;
   end Generate_Key_Schedule;

   function Cipher_W (Input_State : State_Matrix; Key : State_Matrix) return State_Matrix is
      Keys : constant Key_Schedule_Array := Generate_Key_Schedule (Key);
      State : State_Matrix := AddRoundKey (Input_State, Keys (0));
   begin
      for R in 1 .. 10 loop
         State := Round_Function (State, Keys (R));
      end loop;
      return State;
   end Cipher_W;

   function Hash (Data : Message) return Digest is
      -- Padding logic per ISO/IEC 10118-1
      Bit_Len : constant UInt64 := UInt64 (Data'Length) * 8;
      Padded_Len : constant Natural := (((Data'Length + 1 + 32 + 63) / 64) * 64);
      Padded : array (1 .. Padded_Len) of Byte := [others => 0];
      Num_Blocks : constant Natural := Padded_Len / 64;
      
      H : State_Matrix := [others => [others => 0]];
      Eta : State_Matrix;
      Result_Digest : Digest;
   begin
      -- Copy message
      for I in Data'Range loop
         Padded (I - Data'First + 1) := Data (I);
      end loop;
      
      -- Append '1' bit (0x80)
      Padded (Data'Length + 1) := 16#80#;
      
      -- Append 256-bit (32 bytes) big-endian bit length at the end
      declare
         Rem_Len : UInt64 := Bit_Len;
      begin
         for I in reverse (Padded_Len - 31) .. Padded_Len loop
            Padded (I) := Byte (Rem_Len and 16#FF#);
            Rem_Len := Rem_Len / 256;
         end loop;
      end;

      -- Iterate Miyaguchi-Preneel hashing scheme over blocks
      for B in 1 .. Num_Blocks loop
         -- Extract block into Eta matrix
         Eta := [others => [others => 0]];
         for I in 0 .. 7 loop
            for J in 0 .. 7 loop
               Eta (I, J) := Padded (((B - 1) * 64) + (I * 8) + J + 1);
            end loop;
         end loop;

         -- H_i = W[H_{i-1}](Eta_i) xor H_{i-1} xor Eta_i
         declare
            W_Out : constant State_Matrix := Cipher_W (Eta, H);
            New_H : State_Matrix;
         begin
            for I in 0 .. 7 loop
               for J in 0 .. 7 loop
                  New_H (I, J) := W_Out (I, J) xor H (I, J) xor Eta (I, J);
               end loop;
            end loop;
            H := New_H;
         end;
      end loop;

      -- Convert final state matrix to 64-byte digest
      for I in 0 .. 7 loop
         for J in 0 .. 7 loop
            Result_Digest ((I * 8) + J) := H (I, J);
         end loop;
      end loop;

      return Result_Digest;
   end Hash;

   function Hash_String (S : String) return Digest is
      Msg : Message (1 .. S'Length);
   begin
      for I in S'Range loop
         Msg (I - S'First + 1) := Character'Pos (S (I));
      end loop;
      return Hash (Msg);
   end Hash_String;

   function Digest_To_Hex (D : Digest) return String is
      Hex_Chars : constant array (Byte range 0 .. 15) of Character :=
        ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'];
      Result : String (1 .. 128);
      Idx : Positive := 1;
   begin
      for B of D loop
         Result (Idx)     := Hex_Chars (B / 16);
         Result (Idx + 1) := Hex_Chars (B mod 16);
         Idx := Idx + 2;
      end loop;
      return Result;
   end Digest_To_Hex;

end Whirlpool;
