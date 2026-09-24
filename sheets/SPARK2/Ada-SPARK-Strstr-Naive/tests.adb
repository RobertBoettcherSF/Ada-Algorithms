with Ada.Assertions; use Ada.Assertions;
with Strstr_Naive; use Strstr_Naive;
procedure Tests is
   Text : constant Text_Array := "THE QUICK FO";
   Found : constant Pattern_Array := "QUI";
   Missing : constant Pattern_Array := "ZZZ";
begin
   Assert (Search (Text, Found) = 5);
   Assert (Search (Text, Missing) = 0);
end Tests;
