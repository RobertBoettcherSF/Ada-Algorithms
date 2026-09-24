--  Substring_Search body — survey sketches of Naive, KMP, Rabin–Karp,
--  and Boyer–Moore–Horspool. Each returns the same 1-based match starts
--  as Naive_Search (overlapping included).

pragma Ada_2022;

package body Substring_Search is

   subtype Hash_Int is Long_Long_Integer;

   function Ord_Hash (C : Character) return Hash_Int is
   begin
      return Hash_Int (Character'Pos (C));
   end Ord_Hash;

   function Ord_Alpha (C : Character) return Alphabet_Index is
   begin
      return Character'Pos (C);
   end Ord_Alpha;

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
   -- LPS / π table (KMP)
   ---------------------------------------------------------------------------

   function Build_LPS (Pattern : String) return LPS_Array is
   begin
      Check_Pattern (Pattern);

      declare
         M   : constant Positive := Pattern'Length;
         PF  : constant Positive := Pattern'First;
         LPS : LPS_Array (1 .. M);
         Len : Natural := 0;
         I   : Positive := 2;
      begin
         LPS (1) := 0;

         while I <= M loop
            if Pattern (PF + I - 1) = Pattern (PF + Len) then
               Len := Len + 1;
               LPS (I) := Len;
               I := I + 1;
            elsif Len /= 0 then
               Len := LPS (Len);
            else
               LPS (I) := 0;
               I := I + 1;
            end if;
         end loop;

         return LPS;
      end;
   end Build_LPS;

   ---------------------------------------------------------------------------
   -- Horspool skip / bad-character table
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

      --  Rightmost occurrence in x[0 .. m-2] wins; last char excluded.
      for I in 0 .. M - 2 loop
         Bc (Ord_Alpha (Pattern (PF + I))) := M - 1 - I;
      end loop;

      return Bc;
   end Build_Bad_Character;

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
   -- Knuth–Morris–Pratt
   ---------------------------------------------------------------------------

   function KMP_Search (Pattern, Text : String) return Match_Index_Array is
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
         LPS      : constant LPS_Array := Build_LPS (Pattern);
         Max_Hits : constant Natural := N - M + 1;
         Buf      : Match_Index_Array (1 .. Max_Hits);
         Count    : Natural := 0;
         I        : Natural := 0;
         J        : Natural := 0;
      begin
         while I < N loop
            if Pattern (PF + J) = Text (TF + I) then
               I := I + 1;
               J := J + 1;
               if J = M then
                  Count := Count + 1;
                  Buf (Count) := I - M + 1;
                  J := LPS (J);
               end if;
            elsif J /= 0 then
               J := LPS (J);
            else
               I := I + 1;
            end if;
         end loop;

         return Buf (1 .. Count);
      end;
   end KMP_Search;

   ---------------------------------------------------------------------------
   -- Rabin–Karp helpers
   ---------------------------------------------------------------------------

   function Window_Hash
     (S      : String;
      First  : Positive;
      Length : Positive;
      Base   : Hash_Int;
      Q      : Hash_Int) return Hash_Int
   is
      H : Hash_Int := 0;
   begin
      for K in 0 .. Length - 1 loop
         H := (H * Base + Ord_Hash (S (First + K))) mod Q;
      end loop;
      return H;
   end Window_Hash;

   function Exact_Match
     (Pattern : String;
      Text    : String;
      Start   : Natural) return Boolean
   is
      PF : constant Positive := Pattern'First;
      TF : constant Positive := Text'First;
      M  : constant Natural  := Pattern'Length;
   begin
      for K in 0 .. M - 1 loop
         if Pattern (PF + K) /= Text (TF + Start + K) then
            return False;
         end if;
      end loop;
      return True;
   end Exact_Match;

   ---------------------------------------------------------------------------
   -- Rabin–Karp
   ---------------------------------------------------------------------------

   function Rabin_Karp_Search
     (Pattern, Text : String;
      Base          : Positive := Default_Base;
      Modulus       : Positive := Default_Modulus)
      return Match_Index_Array
   is
      M  : constant Natural := Pattern'Length;
      N  : constant Natural := Text'Length;
      PF : constant Positive := Pattern'First;
      TF : constant Positive := Text'First;
   begin
      Check_Bounds (Pattern, Text);
      if Modulus < 2 then
         raise Invalid_Argument with "modulus must be >= 2";
      end if;

      if M > N then
         declare
            Empty : Match_Index_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      declare
         Q        : constant Hash_Int := Hash_Int (Modulus);
         B        : constant Hash_Int := Hash_Int (Base) mod Q;
         High_Pow : Hash_Int := 1;
         Pat_Hash : Hash_Int;
         Win_Hash : Hash_Int;
         Max_Hits : constant Natural := N - M + 1;
         Buf      : Match_Index_Array (1 .. Max_Hits);
         Count    : Natural := 0;
         Lead     : Hash_Int;
      begin
         for I in 1 .. M - 1 loop
            High_Pow := (High_Pow * B) mod Q;
         end loop;

         Pat_Hash := Window_Hash (Pattern, PF, M, B, Q);
         Win_Hash := Window_Hash (Text, TF, M, B, Q);

         if Win_Hash = Pat_Hash and then Exact_Match (Pattern, Text, 0) then
            Count := Count + 1;
            Buf (Count) := 1;
         end if;

         for Start in 0 .. N - M - 1 loop
            Lead := (Ord_Hash (Text (TF + Start)) * High_Pow) mod Q;
            Win_Hash := (Win_Hash - Lead) mod Q;
            Win_Hash :=
              (Win_Hash * B + Ord_Hash (Text (TF + Start + M))) mod Q;

            if Win_Hash = Pat_Hash
              and then Exact_Match (Pattern, Text, Start + 1)
            then
               Count := Count + 1;
               Buf (Count) := Start + 2;
            end if;
         end loop;

         return Buf (1 .. Count);
      end;
   end Rabin_Karp_Search;

   ---------------------------------------------------------------------------
   -- Boyer–Moore–Horspool
   ---------------------------------------------------------------------------

   function Boyer_Moore_Horspool_Search
     (Pattern, Text : String) return Match_Index_Array
   is
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
         Max_Hits : constant Natural := N - M + 1;
         Buf      : Match_Index_Array (1 .. Max_Hits);
         Count    : Natural := 0;
         J        : Natural := 0;
         I        : Integer;
         C        : Character;
      begin
         while J <= N - M loop
            C := Text (TF + J + M - 1);

            I := M - 1;
            while I >= 0
              and then Pattern (PF + I) = Text (TF + J + I)
            loop
               I := I - 1;
            end loop;

            if I < 0 then
               Count := Count + 1;
               Buf (Count) := J + 1;
            end if;

            J := J + Bm_Bc (Ord_Alpha (C));
         end loop;

         return Buf (1 .. Count);
      end;
   end Boyer_Moore_Horspool_Search;

   ---------------------------------------------------------------------------
   -- Dispatcher
   ---------------------------------------------------------------------------

   function Search
     (Pattern, Text : String;
      Method        : Search_Method := Naive) return Match_Index_Array
   is
   begin
      case Method is
         when Naive =>
            return Naive_Search (Pattern, Text);
         when KMP =>
            return KMP_Search (Pattern, Text);
         when Rabin_Karp =>
            return Rabin_Karp_Search (Pattern, Text);
         when Boyer_Moore_Horspool =>
            return Boyer_Moore_Horspool_Search (Pattern, Text);
      end case;
   end Search;

end Substring_Search;
