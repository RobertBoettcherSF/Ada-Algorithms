pragma Ada_2022;
--  Own tests for Binary_GCD (see tests/SOURCES.txt).
--  Gcd, Gcd_Recursive and Gcd_Euclidean against the definition: a common divisor that every common
--  divisor divides (checked by brute force on small values, and on large values by the divisibility
--  property plus coprimality of the cofactors); gcd (0, b) = b.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Binary_GCD; use Binary_GCD;

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
   function Own_Gcd (A, B : U64) return U64 is   --  repeated subtraction, small values only
      X : U64 := A; Y : U64 := B;
   begin
      if X = 0 then return Y; end if;
      if Y = 0 then return X; end if;
      while X /= Y loop
         if X > Y then X := X - Y; else Y := Y - X; end if;
      end loop;
      return X;
   end Own_Gcd;
   function Big return U64 is
     (U64 (Next (0, 2_000_000_000)) * U64 (Next (1, 2_000_000_000)) + U64 (Next (0, 1000)));
begin
   for A in U64 range 0 .. 60 loop
      for B in U64 range 0 .. 60 loop
         declare
            Own : constant U64 := Own_Gcd (A, B);
         begin
            Report (Gcd (A, B) = Own and then Gcd_Recursive (A, B) = Own and then Gcd_Euclidean (A, B) = Own,
                    "gcd" & A'Image & B'Image & " /= own" & Own'Image);
         end;
      end loop;
   end loop;
   for Run in 1 .. 5000 loop
      declare
         F : constant U64 := U64 (Next (1, 100_000));
         A : constant U64 := (Big mod 1_000_000_000_000) * F;
         B : constant U64 := (Big mod 1_000_000_000_000) * F;
         G : constant U64 := Gcd (A, B);
      begin
         if A = 0 or else B = 0 then
            Report (G = A + B, "gcd with a zero argument, run" & Run'Image);
         else
            --  G divides both, F divides G (a common divisor divides the gcd), and the cofactors are coprime
            Report (G > 0 and then A mod G = 0 and then B mod G = 0 and then G mod F = 0
                    and then Gcd_Euclidean (A / G, B / G) = 1
                    and then Gcd_Recursive (A, B) = G,
                    "gcd property fails, run" & Run'Image);
         end if;
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
