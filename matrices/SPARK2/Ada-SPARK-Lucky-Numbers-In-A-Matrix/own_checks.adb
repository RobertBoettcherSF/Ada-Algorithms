--  Own tests for Lucky_Numbers (see tests/SOURCES.txt).
--  A lucky number is <= every element of its row and >= every element of its column.
--  Found must be True exactly when one exists, and Value must then be one.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Lucky_Numbers; use Lucky_Numbers;

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
   function Is_Lucky (M : Matrix; R, C : Index) return Boolean is
   begin
      for J in Index loop
         if M (R, J) < M (R, C) then return False; end if;
      end loop;
      for I in Index loop
         if M (I, C) > M (R, C) then return False; end if;
      end loop;
      return True;
   end Is_Lucky;

   procedure Check (M : Matrix; Label : String) is
      V : Pixel;
      Found : Boolean;
      Exists, Value_Ok : Boolean := False;
   begin
      Find (M, V, Found);
      for R in Index loop
         for C in Index loop
            if Is_Lucky (M, R, C) then
               Exists := True;
               if M (R, C) = V then Value_Ok := True; end if;
            end if;
         end loop;
      end loop;
      Report (Found = Exists and then (not Found or else Value_Ok), Label);
   end Check;

   M : Matrix;
   Used : array (Pixel) of Boolean;
begin
   --  random matrices of distinct values (at most one lucky number) and of values 0 .. 3
   --  (many ties); every fourth distinct matrix gets a planted lucky number at a random cell
   for Trial in 1 .. 20_000 loop
      if Trial mod 2 = 0 then
         Used := [others => False];
         for R in Index loop
            for C in Index loop
               loop
                  M (R, C) := Next (0, 99);
                  exit when not Used (M (R, C));
               end loop;
               Used (M (R, C)) := True;
            end loop;
         end loop;
         if Trial mod 4 = 0 then
            declare
               R0 : constant Index := Next (1, Side);
               C0 : constant Index := Next (1, Side);
            begin
               --  rows other than R0 get values < 50 in column C0, row R0 values >= 50 elsewhere
               for I in Index loop
                  if I /= R0 then M (I, C0) := Next (0, 9) * 4 + (I - 1); end if;
               end loop;
               for J in Index loop
                  if J /= C0 then M (R0, J) := 60 + Next (0, 9) * 4 + (J - 1); end if;
               end loop;
               M (R0, C0) := 50;
            end;
         end if;
      else
         for R in Index loop
            for C in Index loop
               M (R, C) := Next (0, 3);
            end loop;
         end loop;
      end if;
      Check (M, "random matrix" & Integer'Image (Trial));
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
