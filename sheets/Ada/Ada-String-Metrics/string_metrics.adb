--  String_Metrics body — self-contained survey implementations.

pragma Ada_2022;

package body String_Metrics is

   subtype Index is Natural range 0 .. Max_Len;
   type DP_Row is array (Index) of Natural;

   subtype Flag_Index is Natural range 0 .. Max_Len;
   type Flag_Array is array (Flag_Index range <>) of Boolean;

   subtype Bigram is String (1 .. 2);
   type Bigram_Array is array (Positive range <>) of Bigram;

   procedure Check_Bounds (A, B : String) is
   begin
      if A'Length > Max_Len or else B'Length > Max_Len then
         raise Invalid_Argument;
      end if;
   end Check_Bounds;

   --  Character of S at 1-based logical position P (works for any S'First).
   function Char_At (S : String; P : Positive) return Character is
     (S (S'First + (P - 1)));

   function Nat_Min (X, Y : Natural) return Natural is
     (if X <= Y then X else Y);

   function Nat_Max (X, Y : Natural) return Natural is
     (if X >= Y then X else Y);

   function Nat_Min3 (X, Y, Z : Natural) return Natural is
     (Nat_Min (X, Nat_Min (Y, Z)));

   ---------------------------------------------------------------------------
   -- Levenshtein (two-row Wagner–Fischer)
   ---------------------------------------------------------------------------

   function Levenshtein_Rows (Outer, Inner : String) return Natural is
      M    : constant Natural := Outer'Length;
      N    : constant Natural := Inner'Length;
      Prev : DP_Row := [others => 0];
      Curr : DP_Row := [others => 0];
      Cost : Natural;
   begin
      for J in 0 .. N loop
         Prev (J) := J;
      end loop;

      for I in 1 .. M loop
         Curr (0) := I;
         for J in 1 .. N loop
            if Char_At (Outer, I) = Char_At (Inner, J) then
               Cost := 0;
            else
               Cost := 1;
            end if;
            Curr (J) := Nat_Min3
              (Prev (J) + 1,
               Curr (J - 1) + 1,
               Prev (J - 1) + Cost);
         end loop;
         Prev := Curr;
      end loop;

      return Prev (N);
   end Levenshtein_Rows;

   function Levenshtein (A, B : String) return Natural is
      M : constant Natural := A'Length;
      N : constant Natural := B'Length;
   begin
      Check_Bounds (A, B);

      if M = 0 then
         return N;
      end if;
      if N = 0 then
         return M;
      end if;

      if M <= N then
         return Levenshtein_Rows (Outer => B, Inner => A);
      else
         return Levenshtein_Rows (Outer => A, Inner => B);
      end if;
   end Levenshtein;

   ---------------------------------------------------------------------------
   -- Damerau–Levenshtein OSA (three-row restricted DL)
   ---------------------------------------------------------------------------

   function OSA_Rows (Outer, Inner : String) return Natural is
      M     : constant Natural := Outer'Length;
      N     : constant Natural := Inner'Length;
      Prev2 : DP_Row := [others => 0];
      Prev  : DP_Row := [others => 0];
      Curr  : DP_Row := [others => 0];
      Cost  : Natural;
   begin
      for J in 0 .. N loop
         Prev (J) := J;
      end loop;

      for I in 1 .. M loop
         Curr (0) := I;
         for J in 1 .. N loop
            if Char_At (Outer, I) = Char_At (Inner, J) then
               Cost := 0;
            else
               Cost := 1;
            end if;
            Curr (J) := Nat_Min3
              (Prev (J) + 1,
               Curr (J - 1) + 1,
               Prev (J - 1) + Cost);
            if I > 1 and then J > 1
              and then Char_At (Outer, I) = Char_At (Inner, J - 1)
              and then Char_At (Outer, I - 1) = Char_At (Inner, J)
            then
               Curr (J) := Nat_Min (Curr (J), Prev2 (J - 2) + Cost);
            end if;
         end loop;
         Prev2 := Prev;
         Prev  := Curr;
      end loop;

      return Prev (N);
   end OSA_Rows;

   function Damerau_Levenshtein_OSA (A, B : String) return Natural is
      M : constant Natural := A'Length;
      N : constant Natural := B'Length;
   begin
      Check_Bounds (A, B);

      if M = 0 then
         return N;
      end if;
      if N = 0 then
         return M;
      end if;

      if M <= N then
         return OSA_Rows (Outer => B, Inner => A);
      else
         return OSA_Rows (Outer => A, Inner => B);
      end if;
   end Damerau_Levenshtein_OSA;

   ---------------------------------------------------------------------------
   -- Hamming
   ---------------------------------------------------------------------------

   function Hamming (A, B : String) return Natural is
      Diff : Natural := 0;
   begin
      Check_Bounds (A, B);

      if A'Length /= B'Length then
         raise Invalid_Argument;
      end if;

      for I in 1 .. A'Length loop
         if Char_At (A, I) /= Char_At (B, I) then
            Diff := Diff + 1;
         end if;
      end loop;

      return Diff;
   end Hamming;

   ---------------------------------------------------------------------------
   -- Jaro–Winkler
   ---------------------------------------------------------------------------

   function Match_Window (Len_A, Len_B : Natural) return Natural is
      M : constant Natural := Nat_Max (Len_A, Len_B);
      W : Integer;
   begin
      W := Integer (M / 2) - 1;
      if W < 0 then
         return 0;
      else
         return Natural (W);
      end if;
   end Match_Window;

   function Common_Prefix_Len (A, B : String) return Natural is
      Limit : constant Natural :=
        Nat_Min (4, Nat_Min (A'Length, B'Length));
      Count : Natural := 0;
   begin
      for K in 1 .. Limit loop
         if Char_At (A, K) = Char_At (B, K) then
            Count := Count + 1;
         else
            exit;
         end if;
      end loop;
      return Count;
   end Common_Prefix_Len;

   function Jaro_Similarity_Internal (A, B : String) return Float is
      Len_A  : constant Natural := A'Length;
      Len_B  : constant Natural := B'Length;
      Window : Natural;
      Matches : Natural := 0;
      Half_Transpositions : Natural := 0;
      K : Natural;
      Start_J, End_J : Natural;
      M_F, T_F : Float;
   begin
      if Len_A = 0 and then Len_B = 0 then
         return 1.0;
      end if;
      if Len_A = 0 or else Len_B = 0 then
         return 0.0;
      end if;

      if Len_A = Len_B then
         declare
            Same : Boolean := True;
         begin
            for I in 1 .. Len_A loop
               if Char_At (A, I) /= Char_At (B, I) then
                  Same := False;
                  exit;
               end if;
            end loop;
            if Same then
               return 1.0;
            end if;
         end;
      end if;

      Window := Match_Window (Len_A, Len_B);

      declare
         A_Matched : Flag_Array (1 .. Len_A) := [others => False];
         B_Matched : Flag_Array (1 .. Len_B) := [others => False];
      begin
         for I in 1 .. Len_A loop
            Start_J := Nat_Max (1, (if I > Window then I - Window else 1));
            End_J := Nat_Min (Len_B, I + Window);
            for J in Start_J .. End_J loop
               if not B_Matched (J)
                 and then Char_At (A, I) = Char_At (B, J)
               then
                  A_Matched (I) := True;
                  B_Matched (J) := True;
                  Matches := Matches + 1;
                  exit;
               end if;
            end loop;
         end loop;

         if Matches = 0 then
            return 0.0;
         end if;

         K := 1;
         for I in 1 .. Len_A loop
            if A_Matched (I) then
               while K <= Len_B and then not B_Matched (K) loop
                  K := K + 1;
               end loop;
               if K <= Len_B then
                  if Char_At (A, I) /= Char_At (B, K) then
                     Half_Transpositions := Half_Transpositions + 1;
                  end if;
                  K := K + 1;
               end if;
            end if;
         end loop;

         M_F := Float (Matches);
         T_F := Float (Half_Transpositions) / 2.0;
         return (M_F / Float (Len_A)
                 + M_F / Float (Len_B)
                 + (M_F - T_F) / M_F) / 3.0;
      end;
   end Jaro_Similarity_Internal;

   function Jaro_Winkler_Similarity
     (A, B : String; P : Float := 0.1) return Float
   is
      Sim_J : Float;
      Ell   : Natural;
   begin
      Check_Bounds (A, B);

      if A'Length = 0 and then B'Length = 0 then
         return 1.0;
      end if;
      if A'Length = 0 or else B'Length = 0 then
         return 0.0;
      end if;

      Sim_J := Jaro_Similarity_Internal (A, B);
      Ell := Common_Prefix_Len (A, B);
      return Sim_J + Float (Ell) * P * (1.0 - Sim_J);
   end Jaro_Winkler_Similarity;

   ---------------------------------------------------------------------------
   -- Dice (unique character bigrams)
   ---------------------------------------------------------------------------

   function Window2 (S : String; P : Positive) return Bigram is
      F : constant Positive := S'First + (P - 1);
   begin
      return S (F .. F + 1);
   end Window2;

   procedure Collect_Unique
     (S     : String;
      Buf   : out Bigram_Array;
      Count : out Natural)
   is
      Occ : constant Natural :=
        (if S'Length < 2 then 0 else S'Length - 1);
      Local : Bigram_Array (Buf'Range) := [others => "  "];
   begin
      Count := 0;
      for P in 1 .. Occ loop
         declare
            T     : constant Bigram := Window2 (S, P);
            Found : Boolean := False;
         begin
            for J in 1 .. Count loop
               if Local (J) = T then
                  Found := True;
                  exit;
               end if;
            end loop;
            if not Found then
               Count := Count + 1;
               Local (Count) := T;
            end if;
         end;
      end loop;
      Buf := Local;
   end Collect_Unique;

   function Member (Set : Bigram_Array; T : Bigram) return Boolean is
   begin
      for J in Set'Range loop
         if Set (J) = T then
            return True;
         end if;
      end loop;
      return False;
   end Member;

   function Intersection_Size (A, B : Bigram_Array) return Natural is
      N : Natural := 0;
   begin
      for I in A'Range loop
         if Member (B, A (I)) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Intersection_Size;

   function Dice_Bigram (A, B : String) return Float is
      Buf_A : Bigram_Array (1 .. Natural'Max (1, A'Length));
      Buf_B : Bigram_Array (1 .. Natural'Max (1, B'Length));
      NA, NB, Inter : Natural;
      Denom : Float;
   begin
      Check_Bounds (A, B);

      if A'Length = 0 and then B'Length = 0 then
         return 1.0;
      end if;

      if A'Length = 0 or else B'Length = 0 then
         return 0.0;
      end if;

      Collect_Unique (A, Buf_A, NA);
      Collect_Unique (B, Buf_B, NB);
      Inter := Intersection_Size (Buf_A (1 .. NA), Buf_B (1 .. NB));
      Denom := Float (NA + NB);

      if Denom <= 0.0 then
         return 0.0;
      end if;

      return 2.0 * Float (Inter) / Denom;
   end Dice_Bigram;

   ---------------------------------------------------------------------------
   -- Normalized Levenshtein similarity
   ---------------------------------------------------------------------------

   function Normalized_Levenshtein_Similarity (A, B : String) return Float is
      D     : Natural;
      Denom : Natural;
   begin
      Check_Bounds (A, B);

      if A'Length = 0 and then B'Length = 0 then
         return 1.0;
      end if;

      D := Levenshtein (A, B);
      Denom := Nat_Max (A'Length, B'Length);
      return 1.0 - Float (D) / Float (Denom);
   end Normalized_Levenshtein_Similarity;

end String_Metrics;
