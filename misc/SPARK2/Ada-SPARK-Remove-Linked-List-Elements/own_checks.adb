pragma Ada_2022;
--  Own tests for Remove_Linked_List_Elements (see tests/SOURCES.txt).
--  Random Append / Remove_First sequences against an own reference model (a plain array with an
--  explicit length): Remove_First deletes the first occurrence of V and shifts the rest left, and leaves the
--  list unchanged when V is absent.
with Ada.Text_IO; use Ada.Text_IO;
with Remove_Linked_List_Elements; use Remove_Linked_List_Elements;

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
   type Model is array (1 .. 16) of Integer;
begin
   for Run in 1 .. 4000 loop
      declare
         L : List := Empty;
         M : Model := [others => 0];
         N : Natural := 0;
      begin
         for Step in 1 .. 60 loop
            declare
               V : constant Value := (case Next (0, 9) is when 0 => -100, when 1 => 100, when others => Next (-3, 3));
            begin
               if N < 16 and then (N = 0 or else Next (0, 1) = 0) then
                  Append (L, V);
                  N := N + 1; M (N) := V;
               else
                  declare
                     W : Natural := 0;
                  begin
                     for I in 1 .. N loop
                        if M (I) = V then W := I; exit; end if;
                     end loop;
                     Remove_First (L, V);
                     if W > 0 then
                        for I in W .. N - 1 loop M (I) := M (I + 1); end loop;
                        N := N - 1;
                     end if;
                  end;
               end if;
               declare
                  Same : Boolean := Length (L) = N;
               begin
                  if Same then
                     for I in 1 .. N loop
                        Same := Same and then Element (L, I) = M (I);
                     end loop;
                  end if;
                  Report (Same, "run" & Run'Image & " step" & Step'Image);
               end;
            end;
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
