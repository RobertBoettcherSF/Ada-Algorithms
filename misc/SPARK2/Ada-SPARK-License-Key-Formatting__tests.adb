with License_Key_Formatting;
use type License_Key_Formatting.Formatted_Array;
procedure Tests is
   Input : constant License_Key_Formatting.Key_Array := "ABCDEF";
   Expected : constant License_Key_Formatting.Formatted_Array := "AB-CD-EF";
begin
   pragma Assert (License_Key_Formatting.Format (Input) = Expected);
end Tests;
