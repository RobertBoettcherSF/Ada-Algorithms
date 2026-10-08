--  Own tests for Design_Add_And_Search_Words (see tests/SOURCES.txt).
--  Search is True exactly when some added word has the pattern length and matches
--  it letter by letter, with "." matching any letter.
pragma Ada_2022;
with Ada.Text_IO;
with Design_Add_And_Search_Words; use Design_Add_And_Search_Words;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   Seed : Long_Long_Integer := 20_261_008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;
   pragma Warnings (Off, Next);

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
   pragma Warnings (Off, Ins_Sort);

   type Words is array (1 .. Max_Words) of Word;
   Ws : Words;
   Cnt : Natural;
   function Rand_Word (Len : Length_Range; Dots : Boolean) return Word is
      R : Word := (Len => Len, Chars => [others => 'a']);
   begin
      for I in 1 .. Len loop
         R.Chars (I) := (if Dots and then Next (0, 2) = 0 then '.' else Character'Val (Character'Pos ('a') + Next (0, 1)));
      end loop;
      return R;
   end Rand_Word;
   function Match (W, P : Word) return Boolean is
   begin
      if W.Len /= P.Len then
         return False;
      end if;
      for I in 1 .. W.Len loop
         if P.Chars (I) /= '.' and then P.Chars (I) /= W.Chars (I) then
            return False;
         end if;
      end loop;
      return True;
   end Match;
begin
   for K in 1 .. 4_000 loop
      Cnt := Next (0, Max_Words);
      declare
         D : Dictionary;
         P : Word;
         Exp : Boolean := False;
      begin
         for I in 1 .. Cnt loop
            Ws (I) := Rand_Word (Next (0, 4), False);
            Add_Word (D, Ws (I));
         end loop;
         P := Rand_Word (Next (0, 4), True);
         for I in 1 .. Cnt loop
            Exp := Exp or else Match (Ws (I), P);
         end loop;
         Report (Search (D, P) = Exp, "random" & K'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own wildcard matcher reference)");
end Own_Checks;
