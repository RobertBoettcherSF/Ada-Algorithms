--  page_replacement.ads
--  
--  This package implements page replacement algorithms for virtual memory management.
--  It simulates how an operating system handles page faults when physical memory
--  (frames) is full and a new page needs to be loaded.
--
--  Author: Robert Boettcher
--  Language: Ada
--

package Page_Replacement is

   --  Page numbers range from 0 to 1000
   --  Represents the virtual page number in a process's address space
   type Page_Number is range 0 .. 1000;

   --  Frame numbers range from 1 to 100
   --  Represents the physical frame in memory where a page can be loaded
   type Frame_Number is range 1 .. 100;

   --  Page count for tracking usage timestamps
   type Page_Count is range 0 .. 10000;

   --  Reference bit states for a page
   --  Used to track whether a page has been accessed (referenced)
   type Reference_Bit is (Unreferenced, Referenced);

   --  Modified (dirty) bit states for a page
   --  Used to track whether a page has been written to (modified)
   type Modified_Bit is (Clean, Dirty);

   --  Combined state of a page including reference and modified bits
   --  These bits are used by various page replacement algorithms
   type Page_State is record
      Ref : Reference_Bit := Unreferenced;
      Modified : Modified_Bit := Clean;
   end record;

   --  Entry in the page table for a single frame
   --  Contains the page number loaded in that frame, its state,
   --  the last time it was used, and whether it's currently in memory
   type Page_Table_Entry is record
      Page : Page_Number;
      State : Page_State;
      Last_Used : Page_Count := 0;
      In_Memory : Boolean := False;
   end record;

   --  The page table - an array of page table entries
   --  Size is determined by the number of physical frames available
   type Page_Table_Type is array (Frame_Number range <>) of Page_Table_Entry;

   --  A sequence of page references (a reference string)
   --  Represents the order in which pages are accessed by a process
   type Reference_String_Type is array (Positive range <>) of Page_Number;

   --  Enumeration of supported page replacement algorithms
   type Algorithm_Type is (
      FIFO,      -- First-In-First-Out: Replace the page that has been in memory longest
      LRU,       -- Least Recently Used: Replace the page that hasn't been used for longest
      Clock,     -- Clock algorithm: Circular list with reference bits
      Optimal,   -- Optimal (Belady's): Replace page that won't be used for longest time
      NRU,       -- Not Recently Used: Uses reference and modified bits
      Random_Alg -- Random: Replace a random page
   );

   --  Statistics collected during simulation
   --  Tracks the number of page faults and page replacements
   type Algorithm_Statistics is record
      Page_Faults : Page_Count := 0;
      Page_Replacements : Page_Count := 0;
   end record;

   --  Initialize the page table with the given number of frames
   --  All entries start as not in memory with page number 0
   --  Parameters:
   --    The_Page_Table - The page table to initialize
   --    Num_Frames - The number of physical frames available
   procedure Initialize (
      The_Page_Table : out Page_Table_Type;
      Num_Frames : Frame_Number
   );

   --  Simulate page replacement for a given reference string and algorithm
   --  Parameters:
   --    The_References - The sequence of page references to process
   --    Num_Frames - The number of physical frames available
   --    Algorithm - The page replacement algorithm to use
   --    Stats - Output parameter containing simulation statistics
   procedure Simulate (
      The_References : Reference_String_Type;
      Num_Frames : Frame_Number;
      Algorithm : Algorithm_Type;
      Stats : out Algorithm_Statistics
   );

   --  Return the name of an algorithm as a string
   --  Parameters:
   --    Alg - The algorithm type
   --  Returns: The name of the algorithm as a string
   function Algorithm_Name (Alg : Algorithm_Type) return String;

end Page_Replacement;
