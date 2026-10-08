pragma SPARK_Mode (On);

package body Design_Front_Middle_Back_Queue_Stub is
   function Middle_Position (Length : Queue_Length) return Queue_Position is
   begin
      return Queue_Position ((Length + 1) / 2);
   end Middle_Position;

   function Length_After_Push (Length : Queue_Length) return Queue_Length is
   begin
      return Length + 1;
   end Length_After_Push;

   function Length_After_Pop (Length : Queue_Length) return Natural is
   begin
      return Length - 1;
   end Length_After_Pop;
end Design_Front_Middle_Back_Queue_Stub;
