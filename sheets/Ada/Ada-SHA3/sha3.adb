package body SHA3 is

   --  Internal Keccak state representations
   type Word_64 is mod 2**64;
   type State_Array is array (0 .. 4, 0 .. 4) of Word_64;

   --  Keccak-f[1600] Round Constants
   RC : constant array (0 .. 23) of Word_64 :=
     [16#0000000000000001#, 16#0000000000008082#, 16#800000000000808A#,
      16#8000000080008000#, 16#000000000000808B#, 16#0000000080000001#,
      16#8000000080008081#, 16#8000000000008009#, 16#000000000000008A#,
      16#0000000000000088#, 16#0000000080008009#, 16#000000008000000A#,
      16#000000008000808B#, 16#800000000000008B#, 16#8000000000008089#,
      16#8000000000008003#, 16#8000000000008002#, 16#8000000000000080#,
      16#000000000000800A#, 16#800000008000000A#, 16#8000000080008081#,
      16#8000000000008080#, 16#0000000080000001#, 16#8000000080008008#];

   --  Keccak-f[1600] Rho Offsets (Rotation Constants)
   Rho_Offsets : constant array (0 .. 4, 0 .. 4) of Natural :=
     [[0, 36, 3, 41, 18],
      [1, 44, 10, 45, 2],
      [62, 6, 43, 15, 61],
      [28, 55, 25, 21, 56],
      [27, 20, 39, 8, 14]];

   --  Core Keccak-f[1600] Permutation
   procedure Keccak_F1600 (State : in out State_Array) is
      C, D : array (0 .. 4) of Word_64;
      B    : State_Array;

      function RotL (Value : Word_64; Amount : Natural) return Word_64 is
         pragma Inline (RotL);
      begin
         if Amount = 0 then
            return Value;
         end if;
         --  Since Word_64 is modular, multiply and divide safely wrap/shift
         return (Value * (2 ** Amount)) or (Value / (2 ** (64 - Amount)));
      end RotL;
   begin
      for Round in 0 .. 23 loop
         --  Theta step
         for X in 0 .. 4 loop
            C (X) := State (X, 0) xor State (X, 1) xor State (X, 2) xor State (X, 3) xor State (X, 4);
         end loop;
         for X in 0 .. 4 loop
            D (X) := C ((X + 4) mod 5) xor RotL (C ((X + 1) mod 5), 1);
         end loop;
         for Y in 0 .. 4 loop
            for X in 0 .. 4 loop
               State (X, Y) := State (X, Y) xor D (X);
            end loop;
         end loop;

         --  Rho and Pi steps
         for Y in 0 .. 4 loop
            for X in 0 .. 4 loop
               B (Y, (2 * X + 3 * Y) mod 5) := RotL (State (X, Y), Rho_Offsets (X, Y));
            end loop;
         end loop;

         --  Chi step
         for Y in 0 .. 4 loop
            for X in 0 .. 4 loop
               State (X, Y) := B (X, Y) xor ((not B ((X + 1) mod 5, Y)) and B ((X + 2) mod 5, Y));
            end loop;
         end loop;

         --  Iota step
         State (0, 0) := State (0, 0) xor RC (Round);
      end loop;
   end Keccak_F1600;

   --  Absorb full blocks into Keccak State (Little-endian interpretation)
   procedure Xor_Into_State (State : in out State_Array; Data : Byte_Array) is
      Idx      : Natural := Data'First;
      Word_Val : Word_64;
   begin
      for Y in 0 .. 4 loop
         for X in 0 .. 4 loop
            if Idx > Data'Last then
               return;
            end if;
            Word_Val :=
              Word_64 (Data (Idx)) or
              (Word_64 (Data (Idx + 1)) * 16#100#) or
              (Word_64 (Data (Idx + 2)) * 16#1_0000#) or
              (Word_64 (Data (Idx + 3)) * 16#100_0000#) or
              (Word_64 (Data (Idx + 4)) * 16#1_0000_0000#) or
              (Word_64 (Data (Idx + 5)) * 16#100_0000_0000#) or
              (Word_64 (Data (Idx + 6)) * 16#1_0000_0000_0000#) or
              (Word_64 (Data (Idx + 7)) * 16#100_0000_0000_0000#);
            State (X, Y) := State (X, Y) xor Word_Val;
            Idx := Idx + 8;
         end loop;
      end loop;
   end Xor_Into_State;

   --  Squeeze hash blocks out of Keccak State
   procedure Extract_From_State (State : State_Array; Data : out Byte_Array) is
      Idx      : Natural := Data'First;
      Word_Val : Word_64;
   begin
      for Y in 0 .. 4 loop
         for X in 0 .. 4 loop
            if Idx > Data'Last then
               return;
            end if;
            Word_Val := State (X, Y);
            for B in 0 .. 7 loop
               if Idx <= Data'Last then
                  Data (Idx) := Byte (Word_Val and 16#FF#);
                  Word_Val := Word_Val / 256;
                  Idx := Idx + 1;
               else
                  return;
               end if;
            end loop;
         end loop;
      end loop;
   end Extract_From_State;

   --  Generic Sponge Construction Engine
   procedure Sponge
     (Message       : Byte_Array;
      Rate          : Natural;
      Suffix_Byte   : Byte;
      Output_Length : Natural;
      Output        : out Byte_Array)
   is
      State     : State_Array := [others => [others => 0]];
      Block     : Byte_Array (0 .. Rate - 1);
      Pos       : Natural := Message'First;
      Remaining : Natural := Message'Length;
   begin
      if Output_Length = 0 then
         return;
      end if;

      --  Absorb Phase: Full Rate-sized blocks
      while Remaining >= Rate loop
         Xor_Into_State (State, Message (Pos .. Pos + Rate - 1));
         Keccak_F1600 (State);
         Pos := Pos + Rate;
         Remaining := Remaining - Rate;
      end loop;

      --  Padding Phase: Append Suffix, fill 0s, set final bit 1
      Block := [others => 0];
      for I in 0 .. Remaining - 1 loop
         Block (I) := Message (Pos + I);
      end loop;

      Block (Remaining) := Suffix_Byte;
      Block (Rate - 1)  := Block (Rate - 1) xor 16#80#;

      Xor_Into_State (State, Block);
      Keccak_F1600 (State);

      --  Squeeze Phase
      declare
         Out_Pos : Natural := Output'First;
         Out_Rem : Natural := Output_Length;
      begin
         loop
            if Out_Rem <= Rate then
               Extract_From_State (State, Output (Out_Pos .. Out_Pos + Out_Rem - 1));
               exit;
            else
               Extract_From_State (State, Output (Out_Pos .. Out_Pos + Rate - 1));
               Out_Pos := Out_Pos + Rate;
               Out_Rem := Out_Rem - Rate;
               Keccak_F1600 (State);
            end if;
         end loop;
      end;
   end Sponge;

   -----------------------------------------------------------------------------
   --  Variant Implementations
   -----------------------------------------------------------------------------

   function SHA3_224 (Message : Byte_Array) return Hash_224 is
      Result : Hash_224;
   begin
      --  Rate = 1600 - 2*224 = 1152 bits = 144 bytes
      --  SHA-3 suffix byte is 0x06 (bits 01 appended by 1)
      Sponge (Message, 144, 16#06#, 28, Result);
      return Result;
   end SHA3_224;

   function SHA3_256 (Message : Byte_Array) return Hash_256 is
      Result : Hash_256;
   begin
      --  Rate = 1600 - 2*256 = 1088 bits = 136 bytes
      Sponge (Message, 136, 16#06#, 32, Result);
      return Result;
   end SHA3_256;

   function SHA3_384 (Message : Byte_Array) return Hash_384 is
      Result : Hash_384;
   begin
      --  Rate = 1600 - 2*384 = 832 bits = 104 bytes
      Sponge (Message, 104, 16#06#, 48, Result);
      return Result;
   end SHA3_384;

   function SHA3_512 (Message : Byte_Array) return Hash_512 is
      Result : Hash_512;
   begin
      --  Rate = 1600 - 2*512 = 576 bits = 72 bytes
      Sponge (Message, 72, 16#06#, 64, Result);
      return Result;
   end SHA3_512;

   function SHAKE_128 (Message : Byte_Array; Output_Length : Natural) return Byte_Array is
      Result : Byte_Array (1 .. Output_Length);
   begin
      --  Rate = 1600 - 2*128 = 1344 bits = 168 bytes
      --  SHAKE suffix byte is 0x1F (bits 1111 appended by 1)
      if Output_Length > 0 then
         Sponge (Message, 168, 16#1F#, Output_Length, Result);
      end if;
      return Result;
   end SHAKE_128;

   function SHAKE_256 (Message : Byte_Array; Output_Length : Natural) return Byte_Array is
      Result : Byte_Array (1 .. Output_Length);
   begin
      --  Rate = 1600 - 2*256 = 1088 bits = 136 bytes
      if Output_Length > 0 then
         Sponge (Message, 136, 16#1F#, Output_Length, Result);
      end if;
      return Result;
   end SHAKE_256;

end SHA3;
