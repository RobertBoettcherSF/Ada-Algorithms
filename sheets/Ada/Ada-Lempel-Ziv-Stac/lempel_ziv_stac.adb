package body Lempel_Ziv_Stac is

    -------------------------
    -- Bit Stream Handlers --
    -------------------------
    type Bit_Writer is record
        Buffer   : Byte_Array(1 .. Max_Buffer_Size);
        Byte_Pos : Positive := 1;
        Bit_Pos  : Integer range 0 .. 7 := 7;
    end record;

    procedure Write_Bit (Writer : in out Bit_Writer; B : in Boolean) is
    begin
        if Writer.Byte_Pos > Max_Buffer_Size then
            raise Buffer_Overflow;
        end if;
        
        if B then
            -- Explicitly cast the integer literal to our modular Byte type for bitwise OR
            Writer.Buffer(Writer.Byte_Pos) := Writer.Buffer(Writer.Byte_Pos) or Byte(2 ** Writer.Bit_Pos);
        end if;
        
        if Writer.Bit_Pos = 0 then
            Writer.Byte_Pos := Writer.Byte_Pos + 1;
            Writer.Bit_Pos := 7;
            if Writer.Byte_Pos <= Max_Buffer_Size then
                Writer.Buffer(Writer.Byte_Pos) := 0; -- initialize fresh byte
            end if;
        else
            Writer.Bit_Pos := Writer.Bit_Pos - 1;
        end if;
    end Write_Bit;

    procedure Write_Bits (Writer : in out Bit_Writer; Value : in Natural; Count : in Positive) is
    begin
        for I in reverse 0 .. Count - 1 loop
            -- Use mathematical division and modulo to extract the bit without using 'and' on a Natural
            Write_Bit(Writer, (Value / (2 ** I)) mod 2 /= 0);
        end loop;
    end Write_Bits;

    type Bit_Reader is record
        Buffer   : Byte_Array(1 .. Max_Buffer_Size);
        Max_Len  : Natural;
        Byte_Pos : Positive := 1;
        Bit_Pos  : Integer range 0 .. 7 := 7;
    end record;

    function Read_Bit (Reader : in out Bit_Reader) return Boolean is
        Result : Boolean;
    begin
        if Reader.Byte_Pos > Reader.Max_Len then
            raise Decompression_Error;
        end if;
        
        -- Explicitly cast the integer literal to Byte for the bitwise AND
        Result := (Reader.Buffer(Reader.Byte_Pos) and Byte(2 ** Reader.Bit_Pos)) /= 0;
        
        if Reader.Bit_Pos = 0 then
            Reader.Byte_Pos := Reader.Byte_Pos + 1;
            Reader.Bit_Pos := 7;
        else
            Reader.Bit_Pos := Reader.Bit_Pos - 1;
        end if;
        return Result;
    end Read_Bit;

    function Read_Bits (Reader : in out Bit_Reader; Count : Positive) return Natural is
        Result : Natural := 0;
    begin
        for I in reverse 0 .. Count - 1 loop
            if Read_Bit(Reader) then
                Result := Result + (2 ** I);
            end if;
        end loop;
        return Result;
    end Read_Bits;

    --------------------------
    -- LZ77 Dictionary Core --
    --------------------------
    procedure Find_Match(Input : in Byte_Array; Current_Pos : in Positive; Match_Offset : out Natural; Match_Length : out Natural) is
        Max_Len      : Natural := 0;
        Best_Offset  : Natural := 0;
        Start_Search : Positive;
    begin
        -- LZS uses a 2048-byte sliding window
        if Current_Pos - Input'First <= 2048 then
            Start_Search := Input'First;
        else
            Start_Search := Current_Pos - 2048;
        end if;
        
        for I in Start_Search .. Current_Pos - 1 loop
            declare
                Len : Natural := 0;
            begin
                -- Check continuous overlap (allows lengths greater than offset for RLE)
                while Current_Pos + Len <= Input'Last and then Input(I + Len) = Input(Current_Pos + Len) loop
                    Len := Len + 1;
                end loop;
                
                if Len > Max_Len then
                    Max_Len := Len;
                    Best_Offset := Current_Pos - I;
                end if;
            end;
        end loop;
        
        -- LZS threshold for a beneficial match is 2 bytes
        if Max_Len >= 2 then
            Match_Length := Max_Len;
            Match_Offset := Best_Offset;
        else
            Match_Length := 0;
            Match_Offset := 0;
        end if;
    end Find_Match;

    procedure Write_Length(Writer : in out Bit_Writer; Len : in Positive) is
    begin
        if Len = 2 then Write_Bits(Writer, 0, 2);       -- 00
        elsif Len = 3 then Write_Bits(Writer, 1, 2);    -- 01
        elsif Len = 4 then Write_Bits(Writer, 2, 2);    -- 10
        elsif Len = 5 then Write_Bits(Writer, 12, 4);   -- 1100
        elsif Len = 6 then Write_Bits(Writer, 13, 4);   -- 1101
        elsif Len = 7 then Write_Bits(Writer, 14, 4);   -- 1110
        else
            declare
                N       : Natural := (Len + 7) / 15;
                Rem_Val : Natural := Len - (N * 15 - 7);
            begin
                for I in 1 .. N loop
                    Write_Bits(Writer, 15, 4); -- Print '1111' N times
                end loop;
                Write_Bits(Writer, Rem_Val, 4);
            end;
        end if;
    end Write_Length;

    --------------------------
    -- Variant: Compression --
    --------------------------
    procedure Compress (Input : in Byte_Array; Output : out Buffer_Type) is
        Writer       : Bit_Writer;
        Pos          : Positive := Input'First;
        Match_Offset : Natural;
        Match_Length : Natural;
    begin
        Writer.Buffer(Writer.Byte_Pos) := 0;
        
        if Input'Length > 0 then
            while Pos <= Input'Last loop
                Find_Match(Input, Pos, Match_Offset, Match_Length);
                if Match_Length >= 2 then
                    Write_Bit(Writer, True); -- 1: match ref
                    if Match_Offset < 128 then
                        Write_Bit(Writer, True);
                        Write_Bits(Writer, Match_Offset, 7);
                    else
                        Write_Bit(Writer, False);
                        Write_Bits(Writer, Match_Offset, 11);
                    end if;
                    Write_Length(Writer, Match_Length);
                    Pos := Pos + Match_Length;
                else
                    Write_Bit(Writer, False); -- 0: literal
                    Write_Bits(Writer, Natural(Input(Pos)), 8);
                    Pos := Pos + 1;
                end if;
            end loop;
        end if;
        
        -- End marker (110000000) mapped via 9 bits representing decimal 384
        Write_Bits(Writer, 384, 9);
        
        -- Pad to byte boundary
        while Writer.Bit_Pos /= 7 loop
            Write_Bit(Writer, False);
        end loop;
        
        Output.Data(1 .. Writer.Byte_Pos - 1) := Writer.Buffer(1 .. Writer.Byte_Pos - 1);
        Output.Length := Writer.Byte_Pos - 1;
    end Compress;

    ----------------------------
    -- Variant: Decompression --
    ----------------------------
    procedure Decompress (Input : in Buffer_Type; Output : out Buffer_Type) is
        Reader       : Bit_Reader := (Buffer => Input.Data, Max_Len => Input.Length, Byte_Pos => 1, Bit_Pos => 7);
        Out_Pos      : Positive := 1;
        Is_Match     : Boolean;
        Match_Offset : Natural;
        Match_Length : Natural;
    begin
        if Input.Length = 0 then
            Output.Length := 0;
            return;
        end if;

        loop
            Is_Match := Read_Bit(Reader);
            if not Is_Match then
                -- Decode Literal
                if Out_Pos > Max_Buffer_Size then raise Buffer_Overflow; end if;
                Output.Data(Out_Pos) := Byte(Read_Bits(Reader, 8));
                Out_Pos := Out_Pos + 1;
            else
                -- Decode Match or End Marker
                if Read_Bit(Reader) then
                    Match_Offset := Read_Bits(Reader, 7);
                    if Match_Offset = 0 then
                        exit; -- Offset 0 is hijacked for the End Marker in LZS
                    end if;
                else
                    Match_Offset := Read_Bits(Reader, 11);
                    if Match_Offset = 0 then raise Decompression_Error; end if;
                end if;
                
                if Match_Offset >= Out_Pos then
                    raise Decompression_Error;
                end if;
                
                -- Read Multi-Tier Length Code
                declare
                    Len_Code : Natural := Read_Bits(Reader, 2);
                begin
                    if Len_Code = 0 then Match_Length := 2;
                    elsif Len_Code = 1 then Match_Length := 3;
                    elsif Len_Code = 2 then Match_Length := 4;
                    else
                        Len_Code := Read_Bits(Reader, 2);
                        if Len_Code = 0 then Match_Length := 5;
                        elsif Len_Code = 1 then Match_Length := 6;
                        elsif Len_Code = 2 then Match_Length := 7;
                        else
                            declare
                                N : Natural := 0;
                                X : Natural;
                            begin
                                loop
                                    X := Read_Bits(Reader, 4);
                                    if X = 15 then
                                        N := N + 1;
                                    else
                                        Match_Length := X + N * 15 + 8;
                                        exit;
                                    end if;
                                end loop;
                            end;
                        end if;
                    end if;
                end;
                
                -- Extract Dictionary Match
                for I in 1 .. Match_Length loop
                    if Out_Pos > Max_Buffer_Size then raise Buffer_Overflow; end if;
                    Output.Data(Out_Pos) := Output.Data(Out_Pos - Match_Offset);
                    Out_Pos := Out_Pos + 1;
                end loop;
            end if;
        end loop;
        
        Output.Length := Out_Pos - 1;
    end Decompress;

end Lempel_Ziv_Stac;
