pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Number_Of_Substrings_Containing_All_Three_Characters; use Number_Of_Substrings_Containing_All_Three_Characters;
procedure Tests is
   A : constant Symbol_Array := (0, 1, 2, 0, 1, 2, 2, 0);
   B : constant Symbol_Array := (0, 0, 0, 1, 1, 1, 2, 2);
begin
   if Number_Of_Substrings_Containing_All_Three_Characters.Count (A) /= 19 then raise Program_Error; end if;
   if Number_Of_Substrings_Containing_All_Three_Characters.Count (B) /= 6 then raise Program_Error; end if;
   Put_Line ("Substrings containing all three characters: PASS");
end Tests;
