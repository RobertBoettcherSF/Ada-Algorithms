with Ada.Text_IO; use Ada.Text_IO;
with Ada.Containers.Vectors;
with Unicode_Collation; use Unicode_Collation;

procedure Main is
   package String_Vectors is new Ada.Containers.Vectors(Positive, String);
   Vec : String_Vectors.Vector;

   function Compare_Wrapper (Left, Right : String) return Boolean is
   begin
      return Compare(Left, Right) < 0;
   end Compare_Wrapper;

   package String_Sorting is new String_Vectors.Generic_Sorting(Compare_Wrapper);

begin
   Put_Line("Unicode Collation Algorithm Demo");
   Put_Line("=================================");
   New_Line;

   Initialize_DUCET;

   String_Vectors.Append(Vec, "apple");
   String_Vectors.Append(Vec, "Apple");
   String_Vectors.Append(Vec, "ápple");
   String_Vectors.Append(Vec, "banana");
   String_Vectors.Append(Vec, "Banana");
   String_Vectors.Append(Vec, "cherry");
   String_Vectors.Append(Vec, "Cherry");
   String_Vectors.Append(Vec, "apricot");
   String_Vectors.Append(Vec, "Ápple");
   String_Vectors.Append(Vec, "123");

   Put_Line("Sorting with default settings (Tertiary strength):");
   String_Sorting.Sort(Vec);
   for I in 1 .. Positive(String_Vectors.Length(Vec)) loop
      Put_Line(Integer'Image(I) & ". " & String_Vectors.Element(Vec, I));
   end loop;
   New_Line;

   Put_Line("Sorting with Primary strength (case-insensitive):");
   declare
      function Compare_Primary_Wrapper (Left, Right : String) return Boolean is
      begin
         return Compare_Primary(Left, Right) < 0;
      end Compare_Primary_Wrapper;
      package Primary_Sorting is new String_Vectors.Generic_Sorting(Compare_Primary_Wrapper);
   begin
      Primary_Sorting.Sort(Vec);
      for I in 1 .. Positive(String_Vectors.Length(Vec)) loop
         Put_Line(Integer'Image(I) & ". " & String_Vectors.Element(Vec, I));
      end loop;
   end;
   New_Line;

   Put_Line("Comparison Examples:");
   Put_Line("-------------------");
   declare
      Result : Integer;
   begin
      Result := Compare("apple", "Apple");
      if Result < 0 then
         Put_Line("Compare(""apple"", ""Apple"") = " & Integer'Image(Result) & " (apple < Apple)");
      elsif Result > 0 then
         Put_Line("Compare(""apple"", ""Apple"") = " & Integer'Image(Result) & " (apple > Apple)");
      else
         Put_Line("Compare(""apple"", ""Apple"") = " & Integer'Image(Result) & " (equal)");
      end if;

      Result := Compare("apple", "ápple");
      if Result < 0 then
         Put_Line("Compare(""apple"", ""ápple"") = " & Integer'Image(Result) & " (apple < ápple)");
      elsif Result > 0 then
         Put_Line("Compare(""apple"", ""ápple"") = " & Integer'Image(Result) & " (apple > ápple)");
      else
         Put_Line("Compare(""apple"", ""ápple"") = " & Integer'Image(Result) & " (equal)");
      end if;

      Result := Compare("123", "abc");
      if Result < 0 then
         Put_Line("Compare(""123"", ""abc"") = " & Integer'Image(Result) & " (123 < abc)");
      elsif Result > 0 then
         Put_Line("Compare(""123"", ""abc"") = " & Integer'Image(Result) & " (123 > abc)");
      else
         Put_Line("Compare(""123"", ""abc"") = " & Integer'Image(Result) & " (equal)");
      end if;
   end;

   Put_Line("Demo complete.");
end Main;
