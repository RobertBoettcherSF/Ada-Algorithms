with Count_Sorted_Vowel_Strings;
procedure Tests is
begin
   pragma Assert (Count_Sorted_Vowel_Strings.Number_Of_Strings (0) = 1);
   pragma Assert (Count_Sorted_Vowel_Strings.Number_Of_Strings (2) = 15);
   pragma Assert (Count_Sorted_Vowel_Strings.Number_Of_Strings (16) = 4_845);
end Tests;
