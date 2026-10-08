pragma Ada_2022;
--  Own tests for Queue_Using_Stacks (see tests/SOURCES.txt).
--  FIFO model; operations on a full (Enqueue) or empty (Dequeue, Front) queue have no answer and must
--  be rejected rather than silently ignored.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Queue_Using_Stacks; use Queue_Using_Stacks;

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
   Q : Queue;
   Model : array (1 .. 100_000) of Value := [others => 0];
   Front_I, Back : Positive := 1;
begin
   for Run in 1 .. 500 loop
      Q := Empty; Front_I := 1; Back := 1;
      for Op in 1 .. 60 loop
         declare
            Size : constant Natural := Back - Front_I;
         begin
            Report (Q.Size = Size, "size");
            if Size > 0 then Report (Front (Q) = Model (Front_I), "front"); end if;
            if Size < Capacity and then (Size = 0 or else Next (0, 1) = 0) then
               declare
                  V : constant Value := Next (-100, 100);
               begin
                  Q := Enqueue (Q, V); Model (Back) := V; Back := Back + 1;
               end;
            else
               Q := Dequeue (Q); Front_I := Front_I + 1;
            end if;
         end;
      end loop;
   end loop;
   --  no answer: must be rejected
   Q := Empty;
   begin
      declare
         V : constant Value := Front (Q);
      begin
         Report (False, "Front of an empty queue answered" & Integer'Image (V));
      end;
   exception
      when others => Report (True, "rejected");
   end;
   begin
      Q := Dequeue (Empty);
      Report (False, "Dequeue of an empty queue accepted");
   exception
      when others => Report (True, "rejected");
   end;
   Q := Empty;
   for I in 1 .. Capacity loop Q := Enqueue (Q, I); end loop;
   begin
      Q := Enqueue (Q, 99);
      Report (False, "Enqueue on a full queue accepted (value dropped)");
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
