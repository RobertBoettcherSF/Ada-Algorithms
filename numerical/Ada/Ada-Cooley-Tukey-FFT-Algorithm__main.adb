with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Complex_Types; use Ada.Numerics.Complex_Types;
with Cooley_Tukey; use Cooley_Tukey;

procedure Main is
   Signal : Complex_Array(0 .. 3) := (
      (1.0, 0.0), (2.0, 0.0), (3.0, 0.0), (4.0, 0.0)
   );
begin
   Put_Line ("Cooley-Tukey FFT Demo");
   Put_Line ("---------------------");
   Put_Line ("Input Signal:");
   for I in Signal'Range loop
      Put_Line ("  x(" & Integer'Image (I) & ") = " & 
                Float'Image (Signal (I).Re) & " + " & Float'Image (Signal (I).Im) & "i");
   end loop;
   
   FFT_Iterative (Signal);
   
   Put_Line ("");
   Put_Line ("Transformed Signal (FFT):");
   for I in Signal'Range loop
      Put_Line ("  X(" & Integer'Image (I) & ") = " & 
                Float'Image (Signal (I).Re) & " + " & Float'Image (Signal (I).Im) & "i");
   end loop;
end Main;
