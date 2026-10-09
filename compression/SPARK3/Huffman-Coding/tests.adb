pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Huffman_Coding; use Huffman_Coding;
with Own_Checks;
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

   --  Same data stored at other origins: storage may start anywhere
   --  (5, 200, ending at Positive'Last) and an empty array may start at 9.
   declare
      D5   : Symbol_Array (5 .. 12);
      D200 : Symbol_Array (200 .. 207);
      DTop : Symbol_Array (Positive'Last - 7 .. Positive'Last);
      Empty : constant Symbol_Array (9 .. 8) := [others => 'a'];
      G : Freq_Map;
   begin
      for K in 0 .. 7 loop
         D5 (5 + K) := Data (Data'First + K);
         D200 (200 + K) := Data (Data'First + K);
         DTop (DTop'First + K) := Data (Data'First + K);
      end loop;
      Assert (Count_Frequencies (D5) = F);
      Assert (Count_Frequencies (D200) = F);
      Assert (Count_Frequencies (DTop) = F);
      G := Count_Frequencies (Empty);
      Assert (G = [Symbol => 0]);
      Assert (Distinct_Count (G) = 0);
   end;
   Put_Line ("PASS Huffman_Coding shifted origins (5, 200, Positive'Last, empty at 9)");
   Own_Checks;
end Tests;
