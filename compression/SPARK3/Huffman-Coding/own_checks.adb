--  Own tests for Huffman_Coding (see tests/SOURCES.txt).
--  Count_Frequencies, Distinct_Count and Most_Frequent against own counts.
pragma Ada_2022;
with Ada.Text_IO;
with Huffman_Coding; use Huffman_Coding;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   Seed : Long_Long_Integer := 20_261_008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   F : Freq_Map;
   Own : array (Symbol) of Natural;
   D, Mx : Natural;
begin
   for Iter in 1 .. 4_000 loop
      declare
         N : constant Natural := Next (0, Max_Len);
         Data : Symbol_Array (1 .. N);
         Top : constant Character := (if Iter mod 2 = 0 then 'e' else 'z');
      begin
         Own := [others => 0];
         for I in Data'Range loop
            Data (I) := Character'Val (Next (Character'Pos ('a'), Character'Pos (Top)));
            Own (Data (I)) := Own (Data (I)) + 1;
         end loop;
         F := Count_Frequencies (Data);
         D := 0; Mx := 0;
         for S in Symbol loop
            Report (F (S) = Own (S), "count");
            if Own (S) > 0 then D := D + 1; end if;
            Mx := Natural'Max (Mx, Own (S));
         end loop;
         Report (Distinct_Count (F) = D, "distinct");
         if D >= 1 then
            Report (Own (Most_Frequent (F)) = Mx, "most frequent");
         end if;
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own counting reference)");
end Own_Checks;
