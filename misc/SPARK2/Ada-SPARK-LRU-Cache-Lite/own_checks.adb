pragma Ada_2022;
--  Own tests for LRU_Cache_Lite (see tests/SOURCES.txt).
--  LRU model: entries kept in recency order; Put (new key, full) evicts the least recently used entry;
--  Put and Get count as a use; Lookup and Contains do not.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with LRU_Cache_Lite; use LRU_Cache_Lite;

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
   C : Cache;
   MK : array (1 .. 16) of Key;
   MV : array (1 .. 16) of Value;
   N  : Natural;
   function Find (K : Key) return Natural is
   begin
      for I in 1 .. N loop
         if MK (I) = K then return I; end if;
      end loop;
      return 0;
   end Find;
   procedure To_End (P : Positive) is   --  model: move entry P to the most recent end
      K : constant Key := MK (P);
      V : constant Value := MV (P);
   begin
      for I in P .. N - 1 loop MK (I) := MK (I + 1); MV (I) := MV (I + 1); end loop;
      MK (N) := K; MV (N) := V;
   end To_End;
begin
   for Run in 1 .. 1_000 loop
      C := Empty; N := 0;
      for Op in 1 .. 60 loop
         declare
            K : constant Key := Next (0, 24);
            V : constant Value := Next (-100, 100);
            P : constant Natural := Find (K);
            Got : Value;
            Ok : Boolean := True;
         begin
            if P > 0 and then Next (0, 2) = 0 then
               Get (C, K, Got);
               Ok := Got = MV (P);
               To_End (P);
            else
               Put (C, K, V);
               if P > 0 then
                  MV (P) := V; To_End (P);
               elsif N < 16 then
                  N := N + 1; MK (N) := K; MV (N) := V;
               else
                  To_End (1); MK (N) := K; MV (N) := V;   --  evict the least recently used
               end if;
            end if;
            Ok := Ok and then Length (C) = N;
            for Q in Key range 0 .. 24 loop
               Ok := Ok and then Contains (C, Q) = (Find (Q) > 0);
               if Find (Q) > 0 then Ok := Ok and then Lookup (C, Q) = MV (Find (Q)); end if;
            end loop;
            Report (Ok, "run" & Integer'Image (Run) & " op" & Integer'Image (Op));
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
