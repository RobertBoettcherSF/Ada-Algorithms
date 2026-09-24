pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Huffman_Coding; use Huffman_Coding;
procedure Tests is
   Data : constant Symbol_Array :=
     ('a', 'b', 'a', 'c', 'a', 'b', 'a', 'd');
   F : Freq_Map;
begin
   F := Count_Frequencies (Data);
   Assert (F ('a') = 4);
   Assert (F ('b') = 2);
   Assert (Distinct_Count (F) = 4);
   Assert (Most_Frequent (F) = 'a');
   Put_Line ("PASS Huffman_Coding frequency helpers");
   Put_Line ("All Huffman_Coding SPARK topic tests passed.");
end Tests;
