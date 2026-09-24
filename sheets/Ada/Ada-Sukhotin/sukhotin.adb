--  Sukhotin — package body (classic vowel / consonant classification).

pragma Ada_2022;

package body Sukhotin
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Alphabet helpers
   -------------------------------------------------------------------------

   function Is_Alphabetic (C : Character) return Boolean is
   begin
      return C in 'A' .. 'Z' or else C in 'a' .. 'z';
   end Is_Alphabetic;

   function To_Lower_Letter (C : Character) return Letter_Char is
   begin
      if C in 'a' .. 'z' then
         return C;
      elsif C in 'A' .. 'Z' then
         return Character'Val
           (Character'Pos (C) - Character'Pos ('A') + Character'Pos ('a'));
      else
         raise Invalid_Argument;
      end if;
   end To_Lower_Letter;

   function Char_To_Index (C : Letter_Char) return Letter_Index is
   begin
      return Character'Pos (C) - Character'Pos ('a');
   end Char_To_Index;

   function Index_To_Char (I : Letter_Index) return Letter_Char is
   begin
      return Character'Val (Character'Pos ('a') + I);
   end Index_To_Char;

   -------------------------------------------------------------------------
   -- Adjacency
   -------------------------------------------------------------------------

   function Empty_Adjacency return Adjacency_Matrix is
      A : constant Adjacency_Matrix := [others => [others => 0]];
   begin
      return A;
   end Empty_Adjacency;

   function Build_Adjacency (Text : String) return Adjacency_Matrix is
      A        : Adjacency_Matrix := Empty_Adjacency;
      Prev     : Integer := -1;  -- previous letter index, or -1 = none
      Curr     : Letter_Index;
      C        : Character;
   begin
      for K in Text'Range loop
         C := Text (K);
         if Is_Alphabetic (C) then
            Curr := Char_To_Index (To_Lower_Letter (C));
            if Prev >= 0 and then Prev /= Integer (Curr) then
               --  Undirected contact: increment both off-diagonal cells.
               A (Letter_Index (Prev), Curr) :=
                 A (Letter_Index (Prev), Curr) + 1;
               A (Curr, Letter_Index (Prev)) :=
                 A (Curr, Letter_Index (Prev)) + 1;
            end if;
            Prev := Integer (Curr);
         else
            --  Non-letter breaks the adjacency stream (word boundary).
            Prev := -1;
         end if;
      end loop;
      return A;
   end Build_Adjacency;

   function Is_Symmetric (A : Adjacency_Matrix) return Boolean is
   begin
      for I in Letter_Index loop
         if A (I, I) /= 0 then
            return False;
         end if;
         for J in Letter_Index loop
            if A (I, J) /= A (J, I) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Symmetric;

   function Adjacency_Get
     (A : Adjacency_Matrix; I, J : Letter_Index) return Count_Value is
   begin
      return A (I, J);
   end Adjacency_Get;

   function Adjacency_Get
     (A : Adjacency_Matrix; X, Y : Letter_Char) return Count_Value is
   begin
      return A (Char_To_Index (X), Char_To_Index (Y));
   end Adjacency_Get;

   -------------------------------------------------------------------------
   -- Scores
   -------------------------------------------------------------------------

   function Initial_Scores (A : Adjacency_Matrix) return Score_Vector is
      S   : Score_Vector := [others => 0];
      Acc : Score_Value;
   begin
      for I in Letter_Index loop
         Acc := 0;
         for J in Letter_Index loop
            Acc := Acc + Score_Value (A (I, J));
         end loop;
         S (I) := Acc;
      end loop;
      return S;
   end Initial_Scores;

   function Near
     (Left, Right : Score_Value;
      Tol         : Natural := 0) return Boolean
   is
      Diff : Score_Value;
   begin
      if Left >= Right then
         Diff := Left - Right;
      else
         Diff := Right - Left;
      end if;
      return Diff <= Score_Value (Tol);
   end Near;

   -------------------------------------------------------------------------
   -- Core algorithm
   -------------------------------------------------------------------------

   function Run_Sukhotin (A : Adjacency_Matrix) return Classification is
      Result    : Classification;
      S         : Score_Vector := Initial_Scores (A);
      Selected  : Bool_Array := [others => False];
      Remaining : Natural := Max_Symbols;
      Best_I    : Letter_Index;
      Best_S    : Score_Value;
      Found     : Boolean;
   begin
      Result.Is_Vowel    := [others => False];
      Result.Final_Score := S;
      Result.Vowel_Count := 0;

      while Remaining > 0 loop
         --  Pick unmarked letter with maximum positive score (ties: lowest I).
         Found  := False;
         Best_I := 0;
         Best_S := 0;
         for I in Letter_Index loop
            if not Selected (I) and then S (I) > 0 then
               if not Found or else S (I) > Best_S then
                  Found  := True;
                  Best_I := I;
                  Best_S := S (I);
               end if;
            end if;
         end loop;

         exit when not Found;

         --  Promote Best_I to vowel.
         Selected (Best_I)      := True;
         Result.Is_Vowel (Best_I) := True;
         Result.Vowel_Count     := Result.Vowel_Count + 1;
         Remaining              := Remaining - 1;

         --  Classic update: for every other unmarked letter K,
         --  S[K] := S[K] - 2 * A[Best_I, K].
         for K in Letter_Index loop
            if not Selected (K) then
               S (K) := S (K) - 2 * Score_Value (A (Best_I, K));
            end if;
         end loop;

         Result.Final_Score := S;
         --  Preserve the score at selection time for the chosen vowel.
         Result.Final_Score (Best_I) := Best_S;
      end loop;

      --  Residual scores for consonants (and any never-updated cells).
      for I in Letter_Index loop
         if not Result.Is_Vowel (I) then
            Result.Final_Score (I) := S (I);
         end if;
      end loop;

      return Result;
   end Run_Sukhotin;

   function Classify_Text (Text : String) return Classification is
   begin
      return Run_Sukhotin (Build_Adjacency (Text));
   end Classify_Text;

   function Is_Vowel
     (C : Classification; Letter : Character) return Boolean is
   begin
      if not Is_Alphabetic (Letter) then
         return False;
      end if;
      return C.Is_Vowel (Char_To_Index (To_Lower_Letter (Letter)));
   end Is_Vowel;

   function Is_Consonant
     (C : Classification; Letter : Character) return Boolean is
   begin
      if not Is_Alphabetic (Letter) then
         return False;
      end if;
      return not C.Is_Vowel (Char_To_Index (To_Lower_Letter (Letter)));
   end Is_Consonant;

   function Vowel_Set (C : Classification) return String is
      Buf : String (1 .. Max_Symbols);
      N   : Natural := 0;
   begin
      for I in Letter_Index loop
         if C.Is_Vowel (I) then
            N := N + 1;
            Buf (N) := Index_To_Char (I);
         end if;
      end loop;
      return Buf (1 .. N);
   end Vowel_Set;

   function Consonant_Set (C : Classification) return String is
      Buf : String (1 .. Max_Symbols);
      N   : Natural := 0;
   begin
      for I in Letter_Index loop
         if not C.Is_Vowel (I) then
            N := N + 1;
            Buf (N) := Index_To_Char (I);
         end if;
      end loop;
      return Buf (1 .. N);
   end Consonant_Set;

   function Score_Of
     (C : Classification; Letter : Character) return Score_Value is
   begin
      if not Is_Alphabetic (Letter) then
         return 0;
      end if;
      return C.Final_Score (Char_To_Index (To_Lower_Letter (Letter)));
   end Score_Of;

   function Score_Vector_Of (C : Classification) return Score_Vector is
   begin
      return C.Final_Score;
   end Score_Vector_Of;

   function Vowel_Count (C : Classification) return Natural is
   begin
      return C.Vowel_Count;
   end Vowel_Count;

end Sukhotin;
