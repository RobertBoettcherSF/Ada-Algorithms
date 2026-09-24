--  Damerau_Levenshtein_Distance body — three-row OSA / restricted DL DP.

pragma Ada_2022;

package body Damerau_Levenshtein_Distance is

   subtype Index is Natural range 0 .. Max_Len;
   type DP_Row is array (Index) of Natural;

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

   function Nat_Min3 (X, Y, Z : Natural) return Natural is
     (Nat_Min (X, Nat_Min (Y, Z)));

   --  Three-row OSA DP with Outer on the outer loop and Inner on the row
   --  axis. Caller may arrange Inner to be the shorter string.
   --  Prev2 = D(i-2, ·), Prev = D(i-1, ·), Curr = D(i, ·).
   function Distance_Rows (Outer, Inner : String) return Natural is
      M     : constant Natural := Outer'Length;
      N     : constant Natural := Inner'Length;
      Prev2 : DP_Row := [others => 0];
      Prev  : DP_Row := [others => 0];
      Curr  : DP_Row := [others => 0];
      Cost  : Natural;
   begin
      --  D(0, j) = j
      for J in 0 .. N loop
         Prev (J) := J;
      end loop;

      for I in 1 .. M loop
         Curr (0) := I;  -- D(i, 0) = i
         for J in 1 .. N loop
            if Char_At (Outer, I) = Char_At (Inner, J) then
               Cost := 0;
            else
               Cost := 1;
            end if;
            --  delete / insert / substitute-or-match
            Curr (J) := Nat_Min3
              (Prev (J) + 1,
               Curr (J - 1) + 1,
               Prev (J - 1) + Cost);
            --  Adjacent transposition (OSA): A[i]=B[j-1] and A[i-1]=B[j]
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
   end Distance_Rows;

   function Distance (A, B : String) return Natural is
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

      --  Put the shorter string on the inner axis (smaller active row span).
      if M <= N then
         return Distance_Rows (Outer => B, Inner => A);
      else
         return Distance_Rows (Outer => A, Inner => B);
      end if;
   end Distance;

   function Similarity (A, B : String) return Float is
      D     : Natural;
      Denom : Natural;
   begin
      Check_Bounds (A, B);

      if A'Length = 0 and then B'Length = 0 then
         return 1.0;
      end if;

      D := Distance (A, B);
      Denom := Natural'Max (A'Length, B'Length);
      return 1.0 - Float (D) / Float (Denom);
   end Similarity;

end Damerau_Levenshtein_Distance;
