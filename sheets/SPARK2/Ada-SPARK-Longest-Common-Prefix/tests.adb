with Ada.Assertions; use Ada.Assertions;
with Longest_Common_Prefix; use Longest_Common_Prefix;
procedure Tests is
   Words : constant Text_Set :=
     ["flower  ", "flow    ", "flight  "];
   Same : constant Text_Set :=
     ["ada     ", "ada     ", "ada     "];
begin
   Assert (Prefix_Length (Words) = 2);
   Assert (Prefix_Length (Same) = 8);
end Tests;
