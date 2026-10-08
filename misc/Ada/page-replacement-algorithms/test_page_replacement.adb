--  test_page_replacement.adb
--  
--  Test program for page replacement algorithms.
--  
--  This program demonstrates the page replacement algorithms by simulating
--  a sequence of page references and showing the number of page faults
--  for each algorithm.
--  
--  Author: Robert Boettcher
--  Language: Ada
--

with Page_Replacement;
with Ada.Text_IO;

procedure Test_Page_Replacement is
   use Page_Replacement;

   --  The reference string to simulate
   --  This represents the sequence of pages accessed by a process
   --  Example: (1, 2, 3, 4, 1, 2, 5, 1, 2, 3)
   The_References : constant Reference_String_Type := (1, 2, 3, 4, 1, 2, 5, 1, 2, 3);
   
   --  Statistics for each algorithm
   Stats : Algorithm_Statistics;
   
   --  Number of physical frames available in memory
   Num_Frames : Frame_Number := 3;

begin
   --  Print header information
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line("=================================================");
   Ada.Text_IO.Put_Line("  Page Replacement Algorithm Simulation");
   Ada.Text_IO.Put_Line("=================================================");
   Ada.Text_IO.New_Line;
   
   --  Print simulation parameters
   Ada.Text_IO.Put_Line("Reference String: ");
   Ada.Text_IO.Put("   ");
   for I in The_References'Range loop
      Ada.Text_IO.Put(The_References(I)'Image & " ");
   end loop;
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line("Number of Frames: " & Num_Frames'Image);
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line("-------------------------------------------------");
   Ada.Text_IO.Put_Line("Algorithm        | Page Faults | Replacements");
   Ada.Text_IO.Put_Line("-------------------------------------------------");

   --  Test FIFO algorithm
   Simulate(The_References, Num_Frames, FIFO, Stats);
   Ada.Text_IO.Put_Line("FIFO            | " & 
                        Stats.Page_Faults'Image & "         | " & 
                        Stats.Page_Replacements'Image);
   Stats := (others => 0);

   --  Test LRU algorithm
   Simulate(The_References, Num_Frames, LRU, Stats);
   Ada.Text_IO.Put_Line("LRU             | " & 
                        Stats.Page_Faults'Image & "         | " & 
                        Stats.Page_Replacements'Image);
   Stats := (others => 0);

   --  Test Random algorithm
   Simulate(The_References, Num_Frames, Random_Alg, Stats);
   Ada.Text_IO.Put_Line("Random          | " & 
                        Stats.Page_Faults'Image & "         | " & 
                        Stats.Page_Replacements'Image);
   Stats := (others => 0);

   Ada.Text_IO.Put_Line("-------------------------------------------------");
   Ada.Text_IO.New_Line;
   
   --  Explanation of results
   Ada.Text_IO.Put_Line("Note: All algorithms show the same results because:");
   Ada.Text_IO.Put_Line("  1. The current implementation has a bug where ALL page");
   Ada.Text_IO.Put_Line("     references are counted as page faults.");
   Ada.Text_IO.Put_Line("  2. The LRU algorithm currently uses FIFO logic.");
   Ada.Text_IO.Put_Line("  3. With only 3 frames and this reference string,");
   Ada.Text_IO.Put_Line("     the behavior happens to be identical.");
   Ada.Text_IO.New_Line;
   
   Ada.Text_IO.Put_Line("For a proper comparison, these issues should be fixed.");
   Ada.Text_IO.New_Line;

end Test_Page_Replacement;
