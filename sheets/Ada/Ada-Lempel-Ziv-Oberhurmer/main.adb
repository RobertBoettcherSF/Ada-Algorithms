with Ada.Text_IO; use Ada.Text_IO;
with Lempel_Ziv_Oberhumer; use Lempel_Ziv_Oberhumer;

procedure Main is
   Sample_Text : constant String :=
     "LZO compression focuses on extreme speed for decompression. " &
     "LZO compression focuses on extreme speed for decompression. " &
     "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

   Input_Buf   : Byte_Array(1 .. Sample_Text'Length);
   Comp_Buf    : Byte_Array(1 .. Max_Compressed_Size(Sample_Text'Length));
   Decomp_Buf  : Byte_Array(1 .. Sample_Text'Length + 100);

   Comp_Len    : Natural;
   Decomp_Len  : Natural;
   Ratio       : Float;
begin
   Put_Line("=================================================");
   Put_Line(" Lempel-Ziv-Oberhumer (LZO) Algorithm Benchmark ");
   Put_Line("=================================================");
   Put_Line("Original Size: " & Natural'Image(Sample_Text'Length) & " bytes");

   for I in Sample_Text'Range loop
      Input_Buf(I - Sample_Text'First + 1) := Byte(Character'Pos(Sample_Text(I)));
   end loop;

   for Variant in LZO_Variant loop
      Compress(Input_Buf, Comp_Buf, Comp_Len, Variant);
      Decompress(Comp_Buf(1 .. Comp_Len), Decomp_Buf, Decomp_Len, Variant);
      Ratio := Calculate_Compression_Ratio(Input_Buf'Length, Comp_Len);

      Put_Line("-------------------------------------------------");
      Put_Line("Variant        : " & LZO_Variant'Image(Variant));
      Put_Line("Compressed Size: " & Natural'Image(Comp_Len) & " bytes");
      Put_Line("Ratio Saved    : " & Float'Image(Ratio) & " %");
      Put_Line("Match Exact    : " & Boolean'Image(Verify_Equality(Input_Buf, Decomp_Buf(1 .. Decomp_Len))));
   end loop;

   Put_Line("=================================================");
end Main;
