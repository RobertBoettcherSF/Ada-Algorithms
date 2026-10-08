pragma Ada_2022;
--  Own tests for Maximum_Points_You_Can_Obtain_From_Cards (see tests/SOURCES.txt).
--  Taking K cards from the two ends = I from the left and K - I from the right for some I;
--  the answer is the best such sum (own brute force over I).
with Ada.Text_IO; use Ada.Text_IO;
with Maximum_Points_You_Can_Obtain_From_Cards; use Maximum_Points_You_Can_Obtain_From_Cards;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   Seed : Long_Long_Integer := 20261008;
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
   function Ref (C : Card_Array; K : Take_Count) return Natural is
      Best, S : Natural := 0;
   begin
      for I in 0 .. K loop
         S := 0;
         for P in 1 .. I loop S := S + C (P); end loop;
         for P in Element_Count - (K - I) + 1 .. Element_Count loop S := S + C (P); end loop;
         Best := Natural'Max (Best, S);
      end loop;
      return Best;
   end Ref;
begin
   for Run in 1 .. 20000 loop
      declare
         C : Card_Array;
         K : constant Take_Count := Next (0, Element_Count);
      begin
         for I in Index loop C (I) := Next (0, 8); end loop;
         Report (Natural (Max_Points (C, K)) = Ref (C, K), "run" & Integer'Image (Run));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
