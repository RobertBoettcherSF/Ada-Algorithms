pragma Ada_2022;
with Available_Captures_For_Rook; use Available_Captures_For_Rook;
procedure Tests is
   Layout : constant Board :=
     ((Empty, Pawn, Empty, Empty),
      (Empty, Rook, Empty, Pawn),
      (Empty, Empty, Empty, Empty),
      (Pawn, Empty, Empty, Empty));
begin
   pragma Assert (Count_Captures (2, Layout) = 2);
end Tests;
