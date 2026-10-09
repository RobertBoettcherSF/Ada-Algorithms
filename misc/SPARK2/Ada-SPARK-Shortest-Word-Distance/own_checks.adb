pragma Ada_2022;
--  Own checks for Shortest-Word-Distance (V&V sweep, agent A3, 2026-10-09;
--  see tests/SOURCES.txt). Reference: every pair of positions I, J in
--  1 .. Length with Input (I) = First and Input (J) = Second is compared
--  and the smallest |I - J| kept; 32 when there is no such pair (the
--  package's "not found" value; a real distance is at most 31). First and
--  Second are always different letters (the problem's two distinct words).
--  Inputs: every text over {a, b, c} of Length 0 .. 8 (cells after Length
--  filled with seeded letters that would change the answer if read), then
--  20,000 seeded random texts of Length 0 .. 32 over 'a' .. 'd'.
--  Seeded: Park-Miller minimal standard generator; default seed = FNV-1a
--  (32-bit) of the folder name folded into 1 .. 2 ** 31 - 2, printed;
--  AA_SEED=<n> overrides it.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Shortest_Word_Distance; use Shortest_Word_Distance;

procedure Own_Checks with SPARK_Mode => Off is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Name_Hash return Long_Long_Integer is
      Name : constant String := "Ada-SPARK-Shortest-Word-Distance";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : constant Long_Long_Integer :=
        (if V = "" then Default
         else 1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
   begin
      Ada.Text_IO.Put_Line
        ("AA_SEED =" & S'Image
         & (if V = "" then " (default: FNV-1a of the folder name)"
            else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (Name_Hash);
   function Next return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed);
   end Next;

   function Reference (T : Text; L : Length_Type; F, S : Character) return Distance_Type is
      Best : Distance_Type := 32;
   begin
      for I in 1 .. L loop
         for J in 1 .. L loop
            if T (I) = F and then T (J) = S and then abs (I - J) < Best then
               Best := abs (I - J);
            end if;
         end loop;
      end loop;
      return Best;
   end Reference;

   procedure One (T : Text; L : Length_Type) is
      R : Distance_Type;
   begin
      for F in Character range 'a' .. 'c' loop
         for S in Character range 'a' .. 'd' loop
            if F /= S then
               Minimum_Distance (T, L, F, S, R);
               Report (R = Reference (T, L, F, S),
                       "Minimum_Distance " & F & S & " Length" & L'Image
                       & " expected" & Reference (T, L, F, S)'Image);
            end if;
         end loop;
      end loop;
   end One;

   T : Text;
begin
   for L in Length_Type range 0 .. 8 loop
      for Code in 0 .. 3 ** L - 1 loop
         for K in Index loop
            T (K) := (if K <= L then Character'Val (Character'Pos ('a') + (Code / 3 ** (K - 1)) mod 3)
                      else Character'Val (Character'Pos ('a') + Next mod 4));
         end loop;
         One (T, L);
      end loop;
   end loop;
   for R in 1 .. 20_000 loop
      declare
         L : constant Length_Type := Next mod 33;
      begin
         for K in Index loop
            T (K) := Character'Val (Character'Pos ('a') + Next mod 4);
         end loop;
         One (T, L);
      end;
   end loop;
   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
