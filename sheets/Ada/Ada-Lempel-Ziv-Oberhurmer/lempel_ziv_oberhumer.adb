-- ============================================================================
-- Package Body: Lempel_Ziv_Oberhumer (LZO)
-- Full Implementation of standard and specialized LZO variants.
-- ============================================================================

package body Lempel_Ziv_Oberhumer is

   ----------------------------------------------------------------------------
   -- Internal Helper: Find longest match in sliding dictionary window
   ----------------------------------------------------------------------------
   procedure Find_Match (
      Input        : in  Byte_Array;
      Curr         : in  Natural;
      Max_Offset   : in  Natural;
      Min_Len      : in  Natural;
      Max_Len      : in  Natural;
      Match_Offset : out Natural;
      Match_Length : out Natural
   ) is
      Window_Start : Natural;
      Best_Offset  : Natural := 0;
      Best_Len     : Natural := 0;
      Candidate    : Natural;
      Len          : Natural;
   begin
      if Curr < Input'First + Min_Len then
         Match_Offset := 0;
         Match_Length := 0;
         return;
      end if;

      if Curr - Input'First > Max_Offset then
         Window_Start := Curr - Max_Offset;
      else
         Window_Start := Input'First;
      end if;

      Candidate := Window_Start;
      while Candidate < Curr loop
         Len := 0;
         while Curr + Len <= Input'Last and then
               Candidate + Len < Curr and then
               Input(Candidate + Len) = Input(Curr + Len) and then
               Len < Max_Len loop
            Len := Len + 1;
         end loop;

         if Len >= Min_Len and then Len > Best_Len then
            Best_Len    := Len;
            Best_Offset := Curr - Candidate;
         end if;

         Candidate := Candidate + 1;
      end loop;

      Match_Offset := Best_Offset;
      Match_Length := Best_Len;
   end Find_Match;

   ----------------------------------------------------------------------------
   -- Internal Helper: Flush accumulated literal bytes to output buffer
   ----------------------------------------------------------------------------
   procedure Flush_Literals (
      Input     : in     Byte_Array;
      Lit_Start : in     Natural;
      Lit_Len   : in     Natural;
      Output    : in out Byte_Array;
      Out_Pos   : in out Natural
   ) is
      Rem_Len : Natural := Lit_Len;
      Curr_L  : Natural;
      Src_Idx : Natural := Lit_Start;
   begin
      while Rem_Len > 0 loop
         if Rem_Len >= 63 then
            Curr_L := 62;
         else
            Curr_L := Rem_Len;
         end if;

         if Out_Pos > Output'Last then
            raise Buffer_Overrun_Error;
         end if;

         -- Tag bit 7,6 = 00: Literal run
         Output(Out_Pos) := Byte(Curr_L);
         Out_Pos := Out_Pos + 1;

         if Out_Pos + Curr_L - 1 > Output'Last then
            raise Buffer_Overrun_Error;
         end if;

         Output(Out_Pos .. Out_Pos + Curr_L - 1) := Input(Src_Idx .. Src_Idx + Curr_L - 1);
         Out_Pos := Out_Pos + Curr_L;
         Src_Idx := Src_Idx + Curr_L;
         Rem_Len := Rem_Len - Curr_L;
      end loop;
   end Flush_Literals;

   ----------------------------------------------------------------------------
   -- Public Auxiliary Calculations
   ----------------------------------------------------------------------------
   function Max_Compressed_Size (Input_Length : Natural) return Natural is
   begin
      -- Conservative upper bound: input size + expansion factor + stream header/EOS markers
      return Input_Length + (Input_Length / 16) + 64;
   end Max_Compressed_Size;

   function Calculate_Compression_Ratio (Uncompressed_Size, Compressed_Size : Natural) return Float is
   begin
      if Uncompressed_Size = 0 then
         return 0.0;
      end if;
      return (1.0 - (Float(Compressed_Size) / Float(Uncompressed_Size))) * 100.0;
   end Calculate_Compression_Ratio;

   function Verify_Equality (Buf1, Buf2 : Byte_Array) return Boolean is
   begin
      if Buf1'Length /= Buf2'Length then
         return False;
      end if;

      for I in 0 .. Buf1'Length - 1 loop
         if Buf1(Buf1'First + I) /= Buf2(Buf2'First + I) then
            return False;
         end if;
      end loop;
      return True;
   end Verify_Equality;

   ----------------------------------------------------------------------------
   -- Unified Dispatch Interfaces
   ----------------------------------------------------------------------------
   procedure Compress (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural;
      Variant    : in  LZO_Variant := LZO1X
   ) is
   begin
      case Variant is
         when LZO1    => Compress_LZO1(Input, Output, Output_Len);
         when LZO1X   => Compress_LZO1X(Input, Output, Output_Len);
         when LZO1Y   => Compress_LZO1Y(Input, Output, Output_Len);
         when LZO1Z   => Compress_LZO1Z(Input, Output, Output_Len);
         when LZO_RLE => Compress_LZO_RLE(Input, Output, Output_Len);
      end case;
   end Compress;

   procedure Decompress (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural;
      Variant    : in  LZO_Variant := LZO1X
   ) is
   begin
      case Variant is
         when LZO1    => Decompress_LZO1(Input, Output, Output_Len);
         when LZO1X   => Decompress_LZO1X(Input, Output, Output_Len);
         when LZO1Y   => Decompress_LZO1Y(Input, Output, Output_Len);
         when LZO1Z   => Decompress_LZO1Z(Input, Output, Output_Len);
         when LZO_RLE => Decompress_LZO_RLE(Input, Output, Output_Len);
      end case;
   end Decompress;

   ----------------------------------------------------------------------------
   -- VARIANT 1: LZO1 (Basic 12-bit offset variant)
   ----------------------------------------------------------------------------
   procedure Compress_LZO1 (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   ) is
      In_Pos       : Natural := Input'First;
      Out_Pos      : Natural := Output'First;
      Lit_Start    : Natural := Input'First;
      Lit_Len      : Natural := 0;
      Match_Offset : Natural;
      Match_Len    : Natural;
      Len_Code     : Natural;
      Off_High     : Natural;
      Off_Low      : Natural;
      Tag          : Byte;
   begin
      if Input'Length = 0 then
         if Output'Length < 3 then
            raise Buffer_Overrun_Error;
         end if;
         Output(Output'First .. Output'First + 2) := (16#80#, 16#00#, 16#00#);
         Output_Len := 3;
         return;
      end if;

      while In_Pos <= Input'Last loop
         Find_Match(Input, In_Pos, 4095, 2, 260, Match_Offset, Match_Len);

         if Match_Len >= 2 then
            if Lit_Len > 0 then
               Flush_Literals(Input, Lit_Start, Lit_Len, Output, Out_Pos);
               Lit_Len := 0;
            end if;

            if Match_Len - 2 >= 7 then
               Len_Code := 7;
            else
               Len_Code := Match_Len - 2;
            end if;

            Off_High := Match_Offset / 256;
            Off_Low  := Match_Offset mod 256;
            
            Tag := 16#80# or Byte(Len_Code * 16) or (Byte(Off_High) and 16#0F#);

            if Out_Pos + 1 > Output'Last then
               raise Buffer_Overrun_Error;
            end if;

            Output(Out_Pos)     := Tag;
            Output(Out_Pos + 1) := Byte(Off_Low);
            Out_Pos := Out_Pos + 2;

            if Len_Code = 7 then
               if Out_Pos > Output'Last then
                  raise Buffer_Overrun_Error;
               end if;
               Output(Out_Pos) := Byte((Match_Len - 9) mod 256);
               Out_Pos := Out_Pos + 1;
            end if;

            In_Pos    := In_Pos + Match_Len;
            Lit_Start := In_Pos;
         else
            Lit_Len := Lit_Len + 1;
            In_Pos  := In_Pos + 1;
         end if;
      end loop;

      if Lit_Len > 0 then
         Flush_Literals(Input, Lit_Start, Lit_Len, Output, Out_Pos);
      end if;

      if Out_Pos + 2 > Output'Last then
         raise Buffer_Overrun_Error;
      end if;
      Output(Out_Pos .. Out_Pos + 2) := (16#80#, 16#00#, 16#00#);
      Out_Pos := Out_Pos + 3;

      Output_Len := Out_Pos - Output'First;
   end Compress_LZO1;

   procedure Decompress_LZO1 (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   ) is
      In_Pos    : Natural := Input'First;
      Out_Pos   : Natural := Output'First;
      Tag       : Byte;
      Lit_Len   : Natural;
      Match_Len : Natural;
      Offset    : Natural;
      Len_Code  : Natural;
      Off_High  : Natural;
      Off_Low   : Natural;
   begin
      if Input'Length = 0 then
         Output_Len := 0;
         return;
      end if;

      while In_Pos <= Input'Last loop
         Tag    := Input(In_Pos);
         In_Pos := In_Pos + 1;

         if (Tag and 16#80#) = 0 then
            Lit_Len := Natural(Tag and 16#7F#);
            if Lit_Len > 0 then
               if In_Pos + Lit_Len - 1 > Input'Last then
                  raise Corrupt_Input_Error;
               end if;
               if Out_Pos + Lit_Len - 1 > Output'Last then
                  raise Buffer_Overrun_Error;
               end if;

               Output(Out_Pos .. Out_Pos + Lit_Len - 1) := Input(In_Pos .. In_Pos + Lit_Len - 1);
               Out_Pos := Out_Pos + Lit_Len;
               In_Pos  := In_Pos + Lit_Len;
            end if;
         else
            Len_Code := Natural((Tag / 16) and 7);
            Off_High := Natural(Tag and 16#0F#);

            if In_Pos > Input'Last then
               raise Corrupt_Input_Error;
            end if;
            Off_Low := Natural(Input(In_Pos));
            In_Pos  := In_Pos + 1;

            Offset := Off_High * 256 + Off_Low;

            if Len_Code = 0 and Offset = 0 then
               exit;
            end if;

            Match_Len := Len_Code + 2;
            if Len_Code = 7 then
               if In_Pos > Input'Last then
                  raise Corrupt_Input_Error;
               end if;
               Match_Len := Match_Len + Natural(Input(In_Pos));
               In_Pos    := In_Pos + 1;
            end if;

            if Offset = 0 or else Offset > Out_Pos - Output'First then
               raise Corrupt_Input_Error;
            end if;

            if Out_Pos + Match_Len - 1 > Output'Last then
               raise Buffer_Overrun_Error;
            end if;

            for K in 0 .. Match_Len - 1 loop
               Output(Out_Pos + K) := Output(Out_Pos - Offset + K);
            end loop;
            Out_Pos := Out_Pos + Match_Len;
         end if;
      end loop;

      Output_Len := Out_Pos - Output'First;
   end Decompress_LZO1;

   ----------------------------------------------------------------------------
   -- VARIANT 2: LZO1X (Standard 16-bit offset variant)
   ----------------------------------------------------------------------------
   procedure Compress_LZO1X (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   ) is
      In_Pos       : Natural := Input'First;
      Out_Pos      : Natural := Output'First;
      Lit_Start    : Natural := Input'First;
      Lit_Len      : Natural := 0;
      Match_Offset : Natural;
      Match_Len    : Natural;
      Tag          : Byte;
   begin
      if Input'Length = 0 then
         if Output'Length < 4 then
            raise Buffer_Overrun_Error;
         end if;
         Output(Output'First .. Output'First + 3) := (16#C0#, 16#00#, 16#00#, 16#00#);
         Output_Len := 4;
         return;
      end if;

      while In_Pos <= Input'Last loop
         Find_Match(Input, In_Pos, 65535, 3, 255, Match_Offset, Match_Len);

         if Match_Len >= 3 then
            if Lit_Len > 0 then
               Flush_Literals(Input, Lit_Start, Lit_Len, Output, Out_Pos);
               Lit_Len := 0;
            end if;

            if Match_Len <= 34 then
               Tag := 16#80# or Byte(Match_Len - 3);
               if Out_Pos + 2 > Output'Last then
                  raise Buffer_Overrun_Error;
               end if;
               Output(Out_Pos)     := Tag;
               Output(Out_Pos + 1) := Byte(Match_Offset / 256);
               Output(Out_Pos + 2) := Byte(Match_Offset mod 256);
               Out_Pos := Out_Pos + 3;
            else
               Tag := 16#C0#;
               if Out_Pos + 3 > Output'Last then
                  raise Buffer_Overrun_Error;
               end if;
               Output(Out_Pos)     := Tag;
               Output(Out_Pos + 1) := Byte(Match_Len - 35);
               Output(Out_Pos + 2) := Byte(Match_Offset / 256);
               Output(Out_Pos + 3) := Byte(Match_Offset mod 256);
               Out_Pos := Out_Pos + 4;
            end if;

            In_Pos    := In_Pos + Match_Len;
            Lit_Start := In_Pos;
         else
            Lit_Len := Lit_Len + 1;
            In_Pos  := In_Pos + 1;
         end if;
      end loop;

      if Lit_Len > 0 then
         Flush_Literals(Input, Lit_Start, Lit_Len, Output, Out_Pos);
      end if;

      if Out_Pos + 3 > Output'Last then
         raise Buffer_Overrun_Error;
      end if;
      Output(Out_Pos .. Out_Pos + 3) := (16#C0#, 16#00#, 16#00#, 16#00#);
      Out_Pos := Out_Pos + 4;

      Output_Len := Out_Pos - Output'First;
   end Compress_LZO1X;

   procedure Decompress_LZO1X (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   ) is
      In_Pos    : Natural := Input'First;
      Out_Pos   : Natural := Output'First;
      Tag       : Byte;
      Tag_Type  : Byte;
      Lit_Len   : Natural;
      Match_Len : Natural;
      Offset    : Natural;
      Extra_Len : Natural;
   begin
      if Input'Length = 0 then
         Output_Len := 0;
         return;
      end if;

      while In_Pos <= Input'Last loop
         Tag      := Input(In_Pos);
         In_Pos   := In_Pos + 1;
         Tag_Type := Tag and 16#C0#;

         if Tag_Type = 16#00# then
            Lit_Len := Natural(Tag and 16#3F#);
            if Lit_Len > 0 then
               if In_Pos + Lit_Len - 1 > Input'Last then
                  raise Corrupt_Input_Error;
               end if;
               if Out_Pos + Lit_Len - 1 > Output'Last then
                  raise Buffer_Overrun_Error;
               end if;

               Output(Out_Pos .. Out_Pos + Lit_Len - 1) := Input(In_Pos .. In_Pos + Lit_Len - 1);
               Out_Pos := Out_Pos + Lit_Len;
               In_Pos  := In_Pos + Lit_Len;
            end if;
         elsif Tag_Type = 16#80# then
            Match_Len := Natural(Tag and 16#3F#) + 3;
            if In_Pos + 1 > Input'Last then
               raise Corrupt_Input_Error;
            end if;
            Offset := Natural(Input(In_Pos)) * 256 + Natural(Input(In_Pos + 1));
            In_Pos := In_Pos + 2;

            if Offset = 0 or else Offset > Out_Pos - Output'First then
               raise Corrupt_Input_Error;
            end if;
            if Out_Pos + Match_Len - 1 > Output'Last then
               raise Buffer_Overrun_Error;
            end if;

            for K in 0 .. Match_Len - 1 loop
               Output(Out_Pos + K) := Output(Out_Pos - Offset + K);
            end loop;
            Out_Pos := Out_Pos + Match_Len;
         elsif Tag_Type = 16#C0# then
            if In_Pos + 2 > Input'Last then
               raise Corrupt_Input_Error;
            end if;
            Extra_Len := Natural(Input(In_Pos));
            Offset    := Natural(Input(In_Pos + 1)) * 256 + Natural(Input(In_Pos + 2));
            In_Pos    := In_Pos + 3;

            if Extra_Len = 0 and Offset = 0 then
               exit;
            end if;

            Match_Len := Extra_Len + 35;
            if Offset = 0 or else Offset > Out_Pos - Output'First then
               raise Corrupt_Input_Error;
            end if;
            if Out_Pos + Match_Len - 1 > Output'Last then
               raise Buffer_Overrun_Error;
            end if;

            for K in 0 .. Match_Len - 1 loop
               Output(Out_Pos + K) := Output(Out_Pos - Offset + K);
            end loop;
            Out_Pos := Out_Pos + Match_Len;
         else
            raise Corrupt_Input_Error;
         end if;
      end loop;

      Output_Len := Out_Pos - Output'First;
   end Decompress_LZO1X;

   ----------------------------------------------------------------------------
   -- VARIANT 3: LZO1Y (Optimized for larger block matches)
   ----------------------------------------------------------------------------
   procedure Compress_LZO1Y (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   ) is
      In_Pos       : Natural := Input'First;
      Out_Pos      : Natural := Output'First;
      Lit_Start    : Natural := Input'First;
      Lit_Len      : Natural := 0;
      Match_Offset : Natural;
      Match_Len    : Natural;
   begin
      if Input'Length = 0 then
         if Output'Length < 4 then
            raise Buffer_Overrun_Error;
         end if;
         Output(Output'First .. Output'First + 3) := (16#C0#, 16#00#, 16#00#, 16#00#);
         Output_Len := 4;
         return;
      end if;

      while In_Pos <= Input'Last loop
         Find_Match(Input, In_Pos, 65535, 3, 300, Match_Offset, Match_Len);

         if Match_Len >= 3 then
            if Lit_Len > 0 then
               Flush_Literals(Input, Lit_Start, Lit_Len, Output, Out_Pos);
               Lit_Len := 0;
            end if;

            if Match_Len <= 66 then
               if Out_Pos + 2 > Output'Last then
                  raise Buffer_Overrun_Error;
               end if;
               Output(Out_Pos)     := 16#80# or Byte(Match_Len - 3);
               Output(Out_Pos + 1) := Byte(Match_Offset / 256);
               Output(Out_Pos + 2) := Byte(Match_Offset mod 256);
               Out_Pos := Out_Pos + 3;
            else
               if Out_Pos + 3 > Output'Last then
                  raise Buffer_Overrun_Error;
               end if;
               Output(Out_Pos)     := 16#C0#;
               Output(Out_Pos + 1) := Byte(Match_Len - 67);
               Output(Out_Pos + 2) := Byte(Match_Offset / 256);
               Output(Out_Pos + 3) := Byte(Match_Offset mod 256);
               Out_Pos := Out_Pos + 4;
            end if;

            In_Pos    := In_Pos + Match_Len;
            Lit_Start := In_Pos;
         else
            Lit_Len := Lit_Len + 1;
            In_Pos  := In_Pos + 1;
         end if;
      end loop;

      if Lit_Len > 0 then
         Flush_Literals(Input, Lit_Start, Lit_Len, Output, Out_Pos);
      end if;

      if Out_Pos + 3 > Output'Last then
         raise Buffer_Overrun_Error;
      end if;
      Output(Out_Pos .. Out_Pos + 3) := (16#C0#, 16#00#, 16#00#, 16#00#);
      Out_Pos := Out_Pos + 4;

      Output_Len := Out_Pos - Output'First;
   end Compress_LZO1Y;

   procedure Decompress_LZO1Y (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   ) is
      In_Pos    : Natural := Input'First;
      Out_Pos   : Natural := Output'First;
      Tag       : Byte;
      Tag_Type  : Byte;
      Lit_Len   : Natural;
      Match_Len : Natural;
      Offset    : Natural;
      Extra_Len : Natural;
   begin
      if Input'Length = 0 then
         Output_Len := 0;
         return;
      end if;

      while In_Pos <= Input'Last loop
         Tag      := Input(In_Pos);
         In_Pos   := In_Pos + 1;
         Tag_Type := Tag and 16#C0#;

         if Tag_Type = 16#00# then
            Lit_Len := Natural(Tag and 16#3F#);
            if Lit_Len > 0 then
               if In_Pos + Lit_Len - 1 > Input'Last or else Out_Pos + Lit_Len - 1 > Output'Last then
                  raise Corrupt_Input_Error;
               end if;
               Output(Out_Pos .. Out_Pos + Lit_Len - 1) := Input(In_Pos .. In_Pos + Lit_Len - 1);
               Out_Pos := Out_Pos + Lit_Len;
               In_Pos  := In_Pos + Lit_Len;
            end if;
         elsif Tag_Type = 16#80# then
            Match_Len := Natural(Tag and 16#3F#) + 3;
            if In_Pos + 1 > Input'Last then
               raise Corrupt_Input_Error;
            end if;
            Offset := Natural(Input(In_Pos)) * 256 + Natural(Input(In_Pos + 1));
            In_Pos := In_Pos + 2;

            if Offset = 0 or else Offset > Out_Pos - Output'First or else Out_Pos + Match_Len - 1 > Output'Last then
               raise Corrupt_Input_Error;
            end if;

            for K in 0 .. Match_Len - 1 loop
               Output(Out_Pos + K) := Output(Out_Pos - Offset + K);
            end loop;
            Out_Pos := Out_Pos + Match_Len;
         elsif Tag_Type = 16#C0# then
            if In_Pos + 2 > Input'Last then
               raise Corrupt_Input_Error;
            end if;
            Extra_Len := Natural(Input(In_Pos));
            Offset    := Natural(Input(In_Pos + 1)) * 256 + Natural(Input(In_Pos + 2));
            In_Pos    := In_Pos + 3;

            if Extra_Len = 0 and Offset = 0 then
               exit;
            end if;

            Match_Len := Extra_Len + 67;
            if Offset = 0 or else Offset > Out_Pos - Output'First or else Out_Pos + Match_Len - 1 > Output'Last then
               raise Corrupt_Input_Error;
            end if;

            for K in 0 .. Match_Len - 1 loop
               Output(Out_Pos + K) := Output(Out_Pos - Offset + K);
            end loop;
            Out_Pos := Out_Pos + Match_Len;
         else
            raise Corrupt_Input_Error;
         end if;
      end loop;

      Output_Len := Out_Pos - Output'First;
   end Decompress_LZO1Y;

   ----------------------------------------------------------------------------
   -- VARIANT 4: LZO1Z (Offset recycling variant)
   ----------------------------------------------------------------------------
   procedure Compress_LZO1Z (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   ) is
      In_Pos       : Natural := Input'First;
      Out_Pos      : Natural := Output'First;
      Lit_Start    : Natural := Input'First;
      Lit_Len      : Natural := 0;
      Last_Offset  : Natural := 0;
      Match_Offset : Natural;
      Match_Len    : Natural;
   begin
      if Input'Length = 0 then
         if Output'Length < 4 then
            raise Buffer_Overrun_Error;
         end if;
         Output(Output'First .. Output'First + 3) := (16#C0#, 16#00#, 16#00#, 16#00#);
         Output_Len := 4;
         return;
      end if;

      while In_Pos <= Input'Last loop
         Find_Match(Input, In_Pos, 65535, 2, 255, Match_Offset, Match_Len);

         if Match_Len >= 2 then
            if Lit_Len > 0 then
               Flush_Literals(Input, Lit_Start, Lit_Len, Output, Out_Pos);
               Lit_Len := 0;
            end if;

            if Match_Offset = Last_Offset and Match_Len <= 65 then
               if Out_Pos > Output'Last then
                  raise Buffer_Overrun_Error;
               end if;
               Output(Out_Pos) := 16#40# or Byte(Match_Len - 2);
               Out_Pos := Out_Pos + 1;
            else
               Last_Offset := Match_Offset;
               if Out_Pos + 2 > Output'Last then
                  raise Buffer_Overrun_Error;
               end if;
               Output(Out_Pos)     := 16#80# or Byte(Match_Len - 2);
               Output(Out_Pos + 1) := Byte(Match_Offset mod 256);
               Output(Out_Pos + 2) := Byte(Match_Offset / 256);
               Out_Pos := Out_Pos + 3;
            end if;

            In_Pos    := In_Pos + Match_Len;
            Lit_Start := In_Pos;
         else
            Lit_Len := Lit_Len + 1;
            In_Pos  := In_Pos + 1;
         end if;
      end loop;

      if Lit_Len > 0 then
         Flush_Literals(Input, Lit_Start, Lit_Len, Output, Out_Pos);
      end if;

      if Out_Pos + 3 > Output'Last then
         raise Buffer_Overrun_Error;
      end if;
      Output(Out_Pos .. Out_Pos + 3) := (16#C0#, 16#00#, 16#00#, 16#00#);
      Out_Pos := Out_Pos + 4;

      Output_Len := Out_Pos - Output'First;
   end Compress_LZO1Z;

   procedure Decompress_LZO1Z (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   ) is
      In_Pos      : Natural := Input'First;
      Out_Pos     : Natural := Output'First;
      Last_Offset : Natural := 0;
      Tag         : Byte;
      Tag_Type    : Byte;
      Lit_Len     : Natural;
      Match_Len   : Natural;
      Offset      : Natural;
   begin
      if Input'Length = 0 then
         Output_Len := 0;
         return;
      end if;

      while In_Pos <= Input'Last loop
         Tag      := Input(In_Pos);
         In_Pos   := In_Pos + 1;
         Tag_Type := Tag and 16#C0#;

         if Tag_Type = 16#00# then
            Lit_Len := Natural(Tag and 16#3F#);
            if Lit_Len > 0 then
               if In_Pos + Lit_Len - 1 > Input'Last or else Out_Pos + Lit_Len - 1 > Output'Last then
                  raise Corrupt_Input_Error;
               end if;
               Output(Out_Pos .. Out_Pos + Lit_Len - 1) := Input(In_Pos .. In_Pos + Lit_Len - 1);
               Out_Pos := Out_Pos + Lit_Len;
               In_Pos  := In_Pos + Lit_Len;
            end if;
         elsif Tag_Type = 16#40# then
            Match_Len := Natural(Tag and 16#3F#) + 2;
            Offset    := Last_Offset;
            if Offset = 0 or else Offset > Out_Pos - Output'First or else Out_Pos + Match_Len - 1 > Output'Last then
               raise Corrupt_Input_Error;
            end if;

            for K in 0 .. Match_Len - 1 loop
               Output(Out_Pos + K) := Output(Out_Pos - Offset + K);
            end loop;
            Out_Pos := Out_Pos + Match_Len;
         elsif Tag_Type = 16#80# then
            Match_Len := Natural(Tag and 16#3F#) + 2;
            if In_Pos + 1 > Input'Last then
               raise Corrupt_Input_Error;
            end if;
            Offset      := Natural(Input(In_Pos + 1)) * 256 + Natural(Input(In_Pos));
            In_Pos      := In_Pos + 2;
            Last_Offset := Offset;

            if Offset = 0 or else Offset > Out_Pos - Output'First or else Out_Pos + Match_Len - 1 > Output'Last then
               raise Corrupt_Input_Error;
            end if;

            for K in 0 .. Match_Len - 1 loop
               Output(Out_Pos + K) := Output(Out_Pos - Offset + K);
            end loop;
            Out_Pos := Out_Pos + Match_Len;
         elsif Tag_Type = 16#C0# then
            if In_Pos + 2 > Input'Last then
               raise Corrupt_Input_Error;
            end if;
            Offset := Natural(Input(In_Pos + 2)) * 256 + Natural(Input(In_Pos + 1));
            if Offset = 0 then
               exit;
            end if;
            raise Corrupt_Input_Error;
         end if;
      end loop;

      Output_Len := Out_Pos - Output'First;
   end Decompress_LZO1Z;

   ----------------------------------------------------------------------------
   -- VARIANT 5: LZO_RLE (Pure Explicit Run-Length Filter)
   ----------------------------------------------------------------------------
   procedure Compress_LZO_RLE (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   ) is
      In_Pos    : Natural := Input'First;
      Out_Pos   : Natural := Output'First;
      Run_Val   : Byte;
      Run_Len   : Natural;
      Lit_Start : Natural := Input'First;
      Lit_Len   : Natural := 0;

      procedure Flush_RLE_Literals is
      begin
         if Lit_Len > 0 then
            if Out_Pos + Lit_Len + 1 > Output'Last then
               raise Buffer_Overrun_Error;
            end if;
            Output(Out_Pos) := 16#FE#; -- Literal Block Tag
            Output(Out_Pos + 1) := Byte(Lit_Len);
            Output(Out_Pos + 2 .. Out_Pos + 1 + Lit_Len) := Input(Lit_Start .. Lit_Start + Lit_Len - 1);
            Out_Pos := Out_Pos + 2 + Lit_Len;
            Lit_Len := 0;
         end if;
      end Flush_RLE_Literals;
   begin
      if Input'Length = 0 then
         Output_Len := 0;
         return;
      end if;

      while In_Pos <= Input'Last loop
         Run_Val := Input(In_Pos);
         Run_Len := 0;
         -- Limit run length to 255 to fit in a single 8-bit length field
         while In_Pos + Run_Len <= Input'Last and then Input(In_Pos + Run_Len) = Run_Val and then Run_Len < 255 loop
            Run_Len := Run_Len + 1;
         end loop;

         if Run_Len >= 3 then
            Flush_RLE_Literals;
            if Out_Pos + 2 > Output'Last then
               raise Buffer_Overrun_Error;
            end if;
            Output(Out_Pos)     := 16#FF#; -- RLE Block Tag
            Output(Out_Pos + 1) := Run_Val;
            Output(Out_Pos + 2) := Byte(Run_Len);
            Out_Pos := Out_Pos + 3;
            In_Pos  := In_Pos + Run_Len;
            Lit_Start := In_Pos;
         else
            Lit_Len := Lit_Len + 1;
            In_Pos  := In_Pos + 1;
            -- Limit literal block to 255
            if Lit_Len = 255 then
               Flush_RLE_Literals;
               Lit_Start := In_Pos;
            end if;
         end if;
      end loop;

      Flush_RLE_Literals;
      Output_Len := Out_Pos - Output'First;
   end Compress_LZO_RLE;

   procedure Decompress_LZO_RLE (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   ) is
      In_Pos  : Natural := Input'First;
      Out_Pos : Natural := Output'First;
      Tag     : Byte;
      Len     : Natural;
      Val     : Byte;
   begin
      if Input'Length = 0 then
         Output_Len := 0;
         return;
      end if;

      while In_Pos <= Input'Last loop
         Tag := Input(In_Pos);
         In_Pos := In_Pos + 1;

         if Tag = 16#FF# then
            if In_Pos + 1 > Input'Last then
               raise Corrupt_Input_Error;
            end if;
            Val := Input(In_Pos);
            Len := Natural(Input(In_Pos + 1));
            In_Pos := In_Pos + 2;

            if Out_Pos + Len - 1 > Output'Last then
               raise Buffer_Overrun_Error;
            end if;

            for K in 0 .. Len - 1 loop
               Output(Out_Pos + K) := Val;
            end loop;
            Out_Pos := Out_Pos + Len;

         elsif Tag = 16#FE# then
            if In_Pos > Input'Last then
               raise Corrupt_Input_Error;
            end if;
            Len := Natural(Input(In_Pos));
            In_Pos := In_Pos + 1;

            if Len > 0 then
               if In_Pos + Len - 1 > Input'Last then
                  raise Corrupt_Input_Error;
               end if;
               if Out_Pos + Len - 1 > Output'Last then
                  raise Buffer_Overrun_Error;
               end if;

               Output(Out_Pos .. Out_Pos + Len - 1) := Input(In_Pos .. In_Pos + Len - 1);
               Out_Pos := Out_Pos + Len;
               In_Pos  := In_Pos + Len;
            end if;

         else
            raise Corrupt_Input_Error;
         end if;
      end loop;

      Output_Len := Out_Pos - Output'First;
   end Decompress_LZO_RLE;

end Lempel_Ziv_Oberhumer;
