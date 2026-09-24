with Ada.Assertions; use Ada.Assertions;
with Crawler_Log_Folder; use Crawler_Log_Folder;
procedure Tests is F : Folder_Tracker := Root;
begin Enter (F); Enter (F); Assert (Current_Depth (F) = 2); Leave (F); Leave (F); Assert (Is_Root (F)); end Tests;
