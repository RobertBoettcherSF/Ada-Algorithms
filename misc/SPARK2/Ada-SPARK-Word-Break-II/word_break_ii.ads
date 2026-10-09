pragma SPARK_Mode (On);
pragma Ada_2022;

package Word_Break_II is
   --  Original 4-symbol exercise (kept for its tests): splits of A (1 .. N)
   --  into single symbols and pairs of equal neighbours.
   subtype Length is Natural range 0 .. 4;
   subtype Symbol is Natural range 0 .. 25;
   subtype Count is Natural range 0 .. 100;
   type Word is array (Positive range 1 .. 4) of Symbol;

   function Segmentations (A : Word; N : Length) return Count
     with Global => null;

   --  Word Break II: all ways to split S (1 .. N) into words of the
   --  dictionary D (1 .. DC) (words used any number of times; a duplicate
   --  dictionary entry adds no sentence). Text up to 12 letters: at most
   --  2 ** 11 sentences, listed as break sets (Breaks (P) = a word ends at P).
   Max_Len       : constant := 12;
   Max_Word_Len  : constant := 12;
   Max_Words     : constant := 50;
   Max_Sentences : constant := 2 ** Max_Len;   --  proved bound is 2 ** N
   subtype Text_Length is Natural range 0 .. Max_Len;
   subtype Position is Positive range 1 .. Max_Len;
   subtype Word_Length is Positive range 1 .. Max_Word_Len;
   subtype Word_Count is Natural range 0 .. Max_Words;
   subtype Sentence_Count is Natural range 0 .. Max_Sentences;
   type Text is array (Position) of Character;
   type Word_Chars is array (Word_Length) of Character;
   type Dict_Word is record
      Chars : Word_Chars := [others => ' '];
      Len   : Word_Length := 1;
   end record;
   type Dictionary is array (1 .. Max_Words) of Dict_Word;
   type Break_Set is array (Position) of Boolean;
   type Sentence_List is array (1 .. Max_Sentences) of Break_Set;

   --  S (P .. P + L - 1) is a dictionary word.
   function In_Dict (S : Text; P : Position; L : Word_Length; D : Dictionary; DC : Word_Count) return Boolean is
     (for some K in 1 .. DC =>
        D (K).Len = L
        and then (for all I in 1 .. L => D (K).Chars (I) = S (P + I - 1)))
     with Global => null, Pre => P + L - 1 <= Max_Len;

   function Count_Sentences (S : Text; N : Text_Length; D : Dictionary; DC : Word_Count)
     return Sentence_Count
     with Global => null;

   procedure Sentences
     (S : Text; N : Text_Length; D : Dictionary; DC : Word_Count;
      List : out Sentence_List; Count : out Sentence_Count)
     with Global => null,
          Post   => Count = Count_Sentences (S, N, D, DC);
private
   --  Ways (P) = number of ways to split S (P .. N) into words; Ways (N + 1) = 1.
   subtype Ext_Position is Positive range 1 .. Max_Len + 1;
   type Way_Table is array (Ext_Position) of Sentence_Count;

   --  Longest word length that fits at P.
   function Max_Here (N : Text_Length; P : Ext_Position) return Natural is
     (Natural'Min (Max_Word_Len, N + 1 - P))
     with Pre => P <= N + 1;

   --  Sum of Ways (P + L') over the word lengths L' in 1 .. L that match at P
   --  (proof only).
   function Partial (S : Text; N : Text_Length; D : Dictionary; DC : Word_Count;
                     Ways : Way_Table; P : Ext_Position; L : Natural) return Long_Long_Integer is
     (if L = 0 then 0
      else Partial (S, N, D, DC, Ways, P, L - 1)
           + (if In_Dict (S, P, L, D, DC) then Long_Long_Integer (Ways (P + L)) else 0))
     with Ghost, Pre => P <= N and then L <= Max_Here (N, P),
          Post => Partial'Result in 0 .. Long_Long_Integer (L) * Max_Sentences,
          Subprogram_Variant => (Decreases => L);

   --  2 ** I (proof only)
   type Pow_Table is array (0 .. 13) of Long_Long_Integer;
   Pow2 : constant Pow_Table :=
     [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192] with Ghost;

   --  Ways is the table of S (1 .. N), D (1 .. DC) from position From on.
   function Is_Table (S : Text; N : Text_Length; D : Dictionary; DC : Word_Count;
                      Ways : Way_Table; From : Ext_Position) return Boolean is
     (From <= N + 1 and then Ways (N + 1) = 1
      and then (for all P in From .. N =>
                  Long_Long_Integer (Ways (P)) = Partial (S, N, D, DC, Ways, P, Max_Here (N, P))
                  and then Long_Long_Integer (Ways (P)) <= Pow2 (N + 1 - P)))
     with Ghost;

   --  The table, by dynamic programming from the end of the text.
   function Table (S : Text; N : Text_Length; D : Dictionary; DC : Word_Count) return Way_Table
     with Global => null, Post => Is_Table (S, N, D, DC, Table'Result, 1);

   function Count_Sentences (S : Text; N : Text_Length; D : Dictionary; DC : Word_Count)
     return Sentence_Count is (Table (S, N, D, DC) (1));
end Word_Break_II;
