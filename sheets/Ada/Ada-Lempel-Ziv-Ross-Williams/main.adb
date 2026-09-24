with Ada.Text_IO; use Ada.Text_IO;
with Ada.Streams; use Ada.Streams;
with LZRW; use LZRW;

procedure Main is
   Input_Data  : Stream_Element_Array := (65, 66, 67, 65, 66, 67); -- "ABCABC"
   Comp_Data   : Stream_Element_Array (1 .. 1024);
   Decomp_Data : Stream_Element_Array (1 .. 1024);
   Comp_Size   : Natural;
   Decomp_Size : Natural;
begin
   Put_Line ("LZRW Compression Algorithm Variant Simulator");
   Put_Line ("Evaluating standard data stream...");
   
   Compress (Input_Data, Comp_Data, Comp_Size, Variant => LZRW1);
   Put_Line ("Original Array Size: " & Natural'Image (Input_Data'Length));
   Put_Line ("Compressed Array Size: " & Natural'Image (Comp_Size));
   
   Decompress (Comp_Data (1 .. Stream_Element_Offset(Comp_Size)), Decomp_Data, Decomp_Size, Variant => LZRW1);
   
   if Decomp_Size = Input_Data'Length and then Decomp_Data (1 .. Stream_Element_Offset(Decomp_Size)) = Input_Data then
      Put_Line ("System Check PASS: Decompressed buffer identical to Original.");
   else
      Put_Line ("System Check ERROR: Lossless condition failed.");
   end if;
end Main;
