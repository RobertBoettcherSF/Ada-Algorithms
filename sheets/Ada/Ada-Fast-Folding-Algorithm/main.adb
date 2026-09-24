with Ada.Text_IO; use Ada.Text_IO;
with Fast_Folding; use Fast_Folding;

procedure Main is
   Data : Signal_Array (1 .. 8) := (1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0);
   Res  : Profile_Array (1 .. 4);
begin
   Put_Line ("========================================");
   Put_Line ("Fast Folding Algorithm - Main Execution");
   Put_Line ("========================================");
   
   Constant_Period_Fold (Data, 4, Res);
   Put_Line ("Constant Fold Result (Base 4): ");
   for I in Res'Range loop
      Put_Line ("  Phase" & Integer'Image (I) & ":" & Signal_Value'Image (Res (I)));
   end loop;
end Main;
