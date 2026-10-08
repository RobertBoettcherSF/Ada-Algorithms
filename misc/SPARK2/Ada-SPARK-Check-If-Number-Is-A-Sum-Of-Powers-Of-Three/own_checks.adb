--  Own tests for Sum_Powers_Three (see tests/SOURCES.txt).
--  True exactly for sums of distinct powers of three; reference: every subset of {3**0 .. 3**18}.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Sum_Powers_Three; use Sum_Powers_Three;

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
   type Sum_Array is array (Natural range <>) of Natural;
   type Sum_Access is access Sum_Array;
   Sums : constant Sum_Access := new Sum_Array (0 .. 2**19 - 1);
   Small : array (0 .. 2_000_000) of Boolean := [others => False];

   function Listed (V : Natural) return Boolean is   --  binary search in the sorted sums
      Lo : Integer := Sums'First;
      Hi : Integer := Sums'Last;
   begin
      while Lo <= Hi loop
         declare
            Mid : constant Integer := (Lo + Hi) / 2;
         begin
            if Sums (Mid) = V then return True;
            elsif Sums (Mid) < V then Lo := Mid + 1;
            else Hi := Mid - 1; end if;
         end;
      end loop;
      return False;
   end Listed;
begin
   --  subset Mask -> sum of 3**I for the bits I of Mask; increasing in Mask (3**I > sum of lower powers)
   for Mask in Sums'Range loop
      declare
         S : Long_Long_Integer := 0;
         P : Long_Long_Integer := 1;
      begin
         for I in 0 .. 18 loop
            if (Mask / 2**I) mod 2 = 1 then S := S + P; end if;
            P := P * 3;
         end loop;
         Sums (Mask) := Natural (S);
      end;
   end loop;
   for Mask in Sums'Range loop
      if Sums (Mask) <= Number'Last then
         Report (Is_Sum_Of_Powers_Of_Three (Sums (Mask)), "subset sum" & Integer'Image (Sums (Mask)));
      end if;
      if Sums (Mask) <= Small'Last then Small (Sums (Mask)) := True; end if;
   end loop;
   for V in Small'Range loop
      Report (Is_Sum_Of_Powers_Of_Three (V) = Small (V), "small" & Integer'Image (V));
   end loop;
   for Trial in 1 .. 200_000 loop
      declare
         V : constant Number := Next (0, Number'Last);
      begin
         Report (Is_Sum_Of_Powers_Of_Three (V) = Listed (V), "random" & Integer'Image (V));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
