package body LZSS is

   -- Helper: Searches the sliding window to find the longest matching sequence
   function Find_Match (Input : Byte_Array; Current_Pos : Positive) return Token is
      Max_Len      : Natural := 0;
      Best_Dist    : Positive := 1;
      Search_Start : Positive;
      Len          : Natural;
   begin
      -- Determine how far back we can look (bound by Window_Size and array start)
      if Current_Pos > Window_Size and then Current_Pos - Window_Size >= Input'First then
         Search_Start := Current_Pos - Window_Size;
      else
         Search_Start := Input'First;
      end if;

      -- O(N^2) search within the window for the longest match.
      for I in Search_Start .. Current_Pos - 1 loop
         Len := 0;
         -- Extend the match length up to Lookahead_Size boundaries
         while Len < Lookahead_Size and then
               Current_Pos + Len <= Input'Last and then
               Input (I + Len) = Input (Current_Pos + Len)
         loop
            Len := Len + 1;
         end loop;

         if Len > Max_Len then
            Max_Len := Len;
            Best_Dist := Current_Pos - I;
         end if;
      end loop;

      -- Emit Reference token if match exceeds minimum threshold, else Literal.
      if Max_Len >= Min_Match then
         return (Kind => Reference, Distance => Best_Dist, Length => Max_Len);
      else
         return (Kind => Literal, Value => Input (Current_Pos));
      end if;
   end Find_Match;

   -- =========================================================================
   -- VARIANT 1 IMPLEMENTATION
   -- =========================================================================
   procedure Compress_Logical (Input  : in  Byte_Array;
                               Output : out Token_Array;
                               Count  : out Natural) is
      I : Positive := Input'First;
      T : Token;
   begin
      Count := 0;
      if Input'Length = 0 then
         return;
      end if;

      while I <= Input'Last loop
         T := Find_Match (Input, I);
         Count := Count + 1;
         
         if Count > Output'Last then
            raise Compression_Error with "Logical output array bounded too small";
         end if;
         Output (Count) := T;

         if T.Kind = Literal then
            I := I + 1;
         else
            I := I + T.Length;
         end if;
      end loop;
   end Compress_Logical;

   procedure Decompress_Logical (Input  : in  Token_Array;
                                 Output : out Byte_Array;
                                 Count  : out Natural) is
      Out_Pos  : Positive := Output'First;
      Copy_Pos : Positive;
   begin
      Count := 0;
      for I in Input'Range loop
         if Input(I).Kind = Literal then
            if Out_Pos > Output'Last then
               raise Compression_Error with "Output array too small";
            end if;
            Output (Out_Pos) := Input(I).Value;
            Out_Pos := Out_Pos + 1;
         else
            -- Validate referencing distance
            if Out_Pos - Input(I).Distance < Output'First then
               raise Compression_Error with "Malformed token: Distance references before start";
            end if;
            
            Copy_Pos := Out_Pos - Input(I).Distance;
            for J in 1 .. Input(I).Length loop
               if Out_Pos > Output'Last then
                  raise Compression_Error with "Output array too small";
               end if;
               Output (Out_Pos) := Output (Copy_Pos);
               Out_Pos := Out_Pos + 1;
               Copy_Pos := Copy_Pos + 1;
            end loop;
         end if;
      end loop;
      Count := Out_Pos - Output'First;
   end Decompress_Logical;

   -- =========================================================================
   -- VARIANT 2 IMPLEMENTATION (Binary Bit Packing)
   -- =========================================================================
   
   -- Helper structure to handle individual bit streaming across byte boundaries
   type Bit_Buffer (Max_Bytes : Natural) is record
      Data    : Byte_Array (1 .. Max_Bytes);
      Bit_Pos : Natural := 0;
   end record;

   procedure Write_Bits (Buf : in out Bit_Buffer; Value : Natural; Bits : Natural) is
   begin
      for B in reverse 0 .. Bits - 1 loop
         declare
            Target_Byte : constant Positive := (Buf.Bit_Pos / 8) + 1;
            Target_Bit  : constant Natural := 7 - (Buf.Bit_Pos mod 8);
            Bit_Val     : constant Natural := (Value / (2 ** B)) mod 2;
         begin
            if Bit_Val = 1 then
               Buf.Data (Target_Byte) := Buf.Data (Target_Byte) or Byte (2 ** Target_Bit);
            else
               Buf.Data (Target_Byte) := Buf.Data (Target_Byte) and not Byte (2 ** Target_Bit);
            end if;
            Buf.Bit_Pos := Buf.Bit_Pos + 1;
         end;
      end loop;
   end Write_Bits;

   function Read_Bits (Buf : in out Bit_Buffer; Bits : Natural) return Natural is
      Result : Natural := 0;
   begin
      for B in 1 .. Bits loop
         declare
            Source_Byte : constant Positive := (Buf.Bit_Pos / 8) + 1;
            Source_Bit  : constant Natural := 7 - (Buf.Bit_Pos mod 8);
            Bit_Val     : constant Byte := (Buf.Data (Source_Byte) / Byte (2 ** Source_Bit)) mod 2;
         begin
            Result := (Result * 2) + Natural (Bit_Val);
            Buf.Bit_Pos := Buf.Bit_Pos + 1;
         end;
      end loop;
      return Result;
   end Read_Bits;

   function Compress (Input : Byte_Array) return Byte_Array is
      -- Safe upper bound estimation for worst-case incompressible data.
      Worst_Case  : constant Natural := Input'Length * 2 + 10;
      Buf         : Bit_Buffer (Worst_Case);
      I           : Positive := Input'First;
      T           : Token;
      Total_Bytes : Natural;
   begin
      if Input'Length = 0 then
         return Buf.Data(1 .. 0);
      end if;
      
      Buf.Data := (others => 0); -- Initialize zeroes for predictable bitwise ORs

      while I <= Input'Last loop
         T := Find_Match (Input, I);
         if T.Kind = Literal then
            Write_Bits (Buf, 1, 1); -- '1' Flag indicates a literal byte follows
            Write_Bits (Buf, Natural (T.Value), 8);
            I := I + 1;
         else
            Write_Bits (Buf, 0, 1); -- '0' Flag indicates a reference follows
            Write_Bits (Buf, T.Distance - 1, 12); -- Distance encoded as 0..4095
            Write_Bits (Buf, T.Length - Min_Match, 4); -- Length encoded as 0..15
            I := I + T.Length;
         end if;
      end loop;

      Total_Bytes := (Buf.Bit_Pos + 7) / 8;
      return Buf.Data (1 .. Total_Bytes);
   end Compress;

   function Decompress (Input : Byte_Array; Original_Size : Natural) return Byte_Array is
      Buf      : Bit_Buffer (Input'Length + 2);
      Output   : Byte_Array (1 .. Original_Size);
      Out_Pos  : Positive := 1;
      Flag     : Natural;
      Dist     : Natural;
      Len      : Natural;
      Copy_Pos : Positive;
   begin
      if Original_Size = 0 then
         return Output;
      end if;

      Buf.Data(1 .. Input'Length) := Input;

      while Out_Pos <= Original_Size loop
         -- Validate stream size before attempting to read the flag bit
         if Buf.Bit_Pos + 1 > Input'Length * 8 then
            raise Compression_Error with "Unexpected end of bit stream (missing flag)";
         end if;

         Flag := Read_Bits (Buf, 1);
         if Flag = 1 then
            -- Validate stream size before attempting to read literal
            if Buf.Bit_Pos + 8 > Input'Length * 8 then
               raise Compression_Error with "Unexpected end of bit stream (missing literal)";
            end if;
            Output (Out_Pos) := Byte (Read_Bits (Buf, 8));
            Out_Pos := Out_Pos + 1;
         else
            -- Validate stream size before attempting to read distance and length
            if Buf.Bit_Pos + 16 > Input'Length * 8 then
               raise Compression_Error with "Unexpected end of bit stream (missing reference)";
            end if;
            Dist := Read_Bits (Buf, 12) + 1;
            Len  := Read_Bits (Buf, 4) + Min_Match;

            if Out_Pos - Dist < Output'First then
               raise Compression_Error with "Decompression fault: Distance reference invalid";
            end if;
            Copy_Pos := Out_Pos - Dist;

            for J in 1 .. Len loop
               if Out_Pos > Original_Size then
                  raise Compression_Error with "Decompression overflow: Stream specifies larger output";
               end if;
               Output (Out_Pos) := Output (Copy_Pos);
               Out_Pos := Out_Pos + 1;
               Copy_Pos := Copy_Pos + 1;
            end loop;
         end if;
      end loop;

      return Output;
   end Decompress;

end LZSS;
