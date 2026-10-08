with Ada.Assertions; use Ada.Assertions;
with String_Compression; use String_Compression;
with Own_Checks;
procedure Tests is
   Input : Text := [others => ' '];
   Output : Text;
   Counts : Run_Counts;
   Length : Length_Type;
begin
   Input (1 .. 7) := "aabcccc";
   Compress (Input, 7, Output, Counts, Length);
   Assert (Length = 3);
   Assert (Output (1 .. 3) = "abc");
   Assert (Counts (1) = 2 and then Counts (2) = 1 and then Counts (3) = 4);
   Own_Checks;
end Tests;
