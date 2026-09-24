with Ada.Assertions; use Ada.Assertions;
with Remove_Duplicate_Letters; use Remove_Duplicate_Letters;
procedure Tests is
   Input : constant Letters := [0, 1, 0, 2, 1, 3, others => 0];
   Output : Letters;
   Length : Length_Type;
begin
   Keep_First (Input, 6, Output, Length);
   Assert (Length = 4 and Output (1) = 0 and Output (2) = 1);
   Assert (Output (3) = 2 and Output (4) = 3);
end Tests;
