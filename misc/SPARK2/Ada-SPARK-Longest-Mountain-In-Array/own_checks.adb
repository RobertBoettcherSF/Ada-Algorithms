pragma Ada_2022;
--  Own checks for Longest-Mountain-In-Array (V&V sweep, agent A3,
--  2026-10-09; see tests/SOURCES.txt). Reference: every slice I .. J of
--  Data (1 .. Length) with J - I >= 2 is tested directly against the
--  definition (a peak P with I < P < J, strictly rising from I to P and
--  strictly falling from P to J), and the longest such slice wins (0 when
--  there is none). The library instead counts the rise and fall runs around
--  each peak. Inputs: every array over {0, 1, 2} for every Length 0 .. 8
--  (3 ** 8 arrays, the cells after Length filled with seeded junk), then
--  20,000 seeded random arrays of Length 0 .. 32 over -3 .. 3 (plateaus
--  common) and over the whole Value range.
--  Seeded: Park-Miller minimal standard generator; default seed = FNV-1a
--  (32-bit) of the folder name folded into 1 .. 2 ** 31 - 2, printed;
--  AA_SEED=<n> overrides it.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Longest_Mountain_In_Array; use Longest_Mountain_In_Array;

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
      Name : constant String := "Ada-SPARK-Longest-Mountain-In-Array";
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

   function Is_Mountain (D : Values; I, J : Index) return Boolean is
   begin
      for P in I + 1 .. J - 1 loop
         if (for all K in I .. P - 1 => D (K) < D (K + 1))
           and then (for all K in P .. J - 1 => D (K) > D (K + 1))
         then
            return True;
         end if;
      end loop;
      return False;
   end Is_Mountain;

   function Reference (D : Values; L : Length_Type) return Length_Type is
      Best : Length_Type := 0;
   begin
      for I in 1 .. L loop
         for J in I + 2 .. L loop
            if J - I + 1 > Best and then Is_Mountain (D, I, J) then
               Best := J - I + 1;
            end if;
         end loop;
      end loop;
      return Best;
   end Reference;

   procedure One (D : Values; L : Length_Type) is
      R : constant Length_Type := Reference (D, L);
   begin
      Report (Longest (D, L) = R, "Longest, Length" & L'Image & " expected" & R'Image
              & " Data" & D'Image);
   end One;

   D : Values;
begin
   for L in Length_Type range 0 .. 8 loop
      for Code in 0 .. 3 ** L - 1 loop
         for K in Index loop
            D (K) := (if K <= L then (Code / 3 ** (K - 1)) mod 3 else Next mod 2001 - 1000);
         end loop;
         One (D, L);
      end loop;
   end loop;
   for T in 1 .. 20_000 loop
      declare
         L : constant Length_Type := Next mod 33;
      begin
         for K in Index loop
            D (K) := (if T mod 2 = 0 then Next mod 7 - 3 else Next mod 2001 - 1000);
         end loop;
         One (D, L);
      end;
   end loop;
   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
