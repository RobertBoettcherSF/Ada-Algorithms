with Ada.Text_IO; use Ada.Text_IO;
with Elias_Gamma_Coding; use Elias_Gamma_Coding;

procedure Main is
   Test_Value : constant Integer := -42;
   Encoded    : Elias_Bit_Stream;
   Decoded    : Integer;
begin
   Put_Line ("=== Elias Gamma Coding Example ===");
   
   Encoded := Encode_Integer (Test_Value);
   Decoded := Decode_Integer (Encoded);
   
   Put_Line ("Original Value : " & Integer'Image(Test_Value));
   Put_Line ("Mapped Stream  : " & To_String(Encoded));
   Put_Line ("Decoded Value  : " & Integer'Image(Decoded));
   
   if Test_Value = Decoded then
      Put_Line ("Status         : SUCCESS (Matched)");
   else
      Put_Line ("Status         : FAILED (Mismatch)");
   end if;
end Main;
