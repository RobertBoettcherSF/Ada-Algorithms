with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with LZWL; use LZWL;

procedure Main is
   Alphabet : Syllable_Array(1..2) := (To_Unbounded_String("foo"), To_Unbounded_String("bar"));
   Input    : Syllable_Array(1..5) := (To_Unbounded_String("foo"), To_Unbounded_String("bar"), 
                                       To_Unbounded_String("foo"), To_Unbounded_String("bar"), 
                                       To_Unbounded_String("foo"));
   Codes    : Code_Array(1..10);
   Len      : Natural;
begin
   Put_Line ("LZWL Operational Test Run");
   
   Encode_Basic (Alphabet, Input, Codes, Len);
   Put_Line ("=> Basic Variant Stream Encoded Length: " & Len'Image);
   
   Encode_Expanded (Alphabet, Input, Codes, Len);
   Put_Line ("=> Expanded Variant Stream Encoded Length: " & Len'Image);
   
   Put_Line ("Use 'make test' for Verification and Validation Suite");
end Main;
