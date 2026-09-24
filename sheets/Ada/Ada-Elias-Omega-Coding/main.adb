-- main.adb
-- Demonstration executable for Elias Omega Coding variants.

with Ada.Text_IO; use Ada.Text_IO;
with Elias_Omega; use Elias_Omega;

procedure Main is
   Test_Values : constant array (Positive range <>) of Positive := (1, 2, 3, 4, 8, 15, 100, 1000);
begin
   Put_Line ("=== Elias Omega Coding Demonstration ===");
   
   Put_Line ("1. Standard Positive Integer Encoding/Decoding:");
   for Val of Test_Values loop
      declare
         Encoded : constant Bit_Array := Encode (Val);
         Idx     : Positive := Encoded'First;
         Decoded : constant Positive := Decode (Encoded, Idx);
      begin
         Put_Line ("  N = " & Positive'Image (Val) & 
                   " -> Code = " & To_String (Encoded) & 
                   " -> Decoded = " & Positive'Image (Decoded));
      end;
   end loop;

   Put_Line ("\n2. Non-Negative Integer Encoding/Decoding:");
   for Val in 0 .. 5 loop
      declare
         Encoded : constant Bit_Array := Encode_Non_Negative (Val);
         Idx     : Positive := Encoded'First;
         Decoded : constant Natural := Decode_Non_Negative (Encoded, Idx);
      begin
         Put_Line ("  N = " & Natural'Image (Val) & 
                   " -> Code = " & To_String (Encoded) & 
                   " -> Decoded = " & Natural'Image (Decoded));
      end;
   end loop;

   Put_Line ("\n3. Signed Integer Encoding/Decoding:");
   for Val in -3 .. 3 loop
      declare
         Encoded : constant Bit_Array := Encode_Signed (Val);
         Idx     : Positive := Encoded'First;
         Decoded : constant Integer := Decode_Signed (Encoded, Idx);
      begin
         Put_Line ("  N = " & Integer'Image (Val) & 
                   " -> Code = " & To_String (Encoded) & 
                   " -> Decoded = " & Integer'Image (Decoded));
      end;
   end loop;
end Main;
