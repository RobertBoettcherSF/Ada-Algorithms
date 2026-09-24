with Ada.Assertions; use Ada.Assertions;
with Reduce_Array_Size_To_The_Half; use Reduce_Array_Size_To_The_Half;
procedure Tests is
begin
   Assert (Groups_To_Remove (0, 0) = 0);
   Assert (Groups_To_Remove (10, 5) = 1);
   Assert (Groups_To_Remove (10, 3) = 2);
end Tests;
