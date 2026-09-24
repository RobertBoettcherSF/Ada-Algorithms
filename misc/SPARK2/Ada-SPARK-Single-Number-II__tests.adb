with Single_Number_II; use Single_Number_II;
procedure Tests is
   Values : constant Vector := [2, 2, 3, 2, 2];
begin
   pragma Assert (Single (Values) = 3);
end Tests;
