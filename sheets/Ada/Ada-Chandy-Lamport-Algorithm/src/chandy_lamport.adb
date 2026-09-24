package body Chandy_Lamport is

   procedure Init_Node (N : out Node; ID : Node_ID; Initial_Value : Integer) is
   begin
      N.ID := ID;
      N.Current_Value := Initial_Value;
      -- Reset all snapshot states to handle edge case of uninitialized memory
      for S in Snapshot_ID loop
         N.Snapshots(S).Is_Active := False;
         N.Snapshots(S).Has_Recorded := False;
         N.Snapshots(S).Recorded_Value := 0;
         for C in Node_ID loop
            N.Snapshots(S).Channels(C).Is_Recording := False;
            N.Snapshots(S).Channels(C).Is_Closed := True;
            N.Snapshots(S).Channels(C).Messages.Clear;
         end loop;
      end loop;
   end Init_Node;

   procedure Update_Local_State (N : in out Node; Value_Change : Integer) is
   begin
      N.Current_Value := N.Current_Value + Value_Change;
   end Update_Local_State;

   procedure Initiate_Snapshot (N : in out Node; S_ID : Snapshot_ID; Out_Markers : out Message_Queue) is
   begin
      Out_Markers.Clear;
      if not N.Snapshots(S_ID).Has_Recorded then
         -- Step 1: Record own state
         N.Snapshots(S_ID).Is_Active := True;
         N.Snapshots(S_ID).Has_Recorded := True;
         N.Snapshots(S_ID).Recorded_Value := N.Current_Value;

         -- Step 2: Prepare incoming channels and generate outgoing markers
         for C in Node_ID loop
            if C /= N.ID then
               N.Snapshots(S_ID).Channels(C).Is_Recording := True;
               N.Snapshots(S_ID).Channels(C).Is_Closed := False;
               N.Snapshots(S_ID).Channels(C).Messages.Clear;
               
               Out_Markers.Append (Message'(Kind => Marker_Message, Sender => N.ID, Receiver => C, Snap_ID => S_ID));
            else
               -- Edge Case: Ignore self as an incoming channel
               N.Snapshots(S_ID).Channels(C).Is_Recording := False;
               N.Snapshots(S_ID).Channels(C).Is_Closed := True;
            end if;
         end loop;
      end if;
   end Initiate_Snapshot;

   procedure Receive_Message (N : in out Node; Msg : Message; Out_Markers : out Message_Queue) is
   begin
      Out_Markers.Clear;
      case Msg.Kind is
         when App_Message =>
            -- Core behavior: Process the application message
            N.Current_Value := N.Current_Value + Msg.Payload;
            
            -- Chandy-Lamport variant rule: Queue message if snapshot actively recording this channel
            for S in Snapshot_ID loop
               if N.Snapshots(S).Is_Active and then N.Snapshots(S).Channels(Msg.Sender).Is_Recording then
                  N.Snapshots(S).Channels(Msg.Sender).Messages.Append(Msg);
               end if;
            end loop;

         when Marker_Message =>
            declare
               S_ID : constant Snapshot_ID := Msg.Snap_ID;
            begin
               if not N.Snapshots(S_ID).Has_Recorded then
                  -- Receiving Marker for the FIRST time
                  N.Snapshots(S_ID).Is_Active := True;
                  N.Snapshots(S_ID).Has_Recorded := True;
                  N.Snapshots(S_ID).Recorded_Value := N.Current_Value;

                  for C in Node_ID loop
                     if C = Msg.Sender or else C = N.ID then
                        -- Channel marker came from is closed (state becomes empty sequence)
                        N.Snapshots(S_ID).Channels(C).Is_Recording := False;
                        N.Snapshots(S_ID).Channels(C).Is_Closed := True;
                     else
                        -- All other incoming channels start recording
                        N.Snapshots(S_ID).Channels(C).Is_Recording := True;
                        N.Snapshots(S_ID).Channels(C).Is_Closed := False;
                        N.Snapshots(S_ID).Channels(C).Messages.Clear;
                     end if;

                     if C /= N.ID then
                         Out_Markers.Append(Message'(Kind => Marker_Message, Sender => N.ID, Receiver => C, Snap_ID => S_ID));
                     end if;
                  end loop;
               else
                  -- Receiving Marker for a SECOND or subsequent time: Stop recording on this channel
                  N.Snapshots(S_ID).Channels(Msg.Sender).Is_Recording := False;
                  N.Snapshots(S_ID).Channels(Msg.Sender).Is_Closed := True;
               end if;
            end;
      end case;
   end Receive_Message;

   function Is_Snapshot_Complete (N : Node; S_ID : Snapshot_ID) return Boolean is
   begin
      if not N.Snapshots(S_ID).Has_Recorded then
         return False;
      end if;
      for C in Node_ID loop
         if not N.Snapshots(S_ID).Channels(C).Is_Closed then
            return False;
         end if;
      end loop;
      return True;
   end Is_Snapshot_Complete;

   function Get_Recorded_Value (N : Node; S_ID : Snapshot_ID) return Integer is
   begin
      return N.Snapshots(S_ID).Recorded_Value;
   end Get_Recorded_Value;

   function Get_Channel_Messages (N : Node; S_ID : Snapshot_ID; From : Node_ID) return Message_Queue is
   begin
      return N.Snapshots(S_ID).Channels(From).Messages;
   end Get_Channel_Messages;

end Chandy_Lamport;
