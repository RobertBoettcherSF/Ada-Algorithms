package body Dijkstra_Scholten is

   -- Helper Function: Validates boundary edge-cases for array safety
   procedure Validate_Node (Network : Network_Type; Node : Node_ID) is
   begin
      if Node < 1 or else Node > Network.Max_Node then
         raise Invalid_Node_Error with "Node ID out of valid network bounds";
      end if;
   end Validate_Node;

   -- Initializes network state, creating a single Active initiator
   procedure Initialize (Network : out Network_Type; Initiator : Node_ID) is
   begin
      Validate_Node (Network, Initiator);
      Network.Initiator := Initiator;
      
      -- Reset all nodes
      for I in 1 .. Network.Max_Node loop
         Network.Nodes(I) := (ID => I, State => Idle, Parent => Null_Node, Deficit => 0);
      end loop;
      
      -- Bootstrap initiator
      Network.Nodes(Initiator).State := Active;
   end Initialize;

   -- Processes incoming signals/acks and cascades them up the tree if conditions are met
   procedure Receive_Ack (Network : in out Network_Type; At_Node : Node_ID) is
   begin
      Validate_Node (Network, At_Node);
      if Network.Nodes(At_Node).Deficit = 0 then
         raise Negative_Deficit_Error with "Cannot acknowledge when deficit is already 0";
      end if;

      Network.Nodes(At_Node).Deficit := Network.Nodes(At_Node).Deficit - 1;

      -- If the node is currently idle and this ack reduced its deficit to 0, 
      -- it must prune itself from the tree and acknowledge its parent.
      if Network.Nodes(At_Node).State = Idle and then
         Network.Nodes(At_Node).Deficit = 0 and then
         Network.Nodes(At_Node).Parent /= Null_Node
      then
         declare
            Parent_Node : constant Node_ID := Network.Nodes(At_Node).Parent;
         begin
            Network.Nodes(At_Node).Parent := Null_Node;
            Receive_Ack (Network, Parent_Node);
         end;
      end if;
   end Receive_Ack;

   -- Sends a computation message, mutating the deficit counter
   procedure Send_Message (Network : in out Network_Type; From, To : Node_ID) is
   begin
      Validate_Node (Network, From);
      Validate_Node (Network, To);

      -- Only Active nodes can spawn new processes/messages
      if Network.Nodes(From).State = Idle then
         raise Invalid_State_Error with "Idle node cannot send computation messages";
      end if;

      Network.Nodes(From).Deficit := Network.Nodes(From).Deficit + 1;
   end Send_Message;

   -- Registers incoming messages, adding nodes to the spanning tree dynamically
   procedure Receive_Message (Network : in out Network_Type; From, To : Node_ID) is
      In_Tree : Boolean;
   begin
      Validate_Node (Network, From);
      Validate_Node (Network, To);

      -- Check if node is already participating in the tree
      In_Tree := (Network.Nodes(To).Parent /= Null_Node) or else (To = Network.Initiator);

      if Network.Nodes(To).State = Idle then
         Network.Nodes(To).State := Active;
      end if;

      if not In_Tree then
         -- Variant: Join the active dynamic computation tree
         Network.Nodes(To).Parent := From;
      else
         -- Variant: Already in tree, immediately signal an acknowledgment
         Receive_Ack (Network, From);
      end if;
   end Receive_Message;

   -- Marks node as locally done. If its subtree is finished (deficit = 0), it cascade-signals
   procedure Set_Idle (Network : in out Network_Type; Node : Node_ID) is
   begin
      Validate_Node (Network, Node);
      
      -- Ignore redundant idle commands
      if Network.Nodes(Node).State = Idle then
         return; 
      end if;

      Network.Nodes(Node).State := Idle;

      -- Prune node from tree and signal up if its local subtree is strictly terminated
      if Network.Nodes(Node).Deficit = 0 and then Network.Nodes(Node).Parent /= Null_Node then
         declare
            Parent_Node : constant Node_ID := Network.Nodes(Node).Parent;
         begin
            Network.Nodes(Node).Parent := Null_Node;
            Receive_Ack (Network, Parent_Node);
         end;
      end if;
   end Set_Idle;

   -- Global termination occurs purely when the Root matches Idle+Deficit=0
   function Is_Terminated (Network : Network_Type) return Boolean is
      Root : Node_Record renames Network.Nodes(Network.Initiator);
   begin
      return Root.State = Idle and then Root.Deficit = 0;
   end Is_Terminated;

end Dijkstra_Scholten;
