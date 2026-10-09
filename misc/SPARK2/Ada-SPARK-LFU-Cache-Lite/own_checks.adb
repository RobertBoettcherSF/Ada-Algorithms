pragma Ada_2022;
--  Own tests for LFU_Cache_Lite (see tests/SOURCES.txt).
--  LFU model: Put (new key, full) evicts the entry with the fewest uses, ties by least recent use;
--  Put and Touch count as a use; Most_Frequent_Key = most uses, ties by least recent.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with LFU_Cache_Lite; use LFU_Cache_Lite;

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
   MU : array (1 .. 16) of Natural;
   N  : Natural;
   function Find (K : Key) return Natural is
   begin
      for I in 1 .. N loop
         if MK (I) = K then return I; end if;
      end loop;
      return 0;
   end Find;
   procedure To_End (P : Positive) is   --  model: entries in recency order, most recent last
      K : constant Key := MK (P);
      V : constant Value := MV (P);
      U : constant Natural := MU (P);
   begin
      for I in P .. N - 1 loop MK (I) := MK (I + 1); MV (I) := MV (I + 1); MU (I) := MU (I + 1); end loop;
      MK (N) := K; MV (N) := V; MU (N) := U;
   end To_End;
begin
   for Run in 1 .. 1_000 loop
      C := Empty; N := 0;
      for Op in 1 .. 60 loop
         declare
            K : constant Key := Next (0, 24);
            V : constant Value := Next (-100, 100);
            P : constant Natural := Find (K);
            Ok : Boolean := True;
            Best, Low : Natural;
         begin
            if P > 0 and then Next (0, 1) = 0 then
               Touch (C, K);
               MU (P) := MU (P) + 1; To_End (P);
            else
               Put (C, K, V);
               if P > 0 then
                  MV (P) := V; MU (P) := MU (P) + 1; To_End (P);
               else
                  if N = 16 then   --  evict: fewest uses, the least recent among ties
                     Low := 1;
                     for I in 2 .. N loop
                        if MU (I) < MU (Low) then Low := I; end if;
                     end loop;
                     To_End (Low); N := N - 1;
                  end if;
                  N := N + 1; MK (N) := K; MV (N) := V; MU (N) := 1;
               end if;
            end if;
            Ok := Length (C) = N;
            for Q in Key range 0 .. 24 loop
               Ok := Ok and then Contains (C, Q) = (Find (Q) > 0);
               --  the value stored under every present key (model: last Put value of that key)
               if Find (Q) > 0 then
                  Ok := Ok and then Get (C, Q) = MV (Find (Q));
               end if;
            end loop;
            Best := 1;
            for I in 2 .. N loop
               if MU (I) > MU (Best) then Best := I; end if;
            end loop;
            Ok := Ok and then Most_Frequent_Key (C) = MK (Best);
            Report (Ok, "run" & Integer'Image (Run) & " op" & Integer'Image (Op));
         end;
      end loop;
   end loop;
   --  Long check (opt-in, AA_LONG=1; about 2**32 Touch calls, 30 s to a few minutes): use counts must
   --  not stop at Natural'Last. Key 2 gets 2**31 - 1 uses, then key 1 gets 2**31 uses, touched last.
   --  Key 1 has strictly more uses, so it is the most frequent; a counter that stopped at 2**31 - 1
   --  would see a tie and answer the least recently used key, 2.
   if Ada.Environment_Variables.Exists ("AA_LONG") and then Ada.Environment_Variables.Value ("AA_LONG") = "1" then
      C := Empty;
      Put (C, 1, 10); Put (C, 2, 20);                     --  one use each
      for I in 2 .. Long_Long_Integer (Natural'Last) loop  --  key 2: 2**31 - 1 uses
         Touch (C, 2);
      end loop;
      for I in 2 .. Long_Long_Integer (Natural'Last) + 1 loop  --  key 1: 2**31 uses
         Touch (C, 1);
      end loop;
      Report (Most_Frequent_Key (C) = 1, "long: 2**31 uses beat 2**31 - 1 uses");
      Put_Line ("long check done (AA_LONG=1)");
   end if;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
