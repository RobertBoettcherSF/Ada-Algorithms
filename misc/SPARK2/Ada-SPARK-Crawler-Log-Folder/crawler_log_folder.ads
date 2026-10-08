pragma Ada_2022;
package Crawler_Log_Folder with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Depth is Natural range 0 .. Capacity;
   type Folder_Tracker is private;
   function Root return Folder_Tracker with Global => null;
   function Current_Depth (F : Folder_Tracker) return Depth with Global => null;
   procedure Enter (F : in out Folder_Tracker) with Global => null, Pre => Current_Depth (F) < Capacity;
   procedure Leave (F : in out Folder_Tracker) with Global => null, Pre => Current_Depth (F) > 0;
   function Is_Root (F : Folder_Tracker) return Boolean with Global => null;
private
   type Folder_Tracker is record Level : Depth := 0; end record;
end Crawler_Log_Folder;
