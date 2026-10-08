--  Own tests for Rotate_String (see tests/SOURCES.txt).
--  Is_Rotation must be True exactly when Right is a cyclic shift of Left.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Rotate_String; use Rotate_String;

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


   A, B : Text := [others => ' '];
   N : Length_Type;
   Res, Exp : Boolean;
   Sh : Natural;
begin
   for K in 1 .. 4_000 loop
      N := Next (1, (if K mod 2 = 0 then 6 else 32));
      for I in 1 .. N loop
         A (I) := Character'Val (Character'Pos ('a') + Next (0, 1));
      end loop;
      if K mod 3 = 0 then
         for I in 1 .. N loop
            B (I) := Character'Val (Character'Pos ('a') + Next (0, 1));
         end loop;
      else
         Sh := Next (0, N - 1);
         for I in 1 .. N loop
            B (I) := A ((I - 1 + Sh) mod N + 1);
         end loop;
      end if;
      Exp := False;
      for S in 0 .. N - 1 loop
         declare
            Ok : Boolean := True;
         begin
            for I in 1 .. N loop
               Ok := Ok and then B (I) = A ((I - 1 + S) mod N + 1);
            end loop;
            Exp := Exp or else Ok;
         end;
      end loop;
      Is_Rotation (A, B, N, Res);
      Report (Res = Exp, "random" & K'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own every-shift reference)");
end Own_Checks;
