pragma Ada_2022;
--  Own tests for Group_Anagrams (see tests/SOURCES.txt).
--  Label (I) is the number of the first word that is an anagram of word I (the
--  convention of the hand test). Anagram check: own letter counts over all characters.
with Ada.Text_IO; use Ada.Text_IO;
with Group_Anagrams; use Group_Anagrams;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   Seed : Long_Long_Integer := 20261008;
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
   function Anagram (A, B : Word) return Boolean is
      type Tally is array (Character) of Natural;
      TA, TB : Tally := [others => 0];
   begin
      for C of A loop TA (C) := TA (C) + 1; end loop;
      for C of B loop TB (C) := TB (C) + 1; end loop;
      return TA = TB;
   end Anagram;
   function Rand_Word (Alpha : Positive) return Word is
      W : Word;
   begin
      for P in Position loop W (P) := Character'Val (Character'Pos ('a') + Next (0, Alpha - 1)); end loop;
      return W;
   end Rand_Word;
   function Shuffle (W : Word) return Word is
      R : Word := W;
      T : Character;
      K : Position;
   begin
      for P in reverse 2 .. Word_Length loop
         K := Next (1, P); T := R (P); R (P) := R (K); R (K) := T;
      end loop;
      return R;
   end Shuffle;
begin
   for Run in 1 .. 20000 loop
      declare
         S : Word_Set;
         L : Labels;
         Ok : Boolean := True;
         Alpha : constant Positive := Next (2, 4);
      begin
         S (1) := Rand_Word (Alpha);
         for I in 2 .. Word_Count loop
            --  half the time a shuffle of an earlier word, so groups are common
            S (I) := (if Next (0, 1) = 0 then Shuffle (S (Next (1, I - 1))) else Rand_Word (Alpha));
         end loop;
         L := Group (S);
         for I in Word_Index loop
            declare
               First : Word_Index := I;
            begin
               for J in reverse 1 .. I loop
                  if Anagram (S (J), S (I)) then First := J; end if;
               end loop;
               Ok := Ok and then L (I) = First;
            end;
         end loop;
         Report (Ok, "run" & Integer'Image (Run));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
