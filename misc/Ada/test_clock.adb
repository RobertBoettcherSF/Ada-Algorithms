with Clock_Algorithms; use Clock_Algorithms;
with Ada.Text_IO; use Ada.Text_IO;

procedure Test_Clock is
   -- Test Standard Clock algorithm
   procedure Test_Standard_Clock is
      Algo : Clock_Algo := Init_Clock(3);
      Pages : constant array(1..10) of Page_ID := (1, 2, 3, 4, 1, 2, 5, 1, 2, 3);
   begin
      Put_Line("Testing Standard Clock algorithm:");
      Put_Line("  Page access sequence: 1, 2, 3, 4, 1, 2, 5, 1, 2, 3");
      
      for P of Pages loop
         Access_Page(Algo, P);
      end loop;

      Put_Line("  Page Faults: " & Natural'Image(Get_Page_Faults(Algo)));
      Put_Line("  Hit Rate: " & Float'Image(Get_Hit_Rate(Algo)));
      New_Line;
   end Test_Standard_Clock;

   -- Test GCLOCK algorithm
   procedure Test_GCLOCK is
      Algo : GCLOCK_Algo := Init_GCLOCK(3, 2);
      Pages : constant array(1..10) of Page_ID := (1, 2, 3, 4, 1, 2, 5, 1, 2, 3);
   begin
      Put_Line("Testing GCLOCK algorithm:");
      Put_Line("  Page access sequence: 1, 2, 3, 4, 1, 2, 5, 1, 2, 3");
      
      for P of Pages loop
         Access_Page(Algo, P);
      end loop;

      Put_Line("  Page Faults: " & Natural'Image(Get_Page_Faults(Algo)));
      Put_Line("  Hit Rate: " & Float'Image(Get_Hit_Rate(Algo)));
      New_Line;
   end Test_GCLOCK;

   -- Test WSClock algorithm
   procedure Test_WSClock is
      Algo : WSClock_Algo := Init_WSClock(3, 10);
      Pages : constant array(1..10) of Page_ID := (1, 2, 3, 4, 1, 2, 5, 1, 2, 3);
   begin
      Put_Line("Testing WSClock algorithm:");
      Put_Line("  Page access sequence: 1, 2, 3, 4, 1, 2, 5, 1, 2, 3");
      
      for P of Pages loop
         Access_Page(Algo, P);
      end loop;

      Put_Line("  Page Faults: " & Natural'Image(Get_Page_Faults(Algo)));
      Put_Line("  Hit Rate: " & Float'Image(Get_Hit_Rate(Algo)));
      New_Line;
   end Test_WSClock;

begin
   Put_Line("=== Ada Clock Replacement Algorithm Tests ===");
   New_Line;
   
   Test_Standard_Clock;
   Test_GCLOCK;
   Test_WSClock;
   
   Put_Line("All tests completed!");
end Test_Clock;
