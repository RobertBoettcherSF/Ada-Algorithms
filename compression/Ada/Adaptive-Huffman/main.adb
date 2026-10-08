-- main.adb
with Ada.Text_IO; use Ada.Text_IO;
with Adaptive_Huffman; use Adaptive_Huffman;

procedure Main is
   Original : constant String := "Adaptive Huffman Coding in Ada!";
   Encoded_FGK : constant String := Encode(Original, FGK);
   Encoded_Vitter : constant String := Encode(Original, Vitter);
begin
   Put_Line ("Original Text: " & Original);
   Put_Line ("========================================");
   Put_Line ("Encoded (FGK): " & Encoded_FGK);
   Put_Line ("Decoded (FGK): " & Decode(Encoded_FGK, FGK));
   Put_Line ("========================================");
   Put_Line ("Encoded (Vitter): " & Encoded_Vitter);
   Put_Line ("Decoded (Vitter): " & Decode(Encoded_Vitter, Vitter));
end Main;
