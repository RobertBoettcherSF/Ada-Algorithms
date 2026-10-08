pragma Ada_2022;
--  Own tests for Linear_Search (see tests/SOURCES.txt).
--  Find, Find_From and Contains against an own scan (from the end backwards, keeping the last match seen).
with Ada.Text_IO; use Ada.Text_IO;
with Linear_Search; use Linear_Search;

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
begin
   for Run in 1 .. 8000 loop
      declare
         N : constant Natural := Next (0, Max_N);
         A : Element_Array (1 .. N);
         Key : constant Integer := Next (-5, 5);
         Start : constant Natural := (if N = 0 then 0 else Next (1, N));
         First, From : Natural := 0;
      begin
         for I in 1 .. N loop
            A (I) := (case Next (0, 9) is when 0 => Integer'First, when 1 => Integer'Last, when others => Next (-4, 4));
         end loop;
         for I in reverse 1 .. N loop   --  own scan, backwards: the last match seen is the first index
            if A (I) = Key then
               First := I;
               if I >= Start then From := I; end if;
            end if;
         end loop;
         Report (Find (A, Key) = First, "Find, run" & Run'Image);
         Report (Contains (A, Key) = (First > 0), "Contains, run" & Run'Image);
         if N = 0 or else Start in A'Range then
            Report (Find_From (A, Key, Start) = From, "Find_From, run" & Run'Image);
         end if;
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
