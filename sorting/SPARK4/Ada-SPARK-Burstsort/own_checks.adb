--  Own tests for Burstsort (Sort) (written for this repository; see
--  tests/SOURCES.txt). Assumption: the sort is wrong, loses or invents
--  strings, or does nothing. Expected results come only from two
--  properties of a correct sort, checked independently of how the code
--  sorts and of the package's own "<": the output is nondecreasing under
--  Ada's predefined String order on Data (1 .. Length), and every string
--  occurs in the output exactly as often as in the input (occurrence
--  counts, no sorting). Inputs stress the burst recursion: many strings
--  with long shared prefixes (bursts at every depth), strings that end at
--  the shared prefix, more than Burst_Threshold equal strings of full
--  length (the Depth = Max_String_Len return), all 256 characters, and
--  junk characters stored after Length (they must be ignored).
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Environment_Variables;
with Burstsort; use Burstsort;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;
   --  Fixed default seed, printed at start; AA_SEED overrides it.
   subtype Seed_Range is Long_Long_Integer range 1 .. 2_147_483_646;
   Default_Seed : constant Seed_Range := 20_261_008;
   function Initial_Seed return Seed_Range is
     (if Ada.Environment_Variables.Exists ("AA_SEED")
      then Seed_Range'Value (Ada.Environment_Variables.Value ("AA_SEED"))
      else Default_Seed);
   Seed : Long_Long_Integer := Initial_Seed;
   function Next (Lo, Hi : Long_Long_Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Lo + Seed mod (Hi - Lo + 1));
   end Next;

   function Text (B : Bounded_String) return String is
     (B.Data (1 .. B.Length));

   function Count (A : String_Array; V : Bounded_String) return Natural is
      N : Natural := 0;
   begin
      for X of A loop
         if Text (X) = Text (V) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count;

   procedure Check (Input : String_Array; What : String) is
      A  : String_Array := Input;
      Ok : Boolean := True;
   begin
      Sort (A);
      for I in A'First .. A'Last - 1 loop
         if not (Text (A (I)) <= Text (A (I + 1))) then
            Ok := False;
         end if;
      end loop;
      for X of Input loop
         if Count (A, X) /= Count (Input, X) then
            Ok := False;
         end if;
      end loop;
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put ("FAIL Sort (" & What & "):");
            for X of Input loop
               Put (" """ & Text (X) & """");
            end loop;
            New_Line;
         end if;
      end if;
   end Check;

   --  A string of length Len over the characters First .. First + Width - 1,
   --  with random junk after Len when Junk is set.
   function Random_String
     (Len : Natural; First : Character; Width : Positive; Junk : Boolean)
      return Bounded_String
   is
      B : Bounded_String;
   begin
      B.Length := Len;
      for I in 1 .. Len loop
         B.Data (I) := Character'Val
           (Character'Pos (First) + Next (0, Long_Long_Integer (Width - 1)));
      end loop;
      if Junk then
         for I in Len + 1 .. Max_String_Len loop
            B.Data (I) := Character'Val (Next (0, 255));
         end loop;
      end if;
      return B;
   end Random_String;

   Words : constant String_Array :=
     [Make (""), Make ("a"), Make ("b"), Make ("aa"), Make ("ab"),
      Make ("ba")];
   Full : constant String := "abcdefghijklmnop";

begin
   Put_Line ("own checks seed:" & Seed'Image & " (default"
             & Default_Seed'Image & "; set AA_SEED to override)");
   --  1. Every array of length 0 .. 5 over six short words (9,331 arrays:
   --     ties, prefixes, empty strings).
   for Len in 0 .. 5 loop
      for Code in 0 .. 6 ** Len - 1 loop
         declare
            A : String_Array (1 .. Len);
         begin
            for I in A'Range loop
               A (I) := Words (1 + (Code / 6 ** (I - 1)) mod 6);
            end loop;
            Check (A, "words");
         end;
      end loop;
   end loop;
   --  2. Every permutation of seven strings that are prefixes of each
   --     other or differ late (5,040, Heap's method). Seven strings exceed
   --     Burst_Threshold, so each call bursts.
   declare
      P : String_Array (1 .. 7) :=
        [Make ("abc"), Make ("ab"), Make ("abd"), Make ("a"), Make ("b"),
         Make (""), Make ("abcd")];
      C : array (1 .. 7) of Natural := [others => 0];
      I : Positive := 2;
      T : Bounded_String;
   begin
      Check (P, "permutation");
      while I <= 7 loop
         if C (I) < I - 1 then
            if I mod 2 = 1 then
               T := P (1); P (1) := P (I); P (I) := T;
            else
               T := P (C (I) + 1); P (C (I) + 1) := P (I); P (I) := T;
            end if;
            Check (P, "permutation");
            C (I) := C (I) + 1;
            I := 2;
         else
            C (I) := 0;
            I := I + 1;
         end if;
      end loop;
   end;
   --  3. Random arrays of length 0 .. Max_N in six modes: two letters
   --     and lengths 0 .. Max_String_Len (deep shared prefixes), all 256
   --     characters, a long shared prefix plus a short random tail, full
   --     length differing only in the last character, equal full-length
   --     strings with a few others, and strings of a random prefix of
   --     one word; junk after Length in every other array.
   for K in 1 .. 1_500 loop
      declare
         A    : String_Array (1 .. Next (0, Long_Long_Integer (Max_N)));
         Mode : constant Integer := Next (0, 5);
         Junk : constant Boolean := K mod 2 = 0;
      begin
         for I in A'Range loop
            case Mode is
               when 0 =>
                  A (I) := Random_String
                    (Next (0, Long_Long_Integer (Max_String_Len)), 'a', 2, Junk);
               when 1 =>
                  A (I) := Random_String
                    (Next (0, Long_Long_Integer (Max_String_Len)),
                     Character'First, 256, Junk);
               when 2 =>
                  A (I) := Random_String (Next (10, 14), 'x', 2, Junk);
                  A (I).Data (1 .. 10) := "prefixpref";
               when 3 =>
                  A (I) := Random_String (Max_String_Len, 'a', 3, Junk);
                  A (I).Data (1 .. Max_String_Len - 1) := Full (1 .. 15);
               when 4 =>
                  if Next (0, 3) = 0 then
                     A (I) := Random_String
                       (Next (0, Long_Long_Integer (Max_String_Len)), 'a', 16,
                        Junk);
                  else
                     A (I) := Make (Full);
                  end if;
               when others =>
                  A (I) := Random_String
                    (Next (0, Long_Long_Integer (Max_String_Len)), 'a', 1, Junk);
                  if A (I).Length > 0 then
                     A (I).Data (1 .. A (I).Length) := Full (1 .. A (I).Length);
                  end if;
            end case;
         end loop;
         Check (A, "random" & K'Image);
      end;
   end loop;
   --  4. Full length: Max_N equal full strings, Max_N prefixes of one word
   --     in descending length, descending single letters, Character'Last
   --     against Character'First.
   declare
      A : String_Array (1 .. Max_N);
   begin
      A := [others => Make (Full)];
      Check (A, "all equal full");
      for I in A'Range loop
         A (I) := Make (Full (1 .. (Max_N - I) mod (Max_String_Len + 1)));
      end loop;
      Check (A, "nested prefixes full");
      for I in A'Range loop
         A (I) := Make ([Character'Val (Character'Pos ('z') - (I - 1) mod 26)]);
      end loop;
      Check (A, "descending letters full");
      for I in A'Range loop
         A (I) := Make ((if I mod 2 = 0 then [Character'Last, Character'First]
                         else [Character'First, Character'Last]));
      end loop;
      Check (A, "extreme characters full");
   end;

   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " sort calls (nondecreasing + occurrence counts)");
end Own_Checks;
