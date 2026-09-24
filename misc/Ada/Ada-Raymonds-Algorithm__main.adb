-- src/main.adb
with Ada.Text_IO; use Ada.Text_IO;
with Raymonds_Algorithm; use Raymonds_Algorithm;

procedure Main is
   Node_A, Node_B : Node_State;
   Msgs : Message_Buffer;
begin
   Put_Line ("--- Raymond's Algorithm Simulation ---");
   -- Node A is Token Holder (Root). Node B points to Node A.
   Initialize (Node_A, Id => 1, Holder => 1);
   Initialize (Node_B, Id => 2, Holder => 1);

   Put_Line ("[*] Node B requests Critical Section locally...");
   Request_CS (Node_B, Msgs);
   
   for I in 1 .. Msgs.Count loop
      Put_Line ("    -> Emitted: " & Message_Type'Image(Msgs.Messages(I).Kind) &
                " | Sender=" & Node_Id'Image(Msgs.Messages(I).Sender) &
                " | Receiver=" & Node_Id'Image(Msgs.Messages(I).Receiver));
   end loop;

   if Msgs.Count > 0 then
      Put_Line ("[*] Node A receives Request from Node B...");
      declare
         In_Msg   : Message := Msgs.Messages(1);
         Out_Msgs : Message_Buffer;
      begin
         Receive_Request (Node_A, In_Msg.Sender, Out_Msgs);
         for I in 1 .. Out_Msgs.Count loop
            Put_Line ("    -> Emitted: " & Message_Type'Image(Out_Msgs.Messages(I).Kind) &
                      " | Sender=" & Node_Id'Image(Out_Msgs.Messages(I).Sender) &
                      " | Receiver=" & Node_Id'Image(Out_Msgs.Messages(I).Receiver));
         end loop;
      end;
   end if;
   Put_Line ("--- Simulation Complete ---");
end Main;
