pragma SPARK_Mode (Off);

with Ada.Text_IO;         use Ada.Text_IO;
with PCIe_Transfer_Model; use PCIe_Transfer_Model;

procedure Tests is
   Passes : Natural := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      if not Cond then
         Put_Line ("FAIL: " & Name);
         raise Program_Error with Name;
      end if;
      Passes := Passes + 1;
      Put_Line ("PASS: " & Name);
   end Check;

   M  : Model := Create (Budget_Per_Tick => 512);
   Ok : Boolean;
begin
   Check (Total_Bytes (M) = 0 and then Budget (M) = 512, "create");

   Record_Transfer (M, Size => 64, Alignment => 64, Dir => H2D, Ok => Ok);
   Check (Ok and then Total_H2D (M) = 64 and then Used_This_Tick (M) = 64,
          "aligned H2D");

   Record_Transfer (M, Size => 100, Alignment => 64, Dir => D2H, Ok => Ok);
   Check (not Ok and then Total_D2H (M) = 0, "reject misaligned");

   Record_Transfer (M, Size => 128, Alignment => 64, Dir => D2H, Ok => Ok);
   Check (Ok and then Total_D2H (M) = 128 and then Total_Bytes (M) = 192,
          "aligned D2H");

   --  Budget: 512 - 192 = 320 remaining this tick
   Record_Transfer (M, Size => 384, Alignment => 64, Dir => H2D, Ok => Ok);
   Check (not Ok and then Total_Bytes (M) = 192, "reject over budget");

   Record_Transfer (M, Size => 320, Alignment => 64, Dir => H2D, Ok => Ok);
   Check (Ok and then Used_This_Tick (M) = 512 and then Total_H2D (M) = 384,
          "exact budget fill");

   Record_Transfer (M, Size => 64, Alignment => 64, Dir => H2D, Ok => Ok);
   Check (not Ok, "reject when tick budget exhausted");

   Advance_Tick (M);
   Check (Used_This_Tick (M) = 0 and then Total_Bytes (M) = 512,
          "advance tick clears usage");

   Record_Transfer (M, Size => 64, Alignment => 32, Dir => D2H, Ok => Ok);
   Check (Ok and then Total_D2H (M) = 192, "post-tick transfer");

   Reset (M);
   Check (Total_Bytes (M) = 0 and then Used_This_Tick (M) = 0
            and then Budget (M) = 512,
          "reset");

   Put_Line ("----------------");
   Put_Line ("All tests PASS:" & Passes'Image);
end Tests;
