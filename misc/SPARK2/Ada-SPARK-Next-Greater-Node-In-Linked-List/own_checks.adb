pragma Ada_2022;
--  Own tests for Next_Greater_Node_In_Linked_List (see tests/SOURCES.txt).
--  Next_Greater: Result (I) = first later value strictly greater than A (I) in A (1 .. Length), else -1; positions after Length are -1.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Next_Greater_Node_In_Linked_List; use Next_Greater_Node_In_Linked_List;

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
   A : Values;
begin
   for Run in 1 .. 20_000 loop
      declare
         L : constant Natural := Next (0, 32);
         R : constant Results := [for I in Index => 0];
         Got : Results := R;
         Want : Integer;
         Ok : Boolean := True;
      begin
         for I in Index loop A (I) := Next (0, Next (0, 32)); end loop;
         Got := Next_Greater (A, L);
         for I in Index loop
            Want := -1;
            if I <= L then
               for J in reverse I + 1 .. L loop   --  last overwrite = first greater
                  if A (J) > A (I) then Want := A (J); end if;
               end loop;
            end if;
            Ok := Ok and then Got (I) = Want;
         end loop;
         Report (Ok, "run" & Integer'Image (Run));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
