--  Demo of the Unicode_Collation package (default table, punctuation-ignoring comparison, tailoring).
--  Built and run by make test, so it stays in step with the package API.
with Ada.Text_IO; use Ada.Text_IO;
with Unicode_Collation; use Unicode_Collation;

procedure Main is
   Table : constant Character_Table := Get_Default_Table;

   type Word_Access is access constant String;
   W1 : aliased constant String := "banana";
   W2 : aliased constant String := "Apple";
   W3 : aliased constant String := "apple";
   W4 : aliased constant String := "co-op";
   W5 : aliased constant String := "coop";
   W6 : aliased constant String := "123";
   W7 : aliased constant String := "Cherry";
   Words : array (1 .. 7) of Word_Access :=
     (W1'Access, W2'Access, W3'Access, W4'Access, W5'Access, W6'Access, W7'Access);

   procedure Show (Left, Right : String; R : Collation_Result) is
   begin
      Put_Line ("  """ & Left & """ vs """ & Right & """: " & Collation_Result'Image (R));
   end Show;
begin
   Put_Line ("Unicode Collation Algorithm demo");

   --  Insertion sort with Compare_Standard (all three levels).
   for I in Words'First + 1 .. Words'Last loop
      declare
         Key : constant Word_Access := Words (I);
         J   : Integer := I - 1;
      begin
         while J >= Words'First and then Compare_Standard (Words (J).all, Key.all, Table) = Greater loop
            Words (J + 1) := Words (J);
            J := J - 1;
         end loop;
         Words (J + 1) := Key;
      end;
   end loop;
   Put_Line ("Sorted with Compare_Standard:");
   for W of Words loop
      Put_Line ("  " & W.all);
   end loop;

   Put_Line ("Comparisons:");
   Show ("apple", "Apple", Compare_Standard ("apple", "Apple", Table));
   Show ("123", "abc", Compare_Standard ("123", "abc", Table));
   Show ("co-op", "coop", Compare_Standard ("co-op", "coop", Table));
   Put_Line ("Ignoring punctuation:");
   Show ("co-op", "coop", Compare_Ignore_Punctuation ("co-op", "coop", Table));

   declare
      --  Tailoring: give 'z' a primary weight below 'a'.
      Z_First : constant Character_Table :=
        Apply_Tailoring (Table, 'z', (Primary => Table ('a').Primary - 1,
                                      Secondary => Table ('z').Secondary,
                                      Tertiary  => Table ('z').Tertiary));
   begin
      Put_Line ("Tailored ('z' before 'a'):");
      Show ("zebra", "apple", Compare_Standard ("zebra", "apple", Z_First));
   end;
   Put_Line ("Demo complete.");
end Main;
