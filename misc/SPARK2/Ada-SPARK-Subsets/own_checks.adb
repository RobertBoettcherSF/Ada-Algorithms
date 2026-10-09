pragma Ada_2022;
--  Own checks for Subsets (see tests/SOURCES.txt). No expected value comes
--  from the program:
--  * an own recursive generator (leave item K out, then take it) lists
--    every subset of N <= 10 items; stepping from the empty selection
--    must visit each of them exactly once, Found must be False exactly at
--    the last one, and the selection must then be empty again;
--  * an own rank (sum of 2 ** (K - 1) over the selected K, in
--    Long_Long_Integer): on seeded random selections of 0 .. 30 items the
--    next selection has rank + 1, and all-True wraps to rank 0;
--  * Subset against an own recursive extraction (head, then the rest) on
--    seeded random lists with random bounds, and the property that the
--    subset and the subset of the complement together hold every item
--    exactly once (the same multiset);
--  * Count against own repeated doubling, and the ghost Pow2 table
--    regenerated.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Subsets; use Subsets;

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
      Name : constant String := "Ada-SPARK-Subsets";
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

   function Own_Rank (S : Selection) return Long_Long_Integer is
      R : Long_Long_Integer := 0;
      W : Long_Long_Integer := 1;
   begin
      for K in S'Range loop
         if S (K) then
            R := R + W;
         end if;
         W := W + W;
      end loop;
      return R;
   end Own_Rank;

   function Own_Power (N : Natural) return Long_Long_Integer is
      R : Long_Long_Integer := 1;
   begin
      for K in 1 .. N loop
         R := R + R;
      end loop;
      return R;
   end Own_Power;

   --  Every subset of N <= 10 items, by own recursion, as ranks marked
   --  in Seen; Listed counts them.
   type Mark is array (Long_Long_Integer range 0 .. 1_023) of Boolean;

   procedure Generate (N : Natural; Seen : out Mark; Listed : out Natural) is
      Cur : Selection (1 .. N) := [others => False];
      procedure Rec (K : Positive) is
      begin
         if K > N then
            Seen (Own_Rank (Cur)) := True;
            Listed := Listed + 1;
            return;
         end if;
         Cur (K) := False;
         Rec (K + 1);
         Cur (K) := True;
         Rec (K + 1);
         Cur (K) := False;
      end Rec;
   begin
      Seen := [others => False];
      Listed := 0;
      Rec (1);
   end Generate;

   --  Own extraction: the first item if selected, then the rest.
   function Own_Subset (Items : Item_List; S : Selection) return Item_List is
     (if Items'Length = 0 then []
      elsif S (S'First) then [Items (Items'First)] & Own_Subset (Items (Items'First + 1 .. Items'Last), S (S'First + 1 .. S'Last))
      else Own_Subset (Items (Items'First + 1 .. Items'Last), S (S'First + 1 .. S'Last)));

   function Sorted (A : Item_List) return Item_List is
      R : Item_List (1 .. A'Length) := A;
      T : Integer;
   begin
      for I in 2 .. R'Last loop
         for J in reverse 2 .. I loop
            exit when R (J - 1) <= R (J);
            T := R (J); R (J) := R (J - 1); R (J - 1) := T;
         end loop;
      end loop;
      return R;
   end Sorted;
begin
   --  Exhaustive walk for N <= 10.
   for N in 0 .. 10 loop
      declare
         Seen    : Mark;
         Listed  : Natural;
         Visited : Mark := [others => False];
         S       : Small_Selection (1 .. N) := [others => False];
         Found   : Boolean := True;
         Steps   : Natural := 0;
         Ok      : Boolean := True;
      begin
         Generate (N, Seen, Listed);
         Report (Long_Long_Integer (Listed) = Own_Power (N), "generator count" & N'Image);
         Visited (0) := True;
         while Found loop
            Next_Subset (S, Found);
            Steps := Steps + 1;
            exit when Steps > Listed;
            if Found then
               Ok := Ok and then Seen (Own_Rank (S)) and then not Visited (Own_Rank (S));
               Visited (Own_Rank (S)) := True;
            end if;
         end loop;
         Report (Ok and then Steps = Listed and then Visited = Seen
                 and then (for all K in S'Range => not S (K)), "walk" & N'Image);
      end;
   end loop;

   --  Random selections up to 30 items: rank + 1, or wrap.
   for I in 1 .. 5_000 loop
      declare
         N     : constant Natural := Next mod 31;
         S     : Small_Selection (1 .. N);
         Found : Boolean;
         Old   : Long_Long_Integer;
         Dense : constant Natural := Next mod 4;
      begin
         for K in S'Range loop
            S (K) := (case Dense is when 0 => Next mod 2 = 0, when 1 => Next mod 8 /= 0,
                                    when 2 => K > N / 2 or else Next mod 2 = 0, when others => True);
         end loop;
         Old := Own_Rank (S);
         Next_Subset (S, Found);
         if Old = Own_Power (N) - 1 then
            Report (not Found and then Own_Rank (S) = 0, "wrap" & N'Image);
         else
            Report (Found and then Own_Rank (S) = Old + 1, "rank + 1 at" & Old'Image);
         end if;
      end;
   end loop;

   --  Subset on random lists with random bounds.
   for I in 1 .. 3_000 loop
      declare
         F     : constant Positive := 1 + Next mod 100;
         Len   : constant Natural := Next mod 41;
         Items : Item_List (F .. F + Len - 1);
         S     : Selection (F .. F + Len - 1);
         Not_S : Selection (F .. F + Len - 1);
      begin
         for K in Items'Range loop
            Items (K) := Next mod 21 - 10;
            S (K) := Next mod 3 /= 0;
            Not_S (K) := not S (K);
         end loop;
         declare
            Got  : constant Item_List := Subset (Items, S);
            Want : constant Item_List := Own_Subset (Items, S);
            Rest : constant Item_List := Subset (Items, Not_S);
         begin
            Report (Got'First = 1 and then Got'Length = Want'Length
                    and then (Got'Length = 0 or else Got = Want), "Subset vs own" & Len'Image);
            Report (Sorted (Got & Rest) = Sorted (Items), "Subset + complement" & Len'Image);
         end;
      end;
   end loop;

   for N in Item_Count loop
      Report (Long_Long_Integer (Count (N)) = Own_Power (N), "Count" & N'Image);
      pragma Assert (Long_Long_Integer (Pow2 (N)) = Own_Power (N));
   end loop;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
