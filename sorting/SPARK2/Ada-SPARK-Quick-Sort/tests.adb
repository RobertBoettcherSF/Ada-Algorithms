pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Quick_Sort; use Quick_Sort;
with Own_Checks;
procedure Tests is
   Failures : Natural := 0;

   --  Core step: the same Partition_Range that Sort_Range calls.
   procedure Check_Layout
     (A : Input_Array; Expected : Input_Array; Expected_Pivot : Index; Label : String)
   is
      B : Input_Array := A;
      P : Index;
   begin
      Partition_Range (B, Index'First, Index'Last, P);
      if B /= Expected or else P /= Expected_Pivot then
         Failures := Failures + 1;
         Put ("  FAIL partition layout (" & Label & "): got");
         for X of B loop
            Put (X'Image);
         end loop;
         Put (" pivot" & P'Image);
         New_Line;
      end if;
   end Check_Layout;

   procedure Check_Split (A : Input_Array) is
      B : Input_Array := A;
      P : Index;
      Ok : Boolean := True;
   begin
      Partition_Range (B, Index'First, Index'Last, P);
      if B (P) /= A (Index'Last) then
         Ok := False;
      end if;
      for I in Index loop
         if I < P and then B (I) > B (P) then
            Ok := False;
         end if;
         if I > P and then B (I) < B (P) then
            Ok := False;
         end if;
      end loop;
      if not Ok then
         Failures := Failures + 1;
         Put_Line ("  FAIL partition split");
      end if;
   end Check_Split;

   Input : constant Input_Array := [1 => 23, 2 => 4, 3 => 17, 4 => 9,
                                    5 => 1, 6 => 31, 7 => 12, 8 => 6];
   Own_Failed : Boolean := False;
begin
   Check_Layout ([4, 1, 3, 2, 8, 5, 7, 6], [4, 1, 3, 2, 5, 6, 7, 8], 6, "hand 4 1 3 2 8 5 7 6");
   Check_Layout ([8, 7, 6, 5, 4, 3, 2, 1], [1, 7, 6, 5, 4, 3, 2, 8], 1, "hand reverse");
   Check_Layout ([23, 4, 17, 9, 1, 31, 12, 6], [4, 1, 6, 9, 23, 31, 12, 17], 3, "hand tests example");
   Check_Split ([23, 4, 17, 9, 1, 31, 12, 6]);

   declare
      Result : constant Input_Array := Sort (Input);
   begin
      for I in Index loop
         if I < Index'Last and then Result (I) > Result (I + 1) then
            Failures := Failures + 1;
            Put_Line ("  FAIL Sort example is not sorted");
            exit;
         end if;
      end loop;
   end;

   begin
      Own_Checks;
   exception
      when Program_Error =>
         Own_Failed := True;
   end;

   if Failures > 0 or else Own_Failed then
      if Failures > 0 then
         Put_Line ("FAIL Quick_Sort:" & Failures'Image);
      else
         Put_Line ("FAIL Quick_Sort");
      end if;
      raise Program_Error with "tests failed";
   end if;
   Put_Line ("PASS Quick_Sort");
end Tests;
