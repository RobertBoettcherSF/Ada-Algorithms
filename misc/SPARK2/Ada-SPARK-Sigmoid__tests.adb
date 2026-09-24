with Sigmoid; use Sigmoid;
procedure Tests is
begin
   pragma Assert (Evaluate (-4) = 2);
   pragma Assert (Evaluate (0) = 50);
   pragma Assert (Evaluate (4) = 98);
end Tests;
