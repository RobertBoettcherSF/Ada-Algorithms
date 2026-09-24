with ReLU; use ReLU;
procedure Tests is
begin
   pragma Assert (Activate (-7) = 0);
   pragma Assert (Activate (0) = 0);
   pragma Assert (Activate (9) = 9);
end Tests;
