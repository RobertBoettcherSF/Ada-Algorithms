with Ada.Text_IO; use Ada.Text_IO;
with Dynamic_Markov_Compression; use Dynamic_Markov_Compression;

procedure Main is
   Model : DMC_Model;
begin
   Put_Line ("Dynamic Markov Compression Algorithm Runner");
   Model.Initialize (Init_Type => Single_State);
   Put_Line ("Model initialized with 1 state.");
   Model.Update (0);
   Put_Line ("Bit '0' fed. P(0) is now: " & Float'Image (Model.Predict_Zero));
end Main;
