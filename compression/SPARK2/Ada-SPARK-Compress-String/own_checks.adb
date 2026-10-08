--  Own tests for Compress_String (see tests/SOURCES.txt).
--  Compressed_Length = length of the run-length form "character, decimal count" for every run.
with Ada.Text_IO; use Ada.Text_IO;
with Compress_String; use Compress_String;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   function Reference (T : Text) return Natural is
      Total : Natural := 0;
      I : Index'Base := T'First;
   begin
      while I <= T'Last loop
         declare
            J : Index'Base := I;
         begin
            while J + 1 <= T'Last and then T (J + 1) = T (I) loop
               J := J + 1;
            end loop;
            Total := Total + 1 + Integer'Image (J - I + 1)'Length - 1;   --  character + digits
            I := J + 1;
         end;
      end loop;
      return Total;
   end Reference;

   T : Text;
begin
   --  exhaustive over {a, b} (256 strings) and {a, b, c} (6,561 strings)
   for Letters in 2 .. 3 loop
      declare
         Digit : array (Index) of Natural := [others => 0];
         Done : Boolean := False;
      begin
         while not Done loop
            for I in Index loop
               T (I) := Character'Val (Character'Pos ('a') + Digit (I));
            end loop;
            Report (Compressed_Length (T) = Reference (T), "string " & String (T));
            Done := True;
            for I in Index loop
               if Digit (I) < Letters - 1 then
                  Digit (I) := Digit (I) + 1; Done := False; exit;
               else
                  Digit (I) := 0;
               end if;
            end loop;
         end loop;
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
