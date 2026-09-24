with Ones_And_Zeroes;
procedure Tests is
   use Ones_And_Zeroes;
begin
   pragma Assert (Max_Form ((1, 1, 0, 2), (0, 1, 1, 0), 3, 2) = 3);
   pragma Assert (Max_Form ((1, 1, 1, 1), (1, 1, 1, 1), 1, 1) = 1);
   pragma Assert (Max_Form ((1, 1, 1, 1), (1, 1, 1, 1), 0, 0) = 0);
end Tests;
