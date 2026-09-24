with Ada.Assertions; use Ada.Assertions;
with Implement_StrStr; use Implement_StrStr;
procedure Tests is
begin
   Assert (Find ("hello world     ", "worl") = 7);
   Assert (Find ("aaaaabcdefgh    ", "abcd") = 5);
   Assert (Find ("abcdefghijklmnop", "zzzz") = 0);
end Tests;
