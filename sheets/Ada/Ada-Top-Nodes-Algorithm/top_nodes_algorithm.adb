package body Top_Nodes_Algorithm is

   procedure Initialize (Cal : in out Calendar) is
   begin
      Cal.Current_Start := 0;
      Cal.Nodes := (others => (Max_Child_Q => 0, Top_Node_Res => 0));
      Cal.Active_Head := 0;
      Cal.Last_ID := 1;
      
      for I in Cal.Reservations'Range loop
         Cal.Reservations(I).Is_Active := False;
         Cal.Reservations(I).Prev := 0;
         Cal.Reservations(I).Next := 0;
      end loop;
   end Initialize;

   -- Recomputes Max_Child_Q from children based on the core algorithm principle:
   -- q(node) = max(q(left child), q(right child)) + top_node_res
   procedure Update_Node (Cal : in out Calendar; Node_Idx : Positive) is
      Left  : constant Positive := 2 * Node_Idx;
      Right : constant Positive := 2 * Node_Idx + 1;
      Q_Left, Q_Right : Resource_Amount;
   begin
      Q_Left  := Cal.Nodes(Left).Max_Child_Q + Cal.Nodes(Left).Top_Node_Res;
      Q_Right := Cal.Nodes(Right).Max_Child_Q + Cal.Nodes(Right).Top_Node_Res;
      
      if Q_Left > Q_Right then
         Cal.Nodes(Node_Idx).Max_Child_Q := Q_Left;
      else
         Cal.Nodes(Node_Idx).Max_Child_Q := Q_Right;
      end if;
   end Update_Node;

   procedure Add_Range
     (Cal      : in out Calendar;
      Node_Idx : Positive;
      Node_L   : Natural;
      Node_R   : Natural;
      Req_L    : Natural;
      Req_R    : Natural;
      Amount   : Resource_Amount;
      Is_Add   : Boolean)
   is
      Mid : constant Natural := Node_L + (Node_R - Node_L) / 2;
   begin
      -- Node entirely covers requested span: it is a "top-node"
      if Req_L <= Node_L and then Node_R <= Req_R then
         if Is_Add then
            Cal.Nodes(Node_Idx).Top_Node_Res := Cal.Nodes(Node_Idx).Top_Node_Res + Amount;
         else
            Cal.Nodes(Node_Idx).Top_Node_Res := Cal.Nodes(Node_Idx).Top_Node_Res - Amount;
         end if;
         return;
      end if;
      
      if Req_L <= Mid then
         Add_Range (Cal, 2 * Node_Idx, Node_L, Mid, Req_L, Req_R, Amount, Is_Add);
      end if;
      
      if Req_R > Mid then
         Add_Range (Cal, 2 * Node_Idx + 1, Mid + 1, Node_R, Req_L, Req_R, Amount, Is_Add);
      end if;
      
      Update_Node (Cal, Node_Idx);
   end Add_Range;

   -- Maps an absolute time reservation request into the bounded circular segment tree array
   procedure Apply_To_Ranges
     (Cal        : in out Calendar;
      Start_Time : Time_Point;
      End_Time   : Time_Point;
      Amount     : Resource_Amount;
      Is_Add     : Boolean)
   is
      L, R : Natural;
   begin
      if Start_Time > End_Time then
         return;
      end if;
      
      if (End_Time - Start_Time + 1) >= Time_Point(Cal.Capacity) then
         Add_Range (Cal, 1, 0, Cal.Capacity - 1, 0, Cal.Capacity - 1, Amount, Is_Add);
      else
         L := Natural (Start_Time mod Time_Point(Cal.Capacity));
         R := Natural (End_Time mod Time_Point(Cal.Capacity));
         
         if L <= R then
            Add_Range (Cal, 1, 0, Cal.Capacity - 1, L, R, Amount, Is_Add);
         else
            -- Spans across the array modulo boundary
            Add_Range (Cal, 1, 0, Cal.Capacity - 1, L, Cal.Capacity - 1, Amount, Is_Add);
            Add_Range (Cal, 1, 0, Cal.Capacity - 1, 0, R, Amount, Is_Add);
         end if;
      end if;
   end Apply_To_Ranges;

   function Query_Range
     (Cal      : Calendar;
      Node_Idx : Positive;
      Node_L   : Natural;
      Node_R   : Natural;
      Req_L    : Natural;
      Req_R    : Natural) return Resource_Amount
   is
      Mid : constant Natural := Node_L + (Node_R - Node_L) / 2;
      Max_Val, V1, V2 : Resource_Amount := 0;
   begin
      if Req_L <= Node_L and then Node_R <= Req_R then
         return Cal.Nodes(Node_Idx).Max_Child_Q + Cal.Nodes(Node_Idx).Top_Node_Res;
      end if;
      
      if Req_L <= Mid then
         V1 := Query_Range (Cal, 2 * Node_Idx, Node_L, Mid, Req_L, Req_R);
         Max_Val := V1;
      end if;
      if Req_R > Mid then
         V2 := Query_Range (Cal, 2 * Node_Idx + 1, Mid + 1, Node_R, Req_L, Req_R);
         if V2 > Max_Val then
            Max_Val := V2;
         end if;
      end if;
      
      return Max_Val + Cal.Nodes(Node_Idx).Top_Node_Res;
   end Query_Range;

   function Query_Ranges
     (Cal        : Calendar;
      Start_Time : Time_Point;
      End_Time   : Time_Point) return Resource_Amount
   is
      L, R : Natural;
      V1, V2 : Resource_Amount;
   begin
      if Start_Time > End_Time then
         return 0;
      end if;
      
      if (End_Time - Start_Time + 1) >= Time_Point(Cal.Capacity) then
         return Query_Range (Cal, 1, 0, Cal.Capacity - 1, 0, Cal.Capacity - 1);
      else
         L := Natural (Start_Time mod Time_Point(Cal.Capacity));
         R := Natural (End_Time mod Time_Point(Cal.Capacity));
         
         if L <= R then
            return Query_Range (Cal, 1, 0, Cal.Capacity - 1, L, R);
         else
            V1 := Query_Range (Cal, 1, 0, Cal.Capacity - 1, L, Cal.Capacity - 1);
            V2 := Query_Range (Cal, 1, 0, Cal.Capacity - 1, 0, R);
            if V1 > V2 then
               return V1;
            else
               return V2;
            end if;
         end if;
      end if;
   end Query_Ranges;

   function Get_Current_Start (Cal : Calendar) return Time_Point is
   begin
      return Cal.Current_Start;
   end Get_Current_Start;

   function Check_Availability
     (Cal          : Calendar;
      Start_Time   : Time_Point;
      End_Time     : Time_Point;
      Amount       : Resource_Amount;
      Max_Capacity : Resource_Amount) return Boolean
   is
   begin
      -- Prevent querying past the current active window
      if Start_Time < Cal.Current_Start or else End_Time >= Cal.Current_Start + Time_Point(Cal.Capacity) then
         return False; 
      end if;
      
      return (Query_Ranges (Cal, Start_Time, End_Time) + Amount) <= Max_Capacity;
   end Check_Availability;

   procedure Reserve
     (Cal        : in out Calendar;
      Start_Time : Time_Point;
      End_Time   : Time_Point;
      Amount     : Resource_Amount;
      ID         : out Reservation_ID;
      Success    : out Boolean)
   is
      New_ID : Integer := Integer(Cal.Last_ID);
      Found  : Boolean := False;
   begin
      Success := False;
      ID := 1;
      
      if Start_Time < Cal.Current_Start or else End_Time >= Cal.Current_Start + Time_Point(Cal.Capacity) then
         return; -- Out of window bounds
      end if;
      
      for I in 1 .. Cal.Max_Reservations loop
         if not Cal.Reservations(New_ID).Is_Active then
            Found := True;
            exit;
         end if;
         New_ID := (if New_ID = Cal.Max_Reservations then 1 else New_ID + 1);
      end loop;
      
      if not Found then
         return; 
      end if;
      
      Apply_To_Ranges (Cal, Start_Time, End_Time, Amount, True);
      
      -- Insert at the head of the Active list
      Cal.Reservations(New_ID) := (Is_Active  => True,
                                   Start_Time => Start_Time,
                                   End_Time   => End_Time,
                                   Amount     => Amount,
                                   Prev       => 0,
                                   Next       => Cal.Active_Head);
                                   
      if Cal.Active_Head /= 0 then
         Cal.Reservations(Integer(Cal.Active_Head)).Prev := Optional_ID(New_ID);
      end if;
      Cal.Active_Head := Optional_ID(New_ID);
      
      Cal.Last_ID := Reservation_ID(New_ID);
      ID := Reservation_ID(New_ID);
      Success := True;
   end Reserve;

   procedure Delete_Reservation
     (Cal : in out Calendar;
      ID  : Reservation_ID)
   is
   begin
      if Integer(ID) <= Cal.Max_Reservations and then Cal.Reservations(Integer(ID)).Is_Active then
         Apply_To_Ranges (Cal, Cal.Reservations(Integer(ID)).Start_Time, Cal.Reservations(Integer(ID)).End_Time, Cal.Reservations(Integer(ID)).Amount, False);
         Cal.Reservations(Integer(ID)).Is_Active := False;
         
         -- Detach from Active List
         if Cal.Reservations(Integer(ID)).Prev /= 0 then
            Cal.Reservations(Integer(Cal.Reservations(Integer(ID)).Prev)).Next := Cal.Reservations(Integer(ID)).Next;
         else
            Cal.Active_Head := Cal.Reservations(Integer(ID)).Next;
         end if;
         
         if Cal.Reservations(Integer(ID)).Next /= 0 then
            Cal.Reservations(Integer(Cal.Reservations(Integer(ID)).Next)).Prev := Cal.Reservations(Integer(ID)).Prev;
         end if;
      end if;
   end Delete_Reservation;

   procedure Move_Forward
     (Cal   : in out Calendar;
      Shift : Natural := 1)
   is
      New_Start : Time_Point;
      Curr      : Optional_ID := Cal.Active_Head;
      Next_Node : Optional_ID;
   begin
      if Shift = 0 then return; end if;
      
      New_Start := Cal.Current_Start + Time_Point(Shift);
      
      -- Traverse active reservations to prevent tracking tags from bleeding across 
      -- boundaries via the modulo structure.
      while Curr /= 0 loop
         Next_Node := Cal.Reservations(Integer(Curr)).Next;
         
         if Cal.Reservations(Integer(Curr)).End_Time < New_Start then
            -- Time completely expired
            Delete_Reservation (Cal, Reservation_ID(Curr));
            
         elsif Cal.Reservations(Integer(Curr)).Start_Time < New_Start then
            -- Straddles sliding window boundary; drop the expired time slice
            declare
               ID : constant Reservation_ID := Reservation_ID(Curr);
               R_End : constant Time_Point := Cal.Reservations(Integer(ID)).End_Time;
               R_Amt : constant Resource_Amount := Cal.Reservations(Integer(ID)).Amount;
            begin
               Apply_To_Ranges (Cal, Cal.Reservations(Integer(ID)).Start_Time, R_End, R_Amt, False);
               Cal.Reservations(Integer(ID)).Start_Time := New_Start;
               Apply_To_Ranges (Cal, New_Start, R_End, R_Amt, True);
            end;
         end if;
         
         Curr := Next_Node;
      end loop;
      
      Cal.Current_Start := New_Start;
   end Move_Forward;

end Top_Nodes_Algorithm;
