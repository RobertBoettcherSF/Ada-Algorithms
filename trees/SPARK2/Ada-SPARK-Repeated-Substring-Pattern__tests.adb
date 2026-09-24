with Repeated_Substring_Pattern;
procedure Tests is
   Ones : constant Repeated_Substring_Pattern.Text_Array := "aaaaaa";
   Pair : constant Repeated_Substring_Pattern.Text_Array := "ababab";
   Triplet : constant Repeated_Substring_Pattern.Text_Array := "abcabc";
   No : constant Repeated_Substring_Pattern.Text_Array := "abcdef";
begin
   pragma Assert (Repeated_Substring_Pattern.Is_Repeated (Ones));
   pragma Assert (Repeated_Substring_Pattern.Is_Repeated (Pair));
   pragma Assert (Repeated_Substring_Pattern.Is_Repeated (Triplet));
   pragma Assert (not Repeated_Substring_Pattern.Is_Repeated (No));
end Tests;
