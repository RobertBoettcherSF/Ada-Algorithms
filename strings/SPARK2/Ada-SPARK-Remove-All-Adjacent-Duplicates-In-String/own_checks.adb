--  Own tests for Remove_All_Adjacent_Duplicates_In_String (see tests/SOURCES.txt).
--  Reduce must remove adjacent equal pairs until none remain.
pragma Ada_2022;
with Ada.Text_IO;
with Remove_All_Adjacent_Duplicates_In_String; use Remove_All_Adjacent_Duplicates_In_String;

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


   function P (X, Y : Character) return Boolean is (X = Y);

   --  Own reference: repeatedly delete the leftmost adjacent pair P (X, Y)
   --  until none is left (quadratic, different from a stack-based scan).
   function Reduce_Ref (S : String) return String is
   begin
      for I in S'First .. S'Last - 1 loop
         if P (S (I), S (I + 1)) then
            return Reduce_Ref (S (S'First .. I - 1) & S (I + 2 .. S'Last));
         end if;
      end loop;
      return S;
   end Reduce_Ref;

   T, O : Buffer := [others => ' '];
   N, M : Length;
begin
   for K in 1 .. 4_000 loop
      N := Next (0, Capacity);
      for I in 1 .. N loop
         T (I) := Character'Val (Character'Pos ('a') + Next (0, (if K mod 2 = 0 then 1 else 3)));
      end loop;
      Reduce (T, N, O, M);
      declare
         E : constant String := Reduce_Ref (String (T (1 .. N)));
      begin
         Report (M = E'Length and then String (O (1 .. M)) = E, "random" & K'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own repeated-pair-removal reference)");
end Own_Checks;
