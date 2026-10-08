--  Own check (silent no-op scan, tools/vv/silent_noop.csv): Append on a full list has no
--  room for the value and must be rejected, not dropped silently.
with Ada.Assertions;
with Ada.Text_IO;
with Merge_Two_Sorted_Lists; use Merge_Two_Sorted_Lists;

procedure Full_Append_Check is
   L : List;
begin
   for I in 1 .. Count'Last loop
      Append (L, 1);
   end loop;
   if Length (L) /= Count'Last then raise Program_Error with "list not full"; end if;
   begin
      Append (L, 1);
      Ada.Text_IO.Put_Line ("FAIL own check: Append on a full list accepted (value dropped)");
      raise Program_Error;
   exception
      when Ada.Assertions.Assertion_Error =>
         Ada.Text_IO.Put_Line ("PASS own check: Append on a full list rejected");
   end;
   --  Merge of two lists whose lengths add up to more than Count'Last cannot fit:
   --  it must be rejected, not truncated. Two lists of 8 fill it exactly.
   declare
      A, B : List;
   begin
      for I in 1 .. 8 loop
         Append (A, Value (2 * I));
         Append (B, Value (2 * I + 1));
      end loop;
      declare
         M : constant List := Merge (A, B);
      begin
         if Length (M) /= 16 then raise Program_Error with "merge length"; end if;
         for P in 2 .. 16 loop
            if Element (M, P - 1) > Element (M, P) then raise Program_Error with "merge order"; end if;
         end loop;
      end;
      Append (A, 99);
      begin
         declare
            M : constant List := Merge (A, B);
         begin
            Ada.Text_IO.Put_Line ("FAIL own check: Merge of 9 + 8 accepted, length"
                                  & Count'Image (Length (M)));
            raise Program_Error;
         end;
      exception
         when Ada.Assertions.Assertion_Error =>
            Ada.Text_IO.Put_Line ("PASS own check: Merge that cannot fit rejected");
      end;
   end;
end Full_Append_Check;
