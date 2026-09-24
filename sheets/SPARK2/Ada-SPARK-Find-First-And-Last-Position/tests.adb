with Find_First_And_Last_Position;
procedure Tests is
   Data : constant Find_First_And_Last_Position.Sorted_Array :=
     (1, 2, 2, 2, 3, others => 100);
   Answer : constant Find_First_And_Last_Position.Match_Range :=
     Find_First_And_Last_Position.Locate (Data, 2);
   Missing : constant Find_First_And_Last_Position.Match_Range :=
     Find_First_And_Last_Position.Locate (Data, 9);
begin
   pragma Assert (Answer.First = 2 and then Answer.Last = 4);
   pragma Assert (Missing.First = 0 and then Missing.Last = 0);
end Tests;
