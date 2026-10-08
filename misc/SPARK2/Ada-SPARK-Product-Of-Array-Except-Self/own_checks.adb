--  Own tests for Product_Of_Array_Except_Self (see tests/SOURCES.txt).
--  Products (I) must be the product of all elements except element I.
pragma Ada_2022;
with Ada.Text_IO;
with Product_Of_Array_Except_Self; use Product_Of_Array_Except_Self;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).

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

   X : Input_Array;
   P : Output_Array;
   Ok : Boolean;
begin
   for Code in 0 .. 3 ** Length - 1 loop
      declare
         C : Natural := Code;
      begin
         for I in Index loop
            X (I) := C mod 3;
            C := C / 3;
         end loop;
      end;
      P := Products (X);
      Ok := True;
      for I in Index loop
         declare
            Prod : Integer := 1;
         begin
            for J in Index loop
               if J /= I then Prod := Prod * X (J); end if;
            end loop;
            if P (I) /= Prod then Ok := False; end if;
         end;
      end loop;
      Report (Ok, "input" & Code'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own direct-product reference, exhaustive)");
end Own_Checks;
