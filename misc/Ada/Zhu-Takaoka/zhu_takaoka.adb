--  Zhu_Takaoka body — digram bad-character + Boyer–Moore good-suffix.
--  Algorithm after Charras & Lecroq (Exact String Matching Algorithms),
--  http://www-igm.univ-mlv.fr/~lecroq/string/node20.html

pragma Ada_2022;

package body Zhu_Takaoka is

   function Ord (C : Character) return Alphabet_Index is
   begin
      return Character'Pos (C);
   end Ord;

   function Max_Nat (A, B : Natural) return Natural is
   begin
      if A >= B then
         return A;
      end if;
      return B;
   end Max_Nat;

   procedure Check_Bounds (Pattern, Text : String) is
   begin
      if Pattern'Length = 0 then
         raise Invalid_Argument with "empty pattern";
      end if;
      if Pattern'Length > Max_Pattern_Length then
         raise Invalid_Argument with "pattern too long";
      end if;
      if Text'Length > Max_Text_Length then
         raise Invalid_Argument with "text too long";
      end if;
   end Check_Bounds;

   ---------------------------------------------------------------------------
   -- Naive oracle
   ---------------------------------------------------------------------------

   function Naive_Search (Pattern, Text : String) return Match_Index_Array is
      M : constant Natural := Pattern'Length;
      N : constant Natural := Text'Length;
   begin
      Check_Bounds (Pattern, Text);

      if M > N then
         declare
            Empty : Match_Index_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      declare
         Max_Hits : constant Natural := N - M + 1;
         Buf      : Match_Index_Array (1 .. Max_Hits);
         Count    : Natural := 0;
         PF       : constant Positive := Pattern'First;
         TF       : constant Positive := Text'First;
         Ok       : Boolean;
      begin
         for Start in 0 .. N - M loop
            Ok := True;
            for K in 0 .. M - 1 loop
               if Pattern (PF + K) /= Text (TF + Start + K) then
                  Ok := False;
                  exit;
               end if;
            end loop;
            if Ok then
               Count := Count + 1;
               Buf (Count) := Start + 1;
            end if;
         end loop;
         return Buf (1 .. Count);
      end;
   end Naive_Search;

   ---------------------------------------------------------------------------
   -- Zhu–Takaoka
   ---------------------------------------------------------------------------

   function Search (Pattern, Text : String) return Match_Index_Array is
      M  : constant Natural := Pattern'Length;
      N  : constant Natural := Text'Length;
      PF : constant Positive := Pattern'First;
      TF : constant Positive := Text'First;

      type Gs_Array is array (Natural range <>) of Natural;
      type Suff_Array is array (Natural range <>) of Natural;
      type Zt_Table is
        array (Alphabet_Index, Alphabet_Index) of Natural;

      procedure Pre_Zt_Bc (Zt : out Zt_Table) is
      begin
         for A in Alphabet_Index loop
            for B in Alphabet_Index loop
               Zt (A, B) := M;
            end loop;
         end loop;
         for A in Alphabet_Index loop
            Zt (A, Ord (Pattern (PF))) := M - 1;
         end loop;
         for I in 1 .. M - 2 loop
            --  C: for i = 1; i < m-1; ++i
            --     ztBc[x[i-1]][x[i]] = m-1-i
            Zt (Ord (Pattern (PF + I - 1)), Ord (Pattern (PF + I))) :=
              M - 1 - I;
         end loop;
      end Pre_Zt_Bc;

      procedure Suffixes (Suff : out Suff_Array) is
         F, G : Integer := 0;
         I    : Integer;
      begin
         Suff (M - 1) := M;
         G := M - 1;
         I := M - 2;
         while I >= 0 loop
            if I > G and then Suff (I + M - 1 - F) < Natural (I - G) then
               Suff (I) := Suff (I + M - 1 - F);
            else
               if I < G then
                  G := I;
               end if;
               F := I;
               while G >= 0
                 and then Pattern (PF + G) =
                          Pattern (PF + G + M - 1 - F)
               loop
                  G := G - 1;
               end loop;
               Suff (I) := Natural (F - G);
            end if;
            I := I - 1;
         end loop;
      end Suffixes;

      procedure Pre_Bm_Gs (Bm_Gs : out Gs_Array) is
         Suff : Suff_Array (0 .. M - 1);
         J    : Natural := 0;
      begin
         Suffixes (Suff);

         for I in 0 .. M - 1 loop
            Bm_Gs (I) := M;
         end loop;

         J := 0;
         for I in reverse 0 .. M - 1 loop
            if Suff (I) = I + 1 then
               while J < M - 1 - I loop
                  if Bm_Gs (J) = M then
                     Bm_Gs (J) := M - 1 - I;
                  end if;
                  J := J + 1;
               end loop;
            end if;
         end loop;

         for I in 0 .. M - 2 loop
            Bm_Gs (M - 1 - Suff (I)) := M - 1 - I;
         end loop;
      end Pre_Bm_Gs;

   begin
      Check_Bounds (Pattern, Text);

      if M > N then
         declare
            Empty : Match_Index_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      --  Single-character pattern: digram shift is undefined (needs m≥2).
      --  Fall back to a linear scan (still exported as Search).
      if M = 1 then
         declare
            Max_Hits : constant Natural := N;
            Buf      : Match_Index_Array (1 .. Max_Hits);
            Count    : Natural := 0;
            C        : constant Character := Pattern (PF);
         begin
            for Start in 0 .. N - 1 loop
               if Text (TF + Start) = C then
                  Count := Count + 1;
                  Buf (Count) := Start + 1;
               end if;
            end loop;
            return Buf (1 .. Count);
         end;
      end if;

      declare
         Zt        : Zt_Table;
         Bm_Gs     : Gs_Array (0 .. M - 1);
         Max_Hits  : constant Natural := N - M + 1;
         Buf       : Match_Index_Array (1 .. Max_Hits);
         Count     : Natural := 0;
         J         : Natural := 0;
         I         : Integer;
         Shift     : Natural;
      begin
         Pre_Zt_Bc (Zt);
         Pre_Bm_Gs (Bm_Gs);

         while J <= N - M loop
            I := M - 1;
            while I >= 0
              and then Pattern (PF + I) = Text (TF + J + I)
            loop
               I := I - 1;
            end loop;

            if I < 0 then
               Count := Count + 1;
               Buf (Count) := J + 1;
               J := J + Bm_Gs (0);
            else
               Shift :=
                 Max_Nat
                   (Bm_Gs (I),
                    Zt
                      (Ord (Text (TF + J + M - 2)),
                       Ord (Text (TF + J + M - 1))));
               J := J + Shift;
            end if;
         end loop;

         return Buf (1 .. Count);
      end;
   end Search;

end Zhu_Takaoka;
