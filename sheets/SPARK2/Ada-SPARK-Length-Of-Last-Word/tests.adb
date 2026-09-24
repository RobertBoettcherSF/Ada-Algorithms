with Ada.Assertions; use Ada.Assertions;
with Length_Of_Last_Word; use Length_Of_Last_Word;
procedure Tests is
begin
   Assert (Last_Length ("hello world             ") = 5);
   Assert (Last_Length ("fly me to the moon      ") = 4);
   Assert (Last_Length ("                        ") = 0);
end Tests;
