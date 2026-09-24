with Excel_Sheet_Column;
procedure Tests is
begin
   pragma Assert (Excel_Sheet_Column.Column_Number ('A') = 1);
   pragma Assert (Excel_Sheet_Column.Column_Number ('C') = 3);
   pragma Assert (Excel_Sheet_Column.Column_Number ('Z') = 26);
end Tests;
