--  Karns_Algorithm.ads
--  
--  Specification for Karn's Algorithm (Karn-Partridge Algorithm)
--  for Round-Trip Time (RTT) estimation in TCP.
--  
--  Author: Vibe Code (Mistral AI)
--  Date: 2024
--  
--  Description:
--    This package implements Karn's Algorithm, proposed by Phil Karn and Craig Partridge in 1987.
--    The algorithm addresses the ambiguity in RTT (Round-Trip Time) estimation caused by
--    retransmitted segments in TCP. When a segment is retransmitted, the acknowledgment (ACK)
--    received could correspond to either the original transmission or the retransmission.
--    Karn's Algorithm resolves this ambiguity by:
--      1. Ignoring retransmitted segments when updating RTT estimates.
--      2. Only using unambiguous ACKs (ACKs for segments sent exactly once) to update RTT.
--      3. Incorporating a timer backoff strategy to handle cases where ignoring retransmitted
--         segments could lead to stale RTT estimates (e.g., after a sharp increase in network delay).
--    
--    Timer backoff works by exponentially increasing the timeout value (e.g., doubling it)
--    on each retransmission, ensuring that the RTT estimate eventually adapts to new network conditions.
--
--  Key Features:
--    - Basic Karn's Algorithm: Ignores retransmitted segments for RTT updates.
--    - Jacobson's Smoothing: Uses exponential smoothing for RTT and deviation estimates.
--    - Timer Backoff: Doubles timeout on retransmission to avoid stale estimates.
--    - Edge Case Handling: Validates inputs, handles empty arrays, and manages retransmissions.
--
--  References:
--    - Karn, P., & Partridge, C. (1987). "Improving Round-Trip Time Estimates in Reliable Transport Protocols."
--    - Jacobson, V. (1988). "Congestion Avoidance and Control."
--

with Ada.Real_Time; use Ada.Real_Time;

package Karns_Algorithm is

   --  Custom types for algorithm-specific data
   
   --  Represents the transmission status of a segment.
   --  - First_Transmission: Segment was sent once (unambiguous ACKs can update RTT).
   --  - Retransmitted: Segment was retransmitted (ACKs are ambiguous and ignored for RTT updates).
   type Transmission_Status is (First_Transmission, Retransmitted);
   
   --  Represents a TCP segment with metadata for RTT estimation.
   --  Fields:
   --    - Sequence_Number: Unique identifier for the segment (matches ACK_Number).
   --    - Send_Time: Timestamp when the segment was sent.
   --    - Status: Transmission status (First_Transmission or Retransmitted).
   --    - Retransmit_Count: Number of times the segment has been retransmitted.
   type Segment is record
      Sequence_Number : Positive;  -- Unique identifier for the segment
      Send_Time       : Time;      -- Time when the segment was sent
      Status          : Transmission_Status := First_Transmission;  -- Transmission status
      Retransmit_Count : Natural := 0;  -- Number of retransmissions
   end record;
   
   --  Represents an acknowledgment (ACK) for a segment.
   --  Fields:
   --    - ACK_Number: Acknowledgment number (matches Segment.Sequence_Number).
   --    - Receive_Time: Timestamp when the ACK was received.
   type ACK is record
      ACK_Number : Positive;  -- Acknowledgment number (matches segment sequence)
      Receive_Time : Time;     -- Time when the ACK was received
   end record;
   
   --  Represents RTT (Round-Trip Time) estimation and timeout data.
   --  Fields:
   --    - Current_RTT_Estimate: Latest RTT estimate (updated for unambiguous ACKs).
   --    - Smoothed_RTT: Exponentially smoothed RTT (using Jacobson's algorithm).
   --    - Timeout: Current timeout value for retransmissions.
   --    - Alpha: Smoothing factor for RTT (default: 0.125).
   --    - Beta: Smoothing factor for deviation (default: 0.25).
   --    - Dev_RTT: Mean deviation of RTT (used for timeout calculation).
   type RTT_Data is record
      Current_RTT_Estimate : Duration := 0.0;  -- Current RTT estimate in seconds
      Smoothed_RTT          : Duration := 0.0;  -- Smoothed RTT (e.g., using Jacobson's algorithm)
      Timeout               : Duration := 1.0;  -- Current timeout value in seconds
      Alpha                 : Float := 0.125;   -- Smoothing factor for RTT
      Beta                  : Float := 0.25;    -- Smoothing factor for deviation
      Dev_RTT               : Duration := 0.0;  -- Deviation in RTT
   end record;
   
   --  Array types for managing multiple segments and ACKs.
   type Segment_Array is array (Positive range <>) of Segment;
   type ACK_Array is array (Positive range <>) of ACK;
   
   --  Exceptions
   --  Raised when an ACK does not match any segment in the array.
   Invalid_ACK_Exception : exception;
   
   --  Raised when no unambiguous ACKs are available for RTT updates.
   No_Unambiguous_ACK_Exception : exception;
   
   --  Raised when the timeout becomes too small after backoff (edge case).
   Timeout_Too_Small_Exception : exception;
   
   --  Initializes RTT_Data with default values.
   --  Sets Current_RTT_Estimate, Smoothed_RTT, and Dev_RTT to 0.0,
   --  Timeout to 1.0, Alpha to 0.125, and Beta to 0.25.
   procedure Initialize_RTT_Data (Data : out RTT_Data);
   
   --  Calculates the Round-Trip Time (RTT) for a segment and its ACK.
   --  RTT = ACK.Receive_Time - Segment.Send_Time.
   --  Raises Invalid_ACK_Exception if the ACK does not match the segment.
   function Calculate_RTT (Seg : Segment; Ack_Packet : ACK) return Duration;
   
   --  Updates the RTT estimate using Karn's Algorithm (basic variant).
   --  Only updates RTT for unambiguous ACKs (segments with Status = First_Transmission).
   --  Uses exponential smoothing: New_Estimate = Alpha * RTT + (1 - Alpha) * Old_Estimate.
   --  Updates Timeout as 2 * Current_RTT_Estimate.
   procedure Update_RTT_Estimate (
      Seg : Segment;
      Ack_Packet : ACK;
      Data : in out RTT_Data);
   
   --  Updates the RTT estimate using Karn's Algorithm with Jacobson's smoothing.
   --  Only updates RTT for unambiguous ACKs (segments with Status = First_Transmission).
   --  Uses Jacobson's algorithm for smoothing:
   --    Smoothed_RTT = (1 - Alpha) * Smoothed_RTT + Alpha * RTT
   --    Dev_RTT = (1 - Beta) * Dev_RTT + Beta * |RTT - Smoothed_RTT|
   --  Updates Timeout as Smoothed_RTT + 4 * Dev_RTT.
   procedure Update_RTT_With_Smoothing (
      Seg : Segment;
      Ack_Packet : ACK;
      Data : in out RTT_Data);
   
   --  Handles retransmission of a segment.
   --  Marks the segment as Retransmitted, increments Retransmit_Count,
   --  and applies timer backoff (doubles Timeout).
   procedure Handle_Retransmission (
      Seg : in out Segment;
      Data : in out RTT_Data);
   
   --  Handles timeout by applying timer backoff.
   --  Doubles the Timeout value (exponential backoff).
   --  Raises Timeout_Too_Small_Exception if Timeout becomes too small.
   procedure Handle_Timeout (Data : in out RTT_Data);
   
   --  Resets the Timeout to its initial value (1.0).
   --  Used after successful transmission to reset the backoff state.
   procedure Reset_Timeout (Data : in out RTT_Data);
   
   --  Checks if an ACK is unambiguous (i.e., corresponds to a First_Transmission segment).
   --  Returns True if:
   --    1. The ACK_Number matches the Segment.Sequence_Number.
   --    2. The Segment.Status is First_Transmission.
   function Is_Unambiguous_ACK (Seg : Segment; Ack_Packet : ACK) return Boolean;
   
   --  Simulates Karn's Algorithm for an array of segments and ACKs.
   --  Iterates through all ACKs, finds matching segments, and updates RTT for unambiguous ACKs.
   --  Raises Invalid_ACK_Exception if an ACK does not match any segment.
   procedure Simulate_Karns_Algorithm (
      Segments : in out Segment_Array;
      ACKs     : in out ACK_Array;
      Data     : in out RTT_Data);
   
   --  Simulates Karn's Algorithm with timer backoff.
   --  Similar to Simulate_Karns_Algorithm, but applies timer backoff for retransmitted segments.
   --  Raises Invalid_ACK_Exception if an ACK does not match any segment.
   procedure Simulate_Karns_Algorithm_With_Backoff (
      Segments : in out Segment_Array;
      ACKs     : in out ACK_Array;
      Data     : in out RTT_Data);
   
   --  Validates Segment and ACK arrays for consistency.
   --  Checks for:
   --    - Duplicate sequence numbers in Segments.
   --    - Duplicate ACK numbers in ACKs.
   --    - All ACKs have matching segments in Segments.
   --  Returns True if all checks pass, False otherwise.
   function Are_Arrays_Valid (
      Segments : Segment_Array;
      ACKs     : ACK_Array) return Boolean;
   
   --  Finds the segment matching an ACK in a Segment_Array.
   --  Sets Seg to the matching segment and Found to True if found.
   --  If no match is found, Seg is undefined and Found is False.
   procedure Find_Segment_For_ACK (
      Segments : Segment_Array;
      Ack_Packet : ACK;
      Seg       : out Segment;
      Found     : out Boolean);
   
end Karns_Algorithm;
