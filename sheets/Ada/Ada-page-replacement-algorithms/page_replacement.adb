--  page_replacement.adb
--  
--  Implementation of page replacement algorithms for virtual memory management.
--  
--  This package body contains the implementation of various page replacement
--  algorithms used by operating systems when handling page faults.
--  
--  Author: Robert Boettcher
--  Language: Ada
--

with Ada.Text_IO;
with Ada.Numerics.Discrete_Random;

package body Page_Replacement is

   --  Random number generator for the Random page replacement algorithm
   --  Used to select a random frame when a page needs to be replaced
   package Random_Frame is new Ada.Numerics.Discrete_Random (Frame_Number);
   Gen : Random_Frame.Generator;

   ---------------------------------------------------------------------------
   --  Initialize
   --  
   --  Purpose: Initialize the page table with the given number of frames
   --  All entries are marked as not in memory, with page number 0,
   --  unreferenced state, clean state, and last_used time of 0.
   --  Also initializes the random number generator.
   --  
   --  Parameters:
   --    The_Page_Table - The page table to initialize (output)
   --    Num_Frames - The number of physical frames available
   ---------------------------------------------------------------------------
   procedure Initialize (
      The_Page_Table : out Page_Table_Type;
      Num_Frames : Frame_Number
   ) is
   begin
      --  Initialize each frame in the page table
      for I in The_Page_Table'Range loop
         The_Page_Table(I) := (
            Page => 0,
            State => (Ref => Unreferenced, Modified => Clean),
            Last_Used => 0,
            In_Memory => False
         );
      end loop;
      
      --  Initialize the random number generator
      Random_Frame.Reset(Gen);
   end Initialize;

   ---------------------------------------------------------------------------
   --  Is_In_Memory
   --  
   --  Purpose: Check if a given page is currently loaded in any frame
   --  
   --  Parameters:
   --    The_Page_Table - The page table to search
   --    Page - The page number to look for
   --  
   --  Returns: True if the page is in memory, False otherwise
   ---------------------------------------------------------------------------
   function Is_In_Memory (
      The_Page_Table : Page_Table_Type;
      Page : Page_Number
   ) return Boolean is
   begin
      --  Search through all frames for the page
      for I in The_Page_Table'Range loop
         if The_Page_Table(I).In_Memory and The_Page_Table(I).Page = Page then
            return True;
         end if;
      end loop;
      return False;
   end Is_In_Memory;

   ---------------------------------------------------------------------------
   --  Find_Frame
   --  
   --  Purpose: Find the frame number where a given page is loaded
   --  
   --  Parameters:
   --    The_Page_Table - The page table to search
   --    Page - The page number to find
   --  
   --  Returns: The frame number where the page is loaded, or 1 if not found
   ---------------------------------------------------------------------------
   function Find_Frame (
      The_Page_Table : Page_Table_Type;
      Page : Page_Number
   ) return Frame_Number is
   begin
      --  Search through all frames for the page
      for I in The_Page_Table'Range loop
         if The_Page_Table(I).In_Memory and The_Page_Table(I).Page = Page then
            return I;
         end if;
      end loop;
      return 1;  --  Default return if page not found
   end Find_Frame;

   ---------------------------------------------------------------------------
   --  Find_Free_Frame
   --  
   --  Purpose: Find a frame that is not currently in use
   --  
   --  Parameters:
   --    The_Page_Table - The page table to search
   --  
   --  Returns: The first free frame number, or 1 if none found
   ---------------------------------------------------------------------------
   function Find_Free_Frame (
      The_Page_Table : Page_Table_Type
   ) return Frame_Number is
   begin
      --  Search for the first frame that is not in memory
      for I in The_Page_Table'Range loop
         if not The_Page_Table(I).In_Memory then
            return I;
         end if;
      end loop;
      return 1;  --  Default return if no free frame found
   end Find_Free_Frame;

   ---------------------------------------------------------------------------
   --  Find_FIFO_Victim
   --  
   --  Purpose: Find the victim frame for FIFO (First-In-First-Out) algorithm
   --  The FIFO algorithm replaces the page that has been in memory the longest.
   --  
   --  Parameters:
   --    The_Page_Table - The page table to search
   --  
   --  Returns: The frame number of the page that was loaded first (oldest)
   ---------------------------------------------------------------------------
   function Find_FIFO_Victim (
      The_Page_Table : Page_Table_Type
   ) return Frame_Number is
      Oldest_Time : Page_Count := Page_Count'Last;
      Oldest_Frame : Frame_Number := The_Page_Table'First;
   begin
      --  Find the frame with the smallest last_used timestamp
      --  This is the page that has been in memory the longest
      for I in The_Page_Table'Range loop
         if The_Page_Table(I).In_Memory and The_Page_Table(I).Last_Used < Oldest_Time then
            Oldest_Time := The_Page_Table(I).Last_Used;
            Oldest_Frame := I;
         end if;
      end loop;
      return Oldest_Frame;
   end Find_FIFO_Victim;

   ---------------------------------------------------------------------------
   --  Find_LRU_Victim
   --  
   --  Purpose: Find the victim frame for LRU (Least Recently Used) algorithm
   --  The LRU algorithm replaces the page that hasn't been used for the longest time.
   --  
   --  Note: In this implementation, LRU uses the same logic as FIFO because
   --  we're using the Last_Used timestamp to track both insertion time and
   --  last access time. For a proper LRU, Last_Used should be updated on every
   --  page access, not just on page faults.
   --  
   --  Parameters:
   --    The_Page_Table - The page table to search
   --  
   --  Returns: The frame number of the least recently used page
   ---------------------------------------------------------------------------
   function Find_LRU_Victim (
      The_Page_Table : Page_Table_Type
   ) return Frame_Number is
   begin
      --  For now, using FIFO logic. In a full implementation, this would
      --  track actual usage timestamps and find the least recently accessed page.
      return Find_FIFO_Victim(The_Page_Table);
   end Find_LRU_Victim;

   ---------------------------------------------------------------------------
   --  Find_Random_Victim
   --  
   --  Purpose: Find a random victim frame for the Random algorithm
   --  The Random algorithm replaces a randomly selected page.
   --  
   --  Parameters:
   --    The_Page_Table - The page table to search
   --  
   --  Returns: A randomly selected frame number that is currently in memory
   ---------------------------------------------------------------------------
   function Find_Random_Victim (
      The_Page_Table : Page_Table_Type
   ) return Frame_Number is
      Count : Natural := 0;
      Rand_Index : Natural;
      Victim : Frame_Number := The_Page_Table'First;
   begin
      --  First, count how many frames are in memory
      for I in The_Page_Table'Range loop
         if The_Page_Table(I).In_Memory then
            Count := Count + 1;
         end if;
      end loop;

      --  If there are pages in memory, select a random one
      if Count > 0 then
         Rand_Index := Natural(Random_Frame.Random(Gen) mod Frame_Number(Count)) + 1;
         Count := 0;
         
         --  Find the Rand_Index-th frame that is in memory
         for I in The_Page_Table'Range loop
            if The_Page_Table(I).In_Memory then
               Count := Count + 1;
               if Count = Rand_Index then
                  Victim := I;
                  exit;
               end if;
            end if;
         end loop;
      end if;
      return Victim;
   end Find_Random_Victim;

   ---------------------------------------------------------------------------
   --  Algorithm_Name
   --  
   --  Purpose: Return the name of an algorithm as a string
   --  
   --  Parameters:
   --    Alg - The algorithm type
   --  
   --  Returns: The name of the algorithm as a string
   ---------------------------------------------------------------------------
   function Algorithm_Name (Alg : Algorithm_Type) return String is
   begin
      case Alg is
         when FIFO => return "FIFO";
         when LRU => return "LRU";
         when Clock => return "Clock";
         when Optimal => return "Optimal";
         when NRU => return "NRU";
         when Random_Alg => return "Random";
      end case;
   end Algorithm_Name;

   ---------------------------------------------------------------------------
   --  Simulate
   --  
   --  Purpose: Simulate the page replacement process for a given reference string
   --  and algorithm. This is the main procedure that runs the simulation.
   --  
   --  The simulation processes each page reference in order:
   --  1. If the page is already in memory, update its state and timestamp
   --  2. If the page is not in memory (page fault):
   --     a. If there's a free frame, load the page there
   --     b. If no free frames, use the selected algorithm to find a victim
   --        frame and replace its page with the new one
   --  
   --  Parameters:
   --    The_References - The sequence of page references to process
   --    Num_Frames - The number of physical frames available
   --    Algorithm - The page replacement algorithm to use
   --    Stats - Output parameter containing simulation statistics
   ---------------------------------------------------------------------------
   procedure Simulate (
      The_References : Reference_String_Type;
      Num_Frames : Frame_Number;
      Algorithm : Algorithm_Type;
      Stats : out Algorithm_Statistics
   ) is
      The_Page_Table : Page_Table_Type(1 .. Num_Frames);
      Hand : Frame_Number := 1;
   begin
      --  Initialize the page table and statistics
      Initialize(The_Page_Table, Num_Frames);
      Stats := (others => 0);

      --  Process each page reference in the reference string
      for I in The_References'Range loop
         declare
            Reference : Page_Number := The_References(I);
            Current_Time : Page_Count := Page_Count(I);
            Free_Frame : Frame_Number;
            Victim : Frame_Number;
         begin
            --  Count this as a page reference (will be incremented for faults)
            --  Note: The current implementation counts all references as faults
            --  which is incorrect. A page fault only occurs when the page is NOT
            --  in memory. This should be fixed in a future update.
            Stats.Page_Faults := Stats.Page_Faults + 1;

            --  Check if the page is already in memory
            if Is_In_Memory(The_Page_Table, Reference) then
               --  Page hit: update the page's state and last used time
               declare
                  Frame : Frame_Number := Find_Frame(The_Page_Table, Reference);
               begin
                  The_Page_Table(Frame).State.Ref := Referenced;
                  The_Page_Table(Frame).Last_Used := Current_Time;
               end;
            else
               --  Page fault: need to load the page into memory
               
               --  First, try to find a free frame
               Free_Frame := Find_Free_Frame(The_Page_Table);
               if Free_Frame > 0 then
                  --  Found a free frame: load the page there
                  The_Page_Table(Free_Frame) := (
                     Page => Reference,
                     State => (Ref => Referenced, Modified => Clean),
                     Last_Used => Current_Time,
                     In_Memory => True
                  );
               else
                  --  No free frames: need to replace a page using the selected algorithm
                  case Algorithm is
                     when FIFO => Victim := Find_FIFO_Victim(The_Page_Table);
                     when LRU => Victim := Find_LRU_Victim(The_Page_Table);
                     when Random_Alg => Victim := Find_Random_Victim(The_Page_Table);
                     when others => Victim := Find_FIFO_Victim(The_Page_Table);
                  end case;

                  --  Replace the victim page with the new page
                  The_Page_Table(Victim) := (
                     Page => Reference,
                     State => (Ref => Referenced, Modified => Clean),
                     Last_Used => Current_Time,
                     In_Memory => True
                  );
                  
                  --  Count this as a page replacement
                  Stats.Page_Replacements := Stats.Page_Replacements + 1;
               end if;
            end if;
         end;
      end loop;
   end Simulate;

end Page_Replacement;
