with Largest_Number;
procedure Tests is
begin
   pragma Assert (Largest_Number.Largest_Concatenation (9, 3) = 93);
   pragma Assert (Largest_Number.Largest_Concatenation (3, 9) = 93);
   pragma Assert (Largest_Number.Largest_Concatenation (1, 1) = 11);
end Tests;
