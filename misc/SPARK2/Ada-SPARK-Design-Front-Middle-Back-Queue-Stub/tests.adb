pragma SPARK_Mode (On);
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Design_Front_Middle_Back_Queue_Stub;
use Design_Front_Middle_Back_Queue_Stub;

procedure Tests is
begin
   Assert (Middle_Position (1) = 1);
   Assert (Middle_Position (4) = 2);
   Assert (Middle_Position (5) = 3);
   Assert (Length_After_Push (4) = 5);
   Assert (Length_After_Pop (2) = 1);
   Put_Line ("Design Front Middle Back Queue: PASS");
end Tests;
