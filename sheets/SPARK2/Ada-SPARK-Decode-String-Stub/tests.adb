with Ada.Assertions; use Ada.Assertions;
with Decode_String_Stub; use Decode_String_Stub;

procedure Tests is
begin
   Assert (Length_Of (3, 4) = 12);
   Assert (Length_Of (2, 3) = 6);
   Assert (Length_Of (1, 1) = 1);
end Tests;
