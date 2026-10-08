pragma Ada_2022;
--  Own tests for Validate_Stack_Sequences (see tests/SOURCES.txt).
--  Valid (Pushed, Popped, N): Popped (1 .. N) can be produced by pushing Pushed (1 .. N) in order onto a
--  stack and popping at any time; values distinct (standard statement). Own reference: every
--  interleaving of pushes and pops.
with Ada.Text_IO; use Ada.Text_IO;
with Validate_Stack_Sequences; use Validate_Stack_Sequences;

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
   Pu, Po : Sequence;
   function Reach (N, Pushed_So_Far, Popped_So_Far : Natural; Stack : Sequence; Top : Natural) return Boolean is
      S : Sequence := Stack;
   begin
      if Popped_So_Far = N then return True; end if;
      if Top > 0 and then S (Top) = Po (Popped_So_Far + 1)
        and then Reach (N, Pushed_So_Far, Popped_So_Far + 1, S, Top - 1)
      then
         return True;
      end if;
      if Pushed_So_Far < N then
         S (Top + 1) := Pu (Pushed_So_Far + 1);
         return Reach (N, Pushed_So_Far + 1, Popped_So_Far, S, Top + 1);
      end if;
      return False;
   end Reach;
begin
   for Trial in 1 .. 20_000 loop
      declare
         N : constant Length := Next (0, Capacity);
         Used : array (Value) of Boolean := [others => False];
      begin
         Pu := [others => 0]; Po := [others => 0];
         for I in 1 .. N loop   --  distinct values
            loop
               Pu (I) := Next (0, 9);
               exit when not Used (Pu (I));
            end loop;
            Used (Pu (I)) := True;
         end loop;
         Po := Pu;
         for I in reverse 2 .. N loop   --  random permutation of the pushed values
            declare
               J : constant Positive := Next (1, I);
               T : constant Value := Po (I);
            begin
               Po (I) := Po (J); Po (J) := T;
            end;
         end loop;
         if Trial mod 5 = 0 and then N > 0 then Po (Next (1, N)) := Next (0, 9); end if;   --  maybe a foreign value
         Report (Valid (Pu, Po, N) = Reach (N, 0, 0, [others => 0], 0), "trial" & Integer'Image (Trial));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
