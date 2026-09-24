with Ada.Text_IO; use Ada.Text_IO;
with BWT; use BWT;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

procedure Main is
   Res : BWT_Result;
   Word : constant String := "BANANA";
begin
   Put_Line ("=======================================");
   Put_Line ("Burrows-Wheeler Transform Demo");
   Put_Line ("=======================================");
   Put_Line ("Original Word: " & Word);
   
   -- Demonstrate Variant 1
   Res := Transform (Word);
   Put_Line ("-- Variant 1 (Primary Index) --");
   Put_Line ("BWT String : " & To_String(Res.Transformed_String));
   Put_Line ("Index      : " & Index_Type'Image(Res.Primary_Index));
   Put_Line ("Restored   : " & Inverse_Transform(To_String(Res.Transformed_String), Res.Primary_Index));
   
   -- Demonstrate Variant 2
   declare
      BWT_Str : constant String := Transform_Marker(Word, '$');
   begin
      Put_Line ("-- Variant 2 (EOF Marker) --");
      Put_Line ("BWT String : " & BWT_Str);
      Put_Line ("Restored   : " & Inverse_Transform_Marker(BWT_Str, '$'));
   end;
   Put_Line ("=======================================");
end Main;
