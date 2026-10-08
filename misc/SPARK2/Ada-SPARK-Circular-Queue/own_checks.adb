--  Own tests for Circular_Queue (see tests/SOURCES.txt).
--  Model-based: random Enqueue / Dequeue / Peek sequences against an own FIFO model.
with Ada.Text_IO; use Ada.Text_IO;
with Circular_Queue; use Circular_Queue;

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
   Q : Queue;
   Model : array (1 .. 100_000) of Integer := [others => 0];
   Front, Back : Positive := 1;   --  model holds Model (Front .. Back - 1)
begin
   for Run in 1 .. 500 loop
      Initialize (Q);
      Front := 1; Back := 1;
      for Op in 1 .. 100 loop
         declare
            Size : constant Natural := Back - Front;
         begin
            Report (Length (Q) = Size and then Is_Empty (Q) = (Size = 0) and then Is_Full (Q) = (Size = Capacity), "state");
            if Size > 0 then Report (Peek (Q) = Model (Front), "peek"); end if;
            if Size < Capacity and then (Size = 0 or else Next (0, 1) = 0) then
               declare
                  V : constant Integer := Next (-1000, 1000);
               begin
                  Enqueue (Q, V); Model (Back) := V; Back := Back + 1;
               end;
            elsif Size > 0 then
               declare
                  V : Integer;
               begin
                  Dequeue (Q, V);
                  Report (V = Model (Front), "dequeue order");
                  Front := Front + 1;
               end;
            end if;
         end;
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
