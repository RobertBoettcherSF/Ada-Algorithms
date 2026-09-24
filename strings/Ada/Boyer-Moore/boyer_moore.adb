--  Boyer_Moore body — bad-character + good-suffix (Charras & Lecroq).
--  Algorithm after Exact String Matching Algorithms,
--  http://www-igm.univ-mlv.fr/~lecroq/string/node14.html

pragma Ada_2022;

package body Boyer_Moore is

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

   procedure Check_Pattern (Pattern : String) is
   begin
      if Pattern'Length = 0 then
         raise Invalid_Argument with "empty pattern";
      end if;
      if Pattern'Length > Max_Pattern_Length then
         raise Invalid_Argument with "pattern too long";
      end if;
   end Check_Pattern;

   ---------------------------------------------------------------------------
   -- Bad-character table
   ---------------------------------------------------------------------------

   function Build_Bad_Character (Pattern : String) return Bad_Character_Table
   is
      M  : constant Natural := Pattern'Length;
      PF : constant Positive := Pattern'First;
      Bc : Bad_Character_Table;
   begin
      Check_Pattern (Pattern);

      for C in Alphabet_Index loop
         Bc (C) := M;
      end loop;

      --  Rightmost occurrence in x[0 .. m-2] wins (last write).
      for I in 0 .. M - 2 loop
         Bc (Ord (Pattern (PF + I))) := M - 1 - I;
      end loop;

      return Bc;
   end Build_Bad_Character;

   ---------------------------------------------------------------------------
   -- Good-suffix table (suff + bmGs)
   ---------------------------------------------------------------------------

   function Build_Good_Suffix (Pattern : String) return Good_Suffix_Array is
      M  : constant Natural := Pattern'Length;
      PF : constant Positive := Pattern'First;

      type Suff_Array is array (Natural range <>) of Natural;

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

      Bm_Gs : Good_Suffix_Array (0 .. M - 1);
      Suff  : Suff_Array (0 .. M - 1);
      J     : Natural := 0;
   begin
      Check_Pattern (Pattern);

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

      return Bm_Gs;
   end Build_Good_Suffix;

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
   -- Boyer–Moore search
   ---------------------------------------------------------------------------

   function Search (Pattern, Text : String) return Match_Index_Array is
      M  : constant Natural := Pattern'Length;
      N  : constant Natural := Text'Length;
      PF : constant Positive := Pattern'First;
      TF : constant Positive := Text'First;
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
         Bm_Bc    : constant Bad_Character_Table :=
                      Build_Bad_Character (Pattern);
         Bm_Gs    : constant Good_Suffix_Array :=
                      Build_Good_Suffix (Pattern);
         Max_Hits : constant Natural := N - M + 1;
         Buf      : Match_Index_Array (1 .. Max_Hits);
         Count    : Natural := 0;
         J        : Natural := 0;
         I        : Integer;
         Bc_Shift : Integer;
         Shift    : Natural;
      begin
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
               --  Lecroq: MAX(bmGs[i], bmBc[y[i+j]] - m + 1 + i)
               Bc_Shift :=
                 Integer (Bm_Bc (Ord (Text (TF + J + I))))
                 - Integer (M) + 1 + I;
               if Bc_Shift < 0 then
                  Shift := Bm_Gs (I);
               else
                  Shift :=
                    Max_Nat (Bm_Gs (I), Natural (Bc_Shift));
               end if;
               J := J + Shift;
            end if;
         end loop;

         return Buf (1 .. Count);
      end;
   end Search;

end Boyer_Moore;
