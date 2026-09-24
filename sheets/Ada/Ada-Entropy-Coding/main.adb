with Ada.Text_IO; use Ada.Text_IO;
with Entropy_Encoding; use Entropy_Encoding;

procedure Main is
   Test_String : constant String := "HELLO WORLD ENTROPY";
   Freqs       : Frequency_Map;
   Huff_Codes  : Encoding_Map;
   Encoded_Txt : String (1 .. 1024);
begin
   Put_Line ("--- Entropy Encoding Demonstration ---");
   Put_Line ("Original String: " & Test_String);
   
   -- 1. Get frequencies
   Freqs := Generate_Frequencies (Test_String);
   
   -- 2. Generate Huffman Codes
   Generate_Huffman_Codes (Freqs, Huff_Codes);
   
   -- 3. Encode
   declare
      Bits : constant String := Encode (Test_String, Huff_Codes);
      Recovered : constant String := Decode (Bits, Huff_Codes);
   begin
      Put_Line ("Encoded Bits:    " & Bits);
      Put_Line ("Decoded String:  " & Recovered);
      if Test_String = Recovered then
         Put_Line ("Status: SUCCESS (Lossless transmission achieved)");
      end if;
   end;
end Main;
