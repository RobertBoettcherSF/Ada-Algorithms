pragma SPARK_Mode (On);
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Online_Stock_Span_Stub; use Online_Stock_Span_Stub;

procedure Tests is
   S : State;
   Span : Span_Value;
begin
   Initialize (S);
   Next (S, 100, Span); Assert (Span = 1);
   Next (S, 80, Span); Assert (Span = 1);
   Next (S, 60, Span); Assert (Span = 1);
   Next (S, 70, Span); Assert (Span = 2);
   Next (S, 60, Span); Assert (Span = 1);
   Next (S, 75, Span); Assert (Span = 4);
   Next (S, 85, Span); Assert (Span = 6);
   Next (S, 90, Span); Assert (Span = 7);
   Assert (S.Count = Capacity);
   Put_Line ("Online Stock Span: PASS");
end Tests;
