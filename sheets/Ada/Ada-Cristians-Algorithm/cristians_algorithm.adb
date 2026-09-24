-- cristians_algorithm.adb
-- Implementation for Cristian's Clock Synchronization Algorithm

package body Cristians_Algorithm is

   -------------------
   -- Calculate_RTT --
   -------------------
   function Calculate_RTT (Sample : Sync_Sample) return Time_Delta is
      RTT : Time_Delta;
   begin
      if Sample.T_Recv < Sample.T_Send then
         raise Invalid_Time_Error with "Receive time cannot be before Send time";
      end if;
      
      RTT := Time_Delta (Sample.T_Recv - Sample.T_Send);
      return RTT;
   end Calculate_RTT;

   -----------------------
   -- Synchronize_Basic --
   -----------------------
   function Synchronize_Basic (Sample : Sync_Sample) return Timestamp is
      RTT          : Time_Delta;
      One_Way_Time : Time_Delta;
   begin
      RTT := Calculate_RTT (Sample);
      One_Way_Time := RTT / 2.0;
      
      -- New Time = Server Time + (RTT / 2)
      return Sample.T_Server + Timestamp (One_Way_Time);
   end Synchronize_Basic;

   --------------------------------
   -- Synchronize_With_Threshold --
   --------------------------------
   function Synchronize_With_Threshold 
     (Sample  : Sync_Sample; 
      Max_RTT : Time_Delta) return Timestamp 
   is
      RTT : Time_Delta;
   begin
      RTT := Calculate_RTT (Sample);
      
      -- Reject samples affected by heavy network delays (outliers)
      if RTT > Max_RTT then
         raise Outlier_Error with "Round Trip Time exceeds maximum allowed threshold";
      end if;
      
      return Synchronize_Basic (Sample);
   end Synchronize_With_Threshold;

   --------------------------
   -- Synchronize_Multiple --
   --------------------------
   function Synchronize_Multiple (Samples : Sample_Array) return Timestamp is
      Min_RTT     : Time_Delta := Time_Delta'Last;
      Current_RTT : Time_Delta;
      Best_Sample : Sync_Sample;
      Found       : Boolean := False;
   begin
      if Samples'Length = 0 then
         raise No_Valid_Samples_Error with "Empty sample array provided";
      end if;

      -- Iterate to find the sample with the shortest Round Trip Time
      for I in Samples'Range loop
         Current_RTT := Calculate_RTT (Samples (I));
         if Current_RTT < Min_RTT then
            Min_RTT := Current_RTT;
            Best_Sample := Samples (I);
            Found := True;
         end if;
      end loop;

      if not Found then
         raise No_Valid_Samples_Error with "Could not determine a valid sample";
      end if;

      return Synchronize_Basic (Best_Sample);
   end Synchronize_Multiple;

   ---------------------------
   -- Calculate_Error_Bound --
   ---------------------------
   function Calculate_Error_Bound 
     (Sample    : Sync_Sample; 
      Min_Delay : Time_Delta) return Time_Delta 
   is
      RTT : Time_Delta;
   begin
      RTT := Calculate_RTT (Sample);
      
      if Min_Delay > RTT then
         raise Invalid_Delay_Error with "Minimum physical delay cannot exceed observed RTT";
      end if;
      
      -- Error bound = ± (RTT - Minimum_Delay) / 2
      return (RTT - Min_Delay) / 2.0;
   end Calculate_Error_Bound;

end Cristians_Algorithm;
