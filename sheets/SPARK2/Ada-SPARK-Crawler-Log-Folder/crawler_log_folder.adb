pragma Ada_2022;
package body Crawler_Log_Folder with SPARK_Mode => On is
   function Root return Folder_Tracker is begin return (Level => 0); end Root;
   function Current_Depth (F : Folder_Tracker) return Depth is begin return F.Level; end Current_Depth;
   procedure Enter (F : in out Folder_Tracker) is begin if F.Level < Capacity then F.Level := F.Level + 1; end if; end Enter;
   procedure Leave (F : in out Folder_Tracker) is begin if F.Level > 0 then F.Level := F.Level - 1; end if; end Leave;
   function Is_Root (F : Folder_Tracker) return Boolean is begin return F.Level = 0; end Is_Root;
end Crawler_Log_Folder;
