-- SSTF Algorithm Demonstration Program
-- This program demonstrates the Shortest Seek First disk scheduling algorithm
-- It can be run from the terminal and shows the algorithm in action

with Ada.Text_IO;
with Ada.Integer_Text_IO;
with SSTF;
use SSTF;

procedure SSTF_Demo is

   -- Maximum number of requests for demo
   Max_Demo_Requests : constant := 20;
   
   -- Procedure to display the algorithm header
   procedure Display_Header is
   begin
      Ada.Text_IO.New_Line(2);
      Ada.Text_IO.Put_Line("=================================================");
      Ada.Text_IO.Put_Line("  SHORTEST SEEK FIRST (SSTF) DISK SCHEDULING");
      Ada.Text_IO.Put_Line("  ============================================");
      Ada.Text_IO.Put_Line("");
      Ada.Text_IO.Put_Line("The SSTF algorithm selects the request closest to");
      Ada.Text_IO.Put_Line("the current head position, minimizing seek time.");
      Ada.Text_IO.Put_Line("");
      Ada.Text_IO.Put_Line("=================================================");
      Ada.Text_IO.New_Line;
   end Display_Header;

   -- Procedure to display a demo with predefined requests
   procedure Run_Predefined_Demo is
      -- Predefined request sequences
      type Demo_Case is record
         Name : String(1..40);
         Initial_Head : Track_Index;
         Requests : Track_Array(1..10);
         Request_Count : Integer;
      end record;
      
      Demos : array(1..5) of Demo_Case := (
         -- Demo 1: Simple case
         (Name => "Simple Demo - Head in Middle              ",
          Initial_Head => 50,
          Requests => (1 => 10, 2 => 90, others => 0),
          Request_Count => 2),
          
         -- Demo 2: Multiple requests on both sides
         (Name => "Multiple Requests - Both Sides            ",
          Initial_Head => 100,
          Requests => (1 => 20, 2 => 80, 3 => 120, 4 => 180, others => 0),
          Request_Count => 4),
          
         -- Demo 3: All requests on one side
         (Name => "All Requests on Left Side                 ",
          Initial_Head => 200,
          Requests => (1 => 50, 2 => 100, 3 => 150, others => 0),
          Request_Count => 3),
          
         -- Demo 4: Head at request position
         (Name => "Head at Request Position                  ",
          Initial_Head => 100,
          Requests => (1 => 100, 2 => 50, 3 => 150, 4 => 200, others => 0),
          Request_Count => 4),
          
         -- Demo 5: Complex scenario
         (Name => "Complex Scenario - Mixed Positions         ",
          Initial_Head => 1000,
          Requests => (1 => 500, 2 => 1500, 3 => 200, 4 => 1200, 5 => 800, others => 0),
          Request_Count => 5)
      );
      
      Total_Seek_Distance : Track_Index;
      Current_Head : Track_Index;
   begin
      Ada.Text_IO.Put_Line("PREDEFINED DEMONSTRATIONS");
      Ada.Text_IO.Put_Line("=========================");
      Ada.Text_IO.New_Line;
      
      for Demo_Num in 1..5 loop
         declare
            Demo : Demo_Case := Demos(Demo_Num);
            Actual_Requests : Track_Array(1..Demo.Request_Count);
            Actual_Schedule : Track_Array(1..Demo.Request_Count);
         begin
            -- Copy requests to properly sized array
            for I in 1..Demo.Request_Count loop
               Actual_Requests(I) := Demo.Requests(I);
            end loop;
            
            -- Calculate schedule
            Get_SSTF_Schedule(Demo.Initial_Head, Actual_Requests, Actual_Schedule);
            
            -- Display demo info
            Ada.Text_IO.Put_Line("Demo " & Integer'Image(Demo_Num) & ": " & Demo.Name);
            Ada.Text_IO.Put_Line("  Initial Head Position: " & Track_Index'Image(Demo.Initial_Head));
            Ada.Text_IO.Put("  Requests: ");
            for J in 1..Demo.Request_Count loop
               Ada.Text_IO.Put(Track_Index'Image(Actual_Requests(J)) & " ");
            end loop;
            Ada.Text_IO.New_Line;
            
            Ada.Text_IO.Put("  Schedule: ");
            for J in 1..Demo.Request_Count loop
               Ada.Text_IO.Put(Track_Index'Image(Actual_Schedule(J)) & " ");
            end loop;
            Ada.Text_IO.New_Line;
            
            -- Calculate total seek distance
            Total_Seek_Distance := 0;
            Current_Head := Demo.Initial_Head;
            for J in 1..Demo.Request_Count loop
               if Actual_Schedule(J) >= Current_Head then
                  Total_Seek_Distance := Total_Seek_Distance + (Actual_Schedule(J) - Current_Head);
               else
                  Total_Seek_Distance := Total_Seek_Distance + (Current_Head - Actual_Schedule(J));
               end if;
               Current_Head := Actual_Schedule(J);
            end loop;
            
            Ada.Text_IO.Put_Line("  Total Seek Distance: " & Track_Index'Image(Total_Seek_Distance));
            Ada.Text_IO.New_Line;
         end;
      end loop;
   end Run_Predefined_Demo;

   -- Procedure to run interactive demo
   procedure Run_Interactive_Demo is
      Initial_Head : Track_Index;
      Request_Count : Integer;
      Total_Seek_Distance : Track_Index;
      Current_Head : Track_Index;
   begin
      Ada.Text_IO.Put_Line("INTERACTIVE DEMONSTRATION");
      Ada.Text_IO.Put_Line("========================");
      Ada.Text_IO.New_Line;
      
      -- Get initial head position
      loop
         begin
            Ada.Text_IO.Put("Enter initial head position (0-100000): ");
            Ada.Integer_Text_IO.Get(Initial_Head);
            exit;
         exception
            when others =>
               Ada.Text_IO.Put_Line("Invalid input. Please enter a number between 0 and 100000.");
               Ada.Text_IO.Skip_Line;
         end;
      end loop;
      
      -- Get number of requests
      loop
         begin
            Ada.Text_IO.Put("Enter number of requests (1-10): ");
            Ada.Integer_Text_IO.Get(Request_Count);
            
            if Request_Count < 1 or Request_Count > 10 then
               Ada.Text_IO.Put_Line("Please enter a number between 1 and 10.");
            else
               exit;
            end if;
         exception
            when others =>
               Ada.Text_IO.Put_Line("Invalid input. Please enter a valid number.");
               Ada.Text_IO.Skip_Line;
         end;
      end loop;
      
      -- Get requests
      declare
         Requests : Track_Array(1..Request_Count);
         Schedule : Track_Array(1..Request_Count);
      begin
         Ada.Text_IO.Put_Line("Enter request track positions:");
         for I in 1..Request_Count loop
            loop
               begin
                  Ada.Text_IO.Put("  Request " & Integer'Image(I) & ": ");
                  Ada.Integer_Text_IO.Get(Requests(I));
                  exit;
               exception
                  when others =>
                     Ada.Text_IO.Put_Line("Invalid input. Please enter a valid track number.");
                     Ada.Text_IO.Skip_Line;
            end;
         end loop;
         
         -- Calculate schedule
         Get_SSTF_Schedule(Initial_Head, Requests, Schedule);
         
         -- Display results
         Ada.Text_IO.New_Line;
         Ada.Text_IO.Put_Line("RESULTS:");
         Ada.Text_IO.Put_Line("--------");
         Ada.Text_IO.Put("Initial Head: " & Track_Index'Image(Initial_Head));
         Ada.Text_IO.New_Line;
         
         Ada.Text_IO.Put("Requests:   ");
         for I in 1..Request_Count loop
            Ada.Text_IO.Put(Track_Index'Image(Requests(I)) & " ");
         end loop;
         Ada.Text_IO.New_Line;
         
         Ada.Text_IO.Put("Schedule:   ");
         for I in 1..Request_Count loop
            Ada.Text_IO.Put(Track_Index'Image(Schedule(I)) & " ");
         end loop;
         Ada.Text_IO.New_Line;
         
         -- Calculate and display seek distances for each step
         Ada.Text_IO.New_Line;
         Ada.Text_IO.Put_Line("Step-by-step movement:");
         Current_Head := Initial_Head;
         Total_Seek_Distance := 0;
         
         for I in 1..Request_Count loop
            if Schedule(I) >= Current_Head then
               Total_Seek_Distance := Total_Seek_Distance + (Schedule(I) - Current_Head);
               Ada.Text_IO.Put_Line("  " & Track_Index'Image(Current_Head) & " -> " & 
                                   Track_Index'Image(Schedule(I)) & 
                                   " (seek: " & Track_Index'Image(Schedule(I) - Current_Head) & ")");
            else
               Total_Seek_Distance := Total_Seek_Distance + (Current_Head - Schedule(I));
               Ada.Text_IO.Put_Line("  " & Track_Index'Image(Current_Head) & " -> " & 
                                   Track_Index'Image(Schedule(I)) & 
                                   " (seek: " & Track_Index'Image(Current_Head - Schedule(I)) & ")");
            end if;
            Current_Head := Schedule(I);
         end loop;
         
         Ada.Text_IO.New_Line;
         Ada.Text_IO.Put_Line("Total Seek Distance: " & Track_Index'Image(Total_Seek_Distance));
         Ada.Text_IO.New_Line;
      end;
   end Run_Interactive_Demo;

   -- Procedure to display help
   procedure Display_Help is
   begin
      Ada.Text_IO.Put_Line("SSTF Demo Program - Usage:");
      Ada.Text_IO.Put_Line("  sstf_demo              - Run predefined demos");
      Ada.Text_IO.Put_Line("  sstf_demo interactive  - Run interactive demo");
      Ada.Text_IO.Put_Line("  sstf_demo help         - Show this help");
      Ada.Text_IO.New_Line;
   end Display_Help;

   -- Main procedure
   Args : Ada.Text_IO.File_Type;
   Argument : String(1..10);
   Arg_Length : Integer;
begin
   Display_Header;
   
   -- Check command line arguments
   if Ada.Text_IO.Argument_Count > 0 then
      Ada.Text_IO.Open(
         File => Args,
         Mode => Ada.Text_IO.In_File,
         Name => Ada.Text_IO.Argument(1)
      );
      Ada.Text_IO.Get_Line(Args, Argument, Arg_Length);
      Ada.Text_IO.Close(Args);
      
      if Arg_Length >= 1 and then Argument(1..9) = "interactive" then
         Run_Interactive_Demo;
      elsif Arg_Length >= 1 and then Argument(1..4) = "help" then
         Display_Help;
      else
         Display_Help;
      end if;
   else
      -- Default: run predefined demos
      Run_Predefined_Demo;
      Display_Help;
   end if;
   
   Ada.Text_IO.Put_Line("Demo completed successfully!");
   
exception
   when others =>
      Ada.Text_IO.Put_Line("An error occurred during execution.");
      Ada.Text_IO.Put_Line("Please check your input and try again.");

end SSTF_Demo;
