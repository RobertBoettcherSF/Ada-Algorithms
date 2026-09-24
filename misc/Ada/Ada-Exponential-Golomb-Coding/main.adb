with Ada.Text_IO; use Ada.Text_IO;
with Exponential_Golomb; use Exponential_Golomb;

procedure Main is
   Value    : constant Natural := 42;
   Encoded  : constant Bit_String := Encode_Order_0_Unsigned (Value);
   Consumed : Natural;
begin
   Put_Line ("Exponential-Golomb Coding Demonstrator");
   Put_Line ("--------------------------------------");
   Put_Line ("Original Value (Order-0 Unsigned): " & Natural'Image (Value));
   Put_Line ("Encoded Bit Stream:                " & Encoded);
   Put_Line ("Decoded Value:                     " & Natural'Image (Decode_Order_0_Unsigned (Encoded, Consumed)));
   Put_Line ("Bits Consumed:                     " & Natural'Image (Consumed));
end Main;
