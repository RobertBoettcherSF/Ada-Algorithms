with Valid_Anagram;
procedure Tests is
   Left : constant Valid_Anagram.Text_Array := "abacba";
   Right : constant Valid_Anagram.Text_Array := "baacab";
   Different : constant Valid_Anagram.Text_Array := "abacbb";
begin
   pragma Assert (Valid_Anagram.Is_Anagram (Left, Right));
   pragma Assert (not Valid_Anagram.Is_Anagram (Left, Different));
end Tests;
