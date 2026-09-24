with Ada.Text_IO; use Ada.Text_IO;
with Ada.Streams; use Ada.Streams;
with LZRW; use LZRW;

procedure Tests is
   Total_Tests  : Integer := 0;
   Passed_Tests : Integer := 0;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      Total_Tests := Total_Tests + 1;
      if Condition then
         Put_Line ("      PASS: " & Message);
         Passed_Tests := Passed_Tests + 1;
      else
         Put_Line ("      FAIL: " & Message);
      end if;
   end Assert;
   
   -- Global Mock Memory Blocks
   Empty_In : Stream_Element_Array (1 .. 0);
   Out_Buf  : Stream_Element_Array (1 .. 1024);
   Out_Size : Natural;
   
   procedure Test_1 is
   begin
      Put_Line ("TEST 1 - Empty Array Handling (Boundaries)");
      Compress (Empty_In, Out_Buf, Out_Size);
      Assert (Out_Size = 0, "1.1 Compression of empty array returns size 0");
      
      Decompress (Empty_In, Out_Buf, Out_Size);
      Assert (Out_Size = 0, "1.2 Decompression of empty array returns size 0");
   end Test_1;
   
   procedure Test_2 is
      Data_In : Stream_Element_Array (1 .. 3) := (65, 66, 67); -- "ABC"
      Comp_Buf : Stream_Element_Array (1 .. 10);
      Decomp_Buf : Stream_Element_Array (1 .. 10);
      Comp_Size, Decomp_Size : Natural;
   begin
      Put_Line ("TEST 2 - Literal Compression (No Mathces)");
      Compress (Data_In, Comp_Buf, Comp_Size);
      Assert (Comp_Size = 6, "2.1 Compression yields expected literal byte-count (6 bytes)");
      
      Decompress (Comp_Buf (1 .. Stream_Element_Offset(Comp_Size)), Decomp_Buf, Decomp_Size);
      Assert (Decomp_Size = 3, "2.2 Decompressed literal retains precise length");
      Assert (Decomp_Buf (1..3) = Data_In, "2.3 Decompressed literal mathematically matches origin");
   end Test_2;
   
   procedure Test_3 is
      Data_In : Stream_Element_Array (1 .. 9) := (65, 66, 67, 65, 66, 67, 65, 66, 67);
      Comp_Buf : Stream_Element_Array (1 .. 20);
      Decomp_Buf : Stream_Element_Array (1 .. 20);
      Comp_Size, Decomp_Size : Natural;
   begin
      Put_Line ("TEST 3 - Match Compression (Redundant Data Elimination)");
      Compress (Data_In, Comp_Buf, Comp_Size);
      Assert (Comp_Size < 18, "3.1 Compression successfully shrinks redundant data");
      
      Decompress (Comp_Buf (1 .. Stream_Element_Offset(Comp_Size)), Decomp_Buf, Decomp_Size);
      Assert (Decomp_Size = 9, "3.2 Decompressed match structure rebuilds proper length");
      Assert (Decomp_Buf (1..9) = Data_In, "3.3 Decompressed match exactly mimics original dataset");
   end Test_3;
   
   procedure Test_4 is
      Data_In : Stream_Element_Array (1 .. 5) := (1, 2, 3, 4, 5);
      Small_Buf : Stream_Element_Array (1 .. 2);
      Comp_Size, Decomp_Size : Natural;
   begin
      Put_Line ("TEST 4 - Error Handling: Output Buffer Constrictions");
      begin
         Compress (Data_In, Small_Buf, Comp_Size);
         Assert (False, "4.1 Failed to raise constraint error");
      exception
         when Compression_Error => Assert (True, "4.1 Raises Compression_Error on small output buffer safely");
      end;
      
      begin
         Decompress ((1 => 0, 2 => 65, 3 => 0, 4 => 66, 5 => 0, 6 => 67), Small_Buf, Decomp_Size);
         Assert (False, "4.2 Failed to raise constraint error");
      exception
         when Decompression_Error => Assert (True, "4.2 Raises Decompression_Error on small decomp buffer");
      end;
   end Test_4;
   
   procedure Test_5 is
      Comp_Size : Natural;
   begin
      Put_Line ("TEST 5 - Error Handling: Adversarial / Corrupted Data");
      begin
         Decompress ((1 => 5), Out_Buf, Comp_Size); -- 5 is non-existent control byte
         Assert (False, "5.1 Allowed corrupt control flag");
      exception
         when Decompression_Error => Assert (True, "5.1 Invalid control byte safely raises Decompression_Error");
      end;
      
      begin
         Decompress ((1 => 0, 2 => 65, 3 => 1, 4 => 10, 5 => 3), Out_Buf, Comp_Size); -- Offset 10 out of bounds
         Assert (False, "5.2 Permitted bad memory copy");
      exception
         when Decompression_Error => Assert (True, "5.2 Forged/Out-of-bounds offset blocked (Decompression_Error)");
      end;
      
      begin
         Decompress ((1 => 0), Out_Buf, Comp_Size); -- Missing actual payload
         Assert (False, "5.3 Allowed stream truncation");
      exception
         when Decompression_Error => Assert (True, "5.3 Truncated payload triggers safe exit via Exception");
      end;
   end Test_5;
   
   procedure Test_6 is
      Data_In : Stream_Element_Array (1 .. 5) := (1, 2, 3, 4, 5);
      Comp_Buf : Stream_Element_Array (1 .. 20);
      Comp_Size : Natural;
   begin
      Put_Line ("TEST 6 - Sub-Variant Verification");
      Compress (Data_In, Comp_Buf, Comp_Size, Variant => LZRW1_A);
      Assert (Comp_Size > 0, "6.1 LZRW1_A processes without failure");
      
      Compress (Data_In, Comp_Buf, Comp_Size, Variant => LZRW2);
      Assert (Comp_Size > 0, "6.2 LZRW2 processes without failure");
      
      Compress (Data_In, Comp_Buf, Comp_Size, Variant => LZRW3_A);
      Assert (Comp_Size > 0, "6.3 LZRW3_A processes without failure");
      
      Compress (Data_In, Comp_Buf, Comp_Size, Variant => LZRW5);
      Assert (Comp_Size > 0, "6.4 LZRW4/5 processes without failure");
   end Test_6;
   
   procedure Test_7 is
      Data_In : Stream_Element_Array (1 .. 100);
      Comp_Buf : Stream_Element_Array (1 .. 300);
      Decomp_Buf : Stream_Element_Array (1 .. 300);
      Comp_Size, Decomp_Size : Natural;
   begin
      Put_Line ("TEST 7 - Full Simulation Round-Trip (V&V Goal)");
      for I in Data_In'Range loop
         Data_In(I) := Stream_Element (I mod 4);
      end loop;
      
      Compress (Data_In, Comp_Buf, Comp_Size);
      Decompress (Comp_Buf (1 .. Stream_Element_Offset(Comp_Size)), Decomp_Buf, Decomp_Size);
      
      Assert (Decomp_Size = 100, "7.1 Complex round-trip maintains exact scale constraint");
      Assert (Decomp_Buf (1 .. 100) = Data_In, "7.2 Decompressed matrix guarantees 100% original fidelity");
   end Test_7;

begin
   Put_Line ("--- Starting LZRW Validation Test Suite ---");
   Test_1; Test_2; Test_3; Test_4; Test_5; Test_6; Test_7;
   Put_Line ("-------------------------------------------");
   Put_Line ("Tests Executed: " & Integer'Image(Passed_Tests) & " / " & Integer'Image(Total_Tests));
   if Passed_Tests = Total_Tests then
      Put_Line ("STATUS: PASSED (Assumption Disproven - Code Base Sound)");
   else
      Put_Line ("STATUS: FAILED");
   end if;
end Tests;
