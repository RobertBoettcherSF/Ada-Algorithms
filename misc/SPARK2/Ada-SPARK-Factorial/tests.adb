with Ada.Text_IO; use Ada.Text_IO;
with Factorial; use Factorial;

procedure Tests is
   procedure Check (N : Input; Want : Result) is
   begin
      if Compute (N) /= Want then
         raise Program_Error with N'Image & "! =" & Compute (N)'Image & ", expected" & Want'Image;
      end if;
   end Check;
begin
   Check (0, 1);
   Check (1, 1);
   Check (5, 120);
   Check (12, 479_001_600);
   --  Beyond the old table (N <= 12), each from the previous one:
   --  13! = 13 * 479_001_600 = 6_227_020_800 (no longer fits Natural);
   --  20! = 2_432_902_008_176_640_000 <= Long_Long_Integer'Last
   --  = 9_223_372_036_854_775_807 < 21! = 51_090_942_171_709_440_000.
   Check (13, 6_227_020_800);
   Check (14, 87_178_291_200);
   Check (19, 121_645_100_408_832_000);
   Check (20, 2_432_902_008_176_640_000);
   Put_Line ("factorial checks passed");
end Tests;
