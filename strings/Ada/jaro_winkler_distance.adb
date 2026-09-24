--  Jaro_Winkler_Distance body — Jaro matching window + Winkler prefix boost.

pragma Ada_2022;

package body Jaro_Winkler_Distance is

   subtype Flag_Index is Natural range 0 .. Max_Len;
   type Flag_Array is array (Flag_Index range <>) of Boolean;

   procedure Check_Bounds (A, B : String) is
   begin
      if A'Length > Max_Len or else B'Length > Max_Len then
         raise Invalid_Argument;
      end if;
   end Check_Bounds;

   --  Character of S at 1-based logical position P (works for any S'First).
   function Char_At (S : String; P : Positive) return Character is
     (S (S'First + (P - 1)));

   function Nat_Max (X, Y : Natural) return Natural is
     (if X >= Y then X else Y);

   function Nat_Min (X, Y : Natural) return Natural is
     (if X <= Y then X else Y);

   --  Matching window w = floor(max(m,n)/2) − 1, clamped to ≥ 0 so that
   --  length-1 identical strings still match at the same index.
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

   --  Common prefix length capped at 4 (Winkler ℓ).
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

   function Jaro_Similarity (A, B : String) return Float is
      Len_A : constant Natural := A'Length;
      Len_B : constant Natural := B'Length;
      Window : Natural;
      Matches : Natural := 0;
      Half_Transpositions : Natural := 0;
      K : Natural;
      Start_J, End_J : Natural;
      M_F, T_F : Float;
   begin
      Check_Bounds (A, B);

      if Len_A = 0 and then Len_B = 0 then
         return 1.0;
      end if;
      if Len_A = 0 or else Len_B = 0 then
         return 0.0;
      end if;

      --  Fast path: identical nonempty strings.
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
         --  1-based flags aligned with logical positions 1 .. Len_*.
         A_Matched : Flag_Array (1 .. Len_A) := [others => False];
         B_Matched : Flag_Array (1 .. Len_B) := [others => False];
      begin
         --  Greedy matching within the window.
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

         --  Count order mismatches among matched characters; t = count/2.
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
   end Jaro_Similarity;

   function Jaro_Winkler_Similarity
     (A, B : String; P : Float := Default_P) return Float
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

      Sim_J := Jaro_Similarity (A, B);
      Ell := Common_Prefix_Len (A, B);
      return Sim_J + Float (Ell) * P * (1.0 - Sim_J);
   end Jaro_Winkler_Similarity;

   function Jaro_Winkler_Distance
     (A, B : String; P : Float := Default_P) return Float
   is
   begin
      return 1.0 - Jaro_Winkler_Similarity (A, B, P);
   end Jaro_Winkler_Distance;

end Jaro_Winkler_Distance;
