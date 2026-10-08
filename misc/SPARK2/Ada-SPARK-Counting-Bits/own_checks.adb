--  Own tests for Counting_Bits (see tests/SOURCES.txt).
--  Ones must equal the own bit count.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Counting_Bits; use Counting_Bits;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
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
   Seed : Long_Long_Integer := AA_Seed (20_261_008);
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Ref (V : Natural) return Natural is
      C : Natural := 0;
      X : Natural := V;
   begin
      while X > 0 loop
         C := C + X mod 2;
         X := X / 2;
      end loop;
      return C;
   end Ref;
begin
   for V in 0 .. 2 ** 16 loop
      Report (Ones (V) = Ref (V), "small");
   end loop;
   for Iter in 1 .. 20_000 loop
      declare
         V : constant Input := Next (0, Input'Last);
      begin
         Report (Ones (V) = Ref (V), "random");
      end;
   end loop;
   for K in 0 .. 29 loop
      Report (Ones (2 ** K) = 1, "power of two");
   end loop;
   Report (Ones (Input'Last) = Ref (Input'Last), "last");
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own bit-count reference)");
end Own_Checks;
