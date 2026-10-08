with Ada.Text_IO; use Ada.Text_IO;
with Adaptive_Additive; use Adaptive_Additive;

procedure Main is
   Amp   : Real_Array(1 .. 4) := (1.0, 0.5, 0.5, 1.0);
   Inten : Real_Array(1 .. 4) := (2.0, 2.0, 2.0, 2.0);
   Phase : Real_Array(1 .. 4);
   Conv  : Boolean;
begin
   Put_Line("Adaptive-Additive Algorithm Execution");
   Put_Line("Running standard AA variant (a=0.5)...");
   AA_Algorithm(Amp, Inten, 0.5, 100, 0.05, Phase, Conv);
   
   if Conv then
      Put_Line("Result: Converged.");
   else
      Put_Line("Result: Max Iterations reached.");
   end if;
   
   Put_Line("Calculated Spatial Phases (Radians):");
   for I in Phase'Range loop
      Put_Line("  Phase(" & Integer'Image(I) & ") = " & Float'Image(Phase(I)));
   end loop;
end Main;
