with Ada.Assertions; use Ada.Assertions;
with Word_Break; use Word_Break;
procedure Tests is
   Ada_Word : constant Word := "ada     ";
   Spark_Word : constant Word := "spark   ";
   Joined : constant Word := "adaspark";
   Unknown : constant Word := "adax    ";
begin
   Assert (Is_Breakable (Ada_Word));
   Assert (Is_Breakable (Spark_Word));
   Assert (Is_Breakable (Joined));
   Assert (not Is_Breakable (Unknown));
end Tests;
