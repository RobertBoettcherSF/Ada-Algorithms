with Ada.Text_IO; use Ada.Text_IO;
with Gerchberg_Saxton; use Gerchberg_Saxton;

procedure Main is
   Source : Real_Array (1 .. 4) := (1.0, 1.0, 1.0, 1.0);
   Target : Real_Array (1 .. 4) := (2.0, 0.0, 2.0, 0.0);
   Result : Real_Array (1 .. 4);
begin
   Put_Line ("--- Gerchberg-Saxton Algorithm Runner ---");
   Put_Line ("Running Standard GS Variant...");
   Result := Standard_GS (Source, Target, Max_Iter => 10);
   
   Put_Line ("Resulting Phase angles (radians):");
   for I in Result'Range loop
      Put_Line ("  Phase(" & Integer'Image(I) & ") = " & Real'Image(Result(I)));
   end loop;
   Put_Line ("Completed Successfully.");
end Main;
