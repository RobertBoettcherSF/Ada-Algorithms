--  Own tests for Exponential_Search (see tests/SOURCES.txt).
--  On a sorted array: Search returns an index holding Target, or 0 if absent.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Exponential_Search; use Exponential_Search;

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

   --  Own reference: straight insertion sort.
   type IArr is array (Positive range <>) of Integer;
   procedure Ins_Sort (A : in out IArr) is
      T : Integer;
      J : Positive;
   begin
      for I in A'First + 1 .. A'Last loop
         T := A (I);
         J := I;
         while J > A'First and then A (J - 1) > T loop
            A (J) := A (J - 1);
            J := J - 1;
         end loop;
         A (J) := T;
      end loop;
   end Ins_Sort;

   A : Data;
   T : Element;
   E : IArr (1 .. Capacity);
begin
   for K in 1 .. 5_000 loop
      for I in Index loop
         E (I) := Next (0, (if K mod 2 = 0 then 12 else 1_000));
      end loop;
      Ins_Sort (E);
      for I in Index loop
         A (I) := E (I);
      end loop;
      T := (if K mod 3 = 0 then A (Next (1, Capacity)) else Next (0, (if K mod 2 = 0 then 12 else 1_000)));
      declare
         R : constant Search_Result := Search (A, T);
         Present : Boolean := False;
      begin
         for I in Index loop
            Present := Present or else A (I) = T;
         end loop;
         Report ((if Present then R in Index and then A (R) = T else R = 0), "random" & K'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own linear-scan membership reference)");
end Own_Checks;
