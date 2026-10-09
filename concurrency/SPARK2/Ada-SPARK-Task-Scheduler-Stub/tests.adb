pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Task_Scheduler_Stub; use Task_Scheduler_Stub;
procedure Tests is
   Fails : Natural := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      if not Cond then
         Fails := Fails + 1;
         if Fails <= 20 then
            Put_Line ("FAIL " & Name);
         end if;
      end if;
   end Check;

   --  Reference: walk the durations from shortest to longest and, for
   --  each, list the tasks with that duration in index order.
   function Ref (Tasks : Task_Array) return Schedule_Array is
      R   : Schedule_Array (Tasks'Range) := [others => Tasks'First];
      Pos : Integer := Tasks'First;
   begin
      for D in Task_Scheduler_Stub.Duration loop
         for T in Tasks'Range loop
            if Tasks (T) = D then
               R (Pos) := T;
               Pos := Pos + 1;
            end if;
         end loop;
      end loop;
      return R;
   end Ref;

   procedure Compare (Tasks : Task_Array; Name : String) is
   begin
      Check (Shortest_First (Tasks) = Ref (Tasks), Name);
   end Compare;

   Seed  : constant := 20261009;
   State : Long_Long_Integer := Seed;
   function Next (M : Positive) return Natural is
   begin
      State := (State * 1103515245 + 12345) mod 2**31;
      return Natural (State / 65536 mod Long_Long_Integer (M));
   end Next;
begin
   Check (Shortest_First ([8, 3, 5, 1, 4, 2]) = [4, 6, 2, 5, 3, 1], "mixed");
   Check (Shortest_First ([1, 2, 3, 4, 5, 6]) = [1, 2, 3, 4, 5, 6], "ascending");
   Check (Shortest_First ([6, 5, 4, 3, 2, 1]) = [6, 5, 4, 3, 2, 1], "descending");
   --  Equal durations run in submission (index) order
   Check (Shortest_First ([5, 5, 1, 5, 5, 5]) = [3, 1, 2, 4, 5, 6], "ties keep index order");
   Check (Shortest_First ([7, 7, 7]) = [1, 2, 3], "all equal");
   Check (Shortest_First ([1 .. 0 => 1]) = [1 .. 0 => 1], "no tasks");
   Check (Shortest_First ([10 => 4, 11 => 2, 12 => 4]) = [10 => 11, 11 => 10, 12 => 12], "lower bound 10");

   --  Exhaustive: every array of length 0 .. 7 with durations 1 .. 3
   for N in 0 .. 7 loop
      declare
         A    : Task_Array (1 .. N) := [others => 1];
         Done : Boolean;
      begin
         loop
            Compare (A, "exhaustive N =" & N'Image);
            Done := True;
            for P in reverse A'Range loop
               if A (P) < 3 then
                  A (P) := A (P) + 1;
                  A (P + 1 .. N) := [others => 1];
                  Done := False;
                  exit;
               end if;
            end loop;
            exit when Done;
         end loop;
      end;
   end loop;

   --  Seeded random (seed 20261009): 20,000 arrays, length 0 .. 30,
   --  durations 1 .. 20, lower bound 1 .. 40
   for K in 1 .. 20_000 loop
      declare
         N  : constant Natural := Next (31);
         Lo : constant Positive := 1 + Next (40);
         A  : Task_Array (Lo .. Lo + N - 1);
      begin
         for P in A'Range loop
            A (P) := 1 + Next (20);
         end loop;
         Compare (A, "random" & K'Image);
      end;
   end loop;

   if Fails = 0 then
      Put_Line ("PASS Task_Scheduler_Stub");
   else
      Put_Line ("FAILED" & Fails'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
