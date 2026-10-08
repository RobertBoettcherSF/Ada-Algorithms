pragma Ada_2022;
--  Own tests for Longest_Word_In_Dictionary (see tests/SOURCES.txt).
--  Longest_Length: length of the longest word all of whose prefixes (length 1 .. Len) are words of the
--  dictionary; empty slots (Len = 0) are not words. Own reference compares letter strings.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Longest_Word_In_Dictionary; use Longest_Word_In_Dictionary;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20261008);
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   W : Word_Array;
   function Img (X : Word) return String is
      S : String (1 .. X.Len);
   begin
      for I in S'Range loop S (I) := X.Chars (I); end loop;
      return S;
   end Img;
   function In_Dict (S : String) return Boolean is (for some X of W => X.Len > 0 and then Img (X) = S);
   function Brute return Natural is
      Best : Natural := 0;
   begin
      for X of W loop
         if X.Len > 0 and then (for all L in 1 .. X.Len => In_Dict (Img (X) (1 .. L))) then
            Best := Natural'Max (Best, X.Len);
         end if;
      end loop;
      return Best;
   end Brute;
begin
   for Trial in 1 .. 30_000 loop
      for I in Word_Index loop
         W (I).Len := Next (0, 4);
         W (I).Chars := [others => 'a'];
         for J in 1 .. W (I).Len loop
            W (I).Chars (J) := Character'Val (Character'Pos ('a') + Next (0, 1));
         end loop;
         for J in W (I).Len + 1 .. Max_Length loop   --  junk after Len must not matter
            W (I).Chars (J) := Character'Val (Character'Pos ('a') + Next (0, 3));
         end loop;
      end loop;
      Report (Longest_Length (W) = Brute, "trial" & Integer'Image (Trial));
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
