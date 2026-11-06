pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Heap_Sort; use Heap_Sort;
with Own_Checks;
procedure Tests is
   Failures : Natural := 0;

   function Sorted_OK (A : Input_Array) return Boolean is
     (for all I in Index'First .. Index'Last - 1 => A (I) <= A (I + 1));

   --  Core step: the same Heapify that Sort calls (Floyd build, then Sort sifts).
   procedure Check_Layout (A, Expected : Input_Array; Label : String) is
      B : Input_Array := A;
   begin
      Heapify (B);
      if Sorted_OK (Expected) or else Sorted_OK (B) or else B /= Expected
        or else not Is_Max_Heap (B)
      then
         Failures := Failures + 1;
         Put ("  FAIL heapify layout (" & Label & "): got");
         for X of B loop
            Put (X'Image);
         end loop;
         New_Line;
      end if;
   end Check_Layout;

   Input : constant Input_Array := [1 => 23, 2 => 4, 3 => 17, 4 => 9,
                                    5 => 1, 6 => 31, 7 => 12, 8 => 6];
   Ascending : constant Input_Array := [1, 2, 3, 4, 5, 6, 7, 8];
   Own_Failed : Boolean := False;
begin
   if Is_Max_Heap (Ascending) then
      Failures := Failures + 1;
      Put_Line ("  FAIL ascending input was already a max-heap");
   end if;
   Check_Layout (Ascending, [8, 5, 7, 4, 1, 6, 3, 2], "hand ascending");
   Check_Layout ([8, 7, 6, 5, 4, 3, 2, 1], [8, 7, 6, 5, 4, 3, 2, 1], "hand reverse");
   Check_Layout ([4, 1, 3, 2, 8, 5, 7, 6], [8, 6, 7, 4, 1, 5, 3, 2], "hand 4 1 3 2 8 5 7 6");
   Check_Layout ([23, 4, 17, 9, 1, 31, 12, 6], [31, 9, 23, 6, 1, 17, 12, 4], "hand tests example");

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
         Put_Line ("FAIL Heap_Sort:" & Failures'Image);
      else
         Put_Line ("FAIL Heap_Sort");
      end if;
      raise Program_Error with "tests failed";
   end if;
   Put_Line ("PASS Heap_Sort");
end Tests;
