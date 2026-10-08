--  Own tests for Longest_Palindromic_Subsequence (see tests/SOURCES.txt).
--  Longest_Length must equal the longest palindromic subsequence found by trying every subsequence.
pragma Ada_2022;
with Ada.Text_IO;
with Longest_Palindromic_Subsequence; use Longest_Palindromic_Subsequence;

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
   function Ref (N : Natural) return Natural is
      Best : Natural := 0;
      Pick : array (1 .. Max_Length) of Positive;
      K : Natural;
      Ok : Boolean;
   begin
      for Mask in 0 .. 2 ** N - 1 loop
         K := 0;
         for I in 1 .. N loop
            if (Mask / 2 ** (I - 1)) mod 2 = 1 then K := K + 1; Pick (K) := I; end if;
         end loop;
         if K > Best then
            Ok := True;
            for I in 1 .. K / 2 loop
               if X (Pick (I)) /= X (Pick (K + 1 - I)) then Ok := False; end if;
            end loop;
            if Ok then Best := K; end if;
         end if;
      end loop;
      return Best;
   end Ref;
begin
   for N in 0 .. 9 loop                       --  every string over {a, b} up to length 9
      for Code in 0 .. 2 ** N - 1 loop
         X := [others => 'z'];
         for I in 1 .. N loop
            X (I) := (if (Code / 2 ** (I - 1)) mod 2 = 0 then 'a' else 'b');
         end loop;
         Report (Longest_Length (X, N) = Ref (N), "small");
      end loop;
   end loop;
   for Iter in 1 .. 1_500 loop
      declare
         N : constant Natural := Next (0, 13);
      begin
         X := [others => Character'Val (Next (Character'Pos ('a'), Character'Pos ('z')))];
         for I in 1 .. N loop
            X (I) := Character'Val (Character'Pos ('a') + Next (0, 3));
         end loop;
         Report (Longest_Length (X, N) = Ref (N), "random" & Iter'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own all-subsequences reference)");
end Own_Checks;
