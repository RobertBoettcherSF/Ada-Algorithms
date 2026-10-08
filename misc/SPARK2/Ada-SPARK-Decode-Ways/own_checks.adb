--  Own tests for Decode_Ways (see tests/SOURCES.txt).
--  Count must be the number of ways to split the digits into codes 1 .. 26 (no code
--  with a leading zero), for lengths whose count fits Result (up to 29).
pragma Ada_2022;
with Ada.Text_IO;
with Decode_Ways; use Decode_Ways;

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
   X : Digit_Sequence;
   function Ref (From, Len : Positive) return Natural is
      --  ways to decode X (From .. Len)
   begin
      if From > Len then return 1; end if;
      if X (From) = 0 then return 0; end if;
      return Ref (From + 1, Len)
        + (if From < Len and then X (From) * 10 + X (From + 1) <= 26 then Ref (From + 2, Len) else 0);
   end Ref;
begin
   for Iter in 1 .. 4_000 loop
      declare
         N : constant Positive := Next (1, (if Iter mod 4 = 0 then 29 else 12));
      begin
         X := [others => Next (0, 9)];
         for I in 1 .. N loop
            --  mostly 1s and 2s (many decodings), some 0s and larger digits
            X (I) := (case Next (0, 5) is when 0 | 1 => 1, when 2 | 3 => 2, when 4 => 0, when others => Next (3, 9));
         end loop;
         Report (Count (X, N) = Ref (1, N), "random" & Iter'Image);
      end;
   end loop;
   for N in 1 .. 29 loop        --  all ones: the count grows like the Fibonacci numbers
      X := [others => 1];
      Report (Count (X, N) = Ref (1, N), "ones");
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own recursive decoding reference)");
end Own_Checks;
