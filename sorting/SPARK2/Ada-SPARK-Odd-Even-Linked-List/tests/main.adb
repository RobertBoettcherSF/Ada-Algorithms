--  Own tests for Odd_Even_Linked_List.Solve (see tests/SOURCES.txt): after Solve (L) the list
--  holds the nodes at odd positions (1st, 3rd, ...) in their original order, followed by the
--  nodes at even positions (2nd, 4th, ...) in their original order (the standard Odd Even
--  Linked List statement; positions, not values), and keeps its length.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Odd_Even_Linked_List; use Odd_Even_Linked_List;

procedure Main is
   Failures : Natural := 0;
   Checked : Natural := 0;

   type Int_Array is array (Positive range <>) of Integer;

   procedure Check (Input : Int_Array) is
      L : List := Empty;
      Expected : Int_Array (1 .. Input'Length);
      N : Natural := 0;
   begin
      for V of Input loop
         Append (L, V);
      end loop;
      --  own reference: take every other position, starting at the first, then at the second
      for P in Input'Range loop
         if (P - Input'First) mod 2 = 0 then N := N + 1; Expected (N) := Input (P); end if;
      end loop;
      for P in Input'Range loop
         if (P - Input'First) mod 2 = 1 then N := N + 1; Expected (N) := Input (P); end if;
      end loop;
      Solve (L);
      Checked := Checked + 1;
      if L.Length /= Input'Length then
         Failures := Failures + 1;
         Put_Line ("FAIL: length changed");
         return;
      end if;
      for P in 1 .. Input'Length loop
         if Get (L, P) /= Expected (P) then
            Failures := Failures + 1;
            Put_Line ("FAIL: position" & Integer'Image (P) & " of" & Integer'Image (Input'Length));
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
   --  by hand: 2 1 3 5 6 4 7 -> 2 3 6 7 1 5 4 (positions 1 3 5 7, then 2 4 6)
   declare
      L : List := Empty;
      Want : constant Int_Array := [2, 3, 6, 7, 1, 5, 4];
   begin
      for V of Int_Array'[2, 1, 3, 5, 6, 4, 7] loop
         Append (L, V);
      end loop;
      Solve (L);
      for P in Want'Range loop
         if Get (L, P) /= Want (P) then
            Failures := Failures + 1; Put_Line ("FAIL: hand case");
         end if;
      end loop;
   end;
   --  exhaustive: every list of length 0 .. 7 over {0, 1, 2}
   for Len in 0 .. 7 loop
      declare
         Digit : Int_Array (1 .. Len) := [others => 0];
         Done : Boolean := False;
      begin
         while not Done loop
            Check (Digit);
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
         Check (A);
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS Odd_Even_Linked_List own checks:" & Natural'Image (Checked) & " lists");
   else
      Put_Line ("FAIL Odd_Even_Linked_List own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Main;
