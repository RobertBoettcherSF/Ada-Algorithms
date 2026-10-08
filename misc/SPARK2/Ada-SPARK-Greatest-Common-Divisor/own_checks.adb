--  Own tests for Greatest_Common_Divisor (see tests/SOURCES.txt).
--  GCD must be the largest number dividing both inputs (definition, checked by search).
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Greatest_Common_Divisor; use Greatest_Common_Divisor;

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

   function Ref (A, B : Positive) return Positive is
   begin
      for D in reverse 1 .. Positive'Min (A, B) loop
         if A mod D = 0 and then B mod D = 0 then return D; end if;
      end loop;
      return 1;
   end Ref;
begin
   for A in 1 .. 150 loop
      for B in 1 .. 150 loop
         Report (GCD (A, B) = Ref (A, B), "small");
      end loop;
   end loop;
   for Iter in 1 .. 20_000 loop
      declare
         A : constant Input := Next (1, 1_000);
         B : constant Input := Next (1, 1_000);
      begin
         Report (GCD (A, B) = Ref (A, B), "random");
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own divisor-search reference)");
end Own_Checks;
