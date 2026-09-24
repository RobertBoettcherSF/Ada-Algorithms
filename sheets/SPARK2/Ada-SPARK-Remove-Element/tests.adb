with Ada.Assertions; use Ada.Assertions;
with Remove_Element; use Remove_Element;

procedure Tests is
   Data : Values := (1 => 3, 2 => 2, 3 => 2, 4 => 3, 5 => 4, others => 0);
   Length : Length_Type := 5;
begin
   Remove (Data, Length, 3);
   Assert (Length = 3 and Data (1) = 2 and Data (2) = 2 and Data (3) = 4);
end Tests;
