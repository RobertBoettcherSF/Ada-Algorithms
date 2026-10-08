pragma Ada_2022;
--  Own tests for Design_Underground_System_Lite (see tests/SOURCES.txt).
--  Average_Travel_Time: integer (floor) mean duration of the first Length trips from From to To; 0 if none.
with Ada.Text_IO; use Ada.Text_IO;
with Design_Underground_System_Lite; use Design_Underground_System_Lite;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   Seed : Long_Long_Integer := 20261008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   T : Trip_Array;
begin
   for Run in 1 .. 20_000 loop
      declare
         L : constant Natural := Next (0, 32);
         F : constant Natural := Next (0, 3);
         To : constant Natural := Next (0, 3);
         Sum, Cnt : Natural := 0;
      begin
         for I in T'Range loop
            T (I) := (From_Station => Next (0, 3), To_Station => Next (0, 3),
                      Duration => (if Next (0, 9) = 0 then 100_000 else Next (0, 1_000)));
            if I <= L and then T (I).From_Station = F and then T (I).To_Station = To then
               Sum := Sum + T (I).Duration; Cnt := Cnt + 1;
            end if;
         end loop;
         Report (Average_Travel_Time (T, L, F, To) = (if Cnt = 0 then 0 else Sum / Cnt), "run" & Integer'Image (Run));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
