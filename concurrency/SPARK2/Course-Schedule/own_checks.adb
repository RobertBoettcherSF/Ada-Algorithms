--  Own tests for Course_Schedule (written for this repository; see
--  tests/SOURCES.txt). Assumption: Can_Finish / Schedule give the wrong
--  answer for some prerequisite list, or the witness they return does not
--  show the answer. Reference: a brute force in this file that tries all
--  24 orders of the 4 courses; the courses can be finished exactly when
--  one order puts every Required before its Course_Number. Inputs: every
--  one of the 16 ** 4 = 65,536 prerequisite arrays (no randomness).
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Course_Schedule; use Course_Schedule;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;
   Finishable_Count : Natural := 0;

   type Order is array (1 .. Course_Count) of Course;   --  position -> course

   --  Some order of the courses meets every prerequisite.
   function Reference (P : Prerequisite_Array) return Boolean is
      O : Order;
      Used : array (Course) of Boolean := [others => False];
      Found : Boolean := False;

      procedure Try (K : Positive) is
      begin
         if Found then
            return;
         end if;
         if K > Course_Count then
            declare
               Pos : array (Course) of Positive;
               Good : Boolean := True;
            begin
               for J in O'Range loop
                  Pos (O (J)) := J;
               end loop;
               for I in P'Range loop
                  if Pos (P (I).Required) >= Pos (P (I).Course_Number) then
                     Good := False;
                  end if;
               end loop;
               Found := Good;
            end;
            return;
         end if;
         for C in Course loop
            if not Used (C) then
               Used (C) := True;
               O (K) := C;
               Try (K + 1);
               Used (C) := False;
            end if;
         end loop;
      end Try;
   begin
      Try (1);
      return Found;
   end Reference;

   --  The witness checked here directly, not through Is_Order / Is_Stuck.
   function Witness_Ok (P : Prerequisite_Array; R : Schedule_Result) return Boolean is
   begin
      if R.Ok then
         for I in P'Range loop
            if R.Rank (P (I).Required) >= R.Rank (P (I).Course_Number) then
               return False;
            end if;
         end loop;
         return True;
      else
         declare
            Any : Boolean := False;
         begin
            for C in Course loop
               if R.Stuck (C) then
                  Any := True;
                  declare
                     Needs_Member : Boolean := False;
                  begin
                     for I in P'Range loop
                        if P (I).Course_Number = C and then R.Stuck (P (I).Required) then
                           Needs_Member := True;
                        end if;
                     end loop;
                     if not Needs_Member then
                        return False;
                     end if;
                  end;
               end if;
            end loop;
            return Any;
         end;
      end if;
   end Witness_Ok;

   P : Prerequisite_Array;
begin
   for Code in 0 .. 16 ** Prerequisite_Count - 1 loop
      for I in P'Range loop
         declare
            E : constant Natural := Code / 16 ** (I - 1) mod 16;
         begin
            P (I) := (Course_Number => E / 4 + 1, Required => E mod 4 + 1);
         end;
      end loop;
      declare
         Expected : constant Boolean := Reference (P);
         R        : constant Schedule_Result := Schedule (P);
         Got      : constant Boolean := Can_Finish (P);
      begin
         Cases := Cases + 1;
         if Expected then
            Finishable_Count := Finishable_Count + 1;
         end if;
         if Got /= Expected or else R.Ok /= Expected
           or else not Witness_Ok (P, R)
         then
            Failures := Failures + 1;
            if Failures <= 5 then
               Put ("FAIL Can_Finish (");
               for I in P'Range loop
                  Put (P (I).Course_Number'Image & " needs"
                       & P (I).Required'Image & ";");
               end loop;
               Put_Line (" ) =" & Got'Image & ", Schedule.Ok =" & R.Ok'Image
                         & ", expected" & Expected'Image);
            end if;
         end if;
      end;
   end loop;
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " prerequisite arrays ("
             & Finishable_Count'Image
             & " finishable) vs brute force over all orders, witnesses checked");
end Own_Checks;
