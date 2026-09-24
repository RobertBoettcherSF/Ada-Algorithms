-- nagle.adb
-- Implementation of Nagle's Algorithm and its variants.
-- 
-- PROJECT: Nagle's Algorithm Implementation in Ada
-- DESCRIPTION: This package body implements the procedures and functions declared
--              in nagle.ads for TCP/IP congestion control.

with Ada.Containers.Vectors;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Unchecked_Deallocation;

package body Nagle is

   -- Free memory allocated for a Packet
   -- 
   -- IMPLEMENTATION: Uses Ada.Unchecked_Deallocation to free the Buffer_Access
   --                  and sets the pointer to null to prevent dangling references
   procedure Free_Packet (Pkg : in out Packet) is
      procedure Free is new Ada.Unchecked_Deallocation(Buffer_Type, Buffer_Access);
   begin
      if Pkg.Data /= null then
         Free(Pkg.Data);
         Pkg.Data := null;
      end if;
   end Free_Packet;

   -- Calculate total buffered data size
   -- 
   -- IMPLEMENTATION: Iterates through all packets in the buffer and sums their sizes
   -- 
   -- NOTE: Only counts packets where Data is not null
   function Total_Buffered_Size (Buffer : Packet_Vectors.Vector) return Natural is
      Total : Natural := 0;
   begin
      for Pkg of Buffer loop
         if Pkg.Data /= null then
            Total := Total + Pkg.Size;
         end if;
      end loop;
      return Total;
   end Total_Buffered_Size;

   -- Check if buffer has enough data for MSS
   -- 
   -- IMPLEMENTATION: Uses Total_Buffered_Size to check if buffered data >= MSS
   function Has_Enough_Data (
      Buffer : Packet_Vectors.Vector;
      MSS    : Natural
   ) return Boolean is
   begin
      return Total_Buffered_Size(Buffer) >= MSS;
   end Has_Enough_Data;

   -- Merge buffered packets into a single MSS-sized packet
   -- 
   -- IMPLEMENTATION:
   --   1. Allocates a new buffer of size MSS
   --   2. Copies data from buffered packets into the new buffer
   --   3. Stops when the new buffer is full or all packets are processed
   --   4. Returns a Packet with the merged data and actual size used
   -- 
   -- NOTE: If a packet is larger than the remaining space, only the needed bytes are copied
   function Merge_Packets (
      Buffer : Packet_Vectors.Vector;
      MSS    : Natural
   ) return Packet is
      -- Allocate a new buffer for merged data
      Merged_Data : Buffer_Access := new Buffer_Type(1 .. MSS);
      Current_Index : Positive := 1;
      Remaining : Natural := MSS;
   begin
      for Pkg of Buffer loop
         -- Skip null packets
         if Pkg.Data /= null and then Pkg.Size > 0 then
            -- If the entire packet fits in remaining space
            if Pkg.Size <= Remaining then
               Merged_Data(Current_Index .. Current_Index + Pkg.Size - 1) := 
                  Pkg.Data(1 .. Pkg.Size);
               Current_Index := Current_Index + Pkg.Size;
               Remaining := Remaining - Pkg.Size;
            else
               -- Copy only the remaining needed bytes
               Merged_Data(Current_Index .. Current_Index + Remaining - 1) := 
                  Pkg.Data(1 .. Remaining);
               exit;  -- Buffer is full
            end if;
         end if;
      end loop;
      -- Return packet with merged data and actual size used
      return (Data => Merged_Data, Size => MSS - Remaining);
   end Merge_Packets;

   -- Original Nagle's Algorithm (RFC 896)
   -- 
   -- IMPLEMENTATION:
   --   This is the core implementation of Nagle's Algorithm as defined in RFC 896.
   --   The algorithm addresses the "small-packet problem" in TCP/IP networks where
   --   applications send data in small chunks (e.g., 1 byte at a time), resulting in
   --   inefficient network usage due to TCP/IP headers (40 bytes per packet).
   -- 
   --   LOGIC:
   --   1. If there is new data to send:
   --      a. If window size >= MSS AND buffered data >= MSS:
   --         - Send a complete MSS segment now (merge buffered packets)
   --         - Clear the buffer
   --      b. Else if there is unacknowledged data:
   --         - Buffer the new data (don't send yet)
   --      c. Else (no unacknowledged data):
   --         - Send the new data immediately
   --   2. If no new data: Do not send
   -- 
   --   RATIONALE: This prevents the network from being flooded with small packets
   --   while still allowing immediate transmission when there's no risk of
   --   overwhelming the network.
   procedure Original_Nagle (
      MSS           : in     Natural;
      Window_Size   : in     Natural;
      Unacked       : in     Unacknowledged_Flag;
      New_Data      : in     Buffer_Type;
      Buffer        : in out Packet_Vectors.Vector;
      Send_Now      :    out Boolean;
      Packet_To_Send:    out Packet
   ) is
      New_Packet : Packet;
   begin
      -- If there is new data to send
      if New_Data'Length > 0 then
         -- If window size >= MSS and buffered data >= MSS, send now
         if Window_Size >= MSS and then Has_Enough_Data(Buffer, MSS) then
            Send_Now := True;
            Packet_To_Send := Merge_Packets(Buffer, MSS);
            Buffer.Clear;  -- Clear buffer after sending
         else
            -- If there is unacknowledged data, buffer the new data
            if Unacked = Has_Unacked then
               New_Packet.Data := new Buffer_Type(New_Data'Range);
               New_Packet.Data.all := New_Data;
               New_Packet.Size := New_Data'Length;
               Buffer.Append(New_Packet);
               Send_Now := False;
            else
               -- No unacked data: send immediately
               Send_Now := True;
               Packet_To_Send.Data := new Buffer_Type(New_Data'Range);
               Packet_To_Send.Data.all := New_Data;
               Packet_To_Send.Size := New_Data'Length;
            end if;
         end if;
      else
         -- No new data: do not send
         Send_Now := False;
         Packet_To_Send := (Data => null, Size => 0);
      end if;
   exception
      when others =>
         raise Invalid_Input_Error with "Invalid input in Original_Nagle";
   end Original_Nagle;

   -- Minshall's Modification to Nagle's Algorithm
   -- 
   -- IMPLEMENTATION:
   --   This variant was proposed by Greg Minshall to address performance issues
   --   with Nagle's Algorithm when combined with TCP Delayed ACK.
   -- 
   --   The key difference from Original Nagle:
   --   - If the last packet in the buffer is full-sized (exactly MSS bytes),
   --     send new data immediately without waiting
   --   - Otherwise, follow the Original Nagle logic
   -- 
   --   LOGIC:
   --   1. Check if the last buffered packet is full-sized (MSS)
   --   2. If there is new data to send:
   --      a. If last packet is full-sized: Send new data immediately
   --      b. Else if window size >= MSS and buffered data >= MSS: Send merged packet
   --      c. Else if there is unacknowledged data: Buffer the new data
   --      d. Else: Send immediately
   --   3. If no new data: Do not send
   -- 
   --   RATIONALE: This modification reduces the "large-write penalty" that occurs
   --   when a single write spans multiple packets, with the last packet being partial.
   --   In such cases, Original Nagle would wait for either more data or an ACK,
   --   while Minshall's version sends immediately if the last packet was full.
   procedure Minshall_Nagle (
      MSS           : in     Natural;
      Window_Size   : in     Natural;
      Unacked       : in     Unacknowledged_Flag;
      New_Data      : in     Buffer_Type;
      Buffer        : in out Packet_Vectors.Vector;
      Send_Now      :    out Boolean;
      Packet_To_Send:    out Packet
   ) is
      Last_Packet_Full : Boolean := False;
      New_Packet : Packet;
   begin
      -- Check if the last buffered packet is full-sized (MSS)
      if not Buffer.Is_Empty then
         declare
            Last_Pkg : Packet := Buffer.Last_Element;
         begin
            Last_Packet_Full := (Last_Pkg.Size = MSS);
         end;
      end if;

      -- If there is new data to send
      if New_Data'Length > 0 then
         -- If last packet is full-sized, send immediately
         if Last_Packet_Full then
            Send_Now := True;
            Packet_To_Send.Data := new Buffer_Type(New_Data'Range);
            Packet_To_Send.Data.all := New_Data;
            Packet_To_Send.Size := New_Data'Length;
         -- Otherwise, follow Original Nagle logic
         elsif Window_Size >= MSS and then Has_Enough_Data(Buffer, MSS) then
            Send_Now := True;
            Packet_To_Send := Merge_Packets(Buffer, MSS);
            Buffer.Clear;
         elsif Unacked = Has_Unacked then
            New_Packet.Data := new Buffer_Type(New_Data'Range);
            New_Packet.Data.all := New_Data;
            New_Packet.Size := New_Data'Length;
            Buffer.Append(New_Packet);
            Send_Now := False;
         else
            Send_Now := True;
            Packet_To_Send.Data := new Buffer_Type(New_Data'Range);
            Packet_To_Send.Data.all := New_Data;
            Packet_To_Send.Size := New_Data'Length;
         end if;
      else
         Send_Now := False;
         Packet_To_Send := (Data => null, Size => 0);
      end if;
   exception
      when others =>
         raise Invalid_Input_Error with "Invalid input in Minshall_Nagle";
   end Minshall_Nagle;

   -- No Nagle (TCP_NODELAY behavior)
   -- 
   -- IMPLEMENTATION:
   --   This is the simplest variant that bypasses Nagle's Algorithm entirely.
   --   It always sends data immediately without any buffering.
   -- 
   --   LOGIC:
   --   1. If there is data: Send immediately
   --   2. If no data: Do not send
   -- 
   --   USE CASE: This is used for applications that require low latency and
   --   cannot tolerate the delays introduced by Nagle's Algorithm, such as:
   --   - Networked multiplayer games
   --   - Remote desktop applications
   --   - Real-time control systems
   -- 
   --   NOTE: This trades bandwidth efficiency for lower latency.
   procedure No_Nagle (
      New_Data      : in     Buffer_Type;
      Send_Now      :    out Boolean;
      Packet_To_Send:    out Packet
   ) is
   begin
      if New_Data'Length > 0 then
         Send_Now := True;
         Packet_To_Send.Data := new Buffer_Type(New_Data'Range);
         Packet_To_Send.Data.all := New_Data;
         Packet_To_Send.Size := New_Data'Length;
      else
         Send_Now := False;
         Packet_To_Send := (Data => null, Size => 0);
      end if;
   end No_Nagle;

   -- Simulate Delayed ACK interaction
   -- 
   -- IMPLEMENTATION:
   --   Simulates the behavior of TCP Delayed ACK, which waits up to ACK_Timeout
   --   milliseconds before sending an acknowledgment.
   -- 
   --   LOGIC:
   --   If there is unacknowledged data and the timeout has elapsed,
   --   transition to No_Unacked state (ACK received)
   -- 
   --   PURPOSE: This allows testing of the interaction between Nagle's Algorithm
   --   and Delayed ACK, which can cause performance issues (up to 500ms delay
   --   per write-write-read sequence).
   -- 
   --   NOTE: In real TCP implementations, Delayed ACK is often enabled by default.
   procedure Simulate_Delayed_ACK (
      Unacked       : in out Unacknowledged_Flag;
      Time_Elapsed  : in     Natural;
      ACK_Timeout   : in     Natural := 500
   ) is
   begin
      if Unacked = Has_Unacked and then Time_Elapsed >= ACK_Timeout then
         Unacked := No_Unacked;  -- ACK received after timeout
      end if;
   end Simulate_Delayed_ACK;

end Nagle;
