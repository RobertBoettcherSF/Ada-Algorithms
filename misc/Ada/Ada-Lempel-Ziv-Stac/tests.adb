with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Lempel_Ziv_Stac; use Lempel_Ziv_Stac;

procedure Tests is
    function To_Bytes (S : String) return Byte_Array is
        B : Byte_Array (1 .. S'Length);
    begin
        for I in S'Range loop
            B (I - S'First + 1) := Byte (Character'Pos (S (I)));
        end loop;
        return B;
    end To_Bytes;
    
    function To_String (B : Buffer_Type) return String is
        S : String (1 .. B.Length);
    begin
        for I in 1 .. B.Length loop
            S (I) := Character'Val (B.Data (I));
        end loop;
        return S;
    end To_String;

    C_Out, D_Out : Buffer_Type;
begin
    Put_Line ("Starting Test Suite for Lempel-Ziv-Stac");
    Put_Line ("---------------------------------------");

    Put_Line ("TEST 1 - Single Character Compression");
    Put_Line ("  1.1 Assert literal encoding round-trip");
    Compress (To_Bytes ("A"), C_Out);
    Decompress (C_Out, D_Out);
    Assert (To_String (D_Out) = "A", "Expected 'A'");
    Put_Line ("      PASS");

    Put_Line ("TEST 2 - Short String without Matches");
    Put_Line ("  2.1 Assert short literal sequence round-trips");
    Compress (To_Bytes ("Hi"), C_Out);
    Decompress (C_Out, D_Out);
    Assert (To_String (D_Out) = "Hi", "Expected 'Hi'");
    Put_Line ("      PASS");
    
    Put_Line ("TEST 3 - Empty Input (Edge Case)");
    Put_Line ("  3.1 Assert empty input produces just end marker");
    Compress (To_Bytes (""), C_Out);
    -- 9 bits (end marker) padded to 16 bits = 2 bytes.
    Assert (C_Out.Length = 2, "Expected 2 bytes for empty string end marker");
    Put_Line ("      PASS");

    Put_Line ("TEST 4 - Empty Input Decompression");
    Put_Line ("  4.1 Assert decompressing empty stream gives empty output");
    Decompress (C_Out, D_Out);
    Assert (D_Out.Length = 0, "Expected empty output");
    Put_Line ("      PASS");

    Put_Line ("TEST 5 - Simple Match (Offset < 128, Length = 2)");
    Put_Line ("  5.1 Assert match length 2 round-trips");
    Compress (To_Bytes ("ab ab"), C_Out);
    Decompress (C_Out, D_Out);
    Assert (To_String (D_Out) = "ab ab", "Expected 'ab ab'");
    Put_Line ("      PASS");
    
    Put_Line ("TEST 6 - Overlapping Match (Repetition)");
    Put_Line ("  6.1 Assert RLE-like overlapping match is correct");
    Compress (To_Bytes ("AAAAAAAAAA"), C_Out);
    Decompress (C_Out, D_Out);
    Assert (To_String (D_Out) = "AAAAAAAAAA", "Expected 10 'A's");
    Put_Line ("      PASS");

    Put_Line ("TEST 7 - Match Length > 37 (Long Match)");
    Put_Line ("  7.1 Assert N-repeat length encoding works");
    declare
        Long_Str : String (1 .. 100) := (others => 'X');
    begin
        Compress (To_Bytes (Long_Str), C_Out);
        Decompress (C_Out, D_Out);
        Assert (To_String (D_Out) = Long_Str, "Expected 100 'X's");
    end;
    Put_Line ("      PASS");
    
    Put_Line ("TEST 8 - Offset >= 128 (Long Offset)");
    Put_Line ("  8.1 Assert 11-bit offset encoding works");
    declare
        S : String (1 .. 200);
    begin
        for I in 1 .. 150 loop S(I) := Character'Val (I mod 26 + 65); end loop;
        S(151 .. 160) := S(1 .. 10);
        for I in 161 .. 200 loop S(I) := 'B'; end loop;
        Compress (To_Bytes (S), C_Out);
        Decompress (C_Out, D_Out);
        Assert (To_String (D_Out) = S, "Expected correct long offset string");
    end;
    Put_Line ("      PASS");

    Put_Line ("TEST 9 - Maximum Match Limits");
    Put_Line ("  9.1 Assert buffer capacity scales gracefully");
    declare
        Massive : String (1 .. 4000) := (others => 'Z');
    begin
        Compress (To_Bytes (Massive), C_Out);
        Decompress (C_Out, D_Out);
        Assert (To_String (D_Out) = Massive, "Expected 4000 'Z's");
    end;
    Put_Line ("      PASS");

    Put_Line ("TEST 10 - End Marker Alignment Validation");
    Put_Line ("  10.1 Assert output bytes are byte-aligned via padding");
    Compress (To_Bytes ("XYZ"), C_Out);
    Assert (C_Out.Length = 5, "Expected 5 bytes");
    Put_Line ("      PASS");

    Put_Line ("TEST 11 - Decompression Error on Malformed Data");
    Put_Line ("  11.1 Assert missing end marker raises Decompression_Error");
    begin
        C_Out.Length := 1; 
        C_Out.Data(1) := 0;
        Decompress (C_Out, D_Out);
        Assert (False, "Expected Decompression_Error");
    exception
        when Decompression_Error => Put_Line ("      PASS");
    end;

    Put_Line ("TEST 12 - Binary Data Compression");
    Put_Line ("  12.1 Assert non-ASCII bytes round-trip");
    declare
        Bin : Byte_Array (1 .. 5) := (0, 255, 128, 7, 0);
    begin
        Compress (Bin, C_Out);
        Decompress (C_Out, D_Out);
        Assert (D_Out.Length = 5, "Expected 5 bytes");
        Assert (D_Out.Data(1..5) = Bin, "Binary data mismatch");
    end;
    Put_Line ("      PASS");

    Put_Line ("TEST 13 - Mixed Length Encoding Boundaries");
    Put_Line ("  13.1 Assert length 7 and 8 boundaries");
    declare
        S7 : String(1..8) := "A" & "BBBBBBB";
        S8 : String(1..9) := "A" & "BBBBBBBB";
    begin
        Compress(To_Bytes(S7), C_Out); Decompress(C_Out, D_Out); Assert(To_String(D_Out)=S7, "L7");
        Compress(To_Bytes(S8), C_Out); Decompress(C_Out, D_Out); Assert(To_String(D_Out)=S8, "L8");
    end;
    Put_Line ("      PASS");
    
    Put_Line ("TEST 14 - Complex Mixed Data");
    Put_Line ("  14.1 Assert varied matches and literals work flawlessly");
    Compress (To_Bytes ("The quick brown fox jumps over the lazy dog. The quick brown fox!"), C_Out);
    Decompress (C_Out, D_Out);
    Assert (To_String (D_Out) = "The quick brown fox jumps over the lazy dog. The quick brown fox!", "Expected full phrase");
    Put_Line ("      PASS");

    Put_Line ("---------------------------------------");
    Put_Line ("ALL TESTS COMPLETED SUCCESSFULLY");
end Tests;
