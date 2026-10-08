--  Own tests for Burrows_Wheeler_Transform (see tests/SOURCES.txt).
--  Rotation_Character (X, S, O) must be character O of the rotation of X that starts at
--  S, and Rotation_Less must order two different rotations lexicographically.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Burrows_Wheeler_Transform; use Burrows_Wheeler_Transform;

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

   X : Text;
   function Rot (S : Index; O : Natural) return Character is
     (X (((S - 1 + O) mod Max_Length) + 1));
   function Cmp (L, R : Index) return Integer is   --  -1, 0, 1, from the definition
   begin
      for O in 0 .. Max_Length - 1 loop
         if Rot (L, O) < Rot (R, O) then return -1; end if;
         if Rot (L, O) > Rot (R, O) then return 1; end if;
      end loop;
      return 0;
   end Cmp;
   Ok : Boolean;
begin
   for Iter in 1 .. 4_000 loop
      for I in Index loop
         X (I) := Character'Val (Character'Pos ('a') + Next (0, (if Iter mod 2 = 0 then 1 else 2)));
      end loop;
      Ok := True;
      for S in Index loop
         for O in Rotation_Offset loop
            if Rotation_Character (X, S, O) /= Rot (S, O) then Ok := False; end if;
         end loop;
      end loop;
      for L in Index loop
         for R in Index loop
            if Cmp (L, R) /= 0 and then Rotation_Less (X, L, R) /= (Cmp (L, R) < 0) then
               Ok := False;
            end if;
         end loop;
      end loop;
      Report (Ok, "random" & Iter'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (rotations and their order from the definition)");
end Own_Checks;
