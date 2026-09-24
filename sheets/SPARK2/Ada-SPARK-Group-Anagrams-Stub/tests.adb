with Ada.Assertions; use Ada.Assertions;
with Group_Anagrams_Stub; use Group_Anagrams_Stub;
procedure Tests is
   Input : constant Word_Set :=
     (1 => (1 => 'e', 2 => 'a', 3 => 't', 4 => 's', 5 => 'x'),
      2 => (1 => 's', 2 => 't', 3 => 'a', 4 => 'x', 5 => 'e'),
      3 => (1 => 'b', 2 => 'a', 3 => 'k', 4 => 'e', 5 => 'r'));
   Answer : constant Labels := Group (Input);
begin
   Assert (Answer (1) = 1);
   Assert (Answer (2) = 1);
   Assert (Answer (3) = 3);
end Tests;
