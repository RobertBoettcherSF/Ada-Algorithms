pragma SPARK_Mode (Off);

with Ada.Text_IO;           use Ada.Text_IO;
with Memory_Channel_Model;  use Memory_Channel_Model;

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

   M  : Model := Create;
   Ok : Boolean;
begin
   Check (Bytes_Transferred (M) = 0
            and then Row_Hits (M) = 0
            and then Row_Misses (M) = 0,
          "create");

   Open_Row (M, Channel => 0, Bank => 0, Row => 3);
   Check (Row_Misses (M) = 1 and then Row_Hits (M) = 0, "open miss");

   Open_Row (M, Channel => 0, Bank => 0, Row => 3);
   Check (Row_Hits (M) = 1 and then Row_Misses (M) = 1, "reopen hit");

   Read (M, 0, 0, Target_Row => 3, Size => 16, Ok => Ok);
   Check (Ok and then Bytes_Transferred (M) = 16 and then Row_Hits (M) = 2,
          "read hit");

   Write (M, 0, 0, Target_Row => 5, Size => 32, Ok => Ok);
   Check (Ok and then Bytes_Transferred (M) = 48 and then Row_Misses (M) = 2,
          "write row miss");

   Close (M, 0, 0);
   Read (M, 0, 0, Target_Row => 5, Size => 8, Ok => Ok);
   Check (Ok and then Row_Misses (M) = 3 and then Bytes_Transferred (M) = 56,
          "read after close is miss");

   --  Independent bank
   Open_Row (M, Channel => 1, Bank => 1, Row => 1);
   Check (Row_Misses (M) = 4, "other channel/bank miss");

   Reset (M);
   Check (Bytes_Transferred (M) = 0 and then Row_Hits (M) = 0
            and then Row_Misses (M) = 0,
          "reset");

   Put_Line ("----------------");
   Put_Line ("All tests PASS:" & Passes'Image);
end Tests;
