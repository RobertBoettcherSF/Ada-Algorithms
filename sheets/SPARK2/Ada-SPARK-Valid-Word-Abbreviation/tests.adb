with Valid_Word_Abbreviation;
procedure Tests is
   Word : constant Valid_Word_Abbreviation.Text_Array := "planet";
   Good : constant Valid_Word_Abbreviation.Abbreviation_Array := "pl2et";
   Wrong_Number : constant Valid_Word_Abbreviation.Abbreviation_Array := "pl1et";
   Wrong_Letter : constant Valid_Word_Abbreviation.Abbreviation_Array := "pl2ex";
begin
   pragma Assert (Valid_Word_Abbreviation.Is_Valid (Word, Good));
   pragma Assert (not Valid_Word_Abbreviation.Is_Valid (Word, Wrong_Number));
   pragma Assert (not Valid_Word_Abbreviation.Is_Valid (Word, Wrong_Letter));
end Tests;
