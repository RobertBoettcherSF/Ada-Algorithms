with Intersection_Of_Two_Linked_Lists;
with Ada.Text_IO;
procedure Tests is
   use Intersection_Of_Two_Linked_Lists;
   Left : List := Empty;
   Right : List := Empty;
   Other : List := Empty;
begin
   Append (Left, 1); Append (Left, 2); Append (Left, 8); Append (Left, 9);
   Append (Right, 4); Append (Right, 8); Append (Right, 9);
   Append (Other, 4); Append (Other, 8); Append (Other, 7);
   pragma Assert (Common_Suffix_Length (Left, Right) = 2);
   pragma Assert (Common_Suffix_Length (Left, Other) = 0);
   Ada.Text_IO.Put_Line ("Intersection of two linked lists: OK");
end Tests;
