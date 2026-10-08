package body Ricart_Agrawala is

   procedure Initialize 
     (Node    : out RA_Node;
      ID      : in  Node_ID;
      Variant : in  Algorithm_Variant := Algorithm_Variant'(Standard)) is
   begin
      Node.ID               := ID;
      Node.State            := Released;
      Node.Seq_Num          := 0;
      Node.Highest_Seen_Seq := 0;
      Node.Variant          := Variant;
      Node.Deferred         := (others => False);
      Node.Replies_Needed   := 0;
      Node.Permissions      := (others => False);
   end Initialize;

   procedure Request_Critical_Section
     (Node              : in out RA_Node;
      Outgoing_Requests : out Node_Set) is
   begin
      Node.State := Wanted;
      Node.Seq_Num := Node.Highest_Seen_Seq + 1;
      Node.Replies_Needed := 0;
      Outgoing_Requests := (others => False);

      for I in Node_ID loop
         if I /= Node.ID then
            -- Standard variant: Request from everyone.
            -- Roucairol-Carvalho: Request only if permission is not already implicitly held.
            if Node.Variant = Algorithm_Variant'(Standard) or else not Node.Permissions (I) then
               Outgoing_Requests (I) := True;
               Node.Replies_Needed := Node.Replies_Needed + 1;
            else
               Outgoing_Requests (I) := False;
            end if;
         end if;
      end loop;
   end Request_Critical_Section;

   procedure Receive_Request
     (Node       : in out RA_Node;
      Sender     : in  Node_ID;
      Req_Seq    : in  Sequence_Number;
      Send_Reply : out Boolean) is
      
      Defer_Request : Boolean := False;
   begin
      -- Always track the highest sequence number seen to maintain logical clocks
      if Req_Seq > Node.Highest_Seen_Seq then
         Node.Highest_Seen_Seq := Req_Seq;
      end if;

      -- Determine if the incoming request should be deferred
      if Node.State = Held then
         Defer_Request := True;
      elsif Node.State = Wanted then
         -- Tie-breaking: lower sequence number takes priority.
         -- If sequence numbers match, lower Node_ID takes priority.
         if Node.Seq_Num < Req_Seq then
            Defer_Request := True;
         elsif Node.Seq_Num = Req_Seq and then Node.ID < Sender then
            Defer_Request := True;
         else
            Defer_Request := False;
         end if;
      else
         Defer_Request := False;
      end if;

      if Defer_Request then
         Node.Deferred (Sender) := True;
         Send_Reply := False;
         -- In Roucairol-Carvalho, receiving a request invalidates cached permission
         if Node.Variant = Algorithm_Variant'(Roucairol_Carvalho) then
            Node.Permissions (Sender) := False;
         end if;
      else
         Send_Reply := True;
         -- In Roucairol-Carvalho, sending a reply means yielding implicit permission
         if Node.Variant = Algorithm_Variant'(Roucairol_Carvalho) then
            Node.Permissions (Sender) := False;
         end if;
      end if;
   end Receive_Request;

   procedure Receive_Reply
     (Node   : in out RA_Node;
      Sender : in  Node_ID) is
   begin
      -- Cache the permission if using the optimized variant
      if Node.Variant = Algorithm_Variant'(Roucairol_Carvalho) then
         Node.Permissions (Sender) := True;
      end if;

      if Node.Replies_Needed > 0 then
         Node.Replies_Needed := Node.Replies_Needed - 1;
      end if;
   end Receive_Reply;

   function Can_Enter_CS (Node : in RA_Node) return Boolean is
   begin
      return Node.State = Wanted and then Node.Replies_Needed = 0;
   end Can_Enter_CS;

   procedure Enter_CS (Node : in out RA_Node) is
   begin
      if Can_Enter_CS (Node) then
         Node.State := Held;
      end if;
   end Enter_CS;

   procedure Release_Critical_Section
     (Node             : in out RA_Node;
      Outgoing_Replies : out Node_Set) is
   begin
      Node.State := Released;
      Outgoing_Replies := Node.Deferred;
      -- Clear the defer queue after extracting replies
      Node.Deferred := (others => False);
   end Release_Critical_Section;

   function Get_State (Node : in RA_Node) return Node_State is
   begin
      return Node.State;
   end Get_State;

   function Get_Seq_Num (Node : in RA_Node) return Sequence_Number is
   begin
      return Node.Seq_Num;
   end Get_Seq_Num;

end Ricart_Agrawala;
