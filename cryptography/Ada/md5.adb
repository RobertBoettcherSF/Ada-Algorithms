package body MD5 is

   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;

   -- Per-round shift amounts
   S : constant array (0 .. 63) of Natural :=
     [7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
      5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
      4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
      6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21];

   -- Sine-derived constants for each operation
   K : constant array (0 .. 63) of Word :=
     [16#d76aa478#, 16#e8c7b756#, 16#242070db#, 16#c1bdceee#,
      16#f57c0faf#, 16#4787c62a#, 16#a8304613#, 16#fd469501#,
      16#698098d8#, 16#8b44f7af#, 16#ffff5bb1#, 16#895cd7be#,
      16#6b901122#, 16#fd987193#, 16#a679438e#, 16#49b40821#,
      16#f61e2562#, 16#c040b340#, 16#265e5a51#, 16#e9b6c7aa#,
      16#d62f105d#, 16#02441453#, 16#d8a1e681#, 16#e7d3fbc8#,
      16#21e1cde6#, 16#c33707d6#, 16#f4d50d87#, 16#455a14ed#,
      16#a9e3e905#, 16#fcefa3f8#, 16#676f02d9#, 16#8d2a4c8a#,
      16#fffa3942#, 16#8771f681#, 16#6d9d6122#, 16#fde5380c#,
      16#a4beea44#, 16#4bdecfa9#, 16#f6bb4b60#, 16#bebfbc70#,
      16#289b7ec6#, 16#eaa127fa#, 16#d4ef3085#, 16#04881d05#,
      16#d9d4d039#, 16#e6db99e5#, 16#1fa27cf8#, 16#c4ac5665#,
      16#f4292244#, 16#432aff97#, 16#ab9423a7#, 16#fc93a039#,
      16#655b59c3#, 16#8f0ccc92#, 16#ffeff47d#, 16#85845dd1#,
      16#6fa87e4f#, 16#fe2ce6e0#, 16#a3014314#, 16#4e0811a1#,
      16#f7537e82#, 16#bd3af235#, 16#2ad7d2bb#, 16#eb86d391#];

   -- Helper to verify state explicitly since Pre-conditions don't run without assertions enabled
   procedure Verify_Open (Ctx : Context) is
   begin
      if Ctx.Status = Closed then
         raise MD5_Error with "Context is closed or uninitialized.";
      end if;
   end Verify_Open;

   function Is_Open (Ctx : Context) return Boolean is
   begin
      return Ctx.Status = Open;
   end Is_Open;

   -- Pack 4 bytes into a 32-bit Word (Little Endian)
   function Pack (B0, B1, B2, B3 : Byte) return Word is
   begin
      return Word (B0) or
             Interfaces.Shift_Left (Word (B1), 8) or
             Interfaces.Shift_Left (Word (B2), 16) or
             Interfaces.Shift_Left (Word (B3), 24);
   end Pack;

   -- Unpack a 32-bit Word into 4 bytes (Little Endian)
   procedure Unpack (W : Word; B0, B1, B2, B3 : out Byte) is
   begin
      B0 := Byte (W and 16#FF#);
      B1 := Byte (Interfaces.Shift_Right (W, 8) and 16#FF#);
      B2 := Byte (Interfaces.Shift_Right (W, 16) and 16#FF#);
      B3 := Byte (Interfaces.Shift_Right (W, 24) and 16#FF#);
   end Unpack;

   -- Core MD5 transformation on a 64-byte block
   procedure Transform (State : in out State_Type; Block : Block_Type) is
      A : Word := State (0);
      B : Word := State (1);
      C : Word := State (2);
      D : Word := State (3);
      M : array (0 .. 15) of Word;
      F, G : Word;
      Temp : Word;
   begin
      -- Unpack block into 16 32-bit words
      for I in 0 .. 15 loop
         M (I) := Pack (Block (I * 4), Block (I * 4 + 1), Block (I * 4 + 2), Block (I * 4 + 3));
      end loop;

      -- Apply 64 rounds of mixing
      for I in 0 .. 63 loop
         if I <= 15 then
            F := (B and C) or ((not B) and D);
            G := Word (I);
         elsif I <= 31 then
            F := (D and B) or ((not D) and C);
            G := Word ((5 * I + 1) mod 16);
         elsif I <= 47 then
            F := B xor C xor D;
            G := Word ((3 * I + 5) mod 16);
         else
            F := C xor (B or (not D));
            G := Word ((7 * I) mod 16);
         end if;

         Temp := D;
         D := C;
         C := B;
         B := B + Interfaces.Rotate_Left (A + F + K (I) + M (Natural (G)), S (I));
         A := Temp;
      end loop;

      -- Update cumulative state
      State (0) := State (0) + A;
      State (1) := State (1) + B;
      State (2) := State (2) + C;
      State (3) := State (3) + D;
   end Transform;

   procedure Init (Ctx : out Context) is
   begin
      Ctx.Status := Open;
      Ctx.State  := [16#67452301#, 16#EFCDAB89#, 16#98BADCFE#, 16#10325476#];
      Ctx.Count  := 0;
      Ctx.Buffer := [others => 0];
   end Init;

   procedure Update (Ctx : in out Context; Data : in Byte_Array) is
      Index  : Natural;
      Offset : Natural := Data'First;
      Length : Natural := Data'Length;
      Part   : Natural;
   begin
      Verify_Open (Ctx);

      Index := Natural ((Ctx.Count / 8) mod 64);
      Part  := 64 - Index;

      -- Increment bit count safely
      Ctx.Count := Ctx.Count + Interfaces.Unsigned_64 (Length) * 8;

      if Length >= Part then
         -- Complete current block
         Ctx.Buffer (Index .. 63) := Data (Offset .. Offset + Part - 1);
         Transform (Ctx.State, Ctx.Buffer);
         Offset := Offset + Part;
         Length := Length - Part;
         Index  := 0;

         -- Process full 64-byte chunks
         while Length >= 64 loop
            declare
               Block : Block_Type;
            begin
               Block := Data (Offset .. Offset + 63);
               Transform (Ctx.State, Block);
               Offset := Offset + 64;
               Length := Length - 64;
            end;
         end loop;
      end if;

      -- Buffer remaining bytes
      if Length > 0 then
         Ctx.Buffer (Index .. Index + Length - 1) := Data (Offset .. Offset + Length - 1);
      end if;
   end Update;

   procedure Update (Ctx : in out Context; Data : in String) is
   begin
      Update (Ctx, To_Bytes (Data));
   end Update;

   procedure Final (Ctx : in out Context; Digest : out Digest_Type) is
      Padding : Byte_Array (0 .. 63) := [others => 0];
      Index   : Natural;
      Pad_Len : Natural;
      Bits    : constant Interfaces.Unsigned_64 := Ctx.Count;
   begin
      Verify_Open (Ctx);

      Index := Natural ((Ctx.Count / 8) mod 64);
      Padding (0) := 16#80#;

      if Index < 56 then
         Pad_Len := 56 - Index;
      else
         Pad_Len := 120 - Index;
      end if;

      Update (Ctx, Padding (0 .. Pad_Len - 1));

      -- Append total length in bits (64-bit, little-endian)
      declare
         Len_Bytes : Byte_Array (0 .. 7);
         Temp      : Interfaces.Unsigned_64 := Bits;
      begin
         for I in 0 .. 7 loop
            Len_Bytes (I) := Byte (Temp and 16#FF#);
            Temp := Interfaces.Shift_Right (Temp, 8);
         end loop;
         Update (Ctx, Len_Bytes);
      end;

      -- Final transformation extracts state into Digest
      for I in 0 .. 3 loop
         Unpack (Ctx.State (I),
                 Digest (I * 4),
                 Digest (I * 4 + 1),
                 Digest (I * 4 + 2),
                 Digest (I * 4 + 3));
      end loop;

      Ctx.Status := Closed;
   end Final;

   function To_Bytes (S : String) return Byte_Array is
      Result : Byte_Array (0 .. S'Length - 1);
   begin
      for I in S'Range loop
         Result (I - S'First) := Byte (Character'Pos (S (I)));
      end loop;
      return Result;
   end To_Bytes;

   function To_Hex (Digest : Digest_Type) return Hex_String is
      Hex_Chars : constant String := "0123456789abcdef";
      Result    : Hex_String;
      Val       : Byte;
   begin
      for I in Digest'Range loop
         Val := Digest (I);
         Result (I * 2 + 1) := Hex_Chars (Natural (Interfaces.Shift_Right (Val, 4)) + 1);
         Result (I * 2 + 2) := Hex_Chars (Natural (Val and 16#0F#) + 1);
      end loop;
      return Result;
   end To_Hex;

   function Hash (Message : Byte_Array) return Digest_Type is
      Ctx    : Context;
      Digest : Digest_Type;
   begin
      Init (Ctx);
      Update (Ctx, Message);
      Final (Ctx, Digest);
      return Digest;
   end Hash;

   function Hash (Message : String) return Hex_String is
      Digest : Digest_Type;
   begin
      Digest := Hash (To_Bytes (Message));
      return To_Hex (Digest);
   end Hash;

end MD5;
