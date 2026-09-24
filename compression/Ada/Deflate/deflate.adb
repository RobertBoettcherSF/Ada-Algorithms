-- deflate.adb
-- Implementation of the Deflate compression algorithm.

package body Deflate is

   -- Helper: Determine matching length between two stream sections
   function Match_Length (Input : Stream_Element_Array; P1, P2 : Stream_Element_Offset) return Natural is
      Len : Natural := 0;
      Max_Len : constant Natural := 258; -- Deflate max match length
   begin
      while P1 + Stream_Element_Offset(Len) <= Input'Last and then
            P2 + Stream_Element_Offset(Len) <= Input'Last and then
            Input(P1 + Stream_Element_Offset(Len)) = Input(P2 + Stream_Element_Offset(Len)) and then
            Len < Max_Len
      loop
         Len := Len + 1;
      end loop;
      return Len;
   end Match_Length;

   -- LZ77 Encoding implementation (Sliding Window)
   procedure LZ77_Encode 
     (Input  : in  Stream_Element_Array;
      Tokens : out Token_Array;
      Count  : out Natural) 
   is
      Current_Pos : Stream_Element_Offset := Input'First;
      Window_Start : Stream_Element_Offset;
      Best_Match_Len, Best_Match_Dist : Natural;
      Curr_Match_Len : Natural;
   begin
      Count := 0;
      if Input'Length = 0 then
         return;
      end if;

      while Current_Pos <= Input'Last loop
         Best_Match_Len := 0;
         Best_Match_Dist := 0;
         
         -- Calculate sliding window bounds (up to 32KB backwards)
         if Current_Pos > 32768 then
            Window_Start := Current_Pos - 32768;
         else
            Window_Start := Input'First;
         end if;

         -- Search for best match in window
         for J in Window_Start .. Current_Pos - 1 loop
            Curr_Match_Len := Match_Length(Input, J, Current_Pos);
            if Curr_Match_Len > Best_Match_Len and Curr_Match_Len >= 3 then
               Best_Match_Len := Curr_Match_Len;
               Best_Match_Dist := Natural(Current_Pos - J);
            end if;
         end loop;

         Count := Count + 1;
         if Count > Tokens'Last then
            raise Buffer_Overflow;
         end if;

         if Best_Match_Len >= 3 then
            Tokens(Count) := (Kind => Match, Length => Best_Match_Len, Distance => Best_Match_Dist);
            Current_Pos := Current_Pos + Stream_Element_Offset(Best_Match_Len);
         else
            Tokens(Count) := (Kind => Literal, Value => Input(Current_Pos));
            Current_Pos := Current_Pos + 1;
         end if;
      end loop;
   end LZ77_Encode;

   -- Variant 1: Stored Blocks
   procedure Process_Stored_Block 
     (Input  : in  Stream_Element_Array;
      Output : out Stream_Element_Array;
      Last   : out Stream_Element_Offset) 
   is
   begin
      if Input'Length > 65535 then
         raise Deflate_Error with "Stored block exceeds 65535 bytes limit";
      end if;
      if Output'Length < Input'Length + 5 then
         raise Buffer_Overflow;
      end if;
      
      -- Header simulation for Stored Block (BFINAL=1, BTYPE=00)
      Output(Output'First) := 16#01#; 
      Output(Output'First + 1) := Stream_Element(Input'Length mod 256);
      Output(Output'First + 2) := Stream_Element(Input'Length / 256);
      Output(Output'First + 3) := not Output(Output'First + 1); -- NLEN
      Output(Output'First + 4) := not Output(Output'First + 2);
      
      -- Copy literal data
      if Input'Length > 0 then
         Output(Output'First + 5 .. Output'First + 4 + Input'Length) := Input;
      end if;
      Last := Output'First + 4 + Input'Length;
   end Process_Stored_Block;

   -- Variant 2: Static Huffman Blocks
   procedure Process_Static_Block 
     (Input  : in  Stream_Element_Array;
      Output : out Stream_Element_Array;
      Last   : out Stream_Element_Offset) 
   is
      Toks : Token_Array(1 .. Input'Length * 2);
      Tok_Count : Natural;
   begin
      -- Generate LZ77 tokens
      LZ77_Encode(Input, Toks, Tok_Count);
      
      -- In a full implementation, we map Toks to fixed bit codes here.
      -- For this architectural implementation, we simulate the encoded output.
      if Output'Length < Stream_Element_Offset(Tok_Count) + 1 then
         raise Buffer_Overflow;
      end if;
      
      Output(Output'First) := 16#03#; -- Header (BFINAL=1, BTYPE=01)
      Last := Output'First;
      
      for I in 1 .. Tok_Count loop
         Last := Last + 1;
         if Toks(I).Kind = Literal then
            Output(Last) := Toks(I).Value;
         else
            -- Simulated match output for structural validation
            Output(Last) := Stream_Element(Toks(I).Length mod 256); 
         end if;
      end loop;
   end Process_Static_Block;

   -- Variant 3: Dynamic Huffman Blocks
   procedure Process_Dynamic_Block 
     (Input  : in  Stream_Element_Array;
      Output : out Stream_Element_Array;
      Last   : out Stream_Element_Offset) 
   is
      Toks : Token_Array(1 .. Input'Length * 2);
      Tok_Count : Natural;
   begin
      LZ77_Encode(Input, Toks, Tok_Count);
      -- Algorithm placeholder for Dynamic Tree Generation.
      -- True Dynamic Deflate requires 2 passes: one to gather frequency of LZ77 tokens,
      -- another to generate Custom Huffman Trees and write them to the block header.
      -- Here we simulate the dynamic block header format.
      
      if Output'Length < Stream_Element_Offset(Tok_Count) + 2 then
         raise Buffer_Overflow;
      end if;
      
      Output(Output'First) := 16#05#; -- Header (BFINAL=1, BTYPE=10)
      Output(Output'First + 1) := 16#FF#; -- Simulated Tree Data
      Last := Output'First + 1;
      
      for I in 1 .. Tok_Count loop
         Last := Last + 1;
         if Toks(I).Kind = Literal then
            Output(Last) := Toks(I).Value;
         else
            Output(Last) := Stream_Element(Toks(I).Length mod 256);
         end if;
      end loop;
   end Process_Dynamic_Block;

   -- Main Compress Router
   procedure Compress 
     (Input    : in  Stream_Element_Array;
      Output   : out Stream_Element_Array;
      Last     : out Stream_Element_Offset;
      Variant  : in  Compression_Variant := Static_Huffman) 
   is
   begin
      if Input'Length = 0 then
         Last := Output'First - 1;
         return;
      end if;

      case Variant is
         when Stored => Process_Stored_Block(Input, Output, Last);
         when Static_Huffman => Process_Static_Block(Input, Output, Last);
         when Dynamic_Huffman => Process_Dynamic_Block(Input, Output, Last);
      end case;
   end Compress;

   -- Decompress (Stubbed simulation for structural tests)
   procedure Decompress 
     (Input    : in  Stream_Element_Array;
      Output   : out Stream_Element_Array;
      Last     : out Stream_Element_Offset) 
   is
   begin
      if Input'Length = 0 then
         Last := Output'First - 1;
         return;
      end if;
      
      -- Basic parsing of the simulated headers for decompression
      if Input(Input'First) = 16#01# then -- Stored block
         declare
            Len : constant Stream_Element_Offset := Stream_Element_Offset(Input(Input'First + 1)) + 
                                                    Stream_Element_Offset(Input(Input'First + 2)) * 256;
         begin
            if Output'Length < Len then raise Buffer_Overflow; end if;
            Output(Output'First .. Output'First + Len - 1) := Input(Input'First + 5 .. Input'First + 4 + Len);
            Last := Output'First + Len - 1;
         end;
      else
         raise Deflate_Error with "Decompression format not supported in stub";
      end if;
   end Decompress;

end Deflate;
