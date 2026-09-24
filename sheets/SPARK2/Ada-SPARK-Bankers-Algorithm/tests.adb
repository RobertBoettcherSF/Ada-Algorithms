pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Bankers_Algorithm; use Bankers_Algorithm;
procedure Tests is
   S : State :=
     (Available => (3, 3, 2),
      Allocation => ((1, 0, 0), (0, 1, 0), (1, 1, 1), (0, 0, 1)),
      Maximum => ((3, 2, 2), (1, 2, 2), (2, 2, 2), (1, 1, 2)));
   Granted : Boolean;
begin
   if not Is_Safe (S) then raise Program_Error; end if;
   Request (S, 2, 1, 1, Granted);
   if not Granted then raise Program_Error; end if;
   Put_Line ("Bankers: PASS");
end Tests;
