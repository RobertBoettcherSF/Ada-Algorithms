--  Lesk body — Simplified / Original Lesk WSD with in-memory dictionary.

pragma Ada_2022;

package body Lesk is

   ---------------------------------------------------------------------------
   -- Character helpers
   ---------------------------------------------------------------------------

   function To_Lower (C : Character) return Character is
   begin
      if C in 'A' .. 'Z' then
         return Character'Val
           (Character'Pos (C) - Character'Pos ('A') + Character'Pos ('a'));
      end if;
      return C;
   end To_Lower;

   function To_Lower (S : String) return String is
      R : String (S'Range);
   begin
      if S'Length > Max_Gloss_Length then
         raise Invalid_Argument with "string exceeds Max_Gloss_Length";
      end if;
      for I in S'Range loop
         R (I) := To_Lower (S (I));
      end loop;
      return R;
   end To_Lower;

   function Is_Letter (C : Character) return Boolean is
   begin
      return C in 'A' .. 'Z' or else C in 'a' .. 'z';
   end Is_Letter;

   ---------------------------------------------------------------------------
   -- Tokens
   ---------------------------------------------------------------------------

   function Empty_Tokens return Token_List is
      L : Token_List;
   begin
      L.Count := 0;
      return L;
   end Empty_Tokens;

   function Token_Length_Of (T : Token) return Token_Length is
   begin
      return T.Len;
   end Token_Length_Of;

   function To_String (T : Token) return String is
   begin
      return T.Data (1 .. T.Len);
   end To_String;

   function Make_Token (S : String) return Token is
      T : Token;
      N : Natural := 0;
   begin
      for C of S loop
         if Is_Letter (C) then
            N := N + 1;
            if N > Max_Token_Length then
               raise Invalid_Argument with "token exceeds Max_Token_Length";
            end if;
            T.Data (N) := To_Lower (C);
         end if;
      end loop;
      if N = 0 then
         raise Invalid_Argument with "empty token";
      end if;
      T.Len := N;
      return T;
   end Make_Token;

   function Same_Token (A, B : Token) return Boolean is
   begin
      if A.Len /= B.Len then
         return False;
      end if;
      return A.Data (1 .. A.Len) = B.Data (1 .. B.Len);
   end Same_Token;

   function Length (List : Token_List) return Token_Count is
   begin
      return List.Count;
   end Length;

   function Element (List : Token_List; Index : Positive) return Token is
   begin
      return List.Items (Index);
   end Element;

   function Contains (List : Token_List; T : Token) return Boolean is
   begin
      for I in 1 .. List.Count loop
         if Same_Token (List.Items (I), T) then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   function Append (List : Token_List; T : Token) return Token_List is
      R : Token_List := List;
   begin
      if R.Count = Max_Tokens then
         raise Invalid_Argument with "token list full";
      end if;
      R.Count := R.Count + 1;
      R.Items (R.Count) := T;
      return R;
   end Append;

   ---------------------------------------------------------------------------
   -- Stopwords
   ---------------------------------------------------------------------------

   function Empty_Stopwords return Stopword_List is
      S : Stopword_List;
   begin
      S.Count := 0;
      return S;
   end Empty_Stopwords;

   function Add_Stopword
     (Stops : Stopword_List; Word : String) return Stopword_List
   is
      R : Stopword_List := Stops;
      T : Token;
   begin
      if Word'Length = 0 then
         return R;
      end if;
      T := Make_Token (Word);
      if R.Count = Max_Stopwords then
         raise Invalid_Argument with "stopword list full";
      end if;
      for I in 1 .. R.Count loop
         if Same_Token (R.Items (I), T) then
            return R;
         end if;
      end loop;
      R.Count := R.Count + 1;
      R.Items (R.Count) := T;
      return R;
   end Add_Stopword;

   function Default_Stopwords return Stopword_List is
      S : Stopword_List := Empty_Stopwords;
   begin
      S := Add_Stopword (S, "a");
      S := Add_Stopword (S, "an");
      S := Add_Stopword (S, "the");
      S := Add_Stopword (S, "of");
      S := Add_Stopword (S, "to");
      S := Add_Stopword (S, "in");
      S := Add_Stopword (S, "on");
      S := Add_Stopword (S, "for");
      S := Add_Stopword (S, "and");
      S := Add_Stopword (S, "or");
      S := Add_Stopword (S, "with");
      S := Add_Stopword (S, "from");
      S := Add_Stopword (S, "by");
      S := Add_Stopword (S, "as");
      S := Add_Stopword (S, "at");
      S := Add_Stopword (S, "is");
      S := Add_Stopword (S, "are");
      S := Add_Stopword (S, "was");
      S := Add_Stopword (S, "were");
      S := Add_Stopword (S, "be");
      S := Add_Stopword (S, "this");
      S := Add_Stopword (S, "that");
      S := Add_Stopword (S, "which");
      S := Add_Stopword (S, "whether");
      S := Add_Stopword (S, "something");
      S := Add_Stopword (S, "certain");
      S := Add_Stopword (S, "kinds");
      S := Add_Stopword (S, "through");
      return S;
   end Default_Stopwords;

   function Is_Stopword (S : String; Stops : Stopword_List) return Boolean is
      T : Token;
      Has_Letter : Boolean := False;
   begin
      for C of S loop
         if Is_Letter (C) then
            Has_Letter := True;
            exit;
         end if;
      end loop;
      if not Has_Letter then
         return False;
      end if;
      T := Make_Token (S);
      for I in 1 .. Stops.Count loop
         if Same_Token (Stops.Items (I), T) then
            return True;
         end if;
      end loop;
      return False;
   end Is_Stopword;

   function Filter_Stopwords
     (List  : Token_List;
      Stops : Stopword_List) return Token_List
   is
      R : Token_List := Empty_Tokens;
   begin
      for I in 1 .. List.Count loop
         declare
            T : constant Token := List.Items (I);
            Hit : Boolean := False;
         begin
            for J in 1 .. Stops.Count loop
               if Same_Token (Stops.Items (J), T) then
                  Hit := True;
                  exit;
               end if;
            end loop;
            if not Hit then
               R := Append (R, T);
            end if;
         end;
      end loop;
      return R;
   end Filter_Stopwords;

   ---------------------------------------------------------------------------
   -- Tokenize / Unique / Overlap
   ---------------------------------------------------------------------------

   function Tokenize (Text : String) return Token_List is
      List  : Token_List := Empty_Tokens;
      Buf   : String (1 .. Max_Token_Length);
      Buf_N : Natural := 0;

      procedure Flush is
         T : Token;
      begin
         if Buf_N = 0 then
            return;
         end if;
         T.Len := Buf_N;
         T.Data (1 .. Buf_N) := Buf (1 .. Buf_N);
         List := Append (List, T);
         Buf_N := 0;
      end Flush;
   begin
      for C of Text loop
         if Is_Letter (C) then
            if Buf_N >= Max_Token_Length then
               raise Invalid_Argument with "token exceeds Max_Token_Length";
            end if;
            Buf_N := Buf_N + 1;
            Buf (Buf_N) := To_Lower (C);
         else
            Flush;
         end if;
      end loop;
      Flush;
      return List;
   end Tokenize;

   function Tokenize
     (Text  : String;
      Stops : Stopword_List) return Token_List
   is
   begin
      return Filter_Stopwords (Tokenize (Text), Stops);
   end Tokenize;

   function Unique_Tokens (List : Token_List) return Token_List is
      R : Token_List := Empty_Tokens;
   begin
      for I in 1 .. List.Count loop
         if not Contains (R, List.Items (I)) then
            R := Append (R, List.Items (I));
         end if;
      end loop;
      return R;
   end Unique_Tokens;

   function Overlap (A, B : Token_List) return Natural is
      UA : constant Token_List := Unique_Tokens (A);
      UB : constant Token_List := Unique_Tokens (B);
      N  : Natural := 0;
   begin
      for I in 1 .. UA.Count loop
         if Contains (UB, UA.Items (I)) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Overlap;

   function Overlap_Count (Gloss, Context : String) return Natural is
   begin
      return Overlap (Tokenize (Gloss), Tokenize (Context));
   end Overlap_Count;

   function Overlap_Count
     (Gloss, Context : String;
      Stops          : Stopword_List) return Natural
   is
   begin
      return Overlap (Tokenize (Gloss, Stops), Tokenize (Context, Stops));
   end Overlap_Count;

   function Near (A, B : Integer; Tol : Natural := 0) return Boolean is
   begin
      if A >= B then
         return Natural (A - B) <= Tol;
      else
         return Natural (B - A) <= Tol;
      end if;
   end Near;

   ---------------------------------------------------------------------------
   -- Dictionary builders
   ---------------------------------------------------------------------------

   function Make_Sense (Gloss : String) return Sense is
      S : Sense;
   begin
      if Gloss'Length > Max_Gloss_Length then
         raise Invalid_Argument with "gloss exceeds Max_Gloss_Length";
      end if;
      S.Len := Gloss'Length;
      if Gloss'Length > 0 then
         S.Gloss (1 .. Gloss'Length) := Gloss;
      end if;
      return S;
   end Make_Sense;

   function Gloss_Of (S : Sense) return String is
   begin
      return S.Gloss (1 .. S.Len);
   end Gloss_Of;

   procedure Set_Word (E : in out Dictionary_Entry; Word : String) is
      L : constant String := To_Lower (Word);
      N : Natural := 0;
      Buf : String (1 .. Max_Word_Length);
   begin
      --  Keep letters only for the headword key.
      for C of L loop
         if Is_Letter (C) then
            N := N + 1;
            if N > Max_Word_Length then
               raise Invalid_Argument with "word exceeds Max_Word_Length";
            end if;
            Buf (N) := C;
         end if;
      end loop;
      if N = 0 then
         raise Invalid_Argument with "empty word";
      end if;
      E.Word_Len := N;
      E.Word (1 .. N) := Buf (1 .. N);
   end Set_Word;

   function Make_Entry
     (Word   : String;
      Gloss1 : String;
      Gloss2 : String := "";
      Gloss3 : String := "";
      Gloss4 : String := "") return Dictionary_Entry
   is
      E : Dictionary_Entry;
      procedure Add (G : String) is
      begin
         if G'Length = 0 then
            return;
         end if;
         if E.Sense_Count = Max_Senses then
            raise Invalid_Argument with "too many senses";
         end if;
         E.Sense_Count := E.Sense_Count + 1;
         E.Senses (E.Sense_Count) := Make_Sense (G);
      end Add;
   begin
      Set_Word (E, Word);
      Add (Gloss1);
      Add (Gloss2);
      Add (Gloss3);
      Add (Gloss4);
      return E;
   end Make_Entry;

   function Word_Of (E : Dictionary_Entry) return String is
   begin
      return E.Word (1 .. E.Word_Len);
   end Word_Of;

   function Find_Entry
     (Dict : Dictionary;
      Word : String) return Natural
   is
      Key : String (1 .. Max_Word_Length);
      N   : Natural := 0;
      Low : constant String := To_Lower (Word);
   begin
      for C of Low loop
         if Is_Letter (C) then
            N := N + 1;
            if N > Max_Word_Length then
               return 0;
            end if;
            Key (N) := C;
         end if;
      end loop;
      if N = 0 then
         return 0;
      end if;
      for I in 1 .. Dict.Count loop
         if Dict.Entries (I).Word_Len = N
           and then Dict.Entries (I).Word (1 .. N) = Key (1 .. N)
         then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Entry;

   ---------------------------------------------------------------------------
   -- Simplified Lesk
   ---------------------------------------------------------------------------

   function Sense_Overlap
     (S       : Sense;
      Context : Token_List) return Natural
   is
   begin
      return Overlap (Tokenize (Gloss_Of (S)), Context);
   end Sense_Overlap;

   function Best_Sense_Index
     (Item    : Dictionary_Entry;
      Context : Token_List) return Natural
   is
      Best_Idx : Natural := 0;
      Best_Ov  : Integer := -1;
      Ov       : Natural;
   begin
      if Item.Sense_Count = 0 then
         return 0;
      end if;
      for I in 1 .. Item.Sense_Count loop
         Ov := Sense_Overlap (Item.Senses (I), Context);
         if Integer (Ov) > Best_Ov then
            Best_Ov  := Integer (Ov);
            Best_Idx := I;
         end if;
      end loop;
      --  Vasilescu-style first-sense backoff when every overlap is zero.
      if Best_Ov = 0 then
         return 1;
      end if;
      return Best_Idx;
   end Best_Sense_Index;

   function Best_Sense_Index
     (Item    : Dictionary_Entry;
      Context : String) return Natural
   is
   begin
      return Best_Sense_Index (Item, Tokenize (Context));
   end Best_Sense_Index;

   function Simplified_Lesk_Score
     (Item    : Dictionary_Entry;
      Context : Token_List;
      Index   : Positive) return Natural
   is
   begin
      return Sense_Overlap (Item.Senses (Index), Context);
   end Simplified_Lesk_Score;

   function Simplified_Lesk
     (Item           : Dictionary_Entry;
      Sentence       : String;
      Exclude_Target : Boolean := True;
      Stops          : Stopword_List := Empty_Stopwords) return Natural
   is
      Raw  : constant Token_List := Tokenize (Sentence);
      Ctx  : Token_List := Empty_Tokens;
      Head : Token;
      Have_Head : Boolean := False;
   begin
      if Item.Sense_Count = 0 then
         return 0;
      end if;
      if Item.Word_Len > 0 then
         Head.Len := Item.Word_Len;
         Head.Data (1 .. Item.Word_Len) := Item.Word (1 .. Item.Word_Len);
         Have_Head := True;
      end if;
      for I in 1 .. Raw.Count loop
         declare
            T : constant Token := Raw.Items (I);
            Skip : Boolean := False;
         begin
            if Exclude_Target and then Have_Head
              and then Same_Token (T, Head)
            then
               Skip := True;
            end if;
            if not Skip then
               Ctx := Append (Ctx, T);
            end if;
         end;
      end loop;
      if Stops.Count > 0 then
         Ctx := Filter_Stopwords (Ctx, Stops);
      end if;
      return Best_Sense_Index (Item, Ctx);
   end Simplified_Lesk;

   ---------------------------------------------------------------------------
   -- Original Lesk-style
   ---------------------------------------------------------------------------

   function Original_Lesk
     (Target_Entry    : Dictionary_Entry;
      Context_Entries : Dictionary;
      Stops           : Stopword_List := Empty_Stopwords) return Natural
   is
      Best_Idx : Natural := 0;
      Best_Sc  : Integer := -1;
      Score    : Natural;
      Pair_Ov  : Natural;
      Max_Pair : Natural;
      G_T, G_C : Token_List;
   begin
      if Target_Entry.Sense_Count = 0 then
         return 0;
      end if;
      for Si in 1 .. Target_Entry.Sense_Count loop
         Score := 0;
         if Stops.Count > 0 then
            G_T := Tokenize (Gloss_Of (Target_Entry.Senses (Si)), Stops);
         else
            G_T := Tokenize (Gloss_Of (Target_Entry.Senses (Si)));
         end if;
         for Ei in 1 .. Context_Entries.Count loop
            declare
               C : Dictionary_Entry renames Context_Entries.Entries (Ei);
            begin
               if C.Word_Len = Target_Entry.Word_Len
                 and then C.Word (1 .. C.Word_Len) =
                          Target_Entry.Word (1 .. Target_Entry.Word_Len)
               then
                  null;  -- skip self
               else
                  Max_Pair := 0;
                  for Sj in 1 .. C.Sense_Count loop
                     if Stops.Count > 0 then
                        G_C := Tokenize (Gloss_Of (C.Senses (Sj)), Stops);
                     else
                        G_C := Tokenize (Gloss_Of (C.Senses (Sj)));
                     end if;
                     Pair_Ov := Overlap (G_T, G_C);
                     if Pair_Ov > Max_Pair then
                        Max_Pair := Pair_Ov;
                     end if;
                  end loop;
                  Score := Score + Max_Pair;
               end if;
            end;
         end loop;
         if Integer (Score) > Best_Sc then
            Best_Sc  := Integer (Score);
            Best_Idx := Si;
         end if;
      end loop;
      if Best_Sc = 0 then
         return 1;
      end if;
      return Best_Idx;
   end Original_Lesk;

   ---------------------------------------------------------------------------
   -- Pine cone fixture
   ---------------------------------------------------------------------------

   function Pine_Entry return Dictionary_Entry is
   begin
      return Make_Entry ("pine", Pine_Gloss_1, Pine_Gloss_2);
   end Pine_Entry;

   function Cone_Entry return Dictionary_Entry is
   begin
      return Make_Entry ("cone", Cone_Gloss_1, Cone_Gloss_2, Cone_Gloss_3);
   end Cone_Entry;

   function Pine_Cone_Dictionary return Dictionary is
      D : Dictionary;
   begin
      D.Count := 2;
      D.Entries (1) := Pine_Entry;
      D.Entries (2) := Cone_Entry;
      return D;
   end Pine_Cone_Dictionary;

   procedure Pine_Cone_Demo
     (Pine_Sense    : out Natural;
      Cone_Sense    : out Natural;
      Gloss_Overlap : out Natural)
   is
      Pine : constant Dictionary_Entry := Pine_Entry;
      Cone : constant Dictionary_Entry := Cone_Entry;
   begin
      Gloss_Overlap := Overlap_Count (Pine_Gloss_1, Cone_Gloss_3);
      Pine_Sense := Simplified_Lesk (Pine, Pine_Context_Sentence);
      Cone_Sense := Simplified_Lesk (Cone, Cone_Context_Sentence);
   end Pine_Cone_Demo;

end Lesk;
