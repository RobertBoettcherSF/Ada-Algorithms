with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO;
with Repeated_String_Match; use Repeated_String_Match;
procedure Tests is
   --  Own tests (tests/SOURCES.txt): Result = the fewest copies of Source (1 .. Source_Length) whose
   --  concatenation contains Target (1 .. Target_Length) as a substring, 0 if no number of copies does.
   A : Text := (others => ' ');
   B : Text := (others => ' ');
   Result : Repeat_Type;
   Seed : Long_Long_Integer := 777_123;
   function Next (Bound : Natural) return Natural is
   begin
      Seed := (Seed * 48271) mod 2147483647;   --  Park-Miller
      return Natural (Seed mod Long_Long_Integer (Bound + 1));
   end Next;
   --  own brute force: concatenate K copies and search naively, K = 1 .. 40
   function Reference (A, B : Text; LA, LB : Positive) return Natural is
   begin
      for K in 1 .. 40 loop
         declare
            S : String (1 .. K * LA);
         begin
            for P in S'Range loop
               S (P) := A ((P - 1) mod LA + 1);
            end loop;
            for Start in 1 .. S'Last - LB + 1 loop
               declare
                  Ok : Boolean := True;
               begin
                  for J in 1 .. LB loop
                     if S (Start + J - 1) /= B (J) then
                        Ok := False;
                     end if;
                  end loop;
                  if Ok then
                     return K;
                  end if;
               end;
            end loop;
         end;
      end loop;
      return 0;
   end Reference;
   procedure Check (SA, SB : String; Expect : Natural) is
   begin
      A := [others => ' '];
      B := [others => ' '];
      for I in SA'Range loop
         A (I - SA'First + 1) := SA (I);
      end loop;
      for I in SB'Range loop
         B (I - SB'First + 1) := SB (I);
      end loop;
      Repeat_Count (A, B, SA'Length, SB'Length, Result);
      Assert (Result = Expect, "fixed case " & SA & " / " & SB);
   end Check;
   Cases : Natural := 0;
begin
   A (1 .. 3) := "abc";
   B (1 .. 6) := "abcabc";
   Repeat_Count (A, B, 3, 6, Result);
   Assert (Result = 2);
   B (1 .. 2) := "ac";
   Repeat_Count (A, B, 3, 2, Result);
   Assert (Result = 0);
   --  hand cases, worked out by hand
   Check ("ab", "ba", 2);            --  "abab" contains "ba"
   Check ("abcd", "cdabcdab", 3);    --  "abcdabcdabcd"
   Check ("a", "aa", 2);
   Check ("abc", "wxyz", 0);
   Check ("abc", "c", 1);
   Check ("abc", "ca", 2);
   Check ("a", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 32);
   Check ("ab", "aa", 0);
   for K in 1 .. 20_000 loop
      declare
         LA : constant Positive := 1 + Next (5);
         LB : constant Positive := 1 + Next (11);
      begin
         for I in 1 .. LA loop
            A (I) := Character'Val (Character'Pos ('a') + Next (1));
         end loop;
         --  half the targets are cut out of a repetition of A, so matches are common
         if Next (1) = 0 then
            declare
               Off : constant Natural := Next (LA - 1);
            begin
               for J in 1 .. LB loop
                  B (J) := A ((Off + J - 1) mod LA + 1);
               end loop;
            end;
         else
            for J in 1 .. LB loop
               B (J) := Character'Val (Character'Pos ('a') + Next (1));
            end loop;
         end if;
         Repeat_Count (A, B, LA, LB, Result);
         Assert (Result = Reference (A, B, LA, LB), "random case" & K'Image);
         Cases := Cases + 1;
      end;
   end loop;
   Ada.Text_IO.Put_Line ("PASS Ada-SPARK-Repeated-String-Match (" & Natural'Image (Cases + 10)
                         & " cases, own brute-force reference)");
end Tests;
