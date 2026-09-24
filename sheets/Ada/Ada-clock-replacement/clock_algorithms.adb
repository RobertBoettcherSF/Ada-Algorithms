package body Clock_Algorithms is

   function Get_Page_Faults (Algo : Base_Algorithm) return Natural is
   begin
      return Algo.Page_Faults;
   end Get_Page_Faults;

   function Get_Hit_Rate (Algo : Base_Algorithm) return Float is
   begin
      if Algo.Accesses = 0 then
         return 0.0;
      end if;
      return Float (Algo.Accesses - Algo.Page_Faults) / Float (Algo.Accesses);
   end Get_Hit_Rate;


   -- ========================================================
   -- 1. Standard Clock
   -- ========================================================
   function Init_Clock (Capacity : Natural) return Clock_Algo is
   begin
      return (Capacity => Capacity, Page_Faults => 0, 
              Accesses => 0, Frames => (others => (0, False)), Hand => 1, Count => 0);
   end Init_Clock;

   procedure Access_Page (Algo : in out Clock_Algo; Page : Page_ID) is
   begin
      Algo.Accesses := Algo.Accesses + 1;
      
      -- Hit check
      for I in 1 .. Algo.Count loop
         if Algo.Frames(I).Page = Page then
            Algo.Frames(I).Ref := True;
            return;
         end if;
      end loop;

      -- Fault
      Algo.Page_Faults := Algo.Page_Faults + 1;

      if Algo.Count < Algo.Capacity then
         Algo.Count := Algo.Count + 1;
         Algo.Frames(Algo.Count) := (Page, True);
      else
         loop
            if Algo.Frames(Algo.Hand).Ref then
               Algo.Frames(Algo.Hand).Ref := False;
               if Algo.Hand = Algo.Capacity then
                  Algo.Hand := 1;
               else
                  Algo.Hand := Algo.Hand + 1;
               end if;
            else
               Algo.Frames(Algo.Hand) := (Page, True);
               if Algo.Hand = Algo.Capacity then
                  Algo.Hand := 1;
               else
                  Algo.Hand := Algo.Hand + 1;
               end if;
               exit;
            end if;
         end loop;
      end if;
   end Access_Page;


   -- ========================================================
   -- 2. GCLOCK
   -- ========================================================
   function Init_GCLOCK (Capacity : Natural; Max_Count : Natural := 2) return GCLOCK_Algo is
   begin
      return (Capacity => Capacity, Page_Faults => 0, 
              Accesses => 0, Frames => (others => (0, 0)), Hand => 1, Count => 0, Max_Count => Max_Count);
   end Init_GCLOCK;

   procedure Access_Page (Algo : in out GCLOCK_Algo; Page : Page_ID) is
   begin
      Algo.Accesses := Algo.Accesses + 1;
      for I in 1 .. Algo.Count loop
         if Algo.Frames(I).Page = Page then
            Algo.Frames(I).Count := Algo.Max_Count;
            return;
         end if;
      end loop;

      Algo.Page_Faults := Algo.Page_Faults + 1;

      if Algo.Count < Algo.Capacity then
         Algo.Count := Algo.Count + 1;
         Algo.Frames(Algo.Count) := (Page, Algo.Max_Count);
      else
         loop
            if Algo.Frames(Algo.Hand).Count > 0 then
               Algo.Frames(Algo.Hand).Count := Algo.Frames(Algo.Hand).Count - 1;
               if Algo.Hand = Algo.Capacity then
                  Algo.Hand := 1;
               else
                  Algo.Hand := Algo.Hand + 1;
               end if;
            else
               Algo.Frames(Algo.Hand) := (Page, Algo.Max_Count);
               if Algo.Hand = Algo.Capacity then
                  Algo.Hand := 1;
               else
                  Algo.Hand := Algo.Hand + 1;
               end if;
               exit;
            end if;
         end loop;
      end if;
   end Access_Page;


   -- ========================================================
   -- 3. WSClock
   -- ========================================================
   function Init_WSClock (Capacity : Natural; Tau : Natural := 10) return WSClock_Algo is
   begin
      return (Capacity => Capacity, Page_Faults => 0, 
              Accesses => 0, Frames => (others => (0, False, 0)), Hand => 1, Count => 0, Tau => Tau, Time => 0);
   end Init_WSClock;

   procedure Access_Page (Algo : in out WSClock_Algo; Page : Page_ID) is
      Starting_Hand : Natural;
      -- Found_Slot    : Boolean := False;
   begin
      Algo.Accesses := Algo.Accesses + 1;
      Algo.Time := Algo.Time + 1;

      -- Hit check
      for I in 1 .. Algo.Count loop
         if Algo.Frames(I).Page = Page then
            Algo.Frames(I).Ref := True;
            Algo.Frames(I).Last_Access := Algo.Time;
            return;
         end if;
      end loop;

      -- Fault
      Algo.Page_Faults := Algo.Page_Faults + 1;

      if Algo.Count < Algo.Capacity then
         Algo.Count := Algo.Count + 1;
         Algo.Frames(Algo.Count) := (Page, True, Algo.Time);
      else
         Starting_Hand := Algo.Hand;
         loop
            if Algo.Frames(Algo.Hand).Ref then
               Algo.Frames(Algo.Hand).Ref := False;
               Algo.Frames(Algo.Hand).Last_Access := Algo.Time;
            else
               if Algo.Time - Algo.Frames(Algo.Hand).Last_Access > Algo.Tau then
                  Algo.Frames(Algo.Hand) := (Page, True, Algo.Time);
                  -- Found_Slot := True;
                  if Algo.Hand = Algo.Capacity then
                     Algo.Hand := 1;
                  else
                     Algo.Hand := Algo.Hand + 1;
                  end if;
                  exit;
               end if;
            end if;

            if Algo.Hand = Algo.Capacity then
               Algo.Hand := 1;
            else
               Algo.Hand := Algo.Hand + 1;
            end if;
            
            if Algo.Hand = Starting_Hand then
               -- Failsafe: if all items are active or recently accessed, replace at current hand
               Algo.Frames(Algo.Hand) := (Page, True, Algo.Time);
               -- Found_Slot := True;
               if Algo.Hand = Algo.Capacity then
                  Algo.Hand := 1;
               else
                  Algo.Hand := Algo.Hand + 1;
               end if;
               exit;
            end if;
         end loop;
      end if;
   end Access_Page;


   -- ========================================================
   -- 4. CAR
   -- ========================================================
   function Init_CAR (Capacity : Natural) return CAR_Algo is
   begin
      return (Capacity => Capacity, Page_Faults => 0, Accesses => 0, P => 0, others => <>);
   end Init_CAR;

   procedure Access_Page (Algo : in out CAR_Algo; Page : Page_ID) is
      use CAR_Vectors;
      use Page_Vectors;

      function Find_In_CAR (Vec : in out CAR_Vectors.Vector; P : Page_ID) return Boolean is
      begin
         for I in 0 .. Natural(Vec.Length) - 1 loop
            if Vec.Element(I).Page = P then
               declare
                  Item : CAR_Entry := Vec.Element(I);
               begin
                  Item.Ref := True;
                  Vec.Replace_Element(I, Item);
               end;
               return True;
            end if;
         end loop;
         return False;
      end Find_In_CAR;

      function Find_In_Page (Vec : Page_Vectors.Vector; P : Page_ID) return Integer is
      begin
         for I in 0 .. Natural(Vec.Length) - 1 loop
            if Vec.Element(I) = P then
               return I;
            end if;
         end loop;
         return -1;
      end Find_In_Page;

      procedure Replace is
         Item : CAR_Entry;
      begin
         loop
            if Natural(Algo.T1.Length) >= 1 and then
               (Natural(Algo.T1.Length) >= Algo.P or else Natural(Algo.T2.Length) = 0) then
               Item := Algo.T1.Element(0);
               Algo.T1.Delete(0);
               if Item.Ref then
                  Item.Ref := False;
                  Algo.T1.Append(Item);
               else
                  Algo.B1.Append(Item.Page);
                  exit;
               end if;
            elsif Natural(Algo.T2.Length) >= 1 then
               Item := Algo.T2.Element(0);
               Algo.T2.Delete(0);
               if Item.Ref then
                  Item.Ref := False;
                  Algo.T2.Append(Item);
               else
                  Algo.B2.Append(Item.Page);
                  exit;
               end if;
            else
               exit;
            end if;
         end loop;
      end Replace;

      Idx : Integer;
   begin
      Algo.Accesses := Algo.Accesses + 1;

      -- Check resident lists (Hits)
      if Find_In_CAR (Algo.T1, Page) or else Find_In_CAR (Algo.T2, Page) then return; end if;
      Algo.Page_Faults := Algo.Page_Faults + 1;

      -- Adjust target capacity 'P' dynamically based on Hit in History lists
      Idx := Find_In_Page (Algo.B1, Page);
      if Idx >= 0 then
         Algo.P := Integer'Min (Algo.Capacity, Algo.P + Integer'Max (1, Natural(Algo.B2.Length) / Integer'Max(1, Natural(Algo.B1.Length))));
         Algo.B1.Delete(Idx);
         Replace;
         Algo.T2.Append((Page => Page, Ref => False));
         return;
      end if;

      Idx := Find_In_Page (Algo.B2, Page);
      if Idx >= 0 then
         Algo.P := Integer'Max (0, Algo.P - Integer'Max (1, Natural(Algo.B1.Length) / Integer'Max(1, Natural(Algo.B2.Length))));
         Algo.B2.Delete(Idx);
         Replace;
         Algo.T2.Append((Page => Page, Ref => False));
         return;
      end if;

      -- Capacity Control Limits
      if Natural(Algo.T1.Length) + Natural(Algo.T2.Length) = Algo.Capacity then
         Replace;
         if Natural(Algo.B1.Length) > 0 and then
            Natural(Algo.T1.Length) + Natural(Algo.B1.Length) >= Algo.Capacity then
            Algo.B1.Delete(0);
         elsif Natural(Algo.B2.Length) > 0 then
            Algo.B2.Delete(0);
         end if;
      elsif Natural(Algo.T1.Length) + Natural(Algo.T2.Length) + Natural(Algo.B1.Length) + Natural(Algo.B2.Length) >= Algo.Capacity then
         if Natural(Algo.T1.Length) + Natural(Algo.T2.Length) + Natural(Algo.B1.Length) + Natural(Algo.B2.Length) >= 2 * Algo.Capacity then
             if Natural(Algo.B1.Length) > 0 then
                 Algo.B1.Delete(0);
             elsif Natural(Algo.B2.Length) > 0 then
                 Algo.B2.Delete(0);
             end if;
         end if;
      end if;

      Algo.T1.Append((Page => Page, Ref => False));
   end Access_Page;


   -- ========================================================
   -- 5. Clock-Pro
   -- ========================================================
   function Init_Clock_Pro (Capacity : Natural) return Clock_Pro_Algo is
   begin
      return (Capacity => Capacity, M => Capacity / 2, Page_Faults => 0, Accesses => 0, others => <>);
   end Init_Clock_Pro;

   procedure Access_Page (Algo : in out Clock_Pro_Algo; Page : Page_ID) is
      use Clock_Pro_Lists;

      procedure Advance (Cursor : in out Clock_Pro_Lists.Cursor) is
      begin
         Cursor := Next (Cursor);
         if not Has_Element (Cursor) then
            Cursor := First (Algo.L);
         end if;
      end Advance;

      function Find_Node (P : Page_ID) return Clock_Pro_Lists.Cursor is
         C : Clock_Pro_Lists.Cursor := First (Algo.L);
      begin
         while Has_Element (C) loop
            if Element(C).Page = P then return C; end if;
            C := Next (C);
         end loop;
         return No_Element;
      end Find_Node;

      C : Clock_Pro_Lists.Cursor;
      Item : Clock_Pro_Entry;
   begin
      Algo.Accesses := Algo.Accesses + 1;
      C := Find_Node (Page);

      if Has_Element (C) then
         Item := Element(C);
         Item.Ref := True;

         -- Page Promotion (Test hit implies the page loop was large)
         if Item.PT = Test then
            Algo.Page_Faults := Algo.Page_Faults + 1;
            Item.PT := Hot;
            Algo.Hot_Count := Algo.Hot_Count + 1;
            Algo.Resident_Count := Algo.Resident_Count + 1;
         elsif Item.PT = Cold then
            Item.PT := Hot;
            Algo.Hot_Count := Algo.Hot_Count + 1;
         end if;

         Algo.L.Replace_Element(C, Item);
      else
         Algo.Page_Faults := Algo.Page_Faults + 1;
         
         -- Eviction Protocol
         if Algo.Resident_Count >= Algo.Capacity then
             if Has_Element (Algo.Hand_Cold) then
                 loop
                     declare
                         Cold_Item : Clock_Pro_Entry := Element (Algo.Hand_Cold);
                     begin
                         if Cold_Item.PT = Cold then
                             if Cold_Item.Ref then
                                 Cold_Item.Ref := False;
                                 Cold_Item.PT := Hot;
                                 Algo.Hot_Count := Algo.Hot_Count + 1;
                                 Algo.L.Replace_Element(Algo.Hand_Cold, Cold_Item);
                             else
                                 -- Turn Cold Resident Page into Non-Resident Test Page
                                 Cold_Item.PT := Test;
                                 Algo.Resident_Count := Algo.Resident_Count - 1;
                                 Algo.L.Replace_Element(Algo.Hand_Cold, Cold_Item);
                                 Advance(Algo.Hand_Cold);
                                 exit;
                             end if;
                         end if;
                         Advance(Algo.Hand_Cold);
                     end;
                 end loop;
             end if;
         end if;

         Algo.L.Append ((Page => Page, PT => Cold, Ref => False));
         Algo.Resident_Count := Algo.Resident_Count + 1;

         if not Has_Element (Algo.Hand_Cold) then
            Algo.Hand_Cold := First (Algo.L);
         end if;
      end if;
   end Access_Page;

end Clock_Algorithms;
