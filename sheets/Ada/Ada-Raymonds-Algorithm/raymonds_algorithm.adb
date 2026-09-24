-- src/raymonds_algorithm.adb
package body Raymonds_Algorithm is

   -- ---------------------------------------------------------
   -- Helpers: Bounded Circular Queue Operations
   -- ---------------------------------------------------------
   procedure Enqueue (Q : in out Node_Queue; Item : Node_Id) is
   begin
      if Q.Count = Max_Queue then
         raise Queue_Overflow;
      end if;
      Q.Rear := (Q.Rear mod Max_Queue) + 1;
      Q.Data (Q.Rear) := Item;
      Q.Count := Q.Count + 1;
   end Enqueue;

   procedure Dequeue (Q : in out Node_Queue; Item : out Node_Id) is
   begin
      if Q.Count = 0 then
         raise Queue_Underflow;
      end if;
      Item := Q.Data (Q.Front);
      Q.Front := (Q.Front mod Max_Queue) + 1;
      Q.Count := Q.Count - 1;
   end Dequeue;

   function Is_Empty (Q : Node_Queue) return Boolean is
   begin
      return Q.Count = 0;
   end Is_Empty;

   procedure Add_Message (Buffer : in out Message_Buffer; Msg : Message) is
   begin
      if Buffer.Count < Buffer.Messages'Last then
         Buffer.Count := Buffer.Count + 1;
         Buffer.Messages (Buffer.Count) := Msg;
      end if;
   end Add_Message;

   -- ---------------------------------------------------------
   -- Core Protocol: Initialization
   -- ---------------------------------------------------------
   procedure Initialize (Node : in out Node_State; Id : Node_Id; Holder : Node_Id) is
   begin
      Node.Id       := Id;
      Node.Holder   := Holder;
      Node.Using_CS := False;
      Node.Asked    := False;
      Node.Req_Q.Count := 0;
      Node.Req_Q.Front := 1;
      Node.Req_Q.Rear  := 0;
   end Initialize;

   -- ---------------------------------------------------------
   -- Core Protocol: Assign Token Logic
   -- ---------------------------------------------------------
   -- Dequeues the next request from the queue and assigns the token.
   -- If the request is from this node itself, it enters the critical section.
   -- Otherwise, it forwards the token to the requesting node and propagates
   -- its own request upward if the queue is not empty.
   -- ---------------------------------------------------------
   procedure Assign_Token (Node : in out Node_State; Out_Msgs : in out Message_Buffer) is
      X : Node_Id;
   begin
      Dequeue (Node.Req_Q, X);
      if X = Node.Id then
         -- Node is granting token to itself
         Node.Using_CS := True;
         Node.Asked    := False;
      else
         -- Forward token to the requesting node
         Node.Holder := X;
         Add_Message (Out_Msgs, (Token_Msg, Node.Id, X));
         -- If there are more requests, propagate this node's request upward
         if not Is_Empty (Node.Req_Q) then
            Add_Message (Out_Msgs, (Request_Msg, Node.Id, Node.Holder));
            Node.Asked := True;
         else
            Node.Asked := False;
         end if;
      end if;
   end Assign_Token;

   -- ---------------------------------------------------------
   -- Variant 1: Standard Raymond's Event Handlers
   -- ---------------------------------------------------------
   
   -- Request Critical Section access.
   -- Enqueues the node's own request and either:
   -- - Sends a request message upward if token is not held locally
   -- - Immediately assigns token if node already holds it and CS is free
   -- ---------------------------------------------------------
   procedure Request_CS (Node : in out Node_State; Out_Msgs : in out Message_Buffer) is
   begin
      -- Add own request to the queue
      Enqueue (Node.Req_Q, Node.Id);
      
      -- If this node doesn't have the token and hasn't asked yet
      if Node.Holder /= Node.Id and then not Node.Asked then
         Add_Message (Out_Msgs, (Request_Msg, Node.Id, Node.Holder));
         Node.Asked := True;
      -- If this node has the token and is not in CS, assign it immediately
      elsif Node.Holder = Node.Id and then not Node.Using_CS then
         Assign_Token (Node, Out_Msgs);
      end if;
   end Request_CS;

   -- Handle incoming request message from another node.
   -- Enqueues the request and either:
   -- - Assigns token immediately if this node holds it and CS is free
   -- - Forwards the request upward if this node doesn't have the token
   -- ---------------------------------------------------------
   procedure Receive_Request (Node : in out Node_State; From : Node_Id; Out_Msgs : in out Message_Buffer) is
   begin
      -- Add the requesting node to the queue
      Enqueue (Node.Req_Q, From);
      
      -- If this node has the token and is not in CS, assign it
      if Node.Holder = Node.Id and then not Node.Using_CS then
         Assign_Token (Node, Out_Msgs);
      -- If this node doesn't have the token and hasn't asked yet, forward request
      elsif Node.Holder /= Node.Id and then not Node.Asked then
         Add_Message (Out_Msgs, (Request_Msg, Node.Id, Node.Holder));
         Node.Asked := True;
      end if;
   end Receive_Request;

   -- Handle incoming token message.
   -- Sets this node as the token holder and assigns the token
   -- to the next node in the queue (or itself if at the front).
   -- ---------------------------------------------------------
   procedure Receive_Token (Node : in out Node_State; Out_Msgs : in out Message_Buffer) is
   begin
      -- This node now holds the token
      Node.Holder := Node.Id;
      -- Assign token to next node in queue
      Assign_Token (Node, Out_Msgs);
   end Receive_Token;

   -- Release the Critical Section.
   -- Marks the node as no longer using the CS and assigns the token
   -- to the next node in the queue if one exists.
   -- ---------------------------------------------------------
   procedure Release_CS (Node : in out Node_State; Out_Msgs : in out Message_Buffer) is
   begin
      Node.Using_CS := False;
      -- If there are pending requests, assign token to next node
      if not Is_Empty (Node.Req_Q) then
         Assign_Token (Node, Out_Msgs);
      end if;
   end Release_CS;

   -- ---------------------------------------------------------
   -- Variant 2: Greedy Protocol Event Handler (Network Optimized)
   -- ---------------------------------------------------------
   -- Optimized version that suppresses duplicate requests.
   -- Before forwarding a request, scans the queue to check if the
   -- requesting node is already queued. If so, skips sending the request
   -- to reduce network traffic.
   -- ---------------------------------------------------------
   procedure Greedy_Receive_Request (Node : in out Node_State; From : Node_Id; Out_Msgs : in out Message_Buffer) is
      Found   : Boolean := False;
      Index   : Positive := Node.Req_Q.Front;
      Counter : Natural := 0;
   begin
      -- Scan queue for existing requests from the same node
      while Counter < Node.Req_Q.Count loop
         if Node.Req_Q.Data (Index) = From then
            Found := True;
            exit;
         end if;
         Index := (Index mod Max_Queue) + 1;
         Counter := Counter + 1;
      end loop;

      -- Only process the request if not already in queue
      if not Found then
         Receive_Request (Node, From, Out_Msgs);
      end if;
   end Greedy_Receive_Request;

end Raymonds_Algorithm;
