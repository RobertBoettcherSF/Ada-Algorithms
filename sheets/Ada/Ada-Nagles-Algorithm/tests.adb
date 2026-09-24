-- tests.adb
-- Test suite for Nagle's Algorithm implementation.
-- Assumes code is broken; tests PASS if assumptions are disproven.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Containers; use Ada.Containers;
with Nagle; use Nagle;

procedure Tests is
   -- Helper to print PASS/FAIL
   procedure Print_Result (Test_Name : String; Passed : Boolean) is
   begin
      if Passed then
         Put_Line("  " & Test_Name & ": PASS");
      else
         Put_Line("  " & Test_Name & ": FAIL");
      end if;
   end Print_Result;

   -- Helper to free a packet
   procedure Free_Test_Packet (Pkg : in out Packet) is
   begin
      Free_Packet(Pkg);
   end Free_Test_Packet;

   -- Test data
   MSS : constant Natural := 1460;
   Window_Size : constant Natural := 2920;  -- 2 * MSS
   Empty_Buffer : Packet_Vectors.Vector;
   Small_Data : Buffer_Type := (1 => 1, 2 => 2, 3 => 3);  -- 3 bytes
   Full_Data : Buffer_Type(1 .. MSS) := (others => 0);
   Large_Data : Buffer_Type(1 .. MSS * 2) := (others => 0);

   -- Test variables
   Send_Now : Boolean;
   Packet_To_Send : Packet;
   Buffer : Packet_Vectors.Vector;
   Unacked : Unacknowledged_Flag;
begin
   Put_Line("=== Nagle's Algorithm Test Suite ===");
   New_Line;

   -- TEST 1: Original Nagle - Send immediately if no unacked data
   Put_Line("TEST 1 - Original Nagle: No Unacked Data");
   Unacked := No_Unacked;
   Buffer.Clear;
   Nagle.Original_Nagle(MSS, Window_Size, Unacked, Small_Data, Buffer, Send_Now, Packet_To_Send);
   Print_Result("1.1 Send_Now = True", Send_Now);
   Print_Result("1.2 Packet_To_Send.Size = 3", Packet_To_Send.Size = 3);
   Print_Result("1.3 Buffer is empty", Buffer.Is_Empty);
   Free_Test_Packet(Packet_To_Send);
   New_Line;

   -- TEST 2: Original Nagle - Buffer if unacked data exists
   Put_Line("TEST 2 - Original Nagle: Unacked Data Exists");
   Unacked := Has_Unacked;
   Buffer.Clear;
   Nagle.Original_Nagle(MSS, Window_Size, Unacked, Small_Data, Buffer, Send_Now, Packet_To_Send);
   Print_Result("2.1 Send_Now = False", not Send_Now);
   Print_Result("2.2 Buffer has 1 packet", Buffer.Length = 1);
   Print_Result("2.3 Packet_To_Send.Size = 0", Packet_To_Send.Size = 0);
   -- Free buffered packets
   for Pkg of Buffer loop
      Free_Test_Packet(Pkg);
   end loop;
   Buffer.Clear;
   New_Line;

   -- TEST 3: Original Nagle - Send if window >= MSS and buffered data >= MSS
   Put_Line("TEST 3 - Original Nagle: Window >= MSS and Buffered Data >= MSS");
   Unacked := Has_Unacked;
   Buffer.Clear;
   declare
      Full_Packet : Packet;
   begin
      Full_Packet.Data := new Buffer_Type(Full_Data'Range);
      Full_Packet.Data.all := Full_Data;
      Full_Packet.Size := MSS;
      Buffer.Append(Full_Packet);
   end;
   Nagle.Original_Nagle(MSS, Window_Size, Unacked, Small_Data, Buffer, Send_Now, Packet_To_Send);
   Print_Result("3.1 Send_Now = True", Send_Now);
   Print_Result("3.2 Packet_To_Send.Size = MSS", Packet_To_Send.Size = MSS);
   Print_Result("3.3 Buffer is empty", Buffer.Is_Empty);
   Free_Test_Packet(Packet_To_Send);
   New_Line;

   -- TEST 4: Minshall Nagle - Send if last packet is full-sized
   Put_Line("TEST 4 - Minshall Nagle: Last Packet Full-Sized");
   Unacked := Has_Unacked;
   Buffer.Clear;
   declare
      Full_Packet : Packet;
   begin
      Full_Packet.Data := new Buffer_Type(Full_Data'Range);
      Full_Packet.Data.all := Full_Data;
      Full_Packet.Size := MSS;
      Buffer.Append(Full_Packet);
   end;
   Nagle.Minshall_Nagle(MSS, Window_Size, Unacked, Small_Data, Buffer, Send_Now, Packet_To_Send);
   Print_Result("4.1 Send_Now = True", Send_Now);
   Print_Result("4.2 Packet_To_Send.Size = 3", Packet_To_Send.Size = 3);
   Print_Result("4.3 Buffer still has 1 packet", Buffer.Length = 1);
   Free_Test_Packet(Packet_To_Send);
   -- Free buffered packets
   for Pkg of Buffer loop
      Free_Test_Packet(Pkg);
   end loop;
   Buffer.Clear;
   New_Line;

   -- TEST 5: Minshall Nagle - Buffer if last packet is partial
   Put_Line("TEST 5 - Minshall Nagle: Last Packet Partial");
   Unacked := Has_Unacked;
   Buffer.Clear;
   declare
      Small_Packet : Packet;
   begin
      Small_Packet.Data := new Buffer_Type(Small_Data'Range);
      Small_Packet.Data.all := Small_Data;
      Small_Packet.Size := 3;
      Buffer.Append(Small_Packet);
   end;
   Nagle.Minshall_Nagle(MSS, Window_Size, Unacked, Small_Data, Buffer, Send_Now, Packet_To_Send);
   Print_Result("5.1 Send_Now = False", not Send_Now);
   Print_Result("5.2 Buffer has 2 packets", Buffer.Length = 2);
   Print_Result("5.3 Packet_To_Send.Size = 0", Packet_To_Send.Size = 0);
   -- Free buffered packets
   for Pkg of Buffer loop
      Free_Test_Packet(Pkg);
   end loop;
   Buffer.Clear;
   New_Line;

   -- TEST 6: No Nagle - Always send immediately
   Put_Line("TEST 6 - No Nagle: Immediate Send");
   Nagle.No_Nagle(Small_Data, Send_Now, Packet_To_Send);
   Print_Result("6.1 Send_Now = True", Send_Now);
   Print_Result("6.2 Packet_To_Send.Size = 3", Packet_To_Send.Size = 3);
   Free_Test_Packet(Packet_To_Send);
   New_Line;

   -- TEST 7: No Nagle - Empty data
   Put_Line("TEST 7 - No Nagle: Empty Data");
   declare
      Empty_Data : Buffer_Type(1 .. 0);
   begin
      Nagle.No_Nagle(Empty_Data, Send_Now, Packet_To_Send);
      Print_Result("7.1 Send_Now = False", not Send_Now);
      Print_Result("7.2 Packet_To_Send.Size = 0", Packet_To_Send.Size = 0);
   end;
   New_Line;

   -- TEST 8: Helper - Has_Enough_Data
   Put_Line("TEST 8 - Helper: Has_Enough_Data");
   Buffer.Clear;
   declare
      Full_Packet : Packet;
   begin
      Full_Packet.Data := new Buffer_Type(Full_Data'Range);
      Full_Packet.Data.all := Full_Data;
      Full_Packet.Size := MSS;
      Buffer.Append(Full_Packet);
   end;
   Print_Result("8.1 Buffer >= MSS", Has_Enough_Data(Buffer, MSS));
   -- Free buffered packets
   for Pkg of Buffer loop
      Free_Test_Packet(Pkg);
   end loop;
   Buffer.Clear;
   declare
      Small_Packet : Packet;
   begin
      Small_Packet.Data := new Buffer_Type(Small_Data'Range);
      Small_Packet.Data.all := Small_Data;
      Small_Packet.Size := 3;
      Buffer.Append(Small_Packet);
   end;
   Print_Result("8.2 Buffer < MSS", not Has_Enough_Data(Buffer, MSS));
   -- Free buffered packets
   for Pkg of Buffer loop
      Free_Test_Packet(Pkg);
   end loop;
   Buffer.Clear;
   New_Line;

   -- TEST 9: Helper - Merge_Packets
   Put_Line("TEST 9 - Helper: Merge_Packets");
   Buffer.Clear;
   declare
      Small_Packet : Packet;
      Full_Packet : Packet;
   begin
      Small_Packet.Data := new Buffer_Type(Small_Data'Range);
      Small_Packet.Data.all := Small_Data;
      Small_Packet.Size := 3;
      Buffer.Append(Small_Packet);
      Full_Packet.Data := new Buffer_Type(Full_Data'Range);
      Full_Packet.Data.all := Full_Data;
      Full_Packet.Size := MSS;
      Buffer.Append(Full_Packet);
   end;
   declare
      Merged : Packet := Merge_Packets(Buffer, MSS);
   begin
      Print_Result("9.1 Merged.Size = MSS", Merged.Size = MSS);
      Free_Test_Packet(Merged);
   end;
   -- Free buffered packets
   for Pkg of Buffer loop
      Free_Test_Packet(Pkg);
   end loop;
   Buffer.Clear;
   New_Line;

   -- TEST 10: Edge Case - Empty Buffer
   Put_Line("TEST 10 - Edge Case: Empty Buffer");
   Unacked := No_Unacked;
   Buffer.Clear;
   Nagle.Original_Nagle(MSS, Window_Size, Unacked, Small_Data, Buffer, Send_Now, Packet_To_Send);
   Print_Result("10.1 Send_Now = True", Send_Now);
   Print_Result("10.2 Packet_To_Send.Size = 3", Packet_To_Send.Size = 3);
   Free_Test_Packet(Packet_To_Send);
   New_Line;

   -- TEST 11: Edge Case - Window Size = 0
   Put_Line("TEST 11 - Edge Case: Window Size = 0");
   Unacked := No_Unacked;
   Buffer.Clear;
   Nagle.Original_Nagle(MSS, 0, Unacked, Small_Data, Buffer, Send_Now, Packet_To_Send);
   Print_Result("11.1 Send_Now = True", Send_Now);
   Print_Result("11.2 Packet_To_Send.Size = 3", Packet_To_Send.Size = 3);
   Free_Test_Packet(Packet_To_Send);
   New_Line;

   -- TEST 12: Delayed ACK Simulation
   Put_Line("TEST 12 - Delayed ACK: Timeout");
   Unacked := Has_Unacked;
   Simulate_Delayed_ACK(Unacked, 500, 500);
   Print_Result("12.1 Unacked = No_Unacked", Unacked = No_Unacked);
   Unacked := Has_Unacked;
   Simulate_Delayed_ACK(Unacked, 499, 500);
   Print_Result("12.2 Unacked remains Has_Unacked", Unacked = Has_Unacked);
   New_Line;

   -- TEST 13: Large Data Handling
   Put_Line("TEST 13 - Large Data: > MSS");
   Unacked := No_Unacked;
   Buffer.Clear;
   Nagle.Original_Nagle(MSS, Window_Size, Unacked, Large_Data, Buffer, Send_Now, Packet_To_Send);
   Print_Result("13.1 Send_Now = True", Send_Now);
   Print_Result("13.2 Packet_To_Send.Size = MSS * 2", Packet_To_Send.Size = MSS * 2);
   Free_Test_Packet(Packet_To_Send);
   New_Line;

   -- TEST 14: Minshall Nagle - Large Data with Partial Last Packet
   Put_Line("TEST 14 - Minshall Nagle: Large Data with Partial Last Packet");
   Unacked := Has_Unacked;
   Buffer.Clear;
   declare
      Large_Packet : Packet;
   begin
      Large_Packet.Data := new Buffer_Type(Large_Data'Range);
      Large_Packet.Data.all := Large_Data;
      Large_Packet.Size := MSS * 2 - 1;  -- Partial last packet
      Buffer.Append(Large_Packet);
   end;
   Nagle.Minshall_Nagle(MSS, Window_Size, Unacked, Small_Data, Buffer, Send_Now, Packet_To_Send);
   Print_Result("14.1 Send_Now = False", not Send_Now);
   Print_Result("14.2 Buffer has 2 packets", Buffer.Length = 2);
   -- Free buffered packets
   for Pkg of Buffer loop
      Free_Test_Packet(Pkg);
   end loop;
   Buffer.Clear;
   New_Line;

   Put_Line("=== Test Suite Complete ===");
end Tests;
