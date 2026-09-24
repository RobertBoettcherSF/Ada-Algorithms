with Valid_Square; use Valid_Square;
procedure Tests with SPARK_Mode => Off is
begin
   pragma Assert (not Is_Valid_Square (0));
   pragma Assert (Is_Valid_Square (1));
   pragma Assert (Is_Valid_Square (10));
end Tests;
