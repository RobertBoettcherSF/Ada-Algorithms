with First_Unique_Char;
procedure Tests is
   Input : constant First_Unique_Char.Text_Array := "swissx";
   Repeated : constant First_Unique_Char.Text_Array := "aabbcc";
   Later : constant First_Unique_Char.Text_Array := "aabccd";
begin
   pragma Assert (First_Unique_Char.Find (Input) = 2);
   pragma Assert (First_Unique_Char.Find (Repeated) = 0);
   pragma Assert (First_Unique_Char.Find (Later) = 3);
end Tests;
