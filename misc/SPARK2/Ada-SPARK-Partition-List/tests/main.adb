--  Own tests for Partition_List.Solve (see tests/SOURCES.txt): after Solve (L, Pivot) the list
--  holds the values below Pivot, in their original order, followed by the values at or above
--  Pivot, in their original order (the standard Partition List statement), and keeps its length.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Partition_List; use Partition_List;

procedure Main is
   Failures : Natural := 0;
   Checked : Natural := 0;

   type Int_Array is array (Positive range <>) of Integer;

   procedure Check (Input : Int_Array; Pivot : Integer) is
      L : List := Empty;
      Expected : Int_Array (1 .. Input'Length);
      N : Natural := 0;
   begin
      for V of Input loop
         Append (L, V);
      end loop;
      --  own reference: filter the input twice
      for V of Input loop
         if V < Pivot then N := N + 1; Expected (N) := V; end if;
      end loop;
      for V of Input loop
         if V >= Pivot then N := N + 1; Expected (N) := V; end if;
      end loop;
      Solve (L, Pivot);
      Checked := Checked + 1;
      if L.Length /= Input'Length then
         Failures := Failures + 1;
         Put_Line ("FAIL: length changed");
         return;
      end if;
      for P in 1 .. Input'Length loop
         if Get (L, P) /= Expected (P) then
            Failures := Failures + 1;
            Put_Line ("FAIL: position" & Integer'Image (P) & " pivot" & Integer'Image (Pivot));
            return;
         end if;
      end loop;
   end Check;

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
begin
   --  by hand: 1 4 3 2 5 2 with pivot 3 -> 1 2 2 4 3 5
   declare
      L : List := Empty;
      Want : constant Int_Array := [1, 2, 2, 4, 3, 5];
   begin
      for V of Int_Array'[1, 4, 3, 2, 5, 2] loop
         Append (L, V);
      end loop;
      Solve (L, 3);
      for P in Want'Range loop
         if Get (L, P) /= Want (P) then
            Failures := Failures + 1; Put_Line ("FAIL: hand case");
         end if;
      end loop;
   end;
   --  exhaustive: every list of length 0 .. 7 over {0, 1, 2}, every pivot -1 .. 3
   for Len in 0 .. 7 loop
      declare
         Digit : Int_Array (1 .. Len) := [others => 0];
         Done : Boolean := False;
      begin
         while not Done loop
            for Pivot in -1 .. 3 loop
               Check (Digit, Pivot);
            end loop;
            Done := True;
            for I in Digit'Range loop
               if Digit (I) < 2 then
                  Digit (I) := Digit (I) + 1; Done := False; exit;
               else
                  Digit (I) := 0;
               end if;
            end loop;
         end loop;
      end;
   end loop;
   --  random full and partial lists, values with repeats and negatives
   for Trial in 1 .. 3_000 loop
      declare
         Len : constant Natural := (if Trial mod 4 = 0 then Capacity else Next (0, Capacity));
         A : Int_Array (1 .. Len);
      begin
         for I in A'Range loop
            A (I) := Next (-20, 20);
         end loop;
         Check (A, Next (-25, 25));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS Partition_List own checks:" & Natural'Image (Checked) & " lists");
   else
      Put_Line ("FAIL Partition_List own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Main;
