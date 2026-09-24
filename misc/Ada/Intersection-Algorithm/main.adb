-- main.adb
with Ada.Text_IO; use Ada.Text_IO;
with Intersection_Algorithm; use Intersection_Algorithm;

procedure Main is
   Result : Result_Record;
   Input  : Interval_Array (1 .. 3) := (
      (Center => 10.0, Radius => 2.0),
      (Center => 12.0, Radius => 1.0),
      (Center => 11.0, Radius => 1.0)
   );
begin
   Put_Line ("Running Intersection Algorithm Variant Analysis...");
   Result := Find_Intersection (Input);
   
   if Result.Success then
      Put_Line ("NTP Consensus Validated:");
      Put_Line ("  Lower Bound: " & Float'Image (Result.Lower));
      Put_Line ("  Upper Bound: " & Float'Image (Result.Upper));
   else
      Put_Line ("FAILED: No valid consensus found.");
   end if;
   
   Put_Line (ASCII.LF & "Run 'make test' to execute the formal verification suite.");
end Main;
