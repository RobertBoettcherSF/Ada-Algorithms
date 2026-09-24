with Ada.Text_IO; use Ada.Text_IO;
with Transform_Coding; use Transform_Coding;

procedure Main is
   Signal   : constant Data_Array(1..4) := (15.5, 30.1, 45.9, 60.2);
   Freq     : Data_Array(1..4);
   Quant    : Quantized_Array(1..4);
   Recon    : Data_Array(1..4);
   Q_Step   : constant Float := 5.0;
begin
   Put_Line ("--- Transform Coding Demonstration ---");
   Put_Line ("1. Original Spatial Signal: ");
   for I in Signal'Range loop
      Put (Float'Image(Signal(I)) & " ");
   end loop;
   New_Line;

   Freq := DCT (Signal);
   Put_Line ("2. DCT (Frequency Domain): ");
   for I in Freq'Range loop
      Put (Float'Image(Freq(I)) & " ");
   end loop;
   New_Line;

   Quant := Quantize (Freq, Q_Step);
   Put_Line ("3. Quantized Transmit Data (Lossy): ");
   for I in Quant'Range loop
      Put (Integer'Image(Quant(I)) & " ");
   end loop;
   New_Line;

   -- Decoding phase
   Recon := Inverse_DCT (Dequantize (Quant, Q_Step));
   Put_Line ("4. Reconstructed Output Signal: ");
   for I in Recon'Range loop
      Put (Float'Image(Recon(I)) & " ");
   end loop;
   New_Line;
end Main;
