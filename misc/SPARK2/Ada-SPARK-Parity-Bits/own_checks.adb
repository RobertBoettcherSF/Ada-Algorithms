pragma Ada_2022;
--  Own tests for Parity_Bits (see tests/SOURCES.txt).
--  Even / Odd: whether the number of set bits is even / odd; own bit count.
with Ada.Environment_Variables;
with Interfaces;
with Ada.Text_IO; use Ada.Text_IO;
with Parity_Bits; use Parity_Bits;

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
   function Ones (V : Word) return Natural is
      X : Word := V;
      N : Natural := 0;
   begin
      while X /= 0 loop N := N + Natural (X mod 2); X := X / 2; end loop;
      return N;
   end Ones;
   procedure Check (V : Word) is
   begin
      Report (Even (V) = (Ones (V) mod 2 = 0) and then Odd (V) = (Ones (V) mod 2 = 1), "V" & Word'Image (V));
   end Check;
begin
   for V in Word range 0 .. 70_000 loop Check (V); end loop;
   for B in 0 .. 31 loop
      Check (2**B); Check (Word'Last - 2**B);
   end loop;
   Check (Word'Last);
   for Run in 1 .. 20_000 loop
      Check (Word (Next (0, 65_535)) * 65_536 + Word (Next (0, 65_535)));
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
