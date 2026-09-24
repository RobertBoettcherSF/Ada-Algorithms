-- main.adb
with Ada.Text_IO;
with Elias_Delta; use Elias_Delta;

procedure Main is
   Val     : constant Positive := 19;
   Encoded : constant String := Encode(Val);
   Decoded : constant Positive := Decode(Encoded);
begin
   Ada.Text_IO.Put_Line("=== Elias Delta Coding Demo ===");
   Ada.Text_IO.Put_Line("Original Value: " & Positive'Image(Val));
   Ada.Text_IO.Put_Line("Encoded Bits:   " & Encoded);
   Ada.Text_IO.Put_Line("Decoded Value:  " & Positive'Image(Decoded));
end Main;
