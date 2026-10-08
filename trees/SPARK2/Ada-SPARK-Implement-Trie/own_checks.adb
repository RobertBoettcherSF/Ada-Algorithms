--  Own tests for Implement_Trie (see tests/SOURCES.txt).
--  After inserting up to 8 words, Contains is exact membership.
pragma Ada_2022;
with Ada.Text_IO;
with Implement_Trie; use Implement_Trie;

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

   function Rand_Word (Len : Length_Range) return Word is
      R : Word := (Len => Len, Chars => [others => 'a']);
   begin
      for I in 1 .. Len loop
         R.Chars (I) := Character'Val (Character'Pos ('a') + Next (0, 1));
      end loop;
      return R;
   end Rand_Word;
   function Same (A, B : Word) return Boolean is
     (A.Len = B.Len and then (for all I in 1 .. A.Len => A.Chars (I) = B.Chars (I)));
   type Words is array (1 .. Max_Words) of Word;
begin
   for K in 1 .. 4_000 loop
      declare
         T : Trie;
         Ws : Words;
         N : constant Natural := Next (0, Max_Words);
      begin
         for I in 1 .. N loop
            Ws (I) := Rand_Word (Next (0, 4));
            Insert (T, Ws (I));
         end loop;
         for Q in 1 .. 10 loop
            declare
               P : constant Word := (if Q <= 3 and then N > 0 then Ws (Next (1, N)) else Rand_Word (Next (0, 4)));
            begin
               Report (Contains (T, P) = (for some I in 1 .. N => Same (Ws (I), P)), "random" & K'Image);
            end;
         end loop;
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own membership reference)");
end Own_Checks;
