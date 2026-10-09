pragma Ada_2022;
--  Own checks for Subsets_II (see tests/SOURCES.txt). No expected value
--  comes from the program:
--  * brute force: the multiset is written out as a flat list (at most 12
--    items); every one of its 2 ** n index subsets is reduced to how many
--    copies of each value it takes, and the distinct results are marked.
--    Stepping from the empty choice must visit exactly the marked ones,
--    each once, then wrap (Found False) to the empty choice; Count must
--    equal the number of marked ones;
--  * an own mixed-radix rank (first value the lowest digit, base
--    Copies + 1): on seeded random choices with up to 30 items in all,
--    the next choice has rank + 1, and the last one wraps to rank 0;
--  * Count against an own product in Long_Long_Integer for random
--    multisets with up to 30 items in all;
--  * Subset against an own expansion (append Take (I) copies of
--    Values (I), I = 1 .. N).
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Subsets_II; use Subsets_II;

procedure Own_Checks with SPARK_Mode => Off is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Name_Hash return Long_Long_Integer is
      Name : constant String := "Ada-SPARK-Subsets-II";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : constant Long_Long_Integer := (if V = "" then Default else Long_Long_Integer'Value (V));
   begin
      Ada.Text_IO.Put_Line ("AA_SEED =" & S'Image & (if V = "" then " (default: FNV-1a of the folder name)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (Name_Hash);
   function Next return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed);
   end Next;

   --  Random copy counts, at least 1 each, Total items in all at most Limit.
   function Random_Copies (N : Length; Limit : Natural) return Count_List is
      A    : Count_List (1 .. N) := [others => 1];
      Left : Integer := Limit - N;
   begin
      for I in A'Range loop
         exit when Left <= 0;
         declare
            Extra : constant Natural := Next mod (Left + 1) / (if Next mod 2 = 0 then 1 else 3);
         begin
            A (I) := A (I) + Extra;
            Left := Left - Extra;
         end;
      end loop;
      return A;
   end Random_Copies;

   function Own_Rank (Copies, Take : Count_List) return Long_Long_Integer is
      R : Long_Long_Integer := 0;
      W : Long_Long_Integer := 1;
   begin
      for I in Copies'Range loop
         R := R + Long_Long_Integer (Take (I)) * W;
         W := W * Long_Long_Integer (Copies (I) + 1);
      end loop;
      return R;
   end Own_Rank;

   function Own_Product (Copies : Count_List) return Long_Long_Integer is
      P : Long_Long_Integer := 1;
   begin
      for C of Copies loop
         P := P * Long_Long_Integer (C + 1);
      end loop;
      return P;
   end Own_Product;

   function Own_Expand (Values : Item_List; Take : Count_List) return Item_List is
      R : Item_List (1 .. 900);
      L : Natural := 0;
   begin
      for I in Values'Range loop
         for K in 1 .. Take (I) loop
            L := L + 1;
            R (L) := Values (I);
         end loop;
      end loop;
      return R (1 .. L);
   end Own_Expand;
begin
   --  Brute force over index subsets of the flat list.
   for Trial in 1 .. 400 loop
      declare
         N      : constant Length := Next mod 6;
         Copies : constant Count_List := Random_Copies (N, 12);
         Flat   : array (1 .. 12) of Positive;   --  which value each flat item is
         Len    : Natural := 0;
         type Mark_Set is array (Long_Long_Integer range 0 .. 4_095) of Boolean;
         Marked : Mark_Set := [others => False];
         Marks  : Natural := 0;
         Seen   : Mark_Set := [others => False];
         C      : Choice := (N => N, Copies => Copies, Take => [others => 0]);
         Found  : Boolean := True;
         Steps  : Natural := 0;
         Ok     : Boolean := True;
      begin
         for I in 1 .. N loop
            for K in 1 .. Copies (I) loop
               Len := Len + 1;
               Flat (Len) := I;
            end loop;
         end loop;
         for Mask in 0 .. 2 ** Len - 1 loop
            declare
               Take : Count_List (1 .. N) := [others => 0];
               M    : Natural := Mask;
            begin
               for P in 1 .. Len loop
                  if M mod 2 = 1 then
                     Take (Flat (P)) := Take (Flat (P)) + 1;
                  end if;
                  M := M / 2;
               end loop;
               if not Marked (Own_Rank (Copies, Take)) then
                  Marked (Own_Rank (Copies, Take)) := True;
                  Marks := Marks + 1;
               end if;
            end;
         end loop;
         Report (Count (C) = Marks, "Count vs brute force");
         Seen (0) := True;
         while Found loop
            Next_Choice (C, Found);
            Steps := Steps + 1;
            exit when Steps > Marks;
            if Found then
               Ok := Ok and then Marked (Own_Rank (Copies, C.Take)) and then not Seen (Own_Rank (Copies, C.Take));
               Seen (Own_Rank (Copies, C.Take)) := True;
            end if;
         end loop;
         Report (Ok and then Steps = Marks and then Seen = Marked and then C.Copies = Copies
                 and then (for all I in 1 .. N => C.Take (I) = 0), "walk vs brute force");
      end;
   end loop;

   --  Random choices up to 30 items: rank + 1 or wrap; Count; Subset.
   for Trial in 1 .. 5_000 loop
      declare
         N      : constant Length := Next mod 31;
         Copies : constant Count_List := Random_Copies (N, 30);
         Take   : Count_List (1 .. N);
         Values : Item_List (1 .. N);
         Full   : constant Boolean := Next mod 5 = 0;
      begin
         for I in 1 .. N loop
            Take (I) := (if Full and then I < N then Copies (I) else Next mod (Copies (I) + 1));
            Values (I) := Next mod 1_001 - 500;
         end loop;
         declare
            C     : Choice := (N => N, Copies => Copies, Take => Take);
            Old   : constant Long_Long_Integer := Own_Rank (Copies, Take);
            Found : Boolean;
            Got   : constant Item_List := Subset (Values, C);
            Want  : constant Item_List := Own_Expand (Values, Take);
         begin
            Report (Got'First = 1 and then Got'Length = Want'Length
                    and then (Got'Length = 0 or else Got = Want), "Subset vs own");
            Report (Long_Long_Integer (Count (C)) = Own_Product (Copies), "Count vs own product");
            Next_Choice (C, Found);
            if Old = Own_Product (Copies) - 1 then
               Report (not Found and then Own_Rank (Copies, C.Take) = 0, "wrap");
            else
               Report (Found and then Own_Rank (Copies, C.Take) = Old + 1 and then C.Copies = Copies, "rank + 1");
            end if;
         end;
      end;
   end loop;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
