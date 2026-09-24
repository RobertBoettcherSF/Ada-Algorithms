with Ada.Text_IO; use Ada.Text_IO;
with PPM_Algorithm; use PPM_Algorithm;

procedure Main is
   Predictor : PPM_Predictor;
   Hist      : Symbol_String := To_Symbol_String("ABACABA");
   Dist      : Distribution;
begin
   Put_Line ("Initializing Unbounded PPM* Predictor (Laplace Variant)...");
   Initialize_Predictor (Predictor, Order_Unbounded, Laplace_Estimator);

   Put_Line ("Ingesting learning history: 'ABACABA'");
   for I in Hist'Range loop
      Update_Predictor (Predictor, Hist(Hist'First .. I - 1), Hist(I));
   end loop;

   Put_Line ("Predicting next symbol distribution for context 'ABACABA'...");
   Dist := Calculate_Blended_Distribution (Predictor, Hist);

   Put_Line ("Prominent probabilities:");
   for S in Symbol loop
      if Dist(S) > 0.02 then 
         Put_Line ("  " & S & ": " & Float'Image (Float(Dist(S))));
      end if;
   end loop;

   Free_Predictor (Predictor);
end Main;
