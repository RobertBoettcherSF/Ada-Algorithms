--  Aho_Corasick — Ada 2023 educational package for Wikipedia
--  "Aho–Corasick algorithm" (Alfred V. Aho & Margaret J. Corasick, 1975).
--  Multi-pattern dictionary matching: build a trie of the dictionary, add
--  failure (suffix) links and output (dictionary-suffix) links by BFS, then
--  scan the text once. Complexity is linear in the total pattern length plus
--  the text length plus the number of reported matches. Reports every
--  occurrence, including overlaps and patterns that are suffixes of others.
--  Reference: https://en.wikipedia.org/wiki/Aho–Corasick_algorithm

pragma Ada_2022;

with Ada.Strings.Unbounded;

package Aho_Corasick
  with SPARK_Mode => Off
is

   package U renames Ada.Strings.Unbounded;
   subtype Unbounded_String is U.Unbounded_String;
   function To_Unbounded_String (S : String) return Unbounded_String
     renames U.To_Unbounded_String;
   function To_String (S : Unbounded_String) return String
     renames U.To_String;
   function Length (S : Unbounded_String) return Natural
     renames U.Length;

   ---------------------------------------------------------------------------
   -- Capacity / alphabet
   ---------------------------------------------------------------------------

   --  Educational bounds (tests stay well below these). Max_Nodes must cover
   --  one root plus at most one new node per pattern character inserted.
   Max_Patterns    : constant Positive := 64;
   Max_Pattern_Len : constant Positive := 128;
   Max_Nodes       : constant Positive := 2_048;
   Max_Text_Length : constant Positive := 10_000;
   Max_Matches     : constant Positive := 50_000;

   --  Full Latin-1 / 8-bit Character set: |Σ| = 256.
   Alphabet_Size : constant Positive := 256;

   subtype Alphabet_Index is Natural range 0 .. Alphabet_Size - 1;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when the pattern list is empty, any individual pattern is
   --  empty, a pattern / the list exceeds Max_Patterns or Max_Pattern_Len,
   --  the trie would need more than Max_Nodes, Text exceeds Max_Text_Length,
   --  or more than Max_Matches hits would be reported. Empty text with a
   --  valid automaton is allowed and yields no matches.

   ---------------------------------------------------------------------------
   -- Patterns and matches (1-based indexing throughout)
   ---------------------------------------------------------------------------

   --  Pattern_Index I means Patterns (Patterns'First + I - 1).
   type Pattern_Array is array (Positive range <>) of Unbounded_String;

   --  One reported hit. Pattern_Index is 1-based into the Build pattern
   --  list. End_Position is the 1-based index of the last matched character
   --  in Text viewed as 1 .. Text'Length (i.e. Text (Text'First +
   --  End_Position - 1)). Start_Position = End_Position - Length + 1.
   type Match is record
      Pattern_Index  : Positive;
      Start_Position : Positive;
      End_Position   : Positive;
   end record;

   type Match_List is array (Positive range <>) of Match;

   ---------------------------------------------------------------------------
   -- Automaton
   ---------------------------------------------------------------------------

   type Automaton is private;

   function Build (Patterns : Pattern_Array) return Automaton;
   --  Insert every pattern into a trie, then BFS-compute failure (suffix)
   --  links and output (dictionary-suffix) links. Raises Invalid_Argument
   --  on an empty list, an empty pattern, or capacity overflow.

   function Pattern_Count (A : Automaton) return Natural;
   --  Number of patterns stored in A.

   function Node_Count (A : Automaton) return Positive;
   --  Number of trie nodes (including the root). Always >= 1.

   function Pattern_Length (A : Automaton; Index : Positive) return Positive;
   --  Length of pattern Index (1-based). Raises Invalid_Argument if Index
   --  is out of range for A.

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Search (A : Automaton; Text : String) return Match_List;
   --  Single left-to-right scan of Text. At each character follow the goto
   --  transition (or failure links until one exists), then emit every
   --  pattern reachable via the output-link chain. Returns all hits
   --  (overlaps and suffix patterns included), ordered by ascending
   --  End_Position then ascending Pattern_Index. Raises Invalid_Argument
   --  if Text exceeds Max_Text_Length. Empty text → empty result.

   function Naive_Search
     (Patterns : Pattern_Array;
      Text     : String) return Match_List;
   --  Brute-force multi-pattern oracle for tests: for each pattern, scan
   --  every alignment. Same empty-list / empty-pattern / length rules as
   --  Build + Search. Result ordering matches Search.

   --  Convenience: build a Pattern_Array from ordinary Strings.
   function Patterns (P1 : String) return Pattern_Array;
   function Patterns (P1, P2 : String) return Pattern_Array;
   function Patterns (P1, P2, P3 : String) return Pattern_Array;
   function Patterns (P1, P2, P3, P4 : String) return Pattern_Array;
   function Patterns (P1, P2, P3, P4, P5 : String) return Pattern_Array;
   function Patterns
     (P1, P2, P3, P4, P5, P6 : String) return Pattern_Array;
   function Patterns
     (P1, P2, P3, P4, P5, P6, P7 : String) return Pattern_Array;

private

   --  Node 1 is the root. Transition / link value 0 means "none".
   subtype Node_Id is Natural range 0 .. Max_Nodes;

   type Transition_Row is array (Alphabet_Index) of Node_Id;
   type Transition_Table is array (1 .. Max_Nodes) of Transition_Row;
   type Node_Array is array (1 .. Max_Nodes) of Node_Id;
   type Length_Array is array (1 .. Max_Patterns) of Natural;
   type Output_Head_Array is array (1 .. Max_Nodes) of Natural;
   type Output_Pat_Array is array (1 .. Max_Patterns) of Positive;
   type Output_Next_Array is array (1 .. Max_Patterns) of Natural;

   type Automaton is record
      Nodes        : Node_Id := 1;
      Patterns     : Natural := 0;
      Lengths      : Length_Array := [others => 0];
      Goto_Table   : Transition_Table := [others => [others => 0]];
      Fail         : Node_Array := [others => 0];
      Out_Link     : Node_Array := [others => 0];
      Output_Head  : Output_Head_Array := [others => 0];
      Output_Pat   : Output_Pat_Array := [others => 1];
      Output_Next  : Output_Next_Array := [others => 0];
      Output_Slots : Natural := 0;
   end record;

end Aho_Corasick;
