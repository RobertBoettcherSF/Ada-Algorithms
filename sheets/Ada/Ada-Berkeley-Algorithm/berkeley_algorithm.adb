-- berkeley_algorithm.adb
-- Implementation of the Berkeley Algorithm variants.

package body Berkeley_Algorithm is

   -----------------------
   -- Calculate_Offsets --
   -----------------------
   procedure Calculate_Offsets
     (Master_Time : in  Time_Value;
      Slaves      : in  Slave_Array;
      Master_Adj  : out Time_Offset;
      Slave_Adjs  : out Offset_Array)
   is
      Total_Sum   : Long_Long_Integer := Long_Long_Integer (Master_Time);
      Valid_Count : Long_Long_Integer := 1; -- Includes Master
      Avg_Time    : Time_Value;
   begin
      -- Step 1: Calculate the estimated current time of all slaves
      for I in Slaves'Range loop
         if Slaves (I).Round_Trip_Time < 0 then
            raise Invalid_Data_Error;
         end if;

         declare
            -- Master estimates slave's time by adding half the RTT
            Estimated_Time : constant Time_Value :=
              Slaves (I).Reported_Time + (Slaves (I).Round_Trip_Time / 2);
         begin
            Total_Sum   := Total_Sum + Long_Long_Integer (Estimated_Time);
            Valid_Count := Valid_Count + 1;
         end;
      end loop;

      -- Step 2: Compute the average time
      Avg_Time := Time_Value (Total_Sum / Valid_Count);

      -- Step 3: Calculate adjustments
      Master_Adj := Time_Offset (Avg_Time) - Time_Offset (Master_Time);

      for I in Slaves'Range loop
         declare
            Estimated_Time : constant Time_Value :=
              Slaves (I).Reported_Time + (Slaves (I).Round_Trip_Time / 2);
         begin
            Slave_Adjs (I).ID     := Slaves (I).ID;
            Slave_Adjs (I).Offset := Time_Offset (Avg_Time) - Time_Offset (Estimated_Time);
         end;
      end loop;
   end Calculate_Offsets;

   --------------------------------------
   -- Calculate_Fault_Tolerant_Offsets --
   --------------------------------------
   procedure Calculate_Fault_Tolerant_Offsets
     (Master_Time   : in  Time_Value;
      Slaves        : in  Slave_Array;
      Max_Tolerance : in  Time_Value;
      Master_Adj    : out Time_Offset;
      Slave_Adjs    : out Offset_Array)
   is
      Total_Sum   : Long_Long_Integer := Long_Long_Integer (Master_Time);
      Valid_Count : Long_Long_Integer := 1; -- Master is always assumed valid initially
      Avg_Time    : Time_Value;
   begin
      if Max_Tolerance < 0 then
         raise Invalid_Data_Error;
      end if;

      -- Step 1: Filter outliers based on Max_Tolerance and sum valid clocks
      for I in Slaves'Range loop
         if Slaves (I).Round_Trip_Time < 0 then
            raise Invalid_Data_Error;
         end if;

         declare
            Estimated_Time : constant Time_Value :=
              Slaves (I).Reported_Time + (Slaves (I).Round_Trip_Time / 2);
            Diff : constant Time_Value := abs (Estimated_Time - Master_Time);
         begin
            -- Only include slave if it falls within the tolerance
            if Diff <= Max_Tolerance then
               Total_Sum   := Total_Sum + Long_Long_Integer (Estimated_Time);
               Valid_Count := Valid_Count + 1;
            end if;
         end;
      end loop;

      -- Step 2: Compute average of valid nodes
      Avg_Time := Time_Value (Total_Sum / Valid_Count);

      -- Step 3: Calculate adjustments
      Master_Adj := Time_Offset (Avg_Time) - Time_Offset (Master_Time);

      for I in Slaves'Range loop
         declare
            Estimated_Time : constant Time_Value :=
              Slaves (I).Reported_Time + (Slaves (I).Round_Trip_Time / 2);
            Diff : constant Time_Value := abs (Estimated_Time - Master_Time);
         begin
            Slave_Adjs (I).ID := Slaves (I).ID;

            -- If it was an outlier, we can either give it a 0 offset or force it to Avg.
            -- In standard Berkeley FT, we still send the offset to correct the faulty node.
            Slave_Adjs (I).Offset := Time_Offset (Avg_Time) - Time_Offset (Estimated_Time);
         end;
      end loop;
   end Calculate_Fault_Tolerant_Offsets;

end Berkeley_Algorithm;
