-- Version: 0.12
-- Test implementations for Disk Scheduling Algorithms

with Ada.Text_IO;
with Disk_Scheduling;

package body Test_Disk_Scheduling is

   use Disk_Scheduling;
   use type Cylinder;

   -- Helper to check if two arrays are equal
   function Arrays_Equal (A, B : Cylinder_Array) return Boolean is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for I in A'Range loop
         if A(I) /= B(I) then
            return False;
         end if;
      end loop;
      return True;
   end Arrays_Equal;
   
   -- Helper to run a test
   procedure Run_Test (Name : String; Condition : Boolean) is
   begin
      Total_Tests := Total_Tests + 1;
      if Condition then
         Passed_Tests := Passed_Tests + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Name);
      else
         Failed_Tests := Failed_Tests + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Name);
      end if;
   end Run_Test;
   
   -- Print summary
   procedure Print_Summary is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("================================================================================");
      Ada.Text_IO.Put_Line ("TEST SUMMARY: " & Integer'Image(Passed_Tests) & "/" & 
                           Integer'Image(Total_Tests) & " passed");
      if Failed_Tests > 0 then
         Ada.Text_IO.Put_Line ("  FAILED: " & Integer'Image(Failed_Tests));
      end if;
      Ada.Text_IO.Put_Line ("================================================================================");
      if Failed_Tests = 0 then
         Ada.Text_IO.Put_Line ("ALL TESTS PASSED");
      else
         Ada.Text_IO.Put_Line ("SOME TESTS FAILED");
      end if;
   end Print_Summary;

   -- ==========================================================================
   -- SCAN Algorithm Tests
   -- ==========================================================================
   
   procedure Test_SCAN_Algorithm is
   begin
      Ada.Text_IO.Put_Line ("--- SCAN Algorithm Tests ---");
      
      -- Test 1: Basic SCAN UP
      declare
         Requests : constant Cylinder_Array := (1 => 98, 2 => 183, 3 => 37, 4 => 122, 5 => 14, 6 => 124, 7 => 65, 8 => 67);
         Start_Head : constant Cylinder := 53;
         Max_Cylinder : constant Cylinder := 199;
         Expected : constant Cylinder_Array := (1 => 65, 2 => 67, 3 => 98, 4 => 122, 5 => 124, 6 => 183, 7 => 199, 8 => 37, 9 => 14);
      begin
         Run_Test ("SCAN_Basic_UP", Arrays_Equal (SCAN (Requests, Start_Head, Up, Max_Cylinder), Expected));
      end;
      
      -- Test 2: SCAN Empty
      declare
         Requests : constant Cylinder_Array (1..0) := (others => 0);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 100;
      begin
         Run_Test ("SCAN_Empty", SCAN (Requests, Start_Head, Up, Max_Cylinder)'Length = 0);
      end;
      
      -- Test 3: SCAN All Right
      declare
         Requests : constant Cylinder_Array := (1 => 100, 2 => 150, 3 => 200);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 300;
         Expected : constant Cylinder_Array := (1 => 100, 2 => 150, 3 => 200, 4 => 300);
      begin
         Run_Test ("SCAN_All_Right", Arrays_Equal (SCAN (Requests, Start_Head, Up, Max_Cylinder), Expected));
      end;
      
      -- Test 4: SCAN All Left
      declare
         Requests : constant Cylinder_Array := (1 => 10, 2 => 20, 3 => 30);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 100;
         Expected : constant Cylinder_Array := (1 => 100, 2 => 30, 3 => 20, 4 => 10);
      begin
         Run_Test ("SCAN_All_Left", Arrays_Equal (SCAN (Requests, Start_Head, Up, Max_Cylinder), Expected));
      end;
      
      -- Test 5: SCAN Head at Zero
      declare
         Requests : constant Cylinder_Array := (1 => 10, 2 => 20, 3 => 30);
         Start_Head : constant Cylinder := 0;
         Max_Cylinder : constant Cylinder := 100;
         Expected : constant Cylinder_Array := (1 => 10, 2 => 20, 3 => 30, 4 => 100);
      begin
         Run_Test ("SCAN_Head_At_Zero", Arrays_Equal (SCAN (Requests, Start_Head, Up, Max_Cylinder), Expected));
      end;
      
      -- Test 6: SCAN Head at Max
      declare
         Requests : constant Cylinder_Array := (1 => 10, 2 => 20, 3 => 30);
         Start_Head : constant Cylinder := 100;
         Max_Cylinder : constant Cylinder := 100;
         Expected : constant Cylinder_Array := (1 => 100, 2 => 30, 3 => 20, 4 => 10);
      begin
         Run_Test ("SCAN_Head_At_Max", Arrays_Equal (SCAN (Requests, Start_Head, Up, Max_Cylinder), Expected));
      end;
      
      -- Test 7: SCAN Single Request
      declare
         Requests : constant Cylinder_Array := (1 => 50);
         Start_Head : constant Cylinder := 100;
         Max_Cylinder : constant Cylinder := 200;
         Expected : constant Cylinder_Array := (1 => 200, 2 => 50);
      begin
         Run_Test ("SCAN_Single_Request", Arrays_Equal (SCAN (Requests, Start_Head, Up, Max_Cylinder), Expected));
      end;
      
      -- Test 8: SCAN Down Direction
      declare
         Requests : constant Cylinder_Array := (1 => 98, 2 => 183, 3 => 37, 4 => 122, 5 => 14, 6 => 124, 7 => 65, 8 => 67);
         Start_Head : constant Cylinder := 53;
         Max_Cylinder : constant Cylinder := 199;
         Expected : constant Cylinder_Array := (1 => 37, 2 => 14, 3 => 0, 4 => 65, 5 => 67, 6 => 98, 7 => 122, 8 => 124, 9 => 183);
      begin
         Run_Test ("SCAN_Down_Direction", Arrays_Equal (SCAN (Requests, Start_Head, Down, Max_Cylinder), Expected));
      end;
   end Test_SCAN_Algorithm;

   -- ==========================================================================
   -- C-SCAN Algorithm Tests
   -- ==========================================================================
   
   procedure Test_C_SCAN_Algorithm is
   begin
      Ada.Text_IO.Put_Line ("--- C-SCAN Algorithm Tests ---");
      
      -- Test 1: Basic C-SCAN UP
      declare
         Requests : constant Cylinder_Array := (1 => 98, 2 => 183, 3 => 37, 4 => 122, 5 => 14, 6 => 124, 7 => 65, 8 => 67);
         Start_Head : constant Cylinder := 53;
         Max_Cylinder : constant Cylinder := 199;
         Expected : constant Cylinder_Array := (1 => 65, 2 => 67, 3 => 98, 4 => 122, 5 => 124, 6 => 183, 7 => 199, 8 => 0, 9 => 14, 10 => 37);
      begin
         Run_Test ("C_SCAN_Basic_UP", Arrays_Equal (C_SCAN (Requests, Start_Head, Up, Max_Cylinder), Expected));
      end;
      
      -- Test 2: C-SCAN Empty
      declare
         Requests : constant Cylinder_Array (1..0) := (others => 0);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 100;
      begin
         Run_Test ("C_SCAN_Empty", C_SCAN (Requests, Start_Head, Up, Max_Cylinder)'Length = 0);
      end;
      
      -- Test 3: C-SCAN All Right
      declare
         Requests : constant Cylinder_Array := (1 => 100, 2 => 150, 3 => 200);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 200;
         Expected : constant Cylinder_Array := (1 => 100, 2 => 150, 3 => 200, 4 => 200, 5 => 0);
      begin
         Run_Test ("C_SCAN_All_Right", Arrays_Equal (C_SCAN (Requests, Start_Head, Up, Max_Cylinder), Expected));
      end;
      
      -- Test 4: C-SCAN All Left
      declare
         Requests : constant Cylinder_Array := (1 => 10, 2 => 20, 3 => 30);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 100;
         Expected : constant Cylinder_Array := (1 => 100, 2 => 0, 3 => 10, 4 => 20, 5 => 30);
      begin
         Run_Test ("C_SCAN_All_Left", Arrays_Equal (C_SCAN (Requests, Start_Head, Up, Max_Cylinder), Expected));
      end;
      
      -- Test 5: C-SCAN Down Direction
      declare
         Requests : constant Cylinder_Array := (1 => 98, 2 => 183, 3 => 37, 4 => 122, 5 => 14, 6 => 124, 7 => 65, 8 => 67);
         Start_Head : constant Cylinder := 53;
         Max_Cylinder : constant Cylinder := 199;
         Expected : constant Cylinder_Array := (1 => 37, 2 => 14, 3 => 0, 4 => 199, 5 => 183, 6 => 124, 7 => 122, 8 => 98, 9 => 67, 10 => 65);
      begin
         Run_Test ("C_SCAN_Down_Direction", Arrays_Equal (C_SCAN (Requests, Start_Head, Down, Max_Cylinder), Expected));
      end;
   end Test_C_SCAN_Algorithm;

   -- ==========================================================================
   -- LOOK Algorithm Tests
   -- ==========================================================================
   
   procedure Test_LOOK_Algorithm is
   begin
      Ada.Text_IO.Put_Line ("--- LOOK Algorithm Tests ---");
      
      -- Test 1: Basic LOOK UP
      declare
         Requests : constant Cylinder_Array := (1 => 98, 2 => 183, 3 => 37, 4 => 122, 5 => 14, 6 => 124, 7 => 65, 8 => 67);
         Start_Head : constant Cylinder := 53;
         Expected : constant Cylinder_Array := (1 => 65, 2 => 67, 3 => 98, 4 => 122, 5 => 124, 6 => 183, 7 => 37, 8 => 14);
      begin
         Run_Test ("LOOK_Basic_UP", Arrays_Equal (LOOK (Requests, Start_Head, Up), Expected));
      end;
      
      -- Test 2: LOOK Empty
      declare
         Requests : constant Cylinder_Array (1..0) := (others => 0);
         Start_Head : constant Cylinder := 50;
      begin
         Run_Test ("LOOK_Empty", LOOK (Requests, Start_Head, Up)'Length = 0);
      end;
      
      -- Test 3: LOOK All Right
      declare
         Requests : constant Cylinder_Array := (1 => 100, 2 => 150, 3 => 200);
         Start_Head : constant Cylinder := 50;
         Expected : constant Cylinder_Array := (1 => 100, 2 => 150, 3 => 200);
      begin
         Run_Test ("LOOK_All_Right", Arrays_Equal (LOOK (Requests, Start_Head, Up), Expected));
      end;
      
      -- Test 4: LOOK All Left
      declare
         Requests : constant Cylinder_Array := (1 => 10, 2 => 20, 3 => 30);
         Start_Head : constant Cylinder := 50;
         Expected : constant Cylinder_Array := (1 => 30, 2 => 20, 3 => 10);
      begin
         Run_Test ("LOOK_All_Left", Arrays_Equal (LOOK (Requests, Start_Head, Up), Expected));
      end;
      
      -- Test 5: LOOK Single Request
      declare
         Requests : constant Cylinder_Array := (1 => 50);
         Start_Head : constant Cylinder := 100;
         Expected : constant Cylinder_Array := (1 => 50);
      begin
         Run_Test ("LOOK_Single_Request", Arrays_Equal (LOOK (Requests, Start_Head, Up), Expected));
      end;
      
      -- Test 6: LOOK Down Direction
      declare
         Requests : constant Cylinder_Array := (1 => 98, 2 => 183, 3 => 37, 4 => 122, 5 => 14, 6 => 124, 7 => 65, 8 => 67);
         Start_Head : constant Cylinder := 53;
         Expected : constant Cylinder_Array := (1 => 37, 2 => 14, 3 => 65, 4 => 67, 5 => 98, 6 => 122, 7 => 124, 8 => 183);
      begin
         Run_Test ("LOOK_Down_Direction", Arrays_Equal (LOOK (Requests, Start_Head, Down), Expected));
      end;
   end Test_LOOK_Algorithm;

   -- ==========================================================================
   -- C-LOOK Algorithm Tests
   -- ==========================================================================
   
   procedure Test_C_LOOK_Algorithm is
   begin
      Ada.Text_IO.Put_Line ("--- C-LOOK Algorithm Tests ---");
      
      -- Test 1: Basic C-LOOK UP
      declare
         Requests : constant Cylinder_Array := (1 => 98, 2 => 183, 3 => 37, 4 => 122, 5 => 14, 6 => 124, 7 => 65, 8 => 67);
         Start_Head : constant Cylinder := 53;
         Expected : constant Cylinder_Array := (1 => 65, 2 => 67, 3 => 98, 4 => 122, 5 => 124, 6 => 183, 7 => 14, 8 => 37);
      begin
         Run_Test ("C_LOOK_Basic_UP", Arrays_Equal (C_LOOK (Requests, Start_Head, Up), Expected));
      end;
      
      -- Test 2: C-LOOK Empty
      declare
         Requests : constant Cylinder_Array (1..0) := (others => 0);
         Start_Head : constant Cylinder := 50;
      begin
         Run_Test ("C_LOOK_Empty", C_LOOK (Requests, Start_Head, Up)'Length = 0);
      end;
      
      -- Test 3: C-LOOK All Right
      declare
         Requests : constant Cylinder_Array := (1 => 100, 2 => 150, 3 => 200);
         Start_Head : constant Cylinder := 50;
         Expected : constant Cylinder_Array := (1 => 100, 2 => 150, 3 => 200);
      begin
         Run_Test ("C_LOOK_All_Right", Arrays_Equal (C_LOOK (Requests, Start_Head, Up), Expected));
      end;
      
      -- Test 4: C-LOOK All Left
      declare
         Requests : constant Cylinder_Array := (1 => 10, 2 => 20, 3 => 30);
         Start_Head : constant Cylinder := 50;
         Expected : constant Cylinder_Array := (1 => 10, 2 => 20, 3 => 30);
      begin
         Run_Test ("C_LOOK_All_Left", Arrays_Equal (C_LOOK (Requests, Start_Head, Up), Expected));
      end;
      
      -- Test 5: C-LOOK Down Direction
      declare
         Requests : constant Cylinder_Array := (1 => 98, 2 => 183, 3 => 37, 4 => 122, 5 => 14, 6 => 124, 7 => 65, 8 => 67);
         Start_Head : constant Cylinder := 53;
         Expected : constant Cylinder_Array := (1 => 37, 2 => 14, 3 => 183, 4 => 124, 5 => 122, 6 => 98, 7 => 67, 8 => 65);
      begin
         Run_Test ("C_LOOK_Down_Direction", Arrays_Equal (C_LOOK (Requests, Start_Head, Down), Expected));
      end;
   end Test_C_LOOK_Algorithm;

   -- ==========================================================================
   -- F-SCAN Algorithm Tests
   -- ==========================================================================
   
   procedure Test_F_SCAN_Algorithm is
   begin
      Ada.Text_IO.Put_Line ("--- F-SCAN Algorithm Tests ---");
      
      -- Test 1: Basic F-SCAN
      declare
         Active_Queue : constant Cylinder_Array := (1 => 98, 2 => 183, 3 => 37, 4 => 122);
         Waiting_Queue : constant Cylinder_Array := (1 => 14, 2 => 124, 3 => 65, 4 => 67);
         Start_Head : constant Cylinder := 53;
         Max_Cylinder : constant Cylinder := 199;
         Expected : constant Cylinder_Array := (1 => 98, 2 => 122, 3 => 183, 4 => 199, 5 => 37, 6 => 14, 7 => 0, 8 => 65, 9 => 67, 10 => 124);
      begin
         Run_Test ("F_SCAN_Basic", Arrays_Equal (F_SCAN (Active_Queue, Waiting_Queue, Start_Head, Up, Max_Cylinder), Expected));
      end;
      
      -- Test 2: F-SCAN Empty Active
      declare
         Active_Queue : constant Cylinder_Array (1..0) := (others => 0);
         Waiting_Queue : constant Cylinder_Array := (1 => 10, 2 => 20, 3 => 30);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 100;
         Expected : constant Cylinder_Array := (1 => 100, 2 => 30, 3 => 20, 4 => 10);
      begin
         Run_Test ("F_SCAN_Empty_Active", Arrays_Equal (F_SCAN (Active_Queue, Waiting_Queue, Start_Head, Up, Max_Cylinder), Expected));
      end;
      
      -- Test 3: F-SCAN Empty Waiting
      declare
         Active_Queue : constant Cylinder_Array := (1 => 10, 2 => 20, 3 => 30);
         Waiting_Queue : constant Cylinder_Array (1..0) := (others => 0);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 100;
         Expected : constant Cylinder_Array := (1 => 100, 2 => 30, 3 => 20, 4 => 10);
      begin
         Run_Test ("F_SCAN_Empty_Waiting", Arrays_Equal (F_SCAN (Active_Queue, Waiting_Queue, Start_Head, Up, Max_Cylinder), Expected));
      end;
      
      -- Test 4: F-SCAN Both Empty
      declare
         Active_Queue : constant Cylinder_Array (1..0) := (others => 0);
         Waiting_Queue : constant Cylinder_Array (1..0) := (others => 0);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 100;
      begin
         Run_Test ("F_SCAN_Both_Empty", F_SCAN (Active_Queue, Waiting_Queue, Start_Head, Up, Max_Cylinder)'Length = 0);
      end;
   end Test_F_SCAN_Algorithm;

   -- ==========================================================================
   -- Assumption Tests
   -- ==========================================================================
   
   procedure Test_Assumptions is
   begin
      Ada.Text_IO.Put_Line ("--- Assumption Validation Tests ---");
      
      -- Test 1: Partition Correct
      declare
         Requests : constant Cylinder_Array := (1 => 10, 2 => 50, 3 => 100, 4 => 150);
         Head : constant Cylinder := 75;
         Left_Count, Right_Count : Integer := 0;
      begin
         for R of Requests loop
            if R < Head then
               Left_Count := Left_Count + 1;
            end if;
         end loop;
         for R of Requests loop
            if R >= Head then
               Right_Count := Right_Count + 1;
            end if;
         end loop;
         Run_Test ("Partition_Correct", Left_Count + Right_Count = Requests'Length);
      end;
      
      -- Test 2: No Overlap
      declare
         Requests : constant Cylinder_Array := (1 => 10, 2 => 50, 3 => 100, 4 => 150);
         Head : constant Cylinder := 75;
         Has_Overlap : Boolean := False;
      begin
         for R of Requests loop
            if R < Head and R >= Head then
               Has_Overlap := True;
            end if;
         end loop;
         Run_Test ("No_Overlap", not Has_Overlap);
      end;
      
      -- Test 3: Left All Less
      declare
         Requests : constant Cylinder_Array := (1 => 10, 2 => 50, 3 => 100, 4 => 150);
         Head : constant Cylinder := 75;
         All_Less : Boolean := True;
      begin
         for R of Requests loop
            if R < Head and R >= Head then
               All_Less := False;
            end if;
         end loop;
         Run_Test ("Left_All_Less", All_Less);
      end;
      
      -- Test 4: Right All GE
      declare
         Requests : constant Cylinder_Array := (1 => 10, 2 => 50, 3 => 100, 4 => 150);
         Head : constant Cylinder := 75;
         All_GE : Boolean := True;
      begin
         for R of Requests loop
            if R >= Head and R < Head then
               All_GE := False;
            end if;
         end loop;
         Run_Test ("Right_All_GE", All_GE);
      end;
   end Test_Assumptions;

   -- ==========================================================================
   -- Tests to be Proven False
   -- ==========================================================================
   
   procedure Test_Proven_False is
   begin
      Ada.Text_IO.Put_Line ("--- Tests to be Proven False ---");
      
      -- Test 1: SCAN Includes Max
      declare
         Requests : constant Cylinder_Array := (1 => 100, 2 => 200);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 300;
         Has_Max : Boolean := False;
      begin
         for R of SCAN (Requests, Start_Head, Up, Max_Cylinder) loop
            if R = Max_Cylinder then
               Has_Max := True;
            end if;
         end loop;
         Run_Test ("SCAN_Includes_Max", Has_Max);
      end;
      
      -- Test 2: LOOK No Max
      declare
         Requests : constant Cylinder_Array := (1 => 100, 2 => 200);
         Start_Head : constant Cylinder := 50;
         Has_Max : Boolean := False;
      begin
         for R of LOOK (Requests, Start_Head, Up) loop
            if R = 300 then
               Has_Max := True;
            end if;
         end loop;
         Run_Test ("LOOK_No_Max", not Has_Max);
      end;
      
      -- Test 3: C-SCAN Includes Both
      declare
         Requests : constant Cylinder_Array := (1 => 10, 2 => 20);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 100;
         Has_Zero : Boolean := False;
         Has_Max : Boolean := False;
      begin
         for R of C_SCAN (Requests, Start_Head, Up, Max_Cylinder) loop
            if R = 0 then
               Has_Zero := True;
            end if;
            if R = Max_Cylinder then
               Has_Max := True;
            end if;
         end loop;
         Run_Test ("CSCAN_Includes_Both", Has_Zero and Has_Max);
      end;
      
      -- Test 4: C-LOOK No Ends
      declare
         Requests : constant Cylinder_Array := (1 => 10, 2 => 20, 3 => 30);
         Start_Head : constant Cylinder := 50;
         Has_Zero : Boolean := False;
         Has_Max : Boolean := False;
      begin
         for R of C_LOOK (Requests, Start_Head, Up) loop
            if R = 0 then
               Has_Zero := True;
            end if;
            if R = 100 then
               Has_Max := True;
            end if;
         end loop;
         Run_Test ("CLOOK_No_Ends", not (Has_Zero or Has_Max));
      end;
      
      -- Test 5: F-SCAN Processes Waiting
      declare
         Active_Queue : constant Cylinder_Array := (1 => 100);
         Waiting_Queue : constant Cylinder_Array := (1 => 200);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 300;
         Has_Waiting : Boolean := False;
      begin
         for R of F_SCAN (Active_Queue, Waiting_Queue, Start_Head, Up, Max_Cylinder) loop
            if R = 200 then
               Has_Waiting := True;
            end if;
         end loop;
         Run_Test ("FSCAN_Processes_Waiting", Has_Waiting);
      end;
      
      -- Test 6: Empty No Error
      declare
         Requests : constant Cylinder_Array (1..0) := (others => 0);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 100;
      begin
         Run_Test ("Empty_No_Error", SCAN (Requests, Start_Head, Up, Max_Cylinder)'Length = 0);
      end;
   end Test_Proven_False;

   -- ==========================================================================
   -- Comparison Tests
   -- ==========================================================================
   
   procedure Test_Comparisons is
   begin
      Ada.Text_IO.Put_Line ("--- Algorithm Comparison Tests ---");
      
      -- Test 1: SCAN vs C-SCAN
      declare
         Requests : constant Cylinder_Array := (1 => 10, 2 => 20, 3 => 30);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 100;
      begin
         Run_Test ("SCAN_vs_CSCAN_Differ", 
                  SCAN (Requests, Start_Head, Up, Max_Cylinder)'Length /=
                  C_SCAN (Requests, Start_Head, Up, Max_Cylinder)'Length);
      end;
      
      -- Test 2: LOOK vs C-LOOK
      declare
         Requests : constant Cylinder_Array := (1 => 10, 2 => 20, 3 => 60, 4 => 80);
         Start_Head : constant Cylinder := 50;
         LOOK_Result : constant Cylinder_Array := LOOK (Requests, Start_Head, Up);
         CLOOK_Result : constant Cylinder_Array := C_LOOK (Requests, Start_Head, Up);
      begin
         Run_Test ("LOOK_vs_CLOOK_Differ", 
                  not Arrays_Equal (LOOK_Result, CLOOK_Result));
      end;
      
      -- Test 3: SCAN vs LOOK
      declare
         Requests : constant Cylinder_Array := (1 => 10, 2 => 20, 3 => 30);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 100;
      begin
         Run_Test ("SCAN_vs_LOOK_Differ", 
                  SCAN (Requests, Start_Head, Up, Max_Cylinder)'Length /=
                  LOOK (Requests, Start_Head, Up)'Length);
      end;
      
      -- Test 4: C-SCAN vs C-LOOK
      declare
         Requests : constant Cylinder_Array := (1 => 10, 2 => 20, 3 => 30);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 100;
      begin
         Run_Test ("CSCAN_vs_CLOOK_Differ", 
                  C_SCAN (Requests, Start_Head, Up, Max_Cylinder)'Length /=
                  C_LOOK (Requests, Start_Head, Up)'Length);
      end;
   end Test_Comparisons;

   -- ==========================================================================
   -- Edge Case Tests
   -- ==========================================================================
   
   procedure Test_Edge_Cases is
   begin
      Ada.Text_IO.Put_Line ("--- Edge Case Tests ---");
      
      -- Test 1: Duplicate Requests
      declare
         Requests : constant Cylinder_Array := (1 => 50, 2 => 50, 3 => 50, 4 => 100);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 200;
      begin
         Run_Test ("Edge_Duplicate_Requests", SCAN (Requests, Start_Head, Up, Max_Cylinder)'Length > 0);
      end;
      
      -- Test 2: Request At Head
      declare
         Requests : constant Cylinder_Array := (1 => 50, 2 => 100, 3 => 150);
         Start_Head : constant Cylinder := 50;
         Max_Cylinder : constant Cylinder := 200;
         Has_50 : Boolean := False;
      begin
         for R of SCAN (Requests, Start_Head, Up, Max_Cylinder) loop
            if R = 50 then
               Has_50 := True;
            end if;
         end loop;
         Run_Test ("Edge_Request_At_Head", Has_50);
      end;
      
      -- Test 3: Large Numbers
      declare
         Requests : constant Cylinder_Array := (1 => 1000, 2 => 2000, 3 => 3000);
         Start_Head : constant Cylinder := 500;
         Max_Cylinder : constant Cylinder := 5000;
      begin
         Run_Test ("Edge_Large_Numbers", SCAN (Requests, Start_Head, Up, Max_Cylinder)'Length > 0);
      end;
   end Test_Edge_Cases;

   -- ==========================================================================
   -- Run All Tests
   -- ==========================================================================
   
   procedure Run_All_Tests is
   begin
      Ada.Text_IO.Put_Line ("================================================================================");
      Ada.Text_IO.Put_Line ("DISK SCHEDULING ALGORITHMS - ADA TEST SUITE");
      Ada.Text_IO.Put_Line ("================================================================================");
      Ada.Text_IO.New_Line;
      
      Test_SCAN_Algorithm;
      Test_C_SCAN_Algorithm;
      Test_LOOK_Algorithm;
      Test_C_LOOK_Algorithm;
      Test_F_SCAN_Algorithm;
      Test_Assumptions;
      Test_Proven_False;
      Test_Comparisons;
      Test_Edge_Cases;
      
      Print_Summary;
   end Run_All_Tests;

end Test_Disk_Scheduling;
