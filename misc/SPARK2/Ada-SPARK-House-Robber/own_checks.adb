--  Own tests for House_Robber (see tests/SOURCES.txt).
--  Maximum must be the largest sum over sets of pairwise non-adjacent houses.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with House_Robber; use House_Robber;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
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
   Seed : Long_Long_Integer := AA_Seed (20_261_008);
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

   A : Values;
   function Ref return Natural is
      Best : Natural := 0;
      S : Natural;
      Ok : Boolean;
   begin
      for Mask in 0 .. 2 ** House_Count - 1 loop
         S := 0; Ok := True;
         for I in House loop
            if (Mask / 2 ** (I - 1)) mod 2 = 1 then
               S := S + A (I);
               if I > 1 and then (Mask / 2 ** (I - 2)) mod 2 = 1 then Ok := False; end if;
            end if;
         end loop;
         if Ok then Best := Natural'Max (Best, S); end if;
      end loop;
      return Best;
   end Ref;
begin
   --  every array over {0, 1, 2}, then random ones
   for Code in 0 .. 3 ** House_Count - 1 loop
      declare
         C : Natural := Code;
      begin
         for I in House loop
            A (I) := C mod 3;
            C := C / 3;
         end loop;
      end;
      Report (Maximum (A) = Ref, "small");
   end loop;
   for Iter in 1 .. 5_000 loop
      for I in House loop
         A (I) := Next (0, 100);
      end loop;
      Report (Maximum (A) = Ref, "random" & Iter'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own subset-enumeration reference)");
end Own_Checks;
