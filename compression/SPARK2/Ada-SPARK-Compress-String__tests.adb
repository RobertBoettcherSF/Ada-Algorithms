with Ada.Assertions; use Ada.Assertions;
with Compress_String; use Compress_String;
procedure Tests is
begin
   Assert (Compressed_Length ("aabccccc") = 6);
   Assert (Compressed_Length ("abcd    ") = 10);
   Assert (Compressed_Length ("        ") = 2);
end Tests;
