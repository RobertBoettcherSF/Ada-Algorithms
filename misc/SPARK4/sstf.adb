package body SSTF with SPARK_Mode is

   procedure Get_SSTF_Schedule
     (Initial_Head : in     Track_Index;
      Requests     : in     Track_Array;
      Schedule     :    out Track_Array)
   is
      -- Keep track of which requests have already been serviced
      type Visited_Array is array (Requests'Range) of Boolean;
      Visited : Visited_Array := (others => False);

      Current_Head : Track_Index := Initial_Head;
      Min_Dist     : Track_Index;
      Best_Idx     : Integer;
      Dist         : Track_Index;
   begin
      -- We must generate a schedule of the same length as the requests
      for I in Schedule'Range loop
         
         Min_Dist := Track_Index'Last;
         Best_Idx := Requests'First; 
         
         -- Find the closest unvisited track request
         -- Loop invariant: Best_Idx is always a valid index in Requests'Range
         for J in Requests'Range loop
            pragma Loop_Invariant (Best_Idx >= Requests'First and Best_Idx <= Requests'Last);
            
            if not Visited (J) then
               
               -- Calculate absolute distance safely without risking negative overflow
               if Requests (J) >= Current_Head then
                  Dist := Requests (J) - Current_Head;
               else
                  Dist := Current_Head - Requests (J);
               end if;

               -- Update shortest distance found
               if Dist <= Min_Dist then
                  Min_Dist := Dist;
                  Best_Idx := J;
               end if;
               
            end if;
         end loop;

         -- Mark the chosen track as visited
         Visited (Best_Idx) := True;
         
         -- Move the head to the new track and record it in the schedule
         Current_Head := Requests (Best_Idx);
         Schedule (I) := Current_Head;
         
      end loop;
   end Get_SSTF_Schedule;

end SSTF;
