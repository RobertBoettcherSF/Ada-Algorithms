--  Own tests for Get_Equal_Substrings_Within_Budget (see tests/SOURCES.txt).
--  Longest = maximal window length with sum |Source (I) - Target (I)| <= Budget.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Get_Equal_Substrings_Within_Budget; use Get_Equal_Substrings_Within_Budget;

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


   S, U : Code_Array;
   B : Budget_Count;
begin
   for K in 1 .. 5_000 loop
      for I in Index loop
         S (I) := Next (0, Code'Last);
         U (I) := (if Next (0, 2) = 0 then S (I) else Next (0, Code'Last));
      end loop;
      B := Next (0, (if K mod 2 = 0 then 20 else Budget_Count'Last));
      declare
         Best : Natural := 0;
         Cost : Natural;
      begin
         for I in Index loop
            for J in I .. Element_Count loop
               Cost := 0;
               for P in I .. J loop
                  Cost := Cost + abs (S (P) - U (P));
               end loop;
               if Cost <= B then
                  Best := Natural'Max (Best, J - I + 1);
               end if;
            end loop;
         end loop;
         Report (Longest (S, U, B) = Best, "random" & K'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own all-windows reference)");
end Own_Checks;
