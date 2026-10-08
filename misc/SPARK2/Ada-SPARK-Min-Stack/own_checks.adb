pragma Ada_2022;
--  Own tests for Min_Stack (see tests/SOURCES.txt).
--  LIFO model with minimum; operations on a full (Push) or empty (Pop, Top_Value, Min_Value) stack have no
--  answer and must be rejected (silent no-op scan, tools/vv/silent_noop.csv).
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Min_Stack; use Min_Stack;

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
   S : Stack;
   M : array (1 .. Capacity) of Value;
   N : Natural;
begin
   for Run in 1 .. 2_000 loop
      S := Empty; N := 0;
      for Op in 1 .. 40 loop
         if N < Capacity and then (N = 0 or else Next (0, 1) = 0) then
            declare
               V : constant Value := Next (-100, 100);
            begin
               S := Push (S, V); N := N + 1; M (N) := V;
            end;
         else
            S := Pop (S); N := N - 1;
         end if;
         Report (Is_Empty (S) = (N = 0), "Is_Empty run" & Integer'Image (Run));
         if N > 0 then
            declare
               Lo : Integer := M (1);
            begin
               for I in 2 .. N loop Lo := Integer'Min (Lo, M (I)); end loop;
               Report (Top_Value (S) = M (N) and then Min_Value (S) = Lo, "run" & Integer'Image (Run) & " op" & Integer'Image (Op));
            end;
         end if;
      end loop;
   end loop;
   --  no answer: must be rejected
   begin
      declare
         V : constant Value := Top_Value (Empty);
      begin
         Report (False, "Top_Value of an empty stack answered" & Integer'Image (V));
      end;
   exception
      when others => Report (True, "rejected");
   end;
   begin
      declare
         V : constant Value := Min_Value (Empty);
      begin
         Report (False, "Min_Value of an empty stack answered" & Integer'Image (V));
      end;
   exception
      when others => Report (True, "rejected");
   end;
   begin
      S := Pop (Empty);
      Report (False, "Pop of an empty stack accepted");
   exception
      when others => Report (True, "rejected");
   end;
   S := Empty;
   for I in 1 .. Capacity loop S := Push (S, I); end loop;
   begin
      S := Push (S, 99);
      Report (False, "Push on a full stack accepted (value dropped)");
   exception
      when others => Report (True, "rejected");
   end;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
