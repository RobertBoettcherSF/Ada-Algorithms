-- main.adb
with Ada.Text_IO; use Ada.Text_IO;
with Parity_Bit; use Parity_Bit;

procedure Main is
   Data   : constant Bit_Array := (1, 0, 1, 1, 0, 1, 0); -- Seven bits
   Parity : Bit;
begin
   Put_Line ("Parity Bit Algorithm Demonstration");
   Put_Line ("----------------------------------");
   
   Parity := Calculate_Parity (Data, Even);
   Put_Line ("Even Parity for 1011010 is: " & Parity'Image);
   
   Parity := Calculate_Parity (Data, Odd);
   Put_Line ("Odd Parity for 1011010 is:  " & Parity'Image);
   
   Put_Line ("Demonstration completed successfully.");
end Main;
