with Ada.Assertions; use Ada.Assertions;
with Fizz_Buzz; use Fizz_Buzz;
procedure Tests is
begin
   Assert (Classify (1) = Number);
   Assert (Classify (3) = Fizz);
   Assert (Classify (5) = Buzz);
   Assert (Classify (15) = FizzBuzz);
   Assert (Classify (100) = Buzz);
end Tests;
