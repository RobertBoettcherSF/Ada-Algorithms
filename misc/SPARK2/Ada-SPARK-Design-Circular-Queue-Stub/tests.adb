pragma SPARK_Mode (On);
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Design_Circular_Queue_Stub; use Design_Circular_Queue_Stub;

procedure Tests is
begin
   Assert (Enqueued_Length (0) = 1);
   Assert (Dequeued_Length (5) = 4);
   Assert (Next_Position (5) = 1);
   Assert (Next_Position (3) = 4);
   Put_Line ("Design Circular Queue: PASS");
end Tests;
