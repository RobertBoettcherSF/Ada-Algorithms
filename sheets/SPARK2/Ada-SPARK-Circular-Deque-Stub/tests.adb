pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Circular_Deque_Stub; use Circular_Deque_Stub;

procedure Tests is
   D : Deque := Empty;
begin
   D := Push_Back (D, 2); D := Push_Front (D, 1); D := Push_Back (D, 3);
   if Front (D) /= 1 or else Back (D) /= 3 then raise Program_Error; end if;
   D := Pop_Front (D); D := Pop_Back (D);
   if Front (D) /= 2 or else Back (D) /= 2 then raise Program_Error; end if;
   Put_Line ("Circular deque stub: PASS");
end Tests;
