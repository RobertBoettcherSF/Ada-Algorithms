with Ada.Containers.Doubly_Linked_Lists;
with Ada.Containers.Vectors;

package Clock_Algorithms is

   type Page_ID is new Integer;

   -- Maximum capacity for all algorithms
   Max_Pages : constant Natural := 1000;

   -- Abstract base type for all page replacement algorithms
   type Base_Algorithm is abstract tagged record
      Capacity    : Natural;
      Page_Faults : Natural := 0;
      Accesses    : Natural := 0;
   end record;

   -- Unified interface to process a memory access
   procedure Access_Page (Algo : in out Base_Algorithm; Page : Page_ID) is abstract;
   function Get_Page_Faults (Algo : Base_Algorithm) return Natural;
   function Get_Hit_Rate (Algo : Base_Algorithm) return Float;


   -- ========================================================
   -- 1. Standard Clock (Second-Chance)
   -- ========================================================
   type Clock_Entry is record
      Page : Page_ID;
      Ref  : Boolean;
   end record;

   type Clock_Frames is array (1 .. Max_Pages) of Clock_Entry;

   type Clock_Algo is new Base_Algorithm with record
      Frames : Clock_Frames;
      Hand   : Natural := 1;
      Count  : Natural := 0;
   end record;
   
   procedure Access_Page (Algo : in out Clock_Algo; Page : Page_ID);
   function Init_Clock (Capacity : Natural) return Clock_Algo;


   -- ========================================================
   -- 2. GCLOCK (Generalized Clock)
   -- ========================================================
   -- Uses a counter rather than a single boolean reference bit.
   type GClock_Entry is record
      Page  : Page_ID;
      Count : Natural;
   end record;

   type GClock_Frames is array (1 .. Max_Pages) of GClock_Entry;

   type GCLOCK_Algo is new Base_Algorithm with record
      Frames    : GClock_Frames;
      Hand      : Natural := 1;
      Count     : Natural := 0;
      Max_Count : Natural := 2;
   end record;
   
   procedure Access_Page (Algo : in out GCLOCK_Algo; Page : Page_ID);
   function Init_GCLOCK (Capacity : Natural; Max_Count : Natural := 2) return GCLOCK_Algo;


   -- ========================================================
   -- 3. WSClock (Working Set Clock)
   -- ========================================================
   -- Adds virtual time and an aging parameter (Tau) to Clock.
   type WSClock_Entry is record
      Page        : Page_ID;
      Ref         : Boolean;
      Last_Access : Natural;
   end record;

   type WSClock_Frames is array (1 .. Max_Pages) of WSClock_Entry;

   type WSClock_Algo is new Base_Algorithm with record
      Frames : WSClock_Frames;
      Hand   : Natural := 1;
      Count  : Natural := 0;
      Tau    : Natural := 10;
      Time   : Natural := 0;
   end record;
   
   procedure Access_Page (Algo : in out WSClock_Algo; Page : Page_ID);
   function Init_WSClock (Capacity : Natural; Tau : Natural := 10) return WSClock_Algo;


   -- ========================================================
   -- 4. CAR (Clock with Adaptive Replacement)
   -- ========================================================
   -- Uses two lists/clocks (T1, T2) and two history caches (B1, B2).
   package Page_Vectors is new Ada.Containers.Vectors 
     (Index_Type => Natural, Element_Type => Page_ID);
     
   type CAR_Entry is record
      Page : Page_ID;
      Ref  : Boolean;
   end record;
   package CAR_Vectors is new Ada.Containers.Vectors 
     (Index_Type => Natural, Element_Type => CAR_Entry);

   type CAR_Algo is new Base_Algorithm with record
      P  : Integer := 0; -- Adaptive target size for T1
      T1 : CAR_Vectors.Vector;
      T2 : CAR_Vectors.Vector;
      B1 : Page_Vectors.Vector;
      B2 : Page_Vectors.Vector;
   end record;
   
   procedure Access_Page (Algo : in out CAR_Algo; Page : Page_ID);
   function Init_CAR (Capacity : Natural) return CAR_Algo;


   -- ========================================================
   -- 5. Clock-Pro
   -- ========================================================
   -- Maintains a single circular list divided into Hot, Cold, and Test pages.
   type Page_Type is (Hot, Cold, Test);
   type Clock_Pro_Entry is record
      Page : Page_ID;
      PT   : Page_Type;
      Ref  : Boolean;
   end record;

   package Clock_Pro_Lists is new Ada.Containers.Doubly_Linked_Lists 
     (Element_Type => Clock_Pro_Entry);

   type Clock_Pro_Algo is new Base_Algorithm with record
      L              : Clock_Pro_Lists.List;
      Hand_Hot       : Clock_Pro_Lists.Cursor := Clock_Pro_Lists.No_Element;
      Hand_Cold      : Clock_Pro_Lists.Cursor := Clock_Pro_Lists.No_Element;
      Hand_Test      : Clock_Pro_Lists.Cursor := Clock_Pro_Lists.No_Element;
      M              : Natural := 0; -- Target number of hot pages
      Hot_Count      : Natural := 0;
      Resident_Count : Natural := 0;
   end record;
   
   procedure Access_Page (Algo : in out Clock_Pro_Algo; Page : Page_ID);
   function Init_Clock_Pro (Capacity : Natural) return Clock_Pro_Algo;

end Clock_Algorithms;
