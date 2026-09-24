package body Csprng is

   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;

   -------------------------------------------------------------------------
   -- VARIANT 1: ChaCha20 Implementation
   -------------------------------------------------------------------------
   function Rotate_Left (Value : U32; Amount : Natural) return U32 is
   begin
      return Interfaces.Rotate_Left (Value, Amount);
   end Rotate_Left;

   procedure Quarter_Round (A, B, C, D : in out U32) is
   begin
      A := A + B; D := D xor A; D := Rotate_Left (D, 16);
      C := C + D; B := B xor C; B := Rotate_Left (B, 12);
      A := A + B; D := D xor A; D := Rotate_Left (D, 8);
      C := C + D; B := B xor C; B := Rotate_Left (B, 7);
   end Quarter_Round;

   function Bytes_To_U32 (B1, B2, B3, B4 : Byte) return U32 is
   begin
      return U32 (B1) or (U32 (B2) * 2**8) or (U32 (B3) * 2**16) or (U32 (B4) * 2**24);
   end Bytes_To_U32;

   procedure U32_To_Bytes (Val : in U32; B1, B2, B3, B4 : out Byte) is
   begin
      B1 := Byte (Val mod 256);
      B2 := Byte ((Val / 2**8) mod 256);
      B3 := Byte ((Val / 2**16) mod 256);
      B4 := Byte ((Val / 2**24) mod 256);
   end U32_To_Bytes;

   procedure Initialize (Gen   : out Cha_Cha_20_Generator;
                         Key   : in  Cha_Cha_Key;
                         Nonce : in  Cha_Cha_Nonce) is
   begin
      Gen.State (0) := 16#61707865#;
      Gen.State (1) := 16#3320646e#;
      Gen.State (2) := 16#79622d32#;
      Gen.State (3) := 16#6b206574#;

      for Idx in 0 .. 7 loop
         Gen.State (4 + Idx) := Bytes_To_U32 (Key (Key'First + Idx * 4),
                                              Key (Key'First + Idx * 4 + 1),
                                              Key (Key'First + Idx * 4 + 2),
                                              Key (Key'First + Idx * 4 + 3));
      end loop;

      Gen.State (12) := 0;
      Gen.State (13) := 0;

      Gen.State (14) := Bytes_To_U32 (Nonce (Nonce'First),
                                      Nonce (Nonce'First + 1),
                                      Nonce (Nonce'First + 2),
                                      Nonce (Nonce'First + 3));
      Gen.State (15) := Bytes_To_U32 (Nonce (Nonce'First + 4),
                                      Nonce (Nonce'First + 5),
                                      Nonce (Nonce'First + 6),
                                      Nonce (Nonce'First + 7));
      Gen.Buffer_Index := 65;
      Gen.Is_Seeded    := True;
   end Initialize;

   procedure Generate_Block (Gen : in out Cha_Cha_20_Generator) is
      Working : Cha_Cha_State := Gen.State;
   begin
      for Idx in 1 .. 10 loop
         Quarter_Round (Working (0), Working (4), Working (8),  Working (12));
         Quarter_Round (Working (1), Working (5), Working (9),  Working (13));
         Quarter_Round (Working (2), Working (6), Working (10), Working (14));
         Quarter_Round (Working (3), Working (7), Working (11), Working (15));

         Quarter_Round (Working (0), Working (5), Working (10), Working (15));
         Quarter_Round (Working (1), Working (6), Working (11), Working (12));
         Quarter_Round (Working (2), Working (7), Working (8),  Working (13));
         Quarter_Round (Working (3), Working (4), Working (9),  Working (14));
      end loop;

      for Idx in 0 .. 15 loop
         Working (Idx) := Working (Idx) + Gen.State (Idx);
         U32_To_Bytes (Working (Idx),
                       Gen.Buffer (1 + Idx * 4),
                       Gen.Buffer (2 + Idx * 4),
                       Gen.Buffer (3 + Idx * 4),
                       Gen.Buffer (4 + Idx * 4));
      end loop;

      Gen.State (12) := Gen.State (12) + 1;
      if Gen.State (12) = 0 then
         Gen.State (13) := Gen.State (13) + 1;
      end if;

      Gen.Buffer_Index := 1;
   end Generate_Block;

   procedure Generate (Gen : in out Cha_Cha_20_Generator; Data : out Byte_Array) is
   begin
      for Idx in Data'Range loop
         if Gen.Buffer_Index > 64 then
            Generate_Block (Gen);
         end if;
         Data (Idx) := Gen.Buffer (Gen.Buffer_Index);
         Gen.Buffer_Index := Gen.Buffer_Index + 1;
      end loop;
   end Generate;

   -------------------------------------------------------------------------
   -- VARIANT 2: Blum Blum Shub Implementation
   -------------------------------------------------------------------------
   procedure Initialize (Gen  : out Bbs_Generator;
                         P    : in  Bbs_Prime;
                         Q    : in  Bbs_Prime;
                         Seed : in  Bbs_State) is
      Temp_Seed : Bbs_State;
   begin
      if P mod 4 /= 3 or else Q mod 4 /= 3 or else P = Q then
         raise Crypto_Error with "BBS requires distinct primes congruent to 3 mod 4";
      end if;

      Gen.M := Bbs_State (P) * Bbs_State (Q);

      if Seed mod Gen.M = 0 then
         raise Crypto_Error with "Seed must not be a multiple of M";
      end if;

      Temp_Seed := Seed mod Gen.M;
      Gen.X := Bbs_State ((Interfaces.Unsigned_64 (Temp_Seed) * 
                           Interfaces.Unsigned_64 (Temp_Seed)) mod 
                           Interfaces.Unsigned_64 (Gen.M));
      Gen.Is_Seeded := True;
   end Initialize;

   procedure Generate (Gen : in out Bbs_Generator; Data : out Byte_Array) is
      Bit_Val      : Byte;
      Current_Byte : Byte;
   begin
      for Idx in Data'Range loop
         Current_Byte := 0;
         for Bit_Pos in 0 .. 7 loop
            Gen.X := Bbs_State ((Interfaces.Unsigned_64 (Gen.X) * 
                                 Interfaces.Unsigned_64 (Gen.X)) mod 
                                 Interfaces.Unsigned_64 (Gen.M));
            Bit_Val := Byte (Gen.X mod 2);
            Current_Byte := Current_Byte or (Bit_Val * (2 ** Bit_Pos));
         end loop;
         Data (Idx) := Current_Byte;
      end loop;
   end Generate;

   -------------------------------------------------------------------------
   -- VARIANT 3: RC4 Implementation
   -------------------------------------------------------------------------
   procedure Initialize (Gen : out Rc4_Generator;
                         Key : in  Byte_Array) is
      J    : Byte := 0;
      Temp : Byte;
   begin
      if Key'Length = 0 then
         raise Crypto_Error with "RC4 key cannot be empty";
      end if;

      for Idx in Byte loop
         Gen.S (Idx) := Idx;
      end loop;

      for Idx in Byte loop
         declare
            Key_Index : constant Positive := Key'First + (Natural (Idx) mod Key'Length);
         begin
            J := J + Gen.S (Idx) + Key (Key_Index);
         end;
         Temp := Gen.S (Idx);
         Gen.S (Idx) := Gen.S (J);
         Gen.S (J) := Temp;
      end loop;

      Gen.I := 0;
      Gen.J := 0;
      Gen.Is_Seeded := True;
   end Initialize;

   procedure Generate (Gen : in out Rc4_Generator; Data : out Byte_Array) is
      Temp : Byte;
      K    : Byte;
   begin
      for Idx in Data'Range loop
         Gen.I := Gen.I + 1;
         Gen.J := Gen.J + Gen.S (Gen.I);
         
         Temp := Gen.S (Gen.I);
         Gen.S (Gen.I) := Gen.S (Gen.J);
         Gen.S (Gen.J) := Temp;
         
         K := Gen.S (Gen.I) + Gen.S (Gen.J);
         Data (Idx) := Gen.S (K);
      end loop;
   end Generate;

end Csprng;
