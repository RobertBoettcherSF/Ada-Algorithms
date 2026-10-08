--  Own checks (see tests/SOURCES.txt). Assume Phonetic_Algorithms is wrong or
--  does nothing; compare every encoder with tests/vectors.txt, written by
--  tools/vv/sweep_phonetic_ref.py: our own reference encoders (whole-string
--  rewrites / a context-window transducer, written from the published rule
--  lists), with Soundex cross-checked against jellyfish 1.1.0 (MIT).
--  Columns: word|soundex|nysiis|metaphone|mra, '!' = Invalid_Argument.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Phonetic_Algorithms; use Phonetic_Algorithms;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;
   F        : File_Type;

   procedure Expect (Cond : Boolean; What : String) is
   begin
      Checked := Checked + 1;
      if not Cond then
         Failures := Failures + 1;
         if Failures <= 25 then
            Put_Line ("  FAIL own: " & What);
         end if;
      end if;
   end Expect;

   type Encoder is access function (S : String) return String;

   procedure Check_One (Name : String; Enc : Encoder; Word, Want : String) is
   begin
      declare
         Got : constant String := Enc (Word);
      begin
         Expect (Want /= "!" and then Got = Want,
                 Name & " (""" & Word & """) = """ & Got & """, reference """ & Want & """");
      end;
   exception
      when Invalid_Argument =>
         Expect (Want = "!", Name & " (""" & Word & """) raised Invalid_Argument, reference """ & Want & """");
   end Check_One;

   type Matcher is access function (A, B : String) return Boolean;

   procedure Check_Match (Name : String; M : Matcher; A, B, Code_A, Code_B : String) is
      Want_Raise : constant Boolean := Code_A = "!" or else Code_B = "!";
   begin
      declare
         Got : constant Boolean := M (A, B);   --  may raise
      begin
         Expect (not Want_Raise and then Got = (Code_A = Code_B),
                 Name & " (""" & A & """, """ & B & """)");
      end;
   exception
      when Invalid_Argument =>
         Expect (Want_Raise, Name & " (""" & A & """, """ & B & """) raised Invalid_Argument");
   end Check_Match;

   Prev_Word : Unbounded_String;
   Prev_Code : array (1 .. 3) of Unbounded_String;
   Have_Prev : Boolean := False;
   Lines     : Natural := 0;
begin
   Open (F, In_File, "tests/vectors.txt");
   while not End_Of_File (F) loop
      declare
         L : constant String := Get_Line (F);
         P : array (1 .. 4) of Natural;
         Start : Positive := L'First;
      begin
         for K in P'Range loop
            P (K) := Ada.Strings.Fixed.Index (L (Start .. L'Last), "|");
            Start := P (K) + 1;
         end loop;
         declare
            Word : constant String := L (L'First .. P (1) - 1);
            Sx   : constant String := L (P (1) + 1 .. P (2) - 1);
            Ny   : constant String := L (P (2) + 1 .. P (3) - 1);
            Me   : constant String := L (P (3) + 1 .. P (4) - 1);
            Mr   : constant String := L (P (4) + 1 .. L'Last);
         begin
            Lines := Lines + 1;
            Check_One ("Soundex", Soundex'Access, Word, Sx);
            Check_One ("NYSIIS", NYSIIS'Access, Word, Ny);
            Check_One ("Metaphone", Metaphone'Access, Word, Me);
            Check_One ("Match_Rating_Encode", Match_Rating_Encode'Access, Word, Mr);
            --  equality helpers on consecutive rows (and on the row with itself)
            if Have_Prev then
               Check_Match ("Codes_Match_Soundex", Codes_Match_Soundex'Access,
                            To_String (Prev_Word), Word, To_String (Prev_Code (1)), Sx);
               Check_Match ("Codes_Match_NYSIIS", Codes_Match_NYSIIS'Access,
                            To_String (Prev_Word), Word, To_String (Prev_Code (2)), Ny);
               Check_Match ("Codes_Match_Metaphone", Codes_Match_Metaphone'Access,
                            To_String (Prev_Word), Word, To_String (Prev_Code (3)), Me);
            end if;
            Check_Match ("Codes_Match_Soundex", Codes_Match_Soundex'Access, Word, Word, Sx, Sx);
            Check_Match ("Codes_Match_NYSIIS", Codes_Match_NYSIIS'Access, Word, Word, Ny, Ny);
            Check_Match ("Codes_Match_Metaphone", Codes_Match_Metaphone'Access, Word, Word, Me, Me);
            Prev_Word := To_Unbounded_String (Word);
            Prev_Code := [To_Unbounded_String (Sx), To_Unbounded_String (Ny), To_Unbounded_String (Me)];
            Have_Prev := True;
         end;
      end;
   end loop;
   Close (F);
   --  empty / overlong / exactly Max_Len inputs (spec: Invalid_Argument when
   --  empty or longer than Max_Len)
   declare
      Long_Ok  : constant String (1 .. Max_Len) := [others => 'B'];
      Too_Long : constant String (1 .. Max_Len + 1) := [others => 'B'];
      type Encoders is array (1 .. 4) of Encoder;
      All_Enc  : constant Encoders := [Soundex'Access, NYSIIS'Access, Metaphone'Access, Match_Rating_Encode'Access];
   begin
      Check_One ("Soundex", Soundex'Access, Long_Ok, "B000");
      Check_One ("NYSIIS", NYSIIS'Access, Long_Ok, "B");
      Check_One ("Metaphone", Metaphone'Access, Long_Ok, "B");
      Check_One ("Match_Rating_Encode", Match_Rating_Encode'Access, Long_Ok, "B");
      for E of All_Enc loop
         Check_One ("encoder", E, Too_Long, "!");
         Check_One ("encoder", E, "", "!");
         Check_One ("encoder", E, "12 -", "!");
      end loop;
   end;
   --  published examples (tests/metaphone_published.txt, Apache Commons Codec
   --  MetaphoneTest, Apache-2.0): word / code pairs and groups of names that
   --  must share one code
   Open (F, In_File, "tests/metaphone_published.txt");
   while not End_Of_File (F) loop
      declare
         L : constant String := Get_Line (F);
      begin
         if L'Length > 2 and then L (L'First) = 'P' then
            declare
               Sp : constant Natural := Ada.Strings.Fixed.Index (L (L'First + 2 .. L'Last), " ");
            begin
               Check_One ("Metaphone (published)", Metaphone'Access, L (L'First + 2 .. Sp - 1), L (Sp + 1 .. L'Last));
            end;
         elsif L'Length > 2 and then L (L'First) = 'G' then
            declare
               Start : Positive := L'First + 2;
               Sp    : Natural;
               First : Unbounded_String;
            begin
               loop
                  Sp := Ada.Strings.Fixed.Index (L (Start .. L'Last), " ");
                  declare
                     Name : constant String := L (Start .. (if Sp = 0 then L'Last else Sp - 1));
                  begin
                     if First = Null_Unbounded_String then
                        First := To_Unbounded_String (Name);
                     else
                        Expect (Codes_Match_Metaphone (To_String (First), Name)
                                and then Codes_Match_Metaphone (Name, To_String (First)),
                                "Metaphone (published) group: " & To_String (First) & " ~ " & Name);
                     end if;
                  end;
                  exit when Sp = 0;
                  Start := Sp + 1;
               end loop;
            end;
         end if;
      end;
   end loop;
   Close (F);
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Checked'Image & " encodings of" & Lines'Image & " words (tests/vectors.txt)");
end Own_Checks;
