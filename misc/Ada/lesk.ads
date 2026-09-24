--  Lesk — Ada 2023 educational package for Wikipedia "Lesk algorithm"
--  (word-sense disambiguation). Michael E. Lesk, SIGDOC 1986: Automatic
--  sense disambiguation using machine readable dictionaries — how to tell
--  a pine cone from an ice cream cone. Classic premise: words in a local
--  neighborhood tend to share a topic; choose the sense whose dictionary
--  gloss overlaps the context (Simplified Lesk) or other words' glosses
--  (Original Lesk). In-memory mini dictionary only — no WordNet dependency.
--  Built-in Wikipedia pine / cone fixture.

pragma Ada_2022;

package Lesk
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity
   ---------------------------------------------------------------------------

   Max_Token_Length : constant Positive := 64;
   Max_Tokens       : constant Positive := 128;
   Max_Senses       : constant Positive := 8;
   Max_Gloss_Length : constant Positive := 256;
   Max_Word_Length  : constant Positive := 64;
   Max_Stopwords    : constant Positive := 64;
   Max_Dict_Entries : constant Positive := 32;
   Max_Context_Words : constant Positive := 16;

   subtype Token_Length is Natural range 0 .. Max_Token_Length;
   subtype Token_Count  is Natural range 0 .. Max_Tokens;
   subtype Sense_Cardinality is Natural range 0 .. Max_Senses;
   subtype Gloss_Length is Natural range 0 .. Max_Gloss_Length;
   subtype Word_Length  is Natural range 0 .. Max_Word_Length;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised on oversize input or empty target with no senses.

   ---------------------------------------------------------------------------
   -- Tokens
   ---------------------------------------------------------------------------

   type Token is private;
   --  Lowercase alphabetic word (length-bounded).

   type Token_List is private;
   --  Ordered list of tokens (capacity Max_Tokens). Overlap uses the
   --  *set* of distinct tokens (duplicates do not increase the score).

   function Empty_Tokens return Token_List
     with Global => null;

   function Token_Length_Of (T : Token) return Token_Length
     with Global => null;

   function To_String (T : Token) return String
     with Global => null;
   --  Exact characters of T (length = Token_Length_Of (T)).

   function Make_Token (S : String) return Token
     with Global => null;
   --  Lowercase alphabetic content of S into a Token.
   --  Raises Invalid_Argument if the result would exceed Max_Token_Length
   --  or if S yields no letters.

   function Length (List : Token_List) return Token_Count
     with Global => null;

   function Element (List : Token_List; Index : Positive) return Token
     with Pre => Index <= Length (List),
          Global => null;

   function Contains (List : Token_List; T : Token) return Boolean
     with Global => null;

   function Append (List : Token_List; T : Token) return Token_List
     with Global => null;
   --  Append T if capacity allows; raises Invalid_Argument if full.

   ---------------------------------------------------------------------------
   -- Stopwords
   ---------------------------------------------------------------------------

   type Stopword_List is private;

   function Empty_Stopwords return Stopword_List
     with Global => null;

   function Default_Stopwords return Stopword_List
     with Global => null;
   --  Small English function-word list: a, an, the, of, to, in, on, for,
   --  and, or, with, from, by, as, at, is, are, was, were, be, this,
   --  that, which, whether, something, certain, kinds, through.

   function Is_Stopword (S : String; Stops : Stopword_List) return Boolean
     with Global => null;

   function Add_Stopword (Stops : Stopword_List; Word : String)
     return Stopword_List
     with Global => null;

   function Filter_Stopwords
     (List  : Token_List;
      Stops : Stopword_List) return Token_List
     with Global => null;
   --  Drop tokens that appear in Stops (case already folded in tokens).

   ---------------------------------------------------------------------------
   -- Tokenize / Overlap
   ---------------------------------------------------------------------------

   function To_Lower (C : Character) return Character
     with Global => null;

   function To_Lower (S : String) return String
     with Global => null;
   --  Raises Invalid_Argument if S'Length > Max_Gloss_Length.

   function Is_Letter (C : Character) return Boolean
     with Global => null;

   function Tokenize (Text : String) return Token_List
     with Global => null;
   --  Split Text into lowercase alphabetic runs (non-letters are separators).
   --  Hyphens and punctuation break tokens (needle-shaped → needle, shaped).
   --  Raises Invalid_Argument if any token exceeds Max_Token_Length or the
   --  list would exceed Max_Tokens.

   function Tokenize
     (Text  : String;
      Stops : Stopword_List) return Token_List
     with Global => null;
   --  Tokenize then Filter_Stopwords.

   function Unique_Tokens (List : Token_List) return Token_List
     with Global => null;
   --  First-occurrence set (preserves order of first sighting).

   function Overlap (A, B : Token_List) return Natural
     with Global => null;
   --  |set(A) ∩ set(B)| — number of distinct shared tokens.
   --  Symmetric: Overlap (A, B) = Overlap (B, A).

   function Overlap_Count (Gloss, Context : String) return Natural
     with Global => null;
   --  Overlap (Tokenize (Gloss), Tokenize (Context)) — no stopword filter.
   --  Wikipedia pine#1 ∩ cone#3 uses this form (shared "of","evergreen"=2).

   function Overlap_Count
     (Gloss, Context : String;
      Stops          : Stopword_List) return Natural
     with Global => null;
   --  Overlap after filtering Stops from both sides.

   function Near (A, B : Integer; Tol : Natural := 0) return Boolean
     with Global => null;
   --  |A - B| <= Tol.

   ---------------------------------------------------------------------------
   -- Dictionary types
   ---------------------------------------------------------------------------

   type Sense is record
      Gloss : String (1 .. Max_Gloss_Length) := [others => ' '];
      Len   : Gloss_Length := 0;
   end record;
   --  One dictionary sense: a gloss string (examples may be concatenated
   --  into Gloss by the caller). Empty when Len = 0.

   type Sense_Array is array (1 .. Max_Senses) of Sense;

   type Dictionary_Entry is record
      Word        : String (1 .. Max_Word_Length) := [others => ' '];
      Word_Len    : Word_Length := 0;
      Senses      : Sense_Array;
      Sense_Count : Sense_Cardinality := 0;
   end record;
   --  Headword plus ordered senses (1 .. Sense_Count). Sense indices are
   --  1-based; ties in scoring pick the lowest index.

   type Entry_Array is array (1 .. Max_Dict_Entries) of Dictionary_Entry;

   type Dictionary is record
      Entries : Entry_Array;
      Count   : Natural := 0;
   end record;

   function Make_Sense (Gloss : String) return Sense
     with Global => null;
   --  Raises Invalid_Argument if Gloss'Length > Max_Gloss_Length.

   function Gloss_Of (S : Sense) return String
     with Global => null;

   function Make_Entry
     (Word   : String;
      Gloss1 : String;
      Gloss2 : String := "";
      Gloss3 : String := "";
      Gloss4 : String := "") return Dictionary_Entry
     with Global => null;
   --  Convenience builder: non-empty glosses become senses 1..N in order.

   function Word_Of (E : Dictionary_Entry) return String
     with Global => null;

   function Find_Entry
     (Dict : Dictionary;
      Word : String) return Natural
     with Global => null;
   --  1-based index of Word in Dict (case-insensitive), or 0 if absent.

   ---------------------------------------------------------------------------
   -- Simplified Lesk
   ---------------------------------------------------------------------------

   function Sense_Overlap
     (S       : Sense;
      Context : Token_List) return Natural
     with Global => null;
   --  Overlap (Tokenize (Gloss_Of (S)), Context).

   function Best_Sense_Index
     (Item    : Dictionary_Entry;
      Context : Token_List) return Natural
     with Global => null;
   --  Argmax_i Overlap (sense_i, Context). Ties → lowest index (first sense).
   --  If Sense_Count = 0, returns 0. If all overlaps are 0, returns 1
   --  (most-frequent / first-sense backoff, Vasilescu-style).

   function Best_Sense_Index
     (Item    : Dictionary_Entry;
      Context : String) return Natural
     with Global => null;
   --  Tokenize Context (no stop filter) then Best_Sense_Index.

   function Simplified_Lesk
     (Item           : Dictionary_Entry;
      Sentence       : String;
      Exclude_Target : Boolean := True;
      Stops          : Stopword_List := Empty_Stopwords) return Natural
     with Global => null;
   --  Classic Simplified Lesk (Kilgarriff & Rosenzweig / Vasilescu):
   --    context ← tokens of Sentence, optionally dropping the headword and
   --    stopwords; score each sense gloss against that context set; return
   --    Best_Sense_Index. Result is a 1-based sense index, or 0 if no senses.

   function Simplified_Lesk_Score
     (Item     : Dictionary_Entry;
      Context  : Token_List;
      Index    : Positive) return Natural
     with Pre => Index <= Item.Sense_Count,
          Global => null;
   --  Overlap score of sense Index alone.

   ---------------------------------------------------------------------------
   -- Original Lesk-style (small / educational)
   ---------------------------------------------------------------------------

   function Original_Lesk
     (Target_Entry : Dictionary_Entry;
      Context_Entries : Dictionary;
      Stops : Stopword_List := Empty_Stopwords) return Natural
     with Global => null;
   --  For each sense S of Target_Entry, score(S) = sum over each other
   --  Dictionary_Entry C in Context_Entries of
   --    max_j Overlap (Gloss(S), Gloss(C.sense_j)) after optional Stops.
   --  Self-entry matching Target_Entry.Word is skipped. Argmax with
   --  lowest-index tie-break; first-sense backoff if all scores 0.
   --  Intended for tiny dictionaries (e.g. pine + cone).

   ---------------------------------------------------------------------------
   -- Wikipedia pine cone fixture
   ---------------------------------------------------------------------------

   --  PINE
   --   1. kinds of evergreen tree with needle-shaped leaves
   --   2. waste away through sorrow or illness
   --  CONE
   --   1. solid body which narrows to a point
   --   2. something of this shape whether solid or hollow
   --   3. fruit of certain evergreen trees
   --  Pine #1 ∩ Cone #3 = 2  ("of", "evergreen") with raw Overlap_Count.

   function Pine_Entry return Dictionary_Entry
     with Global => null;

   function Cone_Entry return Dictionary_Entry
     with Global => null;

   function Pine_Cone_Dictionary return Dictionary
     with Global => null;
   --  Two-entry dictionary: pine then cone.

   procedure Pine_Cone_Demo
     (Pine_Sense : out Natural;
      Cone_Sense : out Natural;
      Gloss_Overlap : out Natural)
     with Global => null;
   --  Gloss_Overlap := Overlap_Count (pine#1, cone#3)  [= 2].
   --  Pine_Sense := Simplified_Lesk on pine with evergreen/tree/cone context.
   --  Cone_Sense := Simplified_Lesk on cone with evergreen/pine/fruit context.
   --  Expected: Pine_Sense = 1, Cone_Sense = 3, Gloss_Overlap = 2.

   Pine_Gloss_1 : constant String :=
     "kinds of evergreen tree with needle-shaped leaves";
   Pine_Gloss_2 : constant String :=
     "waste away through sorrow or illness";
   Cone_Gloss_1 : constant String :=
     "solid body which narrows to a point";
   Cone_Gloss_2 : constant String :=
     "something of this shape whether solid or hollow";
   Cone_Gloss_3 : constant String :=
     "fruit of certain evergreen trees";

   --  Contexts used by Pine_Cone_Demo / Simplified Lesk vignettes.
   Pine_Context_Sentence : constant String :=
     "the evergreen tree produces a cone";
   Cone_Context_Sentence : constant String :=
     "evergreen pine tree fruit";

private

   type Token is record
      Data : String (1 .. Max_Token_Length) := [others => ' '];
      Len  : Token_Length := 0;
   end record;

   type Token_Storage is array (1 .. Max_Tokens) of Token;

   type Token_List is record
      Items : Token_Storage;
      Count : Token_Count := 0;
   end record;

   type Stopword_Storage is array (1 .. Max_Stopwords) of Token;

   type Stopword_List is record
      Items : Stopword_Storage;
      Count : Natural := 0;
   end record;

end Lesk;
