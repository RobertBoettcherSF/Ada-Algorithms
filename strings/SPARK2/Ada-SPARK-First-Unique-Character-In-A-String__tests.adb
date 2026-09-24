with First_Unique_Character_In_A_String;
procedure Tests is
   Input : constant First_Unique_Character_In_A_String.Text_Array := "swissx";
   Repeated : constant First_Unique_Character_In_A_String.Text_Array := "aabbcc";
   Later : constant First_Unique_Character_In_A_String.Text_Array := "aabccd";
begin
   pragma Assert (First_Unique_Character_In_A_String.Find (Input) = 2);
   pragma Assert (First_Unique_Character_In_A_String.Find (Repeated) = 0);
   pragma Assert (First_Unique_Character_In_A_String.Find (Later) = 3);
end Tests;
