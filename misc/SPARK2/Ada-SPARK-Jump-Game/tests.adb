pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Jump_Game; use Jump_Game;
procedure Tests is
   --  Own tests (see tests/SOURCES.txt): A (I) is the longest jump allowed from index I; Can_Jump (A, N)
   --  says whether index N can be reached from index 1. Reference: own breadth-first reachability.
   A : Steps := [others => 0];
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
   function Next (Bound : Natural) return Natural is
   begin
      Seed := (Seed * 48271) mod 2147483647;   --  Park-Miller
      return Natural (Seed mod Long_Long_Integer (Bound + 1));
   end Next;
   function Reference (A : Steps; N : Index) return Boolean is
      Seen : array (Index) of Boolean := [1 => True, others => False];
   begin
      for I in 1 .. N loop
         if Seen (I) then
            for J in I + 1 .. Integer'Min (N, I + Integer'Min (A (I), 32)) loop
               Seen (J) := True;
            end loop;
         end if;
      end loop;
      return Seen (N);
   end Reference;
   procedure Set (V : Steps; N : Index; Expect : Boolean) is
   begin
      Assert (Can_Jump (V, N) = Expect, "fixed case N =" & N'Image);
   end Set;
   Cases : Natural := 0;
begin
   A (1) := 1;
   Assert (Can_Jump (A, 1));
   --  hand cases, expected value worked out by hand
   Set ([2, 3, 1, 1, 4, others => 0], 5, True);
   Set ([3, 2, 1, 0, 4, others => 0], 5, False);   --  index 4 is a dead end, 5 cannot be reached
   Set ([0, 7, others => 0], 2, False);             --  stuck at index 1
   Set ([0, others => 0], 1, True);                 --  already at the last index
   Set ([1, 0, 1, others => 0], 3, False);
   Set ([2, 0, 0, others => 0], 3, True);
   Set ([others => 1], 32, True);
   Set ([31, others => 0], 32, True);
   Set ([30, others => 0], 32, False);
   for K in 1 .. 20_000 loop
      declare
         N : constant Index := 1 + Next (31);
      begin
         for I in Index loop
            A (I) := (if Next (5) = 0 then 0 else Next (3));
         end loop;
         Assert (Can_Jump (A, N) = Reference (A, N), "random case" & K'Image);
         Cases := Cases + 1;
      end;
   end loop;
   Put_Line ("PASS Ada-SPARK-Jump-Game (" & Natural'Image (Cases + 10) & " cases, own reachability reference)");
end Tests;
