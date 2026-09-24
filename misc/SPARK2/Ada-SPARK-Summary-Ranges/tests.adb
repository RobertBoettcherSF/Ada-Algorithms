with Summary_Ranges;
procedure Tests is
begin
   pragma Assert (Summary_Ranges.Summary (1) = 0);
   pragma Assert (Summary_Ranges.Summary (3) = 1);
   pragma Assert (Summary_Ranges.Summary (6) = 2);
   pragma Assert (Summary_Ranges.Summary (10) = 3);
end Tests;
