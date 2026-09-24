package body LZJB is

   -- LZJB Algorithm Parameters
   MATCH_MIN  : constant := 3;
   MATCH_MAX  : constant := 66;
   OFFSET_MAX : constant := 1024;

   -- Pre-computed bit masks for O(1) control byte bitwise checks
   Bit_Masks : constant array(0..7) of Byte :=
     (1, 2, 4, 8, 16, 32, 64, 128);

   -- -------------------------------------------------------------------------
   -- Compression Implementation
   -- -------------------------------------------------------------------------
   function Compress (Input : Byte_Array) return Byte_Array is
      -- Calculate worst-case size: original + control bytes + padding
      Max_Out_Size : constant Positive := Input'Length + (Input'Length / 8) + 16;
      Output       : Byte_Array (1 .. Max_Out_Size);
      
      Src : Positive := Input'First;
      Dst : Positive := Output'First;

      -- Simple hash table for dictionary lookups
      type Hash_Array is array (Byte range 0 .. 255) of Integer;
      Hash_Table   : Hash_Array := (others => 0);

      Ctrl_Pos     : Positive;
      Ctrl_Bits    : Byte;
      
      Len          : Natural;
      Offset       : Integer;
      Hash         : Byte;
      Match_Pos    : Integer;
      
      B1, B2       : Byte;
   begin
      if Input'Length = 0 then
         return Input;
      end if;

      while Src <= Input'Last loop
         Ctrl_Pos := Dst;
         Dst := Dst + 1;
         Ctrl_Bits := 0;

         -- Process up to 8 items (literals or matches) per control byte
         for I in 0 .. 7 loop
            if Src > Input'Last then
               exit;
            end if;

            Len := 0;
            -- Find potential Match in sliding window
            if Src + MATCH_MIN - 1 <= Input'Last then
               Hash := (Input(Src) xor Input(Src + 1) xor Input(Src + 2));
               Match_Pos := Hash_Table(Hash);
               Hash_Table(Hash) := Src;

               if Match_Pos > 0 and then Match_Pos >= Input'First then
                  Offset := Src - Match_Pos;
                  
                  if Offset > 0 and then Offset <= OFFSET_MAX and then
                     Input(Match_Pos) = Input(Src) and then
                     Input(Match_Pos + 1) = Input(Src + 1) and then
                     Input(Match_Pos + 2) = Input(Src + 2)
                  then
                     Len := MATCH_MIN;
                     -- Maximize the match length (up to 66 bytes)
                     while Len < MATCH_MAX and then Src + Len <= Input'Last and then Input(Match_Pos + Len) = Input(Src + Len) loop
                        Len := Len + 1;
                     end loop;
                  end if;
               end if;
            end if;

            if Len >= MATCH_MIN then
               -- Set control bit (1 = match)
               Ctrl_Bits := Ctrl_Bits or Bit_Masks(I);
               
               -- Encode length and offset into 2 bytes (LZJB specification)
               B1 := Byte(Len - MATCH_MIN) or (Byte((Offset - 1) / 256) * 64);
               B2 := Byte((Offset - 1) mod 256);
               
               Output(Dst) := B1;
               Output(Dst + 1) := B2;
               Dst := Dst + 2;
               Src := Src + Len;
            else
               -- Literal (Control bit stays 0)
               Output(Dst) := Input(Src);
               Dst := Dst + 1;
               Src := Src + 1;
            end if;
         end loop;
         -- Commit the control byte for this block
         Output(Ctrl_Pos) := Ctrl_Bits;
      end loop;

      return Output (1 .. Dst - 1);
   end Compress;

   -- -------------------------------------------------------------------------
   -- Decompression Implementation
   -- -------------------------------------------------------------------------
   function Decompress (Input : Byte_Array; Expected_Size : Natural) return Byte_Array is
      Output    : Byte_Array (1 .. Expected_Size);
      Src       : Positive;
      Dst       : Positive;
      Ctrl_Bits : Byte;
      Len       : Natural;
      Offset    : Integer;
      B1, B2    : Byte;
   begin
      if Expected_Size = 0 then
         return Output;
      end if;

      if Input'Length = 0 then
         raise LZJB_Error with "Empty input for non-zero expected size";
      end if;

      Src := Input'First;
      Dst := Output'First;

      while Src <= Input'Last and Dst <= Output'Last loop
         Ctrl_Bits := Input(Src);
         Src := Src + 1;

         for I in 0 .. 7 loop
            if Dst > Output'Last then
               exit;
            end if;

            if (Ctrl_Bits and Bit_Masks(I)) /= 0 then
               -- Decoding a Match (2 bytes)
               if Src + 1 > Input'Last then
                  raise LZJB_Error with "Unexpected end of input in match encoding";
               end if;
               
               B1 := Input(Src);
               B2 := Input(Src + 1);
               Src := Src + 2;
               
               -- Reconstruct length and backward offset
               Len := Natural(B1 and 16#3F#) + MATCH_MIN;
               Offset := (Natural(B1 and 16#C0#) / 64) * 256 + Natural(B2) + 1;
               
               if Dst - Offset < Output'First then
                  raise LZJB_Error with "Invalid match offset";
               end if;
               
               if Dst + Len - 1 > Output'Last then
                  raise LZJB_Error with "Match length exceeds expected output size";
               end if;
               
               -- Replicate data from dictionary window (overlap allowed per RLE nature)
               for J in 0 .. Len - 1 loop
                  Output(Dst + J) := Output(Dst - Offset + J);
               end loop;
               Dst := Dst + Len;
            else
               -- Decoding a Literal (1 byte)
               if Src > Input'Last then
                  raise LZJB_Error with "Unexpected end of input in literal encoding";
               end if;
               Output(Dst) := Input(Src);
               Src := Src + 1;
               Dst := Dst + 1;
            end if;
         end loop;
      end loop;

      if Dst <= Output'Last then
         raise LZJB_Error with "Output size less than expected size";
      end if;

      return Output;
   end Decompress;

end LZJB;
