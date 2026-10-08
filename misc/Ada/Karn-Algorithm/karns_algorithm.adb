--  Karns_Algorithm.adb
--  
--  Implementation of Karn's Algorithm (Karn-Partridge Algorithm)
--  for Round-Trip Time (RTT) estimation in TCP.
--  
--  Author: Vibe Code (Mistral AI)
--  Date: 2024
--  
--  Description:
--    This package body implements Karn's Algorithm, which resolves the ambiguity
--    in RTT estimation caused by retransmitted segments in TCP. The implementation
--    includes:
--      - Basic Karn's Algorithm (ignores retransmitted segments for RTT updates).
--      - Jacobson's smoothing for RTT and deviation estimates.
--      - Timer backoff strategy for handling stale RTT estimates.
--    
--    The algorithm works as follows:
--      1. When a segment is sent, its send time is recorded.
--      2. When an ACK is received, the RTT is calculated as (ACK.Receive_Time - Segment.Send_Time).
--      3. If the segment was sent only once (First_Transmission), the RTT is used to update
--         the RTT estimate. If the segment was retransmitted, the RTT is ignored.
--      4. If a timeout occurs, the timeout value is doubled (exponential backoff) to avoid
--         stale RTT estimates and improve adaptability to changing network conditions.
--

with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO; use Ada.Text_IO;

package body Karns_Algorithm is

   --  Initializes RTT_Data with default values.
   --  Sets all fields to their initial states:
   --    - Current_RTT_Estimate = 0.0
   --    - Smoothed_RTT = 0.0
   --    - Timeout = 1.0 (initial timeout)
   --    - Alpha = 0.125 (smoothing factor for RTT)
   --    - Beta = 0.25 (smoothing factor for deviation)
   --    - Dev_RTT = 0.0
   procedure Initialize_RTT_Data (Data : out RTT_Data) is
   begin
      Data.Current_RTT_Estimate := 0.0;
      Data.Smoothed_RTT := 0.0;
      Data.Timeout := 1.0;  -- Initial timeout of 1 second
      Data.Alpha := 0.125;  -- Smoothing factor for RTT
      Data.Beta := 0.25;    -- Smoothing factor for deviation
      Data.Dev_RTT := 0.0;  -- Initial deviation
   end Initialize_RTT_Data;

   --  Calculates the Round-Trip Time (RTT) for a segment and its ACK.
   --  RTT is computed as the difference between the ACK's receive time and the segment's send time.
   --  
   --  Parameters:
   --    Seg: The segment for which RTT is calculated.
   --    Ack_Packet: The ACK corresponding to the segment.
   --  Returns:
   --    The RTT as a Duration (in seconds).
   --  Raises:
   --    Invalid_ACK_Exception: If Ack_Packet.ACK_Number does not match Seg.Sequence_Number.
   function Calculate_RTT (Seg : Segment; Ack_Packet : ACK) return Duration is
      RTT : Duration;
   begin
      --  Ensure the ACK matches the segment
      if Seg.Sequence_Number /= Ack_Packet.ACK_Number then
         raise Invalid_ACK_Exception with "ACK does not match segment sequence number";
      end if;
      
      --  Calculate RTT as the difference between ACK receive time and segment send time
      RTT := To_Duration(Ack_Packet.Receive_Time - Seg.Send_Time);
      return RTT;
   end Calculate_RTT;

   --  Updates the RTT estimate using Karn's Algorithm (basic variant).
   --  This procedure implements the core rule of Karn's Algorithm: only unambiguous ACKs
   --  (ACKs for segments sent exactly once) are used to update the RTT estimate.
   --  
   --  Parameters:
   --    Seg: The segment for which the RTT is being updated.
   --    Ack_Packet: The ACK corresponding to the segment.
   --    Data: The RTT_Data structure to update.
   --  Behavior:
   --    - If Seg.Status is Retransmitted, the RTT is ignored (Karn's Algorithm rule).
   --    - Otherwise, the RTT is calculated and used to update Current_RTT_Estimate using
   --      exponential smoothing: New_Estimate = Alpha * RTT + (1 - Alpha) * Old_Estimate.
   --    - Timeout is updated as 2 * Current_RTT_Estimate.
   procedure Update_RTT_Estimate (
      Seg : Segment;
      Ack_Packet : ACK;
      Data : in out RTT_Data) is
   
      RTT : Duration;
   begin
      --  Check if the ACK is unambiguous (i.e., for a First_Transmission segment)
      if Seg.Status /= First_Transmission then
         --  Ignore retransmitted segments (Karn's Algorithm core rule)
         return;
      end if;
      
      --  Calculate RTT for the segment and ACK
      RTT := Calculate_RTT(Seg, Ack_Packet);
      
      --  Update the current RTT estimate (exponential smoothing)
      if Data.Current_RTT_Estimate = 0.0 then
         Data.Current_RTT_Estimate := RTT;
      else
         --  Simple exponential smoothing: New_Estimate = Alpha * RTT + (1 - Alpha) * Old_Estimate
         Data.Current_RTT_Estimate := 
            Duration(Float(Data.Current_RTT_Estimate) * (1.0 - Data.Alpha) + 
                     Float(RTT) * Data.Alpha);
      end if;
      
      --  Update the timeout based on the new RTT estimate
      --  Timeout = RTT_Estimate * 2 (common practice in TCP)
      Data.Timeout := Data.Current_RTT_Estimate * 2.0;
   end Update_RTT_Estimate;

   --  Updates the RTT estimate using Karn's Algorithm with Jacobson's smoothing.
   --  This variant uses Jacobson's algorithm for smoothing RTT and deviation estimates,
   --  which is the standard approach in TCP implementations.
   --  
   --  Parameters:
   --    Seg: The segment for which the RTT is being updated.
   --    Ack_Packet: The ACK corresponding to the segment.
   --    Data: The RTT_Data structure to update.
   --  Behavior:
   --    - If Seg.Status is Retransmitted, the RTT is ignored (Karn's Algorithm rule).
   --    - Otherwise, the RTT is calculated and used to update Smoothed_RTT and Dev_RTT using
   --      Jacobson's algorithm:
   --        Smoothed_RTT = (1 - Alpha) * Smoothed_RTT + Alpha * RTT
   --        Dev_RTT = (1 - Beta) * Dev_RTT + Beta * |RTT - Smoothed_RTT|
   --    - Timeout is updated as Smoothed_RTT + 4 * Dev_RTT (common in TCP).
   procedure Update_RTT_With_Smoothing (
      Seg : Segment;
      Ack_Packet : ACK;
      Data : in out RTT_Data) is
   
      RTT : Duration;
      Error : Duration;
   begin
      --  Check if the ACK is unambiguous (i.e., for a First_Transmission segment)
      if Seg.Status /= First_Transmission then
         --  Ignore retransmitted segments (Karn's Algorithm core rule)
         return;
      end if;
      
      --  Calculate RTT for the segment and ACK
      RTT := Calculate_RTT(Seg, Ack_Packet);
      
      --  Jacobson's algorithm for RTT smoothing
      if Data.Smoothed_RTT = 0.0 then
         Data.Smoothed_RTT := RTT;
         Data.Dev_RTT := 0.0;
      else
         Error := abs (RTT - Data.Smoothed_RTT);
         Data.Smoothed_RTT := 
            Duration(Float(Data.Smoothed_RTT) * (1.0 - Data.Alpha) + 
                     Float(RTT) * Data.Alpha);
         Data.Dev_RTT := 
            Duration(Float(Data.Dev_RTT) * (1.0 - Data.Beta) + 
                     Float(Error) * Data.Beta);
      end if;
      
      --  Update the current RTT estimate
      Data.Current_RTT_Estimate := Data.Smoothed_RTT;
      
      --  Update the timeout: Timeout = Smoothed_RTT + 4 * Dev_RTT (common in TCP)
      Data.Timeout := Data.Smoothed_RTT + 4.0 * Data.Dev_RTT;
   end Update_RTT_With_Smoothing;

   --  Handles retransmission of a segment.
   --  This procedure marks a segment as retransmitted, increments its retransmit count,
   --  and applies timer backoff by doubling the timeout.
   --  
   --  Parameters:
   --    Seg: The segment being retransmitted (updated in place).
   --    Data: The RTT_Data structure to update (timeout is doubled).
   procedure Handle_Retransmission (
      Seg : in out Segment;
      Data : in out RTT_Data) is
   begin
      --  Mark the segment as retransmitted
      Seg.Status := Retransmitted;
      Seg.Retransmit_Count := Seg.Retransmit_Count + 1;
      
      --  Apply timer backoff: Double the timeout
      Data.Timeout := Data.Timeout * 2.0;
   end Handle_Retransmission;

   --  Handles timeout by applying timer backoff.
   --  This procedure doubles the timeout value (exponential backoff) to avoid stale
   --  RTT estimates and improve adaptability to changing network conditions.
   --  
   --  Parameters:
   --    Data: The RTT_Data structure to update (timeout is doubled).
   --  Raises:
   --    Timeout_Too_Small_Exception: If the timeout becomes too small after backoff.
   procedure Handle_Timeout (Data : in out RTT_Data) is
   begin
      --  Double the timeout (exponential backoff)
      Data.Timeout := Data.Timeout * 2.0;
      
      --  Check if timeout is too small (edge case)
      if Data.Timeout < 0.001 then
         raise Timeout_Too_Small_Exception with "Timeout is too small after backoff";
      end if;
   end Handle_Timeout;

   --  Resets the timeout to its initial value (1.0).
   --  This is typically called after a successful transmission to reset the backoff state.
   --  
   --  Parameters:
   --    Data: The RTT_Data structure to update (timeout is set to 1.0).
   procedure Reset_Timeout (Data : in out RTT_Data) is
   begin
      Data.Timeout := 1.0;  -- Reset to initial timeout
   end Reset_Timeout;

   --  Checks if an ACK is unambiguous (i.e., corresponds to a First_Transmission segment).
   --  An ACK is unambiguous if it matches a segment that was sent exactly once.
   --  
   --  Parameters:
   --    Seg: The segment to check.
   --    Ack_Packet: The ACK to check.
   --  Returns:
   --    True if the ACK is unambiguous, False otherwise.
   function Is_Unambiguous_ACK (Seg : Segment; Ack_Packet : ACK) return Boolean is
   begin
      --  ACK is unambiguous if:
      --  1. The ACK number matches the segment sequence number
      --  2. The segment was sent only once (First_Transmission)
      return (Seg.Sequence_Number = Ack_Packet.ACK_Number) and 
             (Seg.Status = First_Transmission);
   end Is_Unambiguous_ACK;

   --  Simulates Karn's Algorithm for an array of segments and ACKs.
   --  This procedure iterates through all ACKs, finds matching segments, and updates
   --  the RTT estimate for unambiguous ACKs. It demonstrates the basic variant of Karn's Algorithm.
   --  
   --  Parameters:
   --    Segments: Array of segments to process (updated in place).
   --    ACKs: Array of ACKs to process.
   --    Data: The RTT_Data structure to update.
   --  Raises:
   --    Invalid_ACK_Exception: If an ACK does not match any segment.
   procedure Simulate_Karns_Algorithm (
      Segments : in out Segment_Array;
      ACKs     : in out ACK_Array;
      Data     : in out RTT_Data) is
   
      Segment_Matched : Boolean;
   begin
      --  Iterate through all ACKs and update RTT for unambiguous ACKs
      for Ack_Packet of ACKs loop
         Segment_Matched := False;
         
         --  Find the segment matching the ACK
         for Seg of Segments loop
            if Seg.Sequence_Number = Ack_Packet.ACK_Number then
               Segment_Matched := True;
               
               --  Update RTT estimate if the ACK is unambiguous
               if Is_Unambiguous_ACK(Seg, Ack_Packet) then
                  Update_RTT_Estimate(Seg, Ack_Packet, Data);
               end if;
               
               exit;  --  Exit loop once segment is found
            end if;
         end loop;
         
         --  If no segment matches the ACK, raise an exception
         if not Segment_Matched then
            raise Invalid_ACK_Exception with "No segment matches ACK number: " & Ack_Packet.ACK_Number'Image;
         end if;
      end loop;
   end Simulate_Karns_Algorithm;

   --  Simulates Karn's Algorithm with timer backoff.
   --  This procedure is similar to Simulate_Karns_Algorithm but applies timer backoff
   --  for retransmitted segments. It demonstrates the full Karn's Algorithm with backoff.
   --  
   --  Parameters:
   --    Segments: Array of segments to process (updated in place).
   --    ACKs: Array of ACKs to process.
   --    Data: The RTT_Data structure to update.
   --  Raises:
   --    Invalid_ACK_Exception: If an ACK does not match any segment.
   procedure Simulate_Karns_Algorithm_With_Backoff (
      Segments : in out Segment_Array;
      ACKs     : in out ACK_Array;
      Data     : in out RTT_Data) is
   
      Segment_Matched : Boolean;
   begin
      --  Iterate through all ACKs and update RTT for unambiguous ACKs
      for Ack_Packet of ACKs loop
         Segment_Matched := False;
         
         --  Find the segment matching the ACK
         for Seg of Segments loop
            if Seg.Sequence_Number = Ack_Packet.ACK_Number then
               Segment_Matched := True;
               
               --  Update RTT estimate if the ACK is unambiguous
               if Is_Unambiguous_ACK(Seg, Ack_Packet) then
                  Update_RTT_With_Smoothing(Seg, Ack_Packet, Data);
               else
                  --  If the segment was retransmitted, apply timer backoff
                  Handle_Timeout(Data);
               end if;
               
               exit;  --  Exit loop once segment is found
            end if;
         end loop;
         
         --  If no segment matches the ACK, raise an exception
         if not Segment_Matched then
            raise Invalid_ACK_Exception with "No segment matches ACK number: " & Ack_Packet.ACK_Number'Image;
         end if;
      end loop;
   end Simulate_Karns_Algorithm_With_Backoff;

   --  Validates Segment and ACK arrays for consistency.
   --  This function checks for common errors in input data, such as duplicate sequence
   --  numbers or mismatched ACKs, which could lead to incorrect RTT estimates.
   --  
   --  Parameters:
   --    Segments: Array of segments to validate.
   --    ACKs: Array of ACKs to validate.
   --  Returns:
   --    True if the arrays are valid, False otherwise.
   function Are_Arrays_Valid (
      Segments : Segment_Array;
      ACKs     : ACK_Array) return Boolean is
   
      All_Valid : Boolean := True;
   begin
      --  Check for duplicate sequence numbers in segments
      for I in Segments'Range loop
         for J in I + 1 .. Segments'Last loop
            if Segments(I).Sequence_Number = Segments(J).Sequence_Number then
               All_Valid := False;
               return All_Valid;
            end if;
         end loop;
      end loop;
      
      --  Check for duplicate ACK numbers
      for I in ACKs'Range loop
         for J in I + 1 .. ACKs'Last loop
            if ACKs(I).ACK_Number = ACKs(J).ACK_Number then
               All_Valid := False;
               return All_Valid;
            end if;
         end loop;
      end loop;
      
      --  Check if all ACKs have matching segments
      for Ack_Packet of ACKs loop
         declare
            Found : Boolean := False;
         begin
            for Seg of Segments loop
               if Seg.Sequence_Number = Ack_Packet.ACK_Number then
                  Found := True;
                  exit;
               end if;
            end loop;
            
            if not Found then
               All_Valid := False;
               return All_Valid;
            end if;
         end;
      end loop;
      
      return All_Valid;
   end Are_Arrays_Valid;

   --  Finds the segment matching an ACK in a Segment_Array.
   --  This procedure searches for a segment with a matching sequence number and returns
   --  it if found. It is useful for debugging or manual RTT calculations.
   --  
   --  Parameters:
   --    Segments: Array of segments to search.
   --    Ack_Packet: The ACK to match.
   --    Seg: Output parameter for the matching segment (undefined if not found).
   --    Found: Output parameter indicating whether a match was found.
   procedure Find_Segment_For_ACK (
      Segments : Segment_Array;
      Ack_Packet : ACK;
      Seg       : out Segment;
      Found     : out Boolean) is
   begin
      Found := False;
      for S of Segments loop
         if S.Sequence_Number = Ack_Packet.ACK_Number then
            Seg := S;
            Found := True;
            exit;
         end if;
      end loop;
   end Find_Segment_For_ACK;

end Karns_Algorithm;
