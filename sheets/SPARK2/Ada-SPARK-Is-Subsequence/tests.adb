with Is_Subsequence;
procedure Tests is
begin
   pragma Assert (Is_Subsequence.Check ("", "abc"));
   pragma Assert (Is_Subsequence.Check ("a", "ahbgdc"));
   pragma Assert (not Is_Subsequence.Check ("z", "abc"));
end Tests;
