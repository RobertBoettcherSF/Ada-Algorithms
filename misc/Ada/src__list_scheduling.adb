with Ada.Containers; use Ada.Containers;

package body List_Scheduling is

   -- 1. Arbitrary Order List Scheduling
   function Basic_List_Scheduling
     (Jobs      : Job_List;
      Durations : Job_Duration_Array;
      M         : Machine_ID) return Schedule_List
   is
      Result : Schedule_List;
      Machine_Avail : array (Machine_ID range 1 .. M) of Time_Type := (others => 0);
      Best_Mach : Machine_ID;
      Min_Avail : Time_Type;
   begin
      for I in Jobs'Range loop
         declare
            J : constant Job_ID := Jobs(I);
         begin
            -- Find the machine that becomes available the earliest
            Best_Mach := 1;
            Min_Avail := Machine_Avail(1);
            for Mach in Machine_ID range 2 .. M loop
               if Machine_Avail(Mach) < Min_Avail then
                  Min_Avail := Machine_Avail(Mach);
                  Best_Mach := Mach;
               end if;
            end loop;
            
            -- Assign the job
            Result.Append ((Job        => J,
                            Machine    => Best_Mach,
                            Start_Time => Min_Avail,
                            End_Time   => Min_Avail + Durations(J)));
                            
            Machine_Avail(Best_Mach) := Min_Avail + Durations(J);
         end;
      end loop;
      return Result;
   end Basic_List_Scheduling;

   -- 2. LPT (Longest Processing Time First)
   function LPT_Scheduling
     (Durations : Job_Duration_Array;
      M         : Machine_ID) return Schedule_List
   is
      Temp_Jobs : Job_List(1 .. Durations'Length);
      Count     : Natural := 0;
      
      -- Helper procedure to sort descending by processing time
      procedure Sort is
         Temp : Job_ID;
      begin
         for I in Temp_Jobs'First .. Temp_Jobs'Last - 1 loop
            for J in I + 1 .. Temp_Jobs'Last loop
               if Durations(Temp_Jobs(J)) > Durations(Temp_Jobs(I)) then
                  Temp := Temp_Jobs(I);
                  Temp_Jobs(I) := Temp_Jobs(J);
                  Temp_Jobs(J) := Temp;
               end if;
            end loop;
         end loop;
      end Sort;
      
   begin
      for J in Durations'Range loop
         Count := Count + 1;
         Temp_Jobs(Count) := J;
      end loop;
      
      Sort;
      return Basic_List_Scheduling(Temp_Jobs, Durations, M);
   end LPT_Scheduling;

   -- 3. HLF (Highest Level First)
   function HLF_Scheduling
     (DAG : DAG_Array;
      M   : Machine_ID) return Schedule_List
   is
      type Level_Array is array (DAG'Range) of Time_Type;
      Levels : Level_Array := (others => 0);
      Visited : array (DAG'Range) of Boolean := (others => False);
      
      -- Recursive topological evaluation of nodes' bottom limits
      procedure Compute_Levels (J : Job_ID) is
         Max_Succ_Level : Time_Type := 0;
      begin
         if Visited (J) then return; end if;
         for I in 1 .. Natural(DAG(J).Successors.Length) loop
            declare
               Succ : constant Job_ID := DAG(J).Successors.Element(I);
            begin
               Compute_Levels (Succ);
               if Levels (Succ) > Max_Succ_Level then
                  Max_Succ_Level := Levels (Succ);
               end if;
            end;
         end loop;
         Levels (J) := DAG(J).Duration + Max_Succ_Level;
         Visited (J) := True;
      end Compute_Levels;
      
      In_Degree : array (DAG'Range) of Natural := (others => 0);
      Ready_List : Job_Vectors.Vector;
      Completed_Count : Natural := 0;
      Total_Jobs : constant Natural := DAG'Length;
      
      type Machine_State is record
         Idle      : Boolean := True;
         Job       : Job_ID := Job_ID'First;
         Done_Time : Time_Type := 0;
      end record;
      Machines : array (Machine_ID range 1 .. M) of Machine_State;
      
      Current_Time : Time_Type := 0;
      Result : Schedule_List;
      
      procedure Sort_Ready_List is
         Temp : Job_ID;
      begin
         if Ready_List.Length < 2 then return; end if;
         for I in 1 .. Natural(Ready_List.Length) - 1 loop
            for K in I + 1 .. Natural(Ready_List.Length) loop
               if Levels(Ready_List.Element(K)) > Levels(Ready_List.Element(I)) then
                  Temp := Ready_List.Element(I);
                  Ready_List.Replace_Element(I, Ready_List.Element(K));
                  Ready_List.Replace_Element(K, Temp);
               end if;
            end loop;
         end loop;
      end Sort_Ready_List;
      
   begin
      for J in DAG'Range loop
         if not Visited(J) then
            Compute_Levels (J);
         end if;
      end loop;
      
      -- Prime ready queue with zero-indegree jobs (dependencies cleared)
      for J in DAG'Range loop
         In_Degree(J) := Natural(DAG(J).Predecessors.Length);
         if In_Degree(J) = 0 then
            Ready_List.Append(J);
         end if;
      end loop;
      
      -- Discrete event simulation loop traversing the graph
      while Completed_Count < Total_Jobs loop
         
         -- Free machines where jobs just completed, inject unlocked downstream into queue
         for Mach in Machine_ID range 1 .. M loop
            if not Machines(Mach).Idle and then Machines(Mach).Done_Time <= Current_Time then
               declare
                  Done_Job : constant Job_ID := Machines(Mach).Job;
               begin
                  Machines(Mach).Idle := True;
                  Completed_Count := Completed_Count + 1;
                  for I in 1 .. Natural(DAG(Done_Job).Successors.Length) loop
                     declare
                        Succ : constant Job_ID := DAG(Done_Job).Successors.Element(I);
                     begin
                        In_Degree(Succ) := In_Degree(Succ) - 1;
                        if In_Degree(Succ) = 0 then
                           Ready_List.Append(Succ);
                        end if;
                     end;
                  end loop;
               end;
            end if;
         end loop;
         
         Sort_Ready_List;
         
         -- Disperse jobs to available hardware by Priority Map
         for Mach in Machine_ID range 1 .. M loop
            if Machines(Mach).Idle and then not Ready_List.Is_Empty then
               declare
                  Next_Job : constant Job_ID := Ready_List.First_Element;
               begin
                  Ready_List.Delete_First;
                  Machines(Mach).Idle := False;
                  Machines(Mach).Job := Next_Job;
                  Machines(Mach).Done_Time := Current_Time + DAG(Next_Job).Duration;
                  
                  Result.Append ((Job        => Next_Job,
                                  Machine    => Mach,
                                  Start_Time => Current_Time,
                                  End_Time   => Machines(Mach).Done_Time));
               end;
            end if;
         end loop;
         
         -- Jump time clock to the immediate next finishing job
         if Completed_Count < Total_Jobs then
            declare
               Next_Time : Time_Type := Time_Type'Last;
               Advancing : Boolean := False;
            begin
               for Mach in Machine_ID range 1 .. M loop
                  if not Machines(Mach).Idle then
                     if Machines(Mach).Done_Time < Next_Time then
                        Next_Time := Machines(Mach).Done_Time;
                        Advancing := True;
                     end if;
                  end if;
               end loop;
               if Advancing then
                  Current_Time := Next_Time;
               else
                  exit; -- Break sequence error / infinite lock 
               end if;
            end;
         end if;
      end loop;
      
      return Result;
   end HLF_Scheduling;

   -- 4. HEFT (Heterogeneous Earliest Finish Time)
   function HEFT_Scheduling
     (DAG       : DAG_Array;
      Durations : Duration_Matrix;
      M         : Machine_ID) return Schedule_List
   is
      type Rank_Array is array (DAG'Range) of Float;
      Ranks : Rank_Array := (others => 0.0);
      Visited : array (DAG'Range) of Boolean := (others => False);
      Avg_Durations : array (DAG'Range) of Float;
      
      -- Resolve composite heterogeneous weights utilizing an Upward Rank recursive descent
      procedure Compute_Ranks (J : Job_ID) is
         Max_Succ_Rank : Float := 0.0;
      begin
         if Visited (J) then return; end if;
         for I in 1 .. Natural(DAG(J).Successors.Length) loop
            declare
               Succ : constant Job_ID := DAG(J).Successors.Element(I);
            begin
               Compute_Ranks (Succ);
               if Ranks (Succ) > Max_Succ_Rank then
                  Max_Succ_Rank := Ranks (Succ);
               end if;
            end;
         end loop;
         Ranks (J) := Avg_Durations (J) + Max_Succ_Rank;
         Visited (J) := True;
      end Compute_Ranks;
      
      Sorted_Jobs : Job_List(1 .. DAG'Length);
      Count : Natural := 0;
      
      procedure Sort_Jobs_By_Rank is
         Temp : Job_ID;
      begin
         for I in Sorted_Jobs'First .. Sorted_Jobs'Last - 1 loop
            for K in I + 1 .. Sorted_Jobs'Last loop
               if Ranks(Sorted_Jobs(K)) > Ranks(Sorted_Jobs(I)) then
                  Temp := Sorted_Jobs(I);
                  Sorted_Jobs(I) := Sorted_Jobs(K);
                  Sorted_Jobs(K) := Temp;
               end if;
            end loop;
         end loop;
      end Sort_Jobs_By_Rank;

      Machine_Avail : array (Machine_ID range 1 .. M) of Time_Type := (others => 0);
      Job_Finish_Time : array (DAG'Range) of Time_Type := (others => 0);
      Result : Schedule_List;
      
   begin
      -- Build normalized weightings over heterogenous execution grids
      for J in DAG'Range loop
         declare
            Sum : Natural := 0;
         begin
            for Mach in Machine_ID range 1 .. M loop
               Sum := Sum + Natural(Durations(J, Mach));
            end loop;
            Avg_Durations(J) := Float(Sum) / Float(M);
         end;
      end loop;
      
      for J in DAG'Range loop
         if not Visited(J) then
            Compute_Ranks(J);
         end if;
      end loop;
      
      for J in DAG'Range loop
         Count := Count + 1;
         Sorted_Jobs(Count) := J;
      end loop;
      Sort_Jobs_By_Rank;
      
      -- Place sequentially looking strictly for the absolute fastest finishing combination
      for I in Sorted_Jobs'Range loop
         declare
            J : constant Job_ID := Sorted_Jobs(I);
            Best_Mach : Machine_ID := 1;
            Min_EFT : Time_Type := Time_Type'Last;
            Best_Start_Time : Time_Type := 0;
            
            Pred_Finish_Max : Time_Type := 0;
            Start_Time : Time_Type;
            Finish_Time : Time_Type;
         begin
            for K in 1 .. Natural(DAG(J).Predecessors.Length) loop
               declare
                  Pred : constant Job_ID := DAG(J).Predecessors.Element(K);
               begin
                  if Job_Finish_Time(Pred) > Pred_Finish_Max then
                     Pred_Finish_Max := Job_Finish_Time(Pred);
                  end if;
               end;
            end loop;
            
            for Mach in Machine_ID range 1 .. M loop
               Start_Time := Time_Type'Max(Machine_Avail(Mach), Pred_Finish_Max);
               Finish_Time := Start_Time + Durations(J, Mach);
               
               if Finish_Time < Min_EFT then
                  Min_EFT := Finish_Time;
                  Best_Mach := Mach;
                  Best_Start_Time := Start_Time;
               end if;
            end loop;
            
            Machine_Avail(Best_Mach) := Min_EFT;
            Job_Finish_Time(J) := Min_EFT;
            Result.Append ((Job        => J,
                            Machine    => Best_Mach,
                            Start_Time => Best_Start_Time,
                            End_Time   => Min_EFT));
         end;
      end loop;
      
      return Result;
   end HEFT_Scheduling;

end List_Scheduling;
