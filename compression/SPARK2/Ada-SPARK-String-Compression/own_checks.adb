--  Own tests for String_Compression (see tests/SOURCES.txt).
--  Expanding the runs must give the input back, with maximal runs and counts >= 1.
pragma Ada_2022;
with Ada.Text_IO;
with String_Compression; use String_Compression;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   Seed : Long_Long_Integer := 20_261_008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   X, O : Text;
   Cn : Run_Counts;
   N, OL : Length_Type;
   Ok : Boolean;
begin
   for Iter in 1 .. 5_000 loop
      N := Next (0, 32);
      X := [others => '#'];
      for I in 1 .. N loop
         X (I) := Character'Val (Character'Pos ('a') + Next (0, (if Iter mod 2 = 0 then 1 else 3)));
      end loop;
      Compress (X, N, O, Cn, OL);
      Ok := (OL = 0) = (N = 0);
      declare
         P : Natural := 0;
      begin
         for R in 1 .. OL loop
            if Cn (R) = 0 or else (R > 1 and then O (R) = O (R - 1)) then
               Ok := False;
            end if;
            for K in 1 .. Cn (R) loop
               P := P + 1;
               if P > N or else X (P) /= O (R) then
                  Ok := False;
                  exit;
               end if;
            end loop;
            exit when not Ok;
         end loop;
         if P /= N then Ok := False; end if;
      end;
      Report (Ok, "random" & Iter'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (round trip, maximal runs)");
end Own_Checks;
