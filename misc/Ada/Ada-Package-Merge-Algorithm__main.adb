with Ada.Text_IO; use Ada.Text_IO;
with Package_Merge; use Package_Merge;

procedure Main is
   Freqs : constant Symbol_Frequencies(1..4) := (1.0, 1.0, 2.0, 2.0);
   Lengths : Code_Lengths(1..4);
begin
   Put_Line("Package-Merge Algorithm Demonstration");
   Put_Line("Input Frequencies: 1.0, 1.0, 2.0, 2.0");
   
   Lengths := Space_Efficient_Huffman(Freqs, 3);
   Put_Line("Generated Space-Efficient Lengths (Max Depth = 3):");
   for I in Lengths'Range loop
      Put_Line("Symbol " & I'Image & " length: " & Lengths(I)'Image);
   end loop;
end Main;
