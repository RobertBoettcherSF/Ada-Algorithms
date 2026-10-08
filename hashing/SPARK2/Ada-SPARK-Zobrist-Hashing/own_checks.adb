--  Own tests for Zobrist_Hashing (see tests/SOURCES.txt).
--  Zobrist property: Hash (S) is the XOR of one key per (position, character) pair, with the key not
--  depending on the other characters; and changing one character always changes the hash.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Zobrist_Hashing; use Zobrist_Hashing;

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
   Filler : constant Char_Array (1 .. Max_Len) := [others => 'z'];

   --  key of (Position, C), measured through the public Hash with a fixed filler prefix
   function Key_Of (Position : Positive; C : Character) return Hash_Value is
      With_C : Char_Array (1 .. Position) := Filler (1 .. Position);
   begin
      With_C (Position) := C;
      return Hash (With_C) xor Hash (Filler (1 .. Position - 1));
   end Key_Of;

   function Random_Char return Character is
     (Character'Val (Next (Character'Pos (' '), Character'Pos ('~'))));
begin
   Report (Hash (Filler (1 .. 0)) = 0, "empty");
   for Trial in 1 .. 20_000 loop
      declare
         N : constant Natural := Next (0, Max_Len);
         S : Char_Array (1 .. N);
         Expected : Hash_Value := 0;
      begin
         for I in S'Range loop
            S (I) := (if Trial mod 2 = 0 then Random_Char else Character'Val (Next (Character'Pos ('a'), Character'Pos ('c'))));
            Expected := Expected xor Key_Of (I, S (I));
         end loop;
         Report (Hash (S) = Expected, "xor of keys");
         if N > 0 then   --  one changed character changes the hash
            declare
               T : Char_Array := S;
               P : constant Positive := Next (1, N);
            begin
               T (P) := Random_Char;
               Report ((T (P) = S (P)) = (Hash (T) = Hash (S)), "one character changed");
            end;
         end if;
      end;
   end loop;
   --  every Character (NUL and Character'Last included) at every position hashes without an exception
   for P in 1 .. Max_Len loop
      for C in Character loop
         declare
            S : Char_Array (1 .. P) := Filler (1 .. P);
         begin
            S (P) := C;
            Report (Hash (S) = (Hash (Filler (1 .. P - 1)) xor Key_Of (P, C)), "full Character range");
         end;
      end loop;
   end loop;
   --  position-sensitive: the same character has a different key at every position
   for C in Character loop
      for P1 in 1 .. Max_Len loop
         for P2 in P1 + 1 .. Max_Len loop
            Report (Key_Of (P1, C) /= Key_Of (P2, C), "position-sensitive keys");
         end loop;
      end loop;
   end loop;
   --  per position, every character (all 256) has its own key
   for P in 1 .. Max_Len loop
      for C1 in Character'First .. Character'Pred (Character'Last) loop
         for C2 in Character'Succ (C1) .. Character'Last loop
            Report (Key_Of (P, C1) /= Key_Of (P, C2), "distinct keys");
         end loop;
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
