--  Own tests for One_Edit_Distance (see tests/SOURCES.txt).
--  Is_One_Edit must be True exactly when the Levenshtein distance is 1.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with One_Edit_Distance; use One_Edit_Distance;

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


   --  Own reference: plain recursive Levenshtein distance (no memo; inputs are tiny).
   function Lev (A : String; B : String) return Natural is
   begin
      if A'Length = 0 then
         return B'Length;
      elsif B'Length = 0 then
         return A'Length;
      elsif A (A'Last) = B (B'Last) then
         return Lev (A (A'First .. A'Last - 1), B (B'First .. B'Last - 1));
      else
         return 1 + Natural'Min (Lev (A (A'First .. A'Last - 1), B),
                    Natural'Min (Lev (A, B (B'First .. B'Last - 1)),
                                 Lev (A (A'First .. A'Last - 1), B (B'First .. B'Last - 1))));
      end if;
   end Lev;

   A, B : Text := [others => ' '];
   LA, LB : Length_Type;
   Res : Boolean;
begin
   for K in 1 .. 4_000 loop
      LA := Next (0, (if K mod 4 = 0 then 32 else 7));
      for I in 1 .. LA loop
         A (I) := Character'Val (Character'Pos ('a') + Next (0, 2));
      end loop;
      --  derive B from A by 0, 1 or 2 random edits so that True cases are common
      B := A; LB := LA;
      for E in 1 .. Next (0, 2) loop
         case Next (0, 2) is
            when 0 => if LB > 0 then B (Next (1, LB)) := Character'Val (Character'Pos ('a') + Next (0, 2)); end if;
            when 1 => if LB < 32 then
                         declare P : constant Positive := Next (1, LB + 1); begin
                            B (P + 1 .. LB + 1) := B (P .. LB);
                            B (P) := Character'Val (Character'Pos ('a') + Next (0, 2));
                            LB := LB + 1;
                         end;
                      end if;
            when others => if LB > 0 then
                         declare P : constant Positive := Next (1, LB); begin
                            B (P .. LB - 1) := B (P + 1 .. LB);
                            LB := LB - 1;
                         end;
                      end if;
         end case;
      end loop;
      Is_One_Edit (A, B, LA, LB, Res);
      if LA <= 8 and then LB <= 8 then
         Report (Res = (Lev (String (A (1 .. LA)), String (B (1 .. LB))) = 1), "random" & K'Image);
      end if;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own Levenshtein = 1 reference)");
end Own_Checks;
