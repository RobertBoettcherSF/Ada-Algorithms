with Integer_Break;
procedure Tests is
begin
   pragma Assert (Integer_Break.Maximum (2) = 1);
   pragma Assert (Integer_Break.Maximum (5) = 6);
   pragma Assert (Integer_Break.Maximum (10) = 36);
end Tests;
