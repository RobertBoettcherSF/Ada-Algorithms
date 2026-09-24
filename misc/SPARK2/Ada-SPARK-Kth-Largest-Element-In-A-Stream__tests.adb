pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Kth_Largest_Element_In_A_Stream; use Kth_Largest_Element_In_A_Stream;

procedure Tests is
   S : constant Stream_Array := (7, 2, 9, 4, 9, -1, 5, 3);
   K : constant Stream_Array := (1, 1, 1, 1, 1, 1, 1, 1);
begin
   if Kth_Largest (S, 1) /= 9 then raise Program_Error; end if;
   if Kth_Largest (S, 3) /= 7 then raise Program_Error; end if;
   if Kth_Largest (K, 8) /= 1 then raise Program_Error; end if;
   Put_Line ("Kth largest stream: PASS");
end Tests;
