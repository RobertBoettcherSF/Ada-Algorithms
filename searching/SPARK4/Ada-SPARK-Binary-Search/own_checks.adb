pragma Ada_2022;
--  Own tests for Binary_Search (see tests/SOURCES.txt).
--  Find / Find_First / Find_Last on random sorted arrays (many duplicates) against an own linear scan.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Binary_Search; use Binary_Search;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20261008);
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
   for Run in 1 .. 6000 loop
      declare
         N : constant Natural := Next (0, 30);
         A : Element_Array (1 .. N);
         V : Integer := Next (-20, 0);
         Key : constant Integer := Next (-25, 25);
         First, Last : Natural := 0;
         R : Natural;
      begin
         for I in 1 .. N loop V := V + Next (0, 2); A (I) := V; end loop;
         for I in 1 .. N loop
            if A (I) = Key then
               if First = 0 then First := I; end if;
               Last := I;
            end if;
         end loop;
         R := Find (A, Key);
         Report ((if First = 0 then R = 0 else R in First .. Last), "Find run" & Run'Image & " gave" & R'Image);
         Report (Find_First (A, Key) = First, "Find_First run" & Run'Image);
         Report (Find_Last (A, Key) = Last, "Find_Last run" & Run'Image);
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
