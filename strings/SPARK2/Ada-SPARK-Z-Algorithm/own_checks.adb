--  Own tests for Z_Algorithm (see tests/SOURCES.txt).
--  Result (I) for I >= 2 = length of the longest common prefix of Text and Text (I .. 8).
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Z_Algorithm; use Z_Algorithm;

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


   T : Text_Array;
   Z : Z_Array;
begin
   for K in 1 .. 5_000 loop
      for I in Index loop
         T (I) := Character'Val (Character'Pos ('a') + Next (0, (if K mod 2 = 0 then 1 else 3)));
      end loop;
      Compute_Z (T, Z);
      declare
         Ok : Boolean := True;
         L  : Natural;
      begin
         for I in 2 .. Text_Length loop
            L := 0;
            while I + L <= Text_Length and then T (1 + L) = T (I + L) loop
               L := L + 1;
            end loop;
            Ok := Ok and then Z (I) = L;
         end loop;
         Report (Ok, "random" & K'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own longest-common-prefix reference)");
end Own_Checks;
