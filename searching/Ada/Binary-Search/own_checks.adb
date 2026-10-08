pragma Ada_2022;
--  Own tests for Binary_Search (see tests/SOURCES.txt).
--  Find returns an index holding Key, or A'First - 1 when Key is absent (spec); Find_First /
--  Find_Last return the leftmost / rightmost such index. Own reference: linear scan.
with Ada.Text_IO; use Ada.Text_IO;
with Binary_Search; use Binary_Search;

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
   for Run in 1 .. 20000 loop
      declare
         First : constant Natural := Next (1, 5);
         A : Element_Array (First .. First + Next (0, 30) - 1);
         Key : constant Integer := Next (-12, 12);
         V : Integer := Next (-10, 0);
         L, R : Integer := A'First - 1;
         F, FF, FL : Integer;
      begin
         for X of A loop V := V + Next (0, 2); X := V; end loop;   --  sorted, with duplicates
         for I in A'Range loop
            if A (I) = Key then
               if L = A'First - 1 then L := I; end if;
               R := I;
            end if;
         end loop;
         F := Find (A, Key); FF := Find_First (A, Key); FL := Find_Last (A, Key);
         Report ((if L = A'First - 1 then F = A'First - 1 else F in A'Range and then A (F) = Key)
                 and then FF = L and then FL = R, "run" & Integer'Image (Run));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
