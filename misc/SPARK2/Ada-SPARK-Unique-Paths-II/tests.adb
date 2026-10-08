pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Unique_Paths_II;
with Own_Checks;

procedure Tests is
   Open : Unique_Paths_II.Grid := (others => (others => False));
   Blocked : Unique_Paths_II.Grid := (others => (others => False));
begin
   if Unique_Paths_II.Count (3, 3, Open) /= 6 then
      raise Program_Error;
   end if;
   Blocked (2, 2) := True;
   if Unique_Paths_II.Count (3, 3, Blocked) /= 2 then
      raise Program_Error;
   end if;
   Put_Line ("Unique Paths II: PASS");
   Own_Checks;
end Tests;
