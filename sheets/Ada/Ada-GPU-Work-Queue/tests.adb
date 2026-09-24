pragma SPARK_Mode (Off);

with Ada.Text_IO;    use Ada.Text_IO;
with GPU_Work_Queue; use GPU_Work_Queue;

procedure Tests is
   Passes : Natural := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      if not Cond then
         Put_Line ("FAIL: " & Name);
         raise Program_Error with Name;
      end if;
      Passes := Passes + 1;
      Put_Line ("PASS: " & Name);
   end Check;

   Q     : Queue := Create;
   Ok    : Boolean;
   Kind  : Job_Kind;
   Seen  : Natural;
begin
   Check (Is_Empty (Q) and then Occupancy (Q) = 0, "empty after create");

   --  Fill to capacity
   for I in 1 .. Capacity loop
      Submit (Q, (if I mod 2 = 0 then Copy else Compute), Ok);
      Check (Ok, "submit while filling");
   end loop;
   Check (Is_Full (Q) and then Occupancy (Q) = Capacity, "full after fill");

   --  Reject when full
   Submit (Q, Compute, Ok);
   Check (not Ok and then Occupancy (Q) = Capacity, "reject when full");

   --  Complete frees one slot
   Complete (Q, Ok);
   Check (Ok and then Occupancy (Q) = Capacity - 1, "complete frees slot");
   Submit (Q, Copy, Ok);
   Check (Ok and then Is_Full (Q), "submit after complete");

   --  Drain with Try_Pop (wrap path exercised by prior Tail wrap)
   Reset (Q);
   Check (Occupancy (Q) = 0, "reset");

   --  Explicit wrap: fill, pop half, fill again so Tail wraps
   for I in 1 .. Capacity loop
      Submit (Q, Compute, Ok);
      pragma Assert (Ok);
   end loop;
   for I in 1 .. Capacity / 2 loop
      Try_Pop (Q, Kind, Ok);
      Check (Ok and then Kind = Compute, "pop half");
   end loop;
   for I in 1 .. Capacity / 2 loop
      Submit (Q, Copy, Ok);
      Check (Ok, "submit after wrap region");
   end loop;
   Check (Occupancy (Q) = Capacity, "full after wrap fill");

   --  First Capacity/2 should still be Compute, rest Copy
   Seen := 0;
   for I in 1 .. Capacity / 2 loop
      Try_Pop (Q, Kind, Ok);
      Check (Ok and then Kind = Compute, "order: early compute");
      Seen := Seen + 1;
   end loop;
   for I in 1 .. Capacity / 2 loop
      Try_Pop (Q, Kind, Ok);
      Check (Ok and then Kind = Copy, "order: late copy");
      Seen := Seen + 1;
   end loop;
   Check (Is_Empty (Q) and then Seen = Capacity, "drained after wrap");

   Try_Pop (Q, Kind, Ok);
   Check (not Ok, "try_pop empty");
   Complete (Q, Ok);
   Check (not Ok, "complete empty");

   Put_Line ("----------------");
   Put_Line ("All tests PASS:" & Passes'Image);
end Tests;
