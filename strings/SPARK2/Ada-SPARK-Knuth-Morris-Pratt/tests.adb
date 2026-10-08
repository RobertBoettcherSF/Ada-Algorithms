pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with KMP; use KMP;
procedure Tests is
   Pat : constant Char_Array := ('A', 'A', 'B');
   Pi  : Prefix_Table (1 .. 3);

   --  Reference: Pi (I) = length of the longest proper prefix of
   --  Pat (1 .. I) that is also a suffix of it (direct definition, O(n^3)).
   function Reference (P : Char_Array; I : Positive) return Natural is
   begin
      for L in reverse 1 .. I - 1 loop
         if P (1 .. L) = P (I - L + 1 .. I) then
            return L;
         end if;
      end loop;
      return 0;
   end Reference;

   function Matches_Reference (P : Char_Array) return Boolean is
      T : Prefix_Table (1 .. P'Last);
   begin
      Build_Prefix (P, T);
      for I in P'Range loop
         if T (I) /= Reference (P, I) then
            return False;
         end if;
      end loop;
      return True;
   end Matches_Reference;

   --  Every pattern of length 1 .. Max_Len_Tested over Alphabet.
   function All_Patterns_Match (Alphabet : String; Max_Len_Tested : Positive)
     return Boolean
   is
      K : constant Positive := Alphabet'Length;
   begin
      for N in 1 .. Max_Len_Tested loop
         declare
            Code : Natural := 0;
            Total : constant Natural := K ** N;
         begin
            while Code < Total loop
               declare
                  P : Char_Array (1 .. N);
                  C : Natural := Code;
               begin
                  for I in P'Range loop
                     P (I) := Alphabet (Alphabet'First + C mod K);
                     C := C / K;
                  end loop;
                  if not Matches_Reference (P) then
                     Put_Line ("FAIL prefix table differs for " & String (P));
                     return False;
                  end if;
               end;
               Code := Code + 1;
            end loop;
         end;
      end loop;
      return True;
   end All_Patterns_Match;

   procedure Check_Table (P : Char_Array; Expect : Prefix_Table; Name : String) is
      T : Prefix_Table (1 .. P'Last);
   begin
      Build_Prefix (P, T);
      Assert (T = Expect, Name);
      Put_Line ("PASS " & Name);
   end Check_Table;
begin
   Build_Prefix (Pat, Pi);
   Assert (Pi (1) = 0);
   Assert (Pi (2) = 1);
   Assert (Pi (3) = 0);
   Put_Line ("PASS KMP.Build_Prefix");
   --  Textbook tables (CLRS 32.4; Wikipedia "Knuth-Morris-Pratt algorithm")
   Check_Table ("ABABCABAB", [0, 0, 1, 2, 0, 1, 2, 3, 4], "ABABCABAB");
   Check_Table ("AABAACAABAA", [0, 1, 0, 1, 2, 0, 1, 2, 3, 4, 5], "AABAACAABAA");
   Check_Table ("ABACABABC", [0, 0, 1, 0, 1, 2, 3, 2, 0], "ABACABABC (fallback twice)");
   Check_Table ("AAAA", [0, 1, 2, 3], "AAAA (last entry)");
   Check_Table ("ABCD", [0, 0, 0, 0], "ABCD (mismatch with Len = 0)");
   Assert (All_Patterns_Match ("AB", 10), "all A/B patterns of length 1 .. 10");
   Put_Line ("PASS all A/B patterns of length 1 .. 10 match the definition");
   Assert (All_Patterns_Match ("ABC", 7), "all A/B/C patterns of length 1 .. 7");
   Put_Line ("PASS all A/B/C patterns of length 1 .. 7 match the definition");
   Put_Line ("All KMP SPARK topic tests passed.");
end Tests;
