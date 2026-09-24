with Ada.Text_IO; use Ada.Text_IO;
with Task_Scheduling; use Task_Scheduling;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

begin
   -- TEST 1 — FCFS Basic Functional
   Put_Line ("TEST 1 — FCFS Basic Functional");
   declare
      Tasks : constant Task_Array :=
        [(Id => 1, Arrival => 0, Burst => 5, Deadline => 10),
         (Id => 2, Arrival => 2, Burst => 3, Deadline => 10),
         (Id => 3, Arrival => 5, Burst => 2, Deadline => 10)];
      Res : constant Schedule_Array := Schedule_FCFS (Tasks);
   begin
      Check ("1.1 Correct number of events (3)", Res'Length = 3);
      Check ("1.2 Task 1 starts first", Res(Res'First).Id = 1 and then Res(Res'First).Start_Time = 0);
      Check ("1.3 Task 3 finishes last at T=10", Res(Res'Last).Id = 3 and then Res(Res'Last).End_Time = 10);
   end;

   -- TEST 2 — SJN Basic Functional
   Put_Line ("TEST 2 — SJN Basic Functional");
   declare
      Tasks : constant Task_Array :=
        [(Id => 1, Arrival => 0, Burst => 10, Deadline => 20),
         (Id => 2, Arrival => 1, Burst => 2, Deadline => 20),
         (Id => 3, Arrival => 2, Burst => 1, Deadline => 20)];
      Res : constant Schedule_Array := Schedule_SJN (Tasks);
   begin
      -- SJN is non-preemptive. T1 starts, T2 and T3 wait. T3 is shorter so runs second.
      Check ("2.1 Correct number of events (3)", Res'Length = 3);
      Check ("2.2 Task 3 executes second", Res(Res'First + 1).Id = 3);
      Check ("2.3 Schedule completes at T=13", Res(Res'Last).End_Time = 13);
   end;

   -- TEST 3 — SRTF Basic Functional
   Put_Line ("TEST 3 — SRTF Basic Functional");
   declare
      Tasks : constant Task_Array :=
        [(Id => 1, Arrival => 0, Burst => 10, Deadline => 20),
         (Id => 2, Arrival => 1, Burst => 2, Deadline => 20),
         (Id => 3, Arrival => 2, Burst => 1, Deadline => 20)];
      Res : constant Schedule_Array := Schedule_SRTF (Tasks);
   begin
      -- Expected order: T1(0-1), T2(1-3) merged because T2 still shortest at T=2, T3(3-4), T1(4-13)
      Check ("3.1 Generates 4 context switches due to preemption", Res'Length = 4);
      Check ("3.2 Task 2 preempts Task 1", Res(Res'First + 1).Id = 2);
      Check ("3.3 Task 1 finishes schedule", Res(Res'Last).Id = 1 and then Res(Res'Last).End_Time = 13);
   end;

   -- TEST 4 — EDF Basic Functional
   Put_Line ("TEST 4 — EDF Basic Functional");
   declare
      Tasks : constant Task_Array :=
        [(Id => 1, Arrival => 0, Burst => 3, Deadline => 10),
         (Id => 2, Arrival => 1, Burst => 2, Deadline => 4),
         (Id => 3, Arrival => 2, Burst => 1, Deadline => 2)];
      Res : constant Schedule_Array := Schedule_EDF (Tasks);
   begin
      -- T=0: T1. T=1: T2 has tighter deadline, preempts. T=2: T3 has tighter deadline, preempts.
      -- Expected: T1(0-1), T2(1-2), T3(2-3), T2(3-4), T1(4-6)
      Check ("4.1 Deep preemption triggers 5 segments", Res'Length = 5);
      Check ("4.2 Task 3 hits earliest deadline requirement", Res(Res'First + 2).Id = 3);
      Check ("4.3 Overall time spans to T=6", Res(Res'Last).End_Time = 6);
   end;

   -- TEST 5 — FCFS Gap Handling
   Put_Line ("TEST 5 — FCFS Gap Handling");
   declare
      Tasks : constant Task_Array :=
        [(Id => 1, Arrival => 0, Burst => 2, Deadline => 10),
         (Id => 2, Arrival => 5, Burst => 2, Deadline => 10)];
      Res : constant Schedule_Array := Schedule_FCFS (Tasks);
   begin
      Check ("5.1 Exactly 2 events despite gap", Res'Length = 2);
      Check ("5.2 First task ends at T=2", Res(Res'First).End_Time = 2);
      Check ("5.3 Second task resumes properly at T=5", Res(Res'Last).Start_Time = 5);
   end;

   -- TEST 6 — SJN Identical Bursts
   Put_Line ("TEST 6 — SJN Identical Bursts");
   declare
      Tasks : constant Task_Array :=
        [(Id => 1, Arrival => 0, Burst => 5, Deadline => 10),
         (Id => 2, Arrival => 6, Burst => 2, Deadline => 10),
         (Id => 3, Arrival => 6, Burst => 2, Deadline => 10)];
      Res : constant Schedule_Array := Schedule_SJN (Tasks);
   begin
      -- Gap from 5 to 6. Both T2 and T3 arrive at 6 with Burst 2. Tie break falls to Arrival (equal), then ID.
      Check ("6.1 Schedule captures 3 segments", Res'Length = 3);
      Check ("6.2 Gap is handled correctly for T2", Res(Res'First + 1).Start_Time = 6);
      Check ("6.3 Tie breaker picks Task 2 before Task 3", Res(Res'First + 1).Id = 2 and then Res(Res'Last).Id = 3);
   end;

   -- TEST 7 — SRTF Continuous Preemption (Merging test)
   Put_Line ("TEST 7 — SRTF Continuous Preemption");
   declare
      Tasks : constant Task_Array :=
        [(Id => 1, Arrival => 0, Burst => 10, Deadline => 20),
         (Id => 2, Arrival => 2, Burst => 2, Deadline => 20)];
      Res : constant Schedule_Array := Schedule_SRTF (Tasks);
   begin
      -- T=0: T1 to T=2. T=2: T2 to T=4. T=4: T1 resumes.
      Check ("7.1 Array automatically merges contiguous chunks (Len=3)", Res'Length = 3);
      Check ("7.2 Middle chunk is fully T2", Res(Res'First + 1).Id = 2 and then Res(Res'First + 1).End_Time = 4);
      Check ("7.3 Last chunk is T1 completion", Res(Res'Last).Id = 1 and then Res(Res'Last).End_Time = 12);
   end;

   -- TEST 8 — EDF Identical Deadlines
   Put_Line ("TEST 8 — EDF Identical Deadlines");
   declare
      Tasks : constant Task_Array :=
        [(Id => 1, Arrival => 0, Burst => 2, Deadline => 5),
         (Id => 2, Arrival => 1, Burst => 2, Deadline => 5)];
      Res : constant Schedule_Array := Schedule_EDF (Tasks);
   begin
      -- Both D=5. T1 runs 0..1. At T=1, T1 rem=1 D=5, T2 rem=2 D=5. Tie on D. Arrival breaks it. T1 continues.
      Check ("8.1 No preemption on identical deadline (Len=2)", Res'Length = 2);
      Check ("8.2 T1 completes immediately", Res(Res'First).Id = 1 and then Res(Res'First).End_Time = 2);
      Check ("8.3 T2 runs sequentially", Res(Res'Last).Start_Time = 2);
   end;

   -- TEST 9 — Exception Invalid Parameters
   Put_Line ("TEST 9 — Exception Invalid Parameters");
   declare
      Bad_Tasks   : constant Task_Array := [(Id => 1, Arrival => 0, Burst => 0, Deadline => 10)];
      Raised_FCFS : Boolean := False;
      Raised_SJN  : Boolean := False;
      Raised_SRTF : Boolean := False;
      Raised_EDF  : Boolean := False;
   begin
      begin
         declare 
            Res : constant Schedule_Array := Schedule_FCFS (Bad_Tasks); 
            pragma Unreferenced (Res);
         begin null; end;
      exception when Invalid_Tasks => Raised_FCFS := True;
      end;

      begin
         declare 
            Res : constant Schedule_Array := Schedule_SJN (Bad_Tasks); 
            pragma Unreferenced (Res);
         begin null; end;
      exception when Invalid_Tasks => Raised_SJN := True;
      end;

      begin
         declare 
            Res : constant Schedule_Array := Schedule_SRTF (Bad_Tasks); 
            pragma Unreferenced (Res);
         begin null; end;
      exception when Invalid_Tasks => Raised_SRTF := True;
      end;

      begin
         declare 
            Res : constant Schedule_Array := Schedule_EDF (Bad_Tasks); 
            pragma Unreferenced (Res);
         begin null; end;
      exception when Invalid_Tasks => Raised_EDF := True;
      end;

      Check ("9.1 FCFS rejects bad inputs", Raised_FCFS);
      Check ("9.2 SJN rejects bad inputs", Raised_SJN);
      Check ("9.3 SRTF rejects bad inputs", Raised_SRTF);
      Check ("9.4 EDF rejects bad inputs", Raised_EDF);
   end;

   -- TEST 10 — Exception Empty List
   Put_Line ("TEST 10 — Exception Empty List");
   declare
      Empty_Tasks : constant Task_Array (1 .. 0) := [];
      Raised_FCFS : Boolean := False;
      Raised_SJN  : Boolean := False;
      Raised_EDF  : Boolean := False;
   begin
      begin
         declare 
            Res : constant Schedule_Array := Schedule_FCFS (Empty_Tasks); 
            pragma Unreferenced (Res);
         begin null; end;
      exception when Empty_Task_List => Raised_FCFS := True;
      end;

      begin
         declare 
            Res : constant Schedule_Array := Schedule_SJN (Empty_Tasks); 
            pragma Unreferenced (Res);
         begin null; end;
      exception when Empty_Task_List => Raised_SJN := True;
      end;

      begin
         declare 
            Res : constant Schedule_Array := Schedule_EDF (Empty_Tasks); 
            pragma Unreferenced (Res);
         begin null; end;
      exception when Empty_Task_List => Raised_EDF := True;
      end;

      Check ("10.1 FCFS rejects empty list", Raised_FCFS);
      Check ("10.2 SJN rejects empty list", Raised_SJN);
      Check ("10.3 EDF rejects empty list", Raised_EDF);
   end;

   -- TEST 11 — Single Task Processing
   Put_Line ("TEST 11 — Single Task Processing");
   declare
      Tasks : constant Task_Array := [(Id => 1, Arrival => 5, Burst => 5, Deadline => 15)];
      Res_FCFS : constant Schedule_Array := Schedule_FCFS (Tasks);
      Res_SJN  : constant Schedule_Array := Schedule_SJN (Tasks);
      Res_SRTF : constant Schedule_Array := Schedule_SRTF (Tasks);
      Res_EDF  : constant Schedule_Array := Schedule_EDF (Tasks);
   begin
      Check ("11.1 FCFS manages single task length", Res_FCFS'Length = 1);
      Check ("11.2 SJN matches correct start bounds", Res_SJN(Res_SJN'First).Start_Time = 5);
      Check ("11.3 SRTF matches correct end bounds", Res_SRTF(Res_SRTF'First).End_Time = 10);
      Check ("11.4 EDF manages ID correctly", Res_EDF(Res_EDF'First).Id = 1);
   end;

   -- TEST 12 — FCFS Out of Order Arrivals
   Put_Line ("TEST 12 — FCFS Out of Order Arrivals");
   declare
      Tasks : constant Task_Array :=
        [(Id => 1, Arrival => 5, Burst => 2, Deadline => 10),
         (Id => 2, Arrival => 0, Burst => 2, Deadline => 10)];
      Res : constant Schedule_Array := Schedule_FCFS (Tasks);
   begin
      Check ("12.1 FCFS identifies early arrival internally", Res(Res'First).Id = 2);
      Check ("12.2 Schedule length stays tight", Res'Length = 2);
      Check ("12.3 Later arrival sorted physically behind", Res(Res'Last).Start_Time = 5);
   end;

   -- TEST 13 — Extreme Data Gaps
   Put_Line ("TEST 13 — Extreme Data Gaps");
   declare
      Tasks : constant Task_Array :=
        [(Id => 1, Arrival => 0, Burst => 1, Deadline => 1),
         (Id => 2, Arrival => 100, Burst => 1, Deadline => 101),
         (Id => 3, Arrival => 200, Burst => 1, Deadline => 201)];
      Res : constant Schedule_Array := Schedule_SJN (Tasks);
   begin
      Check ("13.1 Schedule processes large jumps gracefully", Res'Length = 3);
      Check ("13.2 Middle task properly jumps forward", Res(Res'First + 1).Start_Time = 100);
      Check ("13.3 Last task isolated effectively", Res(Res'Last).Start_Time = 200);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
