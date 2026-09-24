with Uncommon_Words_From_Two_Sentences;
procedure Tests is
   Left  : constant Uncommon_Words_From_Two_Sentences.Word_Array := [1, 2, 3];
   Right : constant Uncommon_Words_From_Two_Sentences.Word_Array := [2, 3, 4];
   Same  : constant Uncommon_Words_From_Two_Sentences.Word_Array := [1, 2, 3];
begin
   pragma Assert (Uncommon_Words_From_Two_Sentences.Has_Left_Only (Left, Right));
   pragma Assert (not Uncommon_Words_From_Two_Sentences.Has_Left_Only (Left, Same));
end Tests;
