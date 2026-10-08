pragma Ada_2022;
--  Own tests for Adler32 (see tests/SOURCES.txt).
--  Compute against the standard check value Adler-32 ("Wikipedia") = 16#11E60398# and an own
--  computation from the definition (A = 1 + sum of bytes, B = sum of the running A values, both mod 65521,
--  result B * 65536 + A) using wide integers, on random data up to Max_Length bytes.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Interfaces;
with Adler32; use Adler32;

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
   use type Interfaces.Unsigned_32;
begin
   declare
      S : constant String := "Wikipedia";
      D : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop D (I - S'First + 1) := Character'Pos (S (I)); end loop;
      Report (Compute (D) = 16#11E60398#, "Adler-32 (""Wikipedia"") /= 16#11E60398#");
   end;
   declare
      E : Byte_Array (1 .. 0);
   begin
      Report (Compute (E) = 1, "Adler-32 of empty data /= 1");
   end;
   for Run in 1 .. 5000 loop
      declare
         N : constant Natural := Next (0, Max_Length);
         D : Byte_Array (1 .. N);
         A : Long_Long_Integer := 1;
         B : Long_Long_Integer := 0;
      begin
         for I in 1 .. N loop
            D (I) := Byte (Next (0, 255));
            if Run mod 3 = 0 then D (I) := 255; end if;   --  all-0xFF data stresses the modulo
            A := (A + Long_Long_Integer (D (I))) mod 65521;
            B := (B + A) mod 65521;
         end loop;
         Report (Compute (D) = Interfaces.Unsigned_32 (B * 65536 + A), "Compute differs from own definition, run" & Run'Image);
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
