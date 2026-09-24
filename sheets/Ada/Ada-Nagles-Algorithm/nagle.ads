-- nagle.ads
-- Specification for Nagle's Algorithm and its variants.
-- 
-- PROJECT: Nagle's Algorithm Implementation in Ada
-- DESCRIPTION: This package implements Nagle's Algorithm (RFC 896) and its variants
--              for TCP/IP congestion control. The algorithm improves network
--              efficiency by buffering small packets and sending them in larger chunks.
-- 
-- ALGORITHM VARIANTS:
--   1. Original Nagle's Algorithm: Strict buffering until MSS or ACK is received
--   2. Minshall's Modification: Sends full-sized packets immediately
--   3. No Nagle (TCP_NODELAY): Immediate sending for low-latency applications
-- 
-- REFERENCES:
--   - RFC 896: Congestion Control in IP/TCP Internetworks
--   - https://en.wikipedia.org/wiki/Nagle%27s_algorithm

with Ada.Containers.Vectors;

package Nagle is
   -- Default Maximum Segment Size (MSS) for Ethernet (1460 bytes)
   -- This is the largest amount of data that can be sent in a single TCP segment
   Default_MSS : constant Natural := 1460;

   -- Byte type for packet data (8-bit unsigned)
   -- Used to represent individual bytes in the data buffer
   type Byte is mod 256;

   -- Buffer to accumulate small packets (dynamic array)
   -- This allows for variable-sized data chunks to be stored and merged
   type Buffer_Type is array (Positive range <>) of Byte;

   -- Access type for dynamic buffer data
   -- Required because Ada doesn't allow unconstrained arrays as record components
   type Buffer_Access is access Buffer_Type;

   -- Flag to indicate whether there is unacknowledged data in the pipe
   -- No_Unacked: No data waiting for acknowledgment
   -- Has_Unacked: There is data that has been sent but not yet acknowledged
   type Unacknowledged_Flag is (No_Unacked, Has_Unacked);

   -- Exception for invalid inputs (e.g., null data, invalid sizes)
   Invalid_Input_Error : exception;

   -- Packet structure (using access type for unconstrained array)
   -- Represents a TCP packet with:
   --   Data: Pointer to the actual packet data
   --   Size: Number of bytes in the packet
   type Packet is record
      Data : Buffer_Access;
      Size : Natural;
   end record;

   -- Vector of Packets for buffering
   -- This allows us to store multiple packets in a dynamic list
   package Packet_Vectors is new Ada.Containers.Vectors(
      Index_Type   => Natural,
      Element_Type => Packet
   );
   use Packet_Vectors;

   -- Original Nagle's Algorithm (RFC 896)
   -- 
   -- BEHAVIOR:
   --   - If window size >= MSS AND buffered data >= MSS: Send immediately
   --   - If there is unacknowledged data: Buffer the new data
   --   - Otherwise: Send immediately
   -- 
   -- PARAMETERS:
   --   MSS: Maximum Segment Size (bytes)
   --   Window_Size: Current TCP window size (bytes)
   --   Unacked: Flag indicating if there is unacknowledged data
   --   New_Data: New data to be sent
   --   Buffer: Buffer of packets waiting to be sent
   --   Send_Now: Output flag indicating whether to send now
   --   Packet_To_Send: The packet to be sent (if Send_Now is True)
   procedure Original_Nagle (
      MSS           : in     Natural;
      Window_Size   : in     Natural;
      Unacked       : in     Unacknowledged_Flag;
      New_Data      : in     Buffer_Type;
      Buffer        : in out Packet_Vectors.Vector;
      Send_Now      :    out Boolean;
      Packet_To_Send:    out Packet
   );

   -- Minshall's Modification to Nagle's Algorithm
   -- 
   -- BEHAVIOR:
   --   - If last packet in buffer is full-sized (MSS): Send immediately
   --   - Otherwise: Follow Original Nagle logic
   -- 
   -- PURPOSE: Reduces the "large-write penalty" in protocols like HTTP
   -- by sending full-sized packets immediately while still buffering partial packets
   -- 
   -- PARAMETERS: Same as Original_Nagle
   procedure Minshall_Nagle (
      MSS           : in     Natural;
      Window_Size   : in     Natural;
      Unacked       : in     Unacknowledged_Flag;
      New_Data      : in     Buffer_Type;
      Buffer        : in out Packet_Vectors.Vector;
      Send_Now      :    out Boolean;
      Packet_To_Send:    out Packet
   );

   -- No Nagle (TCP_NODELAY behavior)
   -- 
   -- BEHAVIOR: Always send data immediately without buffering
   -- 
   -- PURPOSE: Used for low-latency applications (e.g., games, remote desktop)
   -- where immediate transmission is more important than bandwidth efficiency
   -- 
   -- PARAMETERS:
   --   New_Data: Data to be sent
   --   Send_Now: Always True (if data exists)
   --   Packet_To_Send: The packet containing New_Data
   procedure No_Nagle (
      New_Data      : in     Buffer_Type;
      Send_Now      :    out Boolean;
      Packet_To_Send:    out Packet
   );

   -- Check if buffer has enough data for MSS
   -- 
   -- PURPOSE: Determines if the buffered data can fill a complete MSS-sized packet
   -- 
   -- RETURNS: True if total buffered data >= MSS, False otherwise
   function Has_Enough_Data (
      Buffer : Packet_Vectors.Vector;
      MSS    : Natural
   ) return Boolean;

   -- Merge small packets into a single MSS-sized packet
   -- 
   -- PURPOSE: Combines multiple small packets from the buffer into one
   --           packet of size MSS (or as close as possible)
   -- 
   -- RETURNS: A new Packet containing merged data
   function Merge_Packets (
      Buffer : Packet_Vectors.Vector;
      MSS    : Natural
   ) return Packet;

   -- Simulate Delayed ACK interaction
   -- 
   -- PURPOSE: Simulates the behavior of TCP Delayed ACK, which can interact
   --          poorly with Nagle's Algorithm (causing up to 500ms delay)
   -- 
   -- PARAMETERS:
   --   Unacked: Flag to update based on timeout
   --   Time_Elapsed: Simulated time since last ACK (milliseconds)
   --   ACK_Timeout: Timeout for Delayed ACK (default: 500ms)
   procedure Simulate_Delayed_ACK (
      Unacked       : in out Unacknowledged_Flag;
      Time_Elapsed  : in     Natural;  -- Simulated time in ms
      ACK_Timeout   : in     Natural := 500  -- Default Delayed ACK timeout
   );

   -- Free memory allocated for a Packet
   -- 
   -- PURPOSE: Prevents memory leaks by freeing the dynamically allocated Data field
   -- 
   -- NOTE: Should be called for all Packet objects when they are no longer needed
   procedure Free_Packet (Pkg : in out Packet);

end Nagle;
