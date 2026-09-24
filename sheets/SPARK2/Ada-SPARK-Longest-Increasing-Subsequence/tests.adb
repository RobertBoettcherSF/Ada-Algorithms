pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Longest_Increasing_Subsequence; use Longest_Increasing_Subsequence;

procedure Tests is
   Values : constant Element_Array := (10, 9, 2, 5, 3, 7, 20, 18);
begin
   if Compute (Values) /= 4 then raise Program_Error; end if;
   Put_Line ("Longest increasing subsequence: PASS");
end Tests;
