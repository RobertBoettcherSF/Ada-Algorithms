pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Top_K_Frequent_Words; use Top_K_Frequent_Words;
procedure Tests is
   W : Word_Array := (1, 2, 1, 3, 1, 2, others => 4);
begin
   Assert (Kth_Frequency (W, 6, 1) = 3);
   Put_Line ("PASS Top K Frequent Words");
end Tests;
