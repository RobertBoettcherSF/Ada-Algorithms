-- aries.ads
-- Specification for ARIES Recovery Algorithm
-- Includes strictly typed definitions for LSN, Transactions, and Logging mechanisms.

package ARIES is

   -- -------------------------------------------------------------------------
   -- Type Definitions (Strong Typing)
   -- -------------------------------------------------------------------------
   type LSN_Type is new Natural;
   Null_LSN : constant LSN_Type := 0;

   type Transaction_ID is new Positive;
   type Page_ID is new Positive;

   type Log_Record_Type is (T_Update, T_Commit, T_Abort, T_CLR, T_Checkpoint);
   
   type Transaction_Status is (Active, Committed, Aborted);

   -- Represents a single entry in the Write-Ahead Log (WAL)
   type Log_Record is record
      LSN           : LSN_Type := Null_LSN;
      Prev_LSN      : LSN_Type := Null_LSN;
      Undo_Next_LSN : LSN_Type := Null_LSN; -- Used by CLR to track next undo target
      TX_ID         : Transaction_ID := 1;
      Record_Type   : Log_Record_Type := T_Update;
      Page          : Page_ID := 1;
   end record;

   -- -------------------------------------------------------------------------
   -- Data Structures (Mocked Database State)
   -- -------------------------------------------------------------------------
   Max_Logs         : constant := 1000;
   Max_Transactions : constant := 100;
   Max_Pages        : constant := 100;

   type Log_Array is array (1 .. Max_Logs) of Log_Record;
   
   type Transaction_Entry is record
      Status        : Transaction_Status := Active;
      Last_LSN      : LSN_Type := Null_LSN;
      Undo_Next_LSN : LSN_Type := Null_LSN;
   end record;
   type TT_Array is array (Transaction_ID range 1 .. Max_Transactions) of Transaction_Entry;
   
   type Page_Entry is record
      Recovery_LSN  : LSN_Type := Null_LSN;
      Is_Dirty      : Boolean := False;
   end record;
   type DPT_Array is array (Page_ID range 1 .. Max_Pages) of Page_Entry;

   -- Disk pages simulate persistent storage containing the PageLSN
   type Disk_Page_Array is array (Page_ID range 1 .. Max_Pages) of LSN_Type;

   -- -------------------------------------------------------------------------
   -- Core Subprograms
   -- -------------------------------------------------------------------------
   
   -- System Operations
   procedure Initialize_System;
   procedure Simulate_Crash;
   
   -- Logging Operations (Normal Execution)
   procedure Log_Update (TX : Transaction_ID; P_ID : Page_ID);
   procedure Log_Commit (TX : Transaction_ID);
   
   -- Recovery Phases (ARIES Variants)
   procedure Analysis_Phase (Redo_LSN : out LSN_Type);
   procedure Redo_Phase (Redo_LSN : in LSN_Type);
   procedure Undo_Phase;
   
   -- Master Recovery Subprogram
   procedure Recover;

   -- -------------------------------------------------------------------------
   -- Public accessors strictly for verification in tests
   -- -------------------------------------------------------------------------
   function Get_Log_Count return Natural;
   function Get_TT (TX : Transaction_ID) return Transaction_Entry;
   function Get_DPT (P_ID : Page_ID) return Page_Entry;
   function Get_Disk_Page_LSN (P_ID : Page_ID) return LSN_Type;

end ARIES;
