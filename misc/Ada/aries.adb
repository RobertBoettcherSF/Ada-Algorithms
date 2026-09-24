-- aries.adb
-- Implementation of the ARIES Algorithm phases: Analysis, Redo, and Undo.
with Ada.Text_IO; use Ada.Text_IO;

package body ARIES is

   -- Internal State
   Log_Buffer : Log_Array;
   Log_Count  : Natural := 0;
   
   -- Volatile Memory (Lost on crash)
   TT  : TT_Array;
   DPT : DPT_Array;
   
   -- Persistent Disk 
   Disk_Pages : Disk_Page_Array;

   -- -------------------------------------------------------------------------
   -- Helper Functions
   -- -------------------------------------------------------------------------
   procedure Write_Log(Rec : in out Log_Record) is
   begin
      if Log_Count < Max_Logs then
         Log_Count := Log_Count + 1;
         Rec.LSN := LSN_Type(Log_Count);
         Log_Buffer(Log_Count) := Rec;
      end if;
   end Write_Log;

   -- -------------------------------------------------------------------------
   -- System Operations
   -- -------------------------------------------------------------------------
   procedure Initialize_System is
   begin
      Log_Count := 0;
      for I in TT'Range loop
         TT(I) := (Status => Active, Last_LSN => Null_LSN, Undo_Next_LSN => Null_LSN);
      end loop;
      for I in DPT'Range loop
         DPT(I) := (Recovery_LSN => Null_LSN, Is_Dirty => False);
         Disk_Pages(I) := Null_LSN;
      end loop;
   end Initialize_System;

   procedure Simulate_Crash is
   begin
      -- Wipes Transaction Table and Dirty Page Table (Volatile Memory)
      for I in TT'Range loop
         TT(I) := (Status => Active, Last_LSN => Null_LSN, Undo_Next_LSN => Null_LSN);
      end loop;
      for I in DPT'Range loop
         DPT(I) := (Recovery_LSN => Null_LSN, Is_Dirty => False);
      end loop;
   end Simulate_Crash;

   -- -------------------------------------------------------------------------
   -- Logging Operations
   -- -------------------------------------------------------------------------
   procedure Log_Update (TX : Transaction_ID; P_ID : Page_ID) is
      Rec : Log_Record;
   begin
      Rec.TX_ID := TX;
      Rec.Page := P_ID;
      Rec.Record_Type := T_Update;
      Rec.Prev_LSN := TT(TX).Last_LSN;
      
      Write_Log(Rec);
      
      -- Update Transaction Table
      TT(TX).Status := Active;
      TT(TX).Last_LSN := Rec.LSN;
      TT(TX).Undo_Next_LSN := Rec.LSN;
      
      -- Update Dirty Page Table
      if not DPT(P_ID).Is_Dirty then
         DPT(P_ID).Is_Dirty := True;
         DPT(P_ID).Recovery_LSN := Rec.LSN;
      end if;
      
      -- Simulate immediately flushing page to disk (Force strategy simulation if needed, but standard is no-force)
      -- ARIES allows pages to hit disk before commit (Steal) and commit without page hitting disk (No-Force)
   end Log_Update;

   procedure Log_Commit (TX : Transaction_ID) is
      Rec : Log_Record;
   begin
      Rec.TX_ID := TX;
      Rec.Record_Type := T_Commit;
      Rec.Prev_LSN := TT(TX).Last_LSN;
      
      Write_Log(Rec);
      TT(TX).Status := Committed;
      TT(TX).Last_LSN := Rec.LSN;
   end Log_Commit;

   -- -------------------------------------------------------------------------
   -- ARIES Phase 1: Analysis
   -- Rebuilds TT and DPT based on WAL.
   -- -------------------------------------------------------------------------
   procedure Analysis_Phase (Redo_LSN : out LSN_Type) is
      Min_Recovery_LSN : LSN_Type := Null_LSN;
   begin
      Redo_LSN := Null_LSN;
      if Log_Count = 0 then
         return;
      end if;

      for I in 1 .. Log_Count loop
         declare
            Rec : Log_Record := Log_Buffer(I);
         begin
            case Rec.Record_Type is
               when T_Update | T_CLR =>
                  -- Update TT
                  TT(Rec.TX_ID).Status := Active;
                  TT(Rec.TX_ID).Last_LSN := Rec.LSN;
                  if Rec.Record_Type = T_Update then
                     TT(Rec.TX_ID).Undo_Next_LSN := Rec.LSN;
                  else
                     TT(Rec.TX_ID).Undo_Next_LSN := Rec.Undo_Next_LSN;
                  end if;

                  -- Update DPT
                  if not DPT(Rec.Page).Is_Dirty then
                     DPT(Rec.Page).Is_Dirty := True;
                     DPT(Rec.Page).Recovery_LSN := Rec.LSN;
                  end if;
                  
               when T_Commit =>
                  TT(Rec.TX_ID).Status := Committed;
                  TT(Rec.TX_ID).Last_LSN := Rec.LSN;
                  
               when T_Abort =>
                  TT(Rec.TX_ID).Status := Aborted;
                  TT(Rec.TX_ID).Last_LSN := Rec.LSN;
                  
               when T_Checkpoint =>
                  null; -- Simplified: assuming start from beginning of log
            end case;
         end;
      end loop;

      -- Calculate Redo_LSN (minimum Recovery_LSN in DPT)
      for I in DPT'Range loop
         if DPT(I).Is_Dirty then
            if Min_Recovery_LSN = Null_LSN or else DPT(I).Recovery_LSN < Min_Recovery_LSN then
               Min_Recovery_LSN := DPT(I).Recovery_LSN;
            end if;
         end if;
      end loop;
      
      Redo_LSN := Min_Recovery_LSN;
   end Analysis_Phase;

   -- -------------------------------------------------------------------------
   -- ARIES Phase 2: Redo
   -- Reapplies updates that did not make it to disk.
   -- -------------------------------------------------------------------------
   procedure Redo_Phase (Redo_LSN : in LSN_Type) is
   begin
      if Redo_LSN = Null_LSN then
         return;
      end if;

      for I in Integer(Redo_LSN) .. Log_Count loop
         declare
            Rec : Log_Record := Log_Buffer(I);
         begin
            if Rec.Record_Type = T_Update or Rec.Record_Type = T_CLR then
               -- 1. Is page in DPT?
               -- 2. Is log LSN >= DPT.Recovery_LSN?
               -- 3. Is log LSN > Disk Page LSN? (The actual disk state)
               if DPT(Rec.Page).Is_Dirty and then
                  Rec.LSN >= DPT(Rec.Page).Recovery_LSN and then
                  Rec.LSN > Disk_Pages(Rec.Page)
               then
                  -- Redo the operation (update disk page LSN)
                  Disk_Pages(Rec.Page) := Rec.LSN;
               end if;
            end if;
         end;
      end loop;
   end Redo_Phase;

   -- -------------------------------------------------------------------------
   -- ARIES Phase 3: Undo
   -- Rolls back uncommitted (active) transactions writing CLRs.
   -- -------------------------------------------------------------------------
   procedure Undo_Phase is
      Max_Undo_LSN : LSN_Type := Null_LSN;
      Target_TX    : Transaction_ID := 1;
      Active_Found : Boolean := True;
   begin
      -- Loop until no active transactions have pending undos
      while Active_Found loop
         Active_Found := False;
         Max_Undo_LSN := Null_LSN;
         
         -- Find the highest Undo_Next_LSN among active transactions
         for I in TT'Range loop
            if TT(I).Status = Active and then TT(I).Undo_Next_LSN /= Null_LSN then
               Active_Found := True;
               if TT(I).Undo_Next_LSN > Max_Undo_LSN then
                  Max_Undo_LSN := TT(I).Undo_Next_LSN;
                  Target_TX := I;
               end if;
            end if;
         end loop;
         
         if Active_Found then
            declare
               Rec_To_Undo : Log_Record := Log_Buffer(Integer(Max_Undo_LSN));
               CLR_Rec     : Log_Record;
            begin
               if Rec_To_Undo.Record_Type = T_Update then
                  -- Write Compensation Log Record (CLR)
                  CLR_Rec.TX_ID := Target_TX;
                  CLR_Rec.Page := Rec_To_Undo.Page;
                  CLR_Rec.Record_Type := T_CLR;
                  CLR_Rec.Prev_LSN := TT(Target_TX).Last_LSN;
                  CLR_Rec.Undo_Next_LSN := Rec_To_Undo.Prev_LSN;
                  Write_Log(CLR_Rec);
                  
                  -- Update TT for this transaction
                  TT(Target_TX).Last_LSN := CLR_Rec.LSN;
                  TT(Target_TX).Undo_Next_LSN := Rec_To_Undo.Prev_LSN;
               else
                  -- If it's not an update, just move pointer back
                  TT(Target_TX).Undo_Next_LSN := Rec_To_Undo.Prev_LSN;
               end if;
               
               -- If we reached the end of the transaction, mark as aborted
               if TT(Target_TX).Undo_Next_LSN = Null_LSN then
                  TT(Target_TX).Status := Aborted;
                  
                  -- Write Abort Log
                  declare
                     Abort_Rec : Log_Record;
                  begin
                     Abort_Rec.TX_ID := Target_TX;
                     Abort_Rec.Record_Type := T_Abort;
                     Abort_Rec.Prev_LSN := TT(Target_TX).Last_LSN;
                     Write_Log(Abort_Rec);
                  end;
               end if;
            end;
         end if;
      end loop;
   end Undo_Phase;

   -- -------------------------------------------------------------------------
   -- Master Recovery Runner
   -- -------------------------------------------------------------------------
   procedure Recover is
      Redo_LSN : LSN_Type;
   begin
      Analysis_Phase(Redo_LSN);
      Redo_Phase(Redo_LSN);
      Undo_Phase;
   end Recover;

   -- -------------------------------------------------------------------------
   -- Accessors for Verification
   -- -------------------------------------------------------------------------
   function Get_Log_Count return Natural is (Log_Count);
   function Get_TT (TX : Transaction_ID) return Transaction_Entry is (TT(TX));
   function Get_DPT (P_ID : Page_ID) return Page_Entry is (DPT(P_ID));
   function Get_Disk_Page_LSN (P_ID : Page_ID) return LSN_Type is (Disk_Pages(P_ID));

end ARIES;
