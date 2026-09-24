with Ada.Text_IO; use Ada.Text_IO;
with Hamming_Distance; use Hamming_Distance;

procedure Main is
begin
   Put_Line ("=== Hamming Distance Algorithm Implementation ===");
   Put_Line ("Example (Wikipedia): 'karolin' vs 'kathrin'");
   Put_Line ("Distance: " & Integer'Image (Distance ("karolin", "kathrin")));
   Put_Line ("");
   Put_Line ("Run 'make test' to execute the formal verification suite.");
end Main;
