pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Non_Decreasing_Array; use Non_Decreasing_Array;
procedure Tests is
   Fails : Natural := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      if not Cond then
         Fails := Fails + 1;
         Put_Line ("FAIL " & Name);
      end if;
   end Check;

   --  Reference: try every single-position change to every Value (and no
   --  change) and test whether the result is non-decreasing.
   function Ref (A, B, C : Value) return Boolean is
      function Sorted (X, Y, Z : Value) return Boolean is (X <= Y and then Y <= Z);
   begin
      if Sorted (A, B, C) then
         return True;
      end if;
      for V in Value loop
         if Sorted (V, B, C) or else Sorted (A, V, C) or else Sorted (A, B, V) then
            return True;
         end if;
      end loop;
      return False;
   end Ref;

   --  Fixed-seed LCG (portable across compilers), seed recorded here.
   Seed  : constant := 20261009;
   State : Long_Long_Integer := Seed;
   function Next return Value is
   begin
      State := (State * 1103515245 + 12345) mod 2**31;
      return Value'First + Value'Base (State mod (Long_Long_Integer (Value'Last) - Long_Long_Integer (Value'First) + 1));
   end Next;

   Disagree : Natural := 0;
begin
   Check (Can_Be_Non_Decreasing (1, 2, 3), "1 2 3");
   Check (Can_Be_Non_Decreasing (3, 1, 2), "3 1 2");
   Check (not Can_Be_Non_Decreasing (3, 2, 1), "3 2 1");
   Check (Can_Be_Non_Decreasing (1, 1, 1), "1 1 1");
   Check (Can_Be_Non_Decreasing (5, 1, 5), "5 1 5");
   Check (not Can_Be_Non_Decreasing (5, 4, 3), "5 4 3");
   Check (Can_Be_Non_Decreasing (1, 3, 2), "1 3 2");
   Check (not Can_Be_Non_Decreasing (4, 2, 1), "4 2 1");
   --  2 2 1 -> 2 2 2 (change the last element)
   Check (Can_Be_Non_Decreasing (2, 2, 1), "2 2 1");
   --  3 5 1 -> 3 5 5 (only the last element can be changed)
   Check (Can_Be_Non_Decreasing (3, 5, 1), "3 5 1");
   Check (Can_Be_Non_Decreasing (10, 1, 10), "10 1 10");
   Check (Can_Be_Non_Decreasing (1, 10, 1), "1 10 1");
   Check (not Can_Be_Non_Decreasing (9, 8, 7), "9 8 7");
   Check (Can_Be_Non_Decreasing (7, 8, 7), "7 8 7");
   Check (Can_Be_Non_Decreasing (Value'Last, Value'Last, Value'First), "Last Last First");
   Check (not Can_Be_Non_Decreasing (Value'Last, 0, Value'First), "Last 0 First");

   --  Exhaustive: every triple of the 65-value domain against the reference.
   for A in Value loop
      for B in Value loop
         for C in Value loop
            if Can_Be_Non_Decreasing (A, B, C) /= Ref (A, B, C) then
               Disagree := Disagree + 1;
               if Disagree <= 5 then
                  Put_Line ("FAIL exhaustive" & A'Image & B'Image & C'Image);
               end if;
            end if;
         end loop;
      end loop;
   end loop;
   Check (Disagree = 0, "exhaustive vs reference:" & Disagree'Image & " of 274625 differ");

   --  Seeded random triples (seed 20261009, 100000 cases).
   Disagree := 0;
   for K in 1 .. 100_000 loop
      declare
         A : constant Value := Next;
         B : constant Value := Next;
         C : constant Value := Next;
      begin
         if Can_Be_Non_Decreasing (A, B, C) /= Ref (A, B, C) then
            Disagree := Disagree + 1;
         end if;
      end;
   end loop;
   Check (Disagree = 0, "random vs reference (seed 20261009):" & Disagree'Image & " of 100000 differ");

   if Fails = 0 then
      Put_Line ("PASS Ada-SPARK-Non-Decreasing-Array");
   else
      Put_Line ("FAILED" & Fails'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
