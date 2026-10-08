pragma Ada_2022;
with Repeated_Substring_Pattern;
procedure Tests is
   package R renames Repeated_Substring_Pattern;
   Ones    : constant R.Text_Array := "aaaaaa";
   Pair    : constant R.Text_Array := "ababab";
   Triplet : constant R.Text_Array := "abcabc";
   No      : constant R.Text_Array := "abcdef";
   AAB     : constant R.Text_Array := "aabaab";
   Mixed   : constant R.Text_Array := "abcabd";
   --  Near-misses: one cell breaks each period (kills single-comparison flips)
   Lone_B2 : constant R.Text_Array := "abaaaa";
   Lone_B4 : constant R.Text_Array := "aaabaa";
   Lone_B6 : constant R.Text_Array := "ababaa";
begin
   pragma Assert (R.Is_Repeated (Ones));
   pragma Assert (R.Is_Repeated (Pair));
   pragma Assert (R.Is_Repeated (Triplet));
   pragma Assert (not R.Is_Repeated (No));
   pragma Assert (R.Is_Repeated (AAB));
   pragma Assert (not R.Is_Repeated (Mixed));
   pragma Assert (not R.Is_Repeated (Lone_B2));
   pragma Assert (not R.Is_Repeated (Lone_B4));
   pragma Assert (not R.Is_Repeated (Lone_B6));
end Tests;
