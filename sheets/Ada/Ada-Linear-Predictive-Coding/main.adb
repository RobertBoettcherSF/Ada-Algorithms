-- main.adb
with Ada.Text_IO; use Ada.Text_IO;
with Linear_Predictive_Coding; use Linear_Predictive_Coding;

procedure Main is
   Sig      : Signal_Array (1 .. 10) := (1.0, 2.0, 3.0, 4.0, 5.0, 4.0, 3.0, 2.0, 1.0, 0.0);
   Coeffs   : Coefficients_Array (1 .. 2);
   Residual : Signal_Array (1 .. 10);
   Recon    : Signal_Array (1 .. 10);
begin
   Put_Line ("--- Linear Predictive Coding Demo ---");
   Analyze (Sig, 2, Autocorrelation, Coeffs, Residual);
   
   Put_Line ("Coefficients:");
   for I in Coeffs'Range loop
      Put_Line ("  a(" & Integer'Image(I) & ") = " & Real'Image(Coeffs(I)));
   end loop;

   Recon := Synthesize (Coeffs, Residual);
   Put_Line ("Synthesis Output vs Original (Check Identity):");
   for I in Sig'Range loop
      Put_Line ("  Orig: " & Real'Image(Sig(I)) & " | Recon: " & Real'Image(Recon(I)));
   end loop;
end Main;
