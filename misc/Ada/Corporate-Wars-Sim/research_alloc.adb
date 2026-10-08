package body Research_Alloc is

   use type Economy.Credits;

   function Total (A : Allocation) return Economy.Credits is
      Sum : Economy.Credits := 0;
   begin
      for B in Bucket loop
         Sum := Sum + A (B);
      end loop;
      return Sum;
   end Total;

   function Is_Valid (A : Allocation; Budget : Economy.Credits) return Boolean is
   begin
      return Total (A) <= Budget;
   end Is_Valid;

   function Empty return Allocation is
   begin
      return [others => 0];
   end Empty;

   function Even_Split (Budget : Economy.Credits) return Allocation is
      N    : constant Economy.Credits :=
        Economy.Credits (Bucket'Pos (Bucket'Last) + 1);
      Each : constant Economy.Credits := Budget / N;
      Rest : constant Economy.Credits := Budget rem N;
      A    : Allocation := [others => Each];
   begin
      A (Weapons) := A (Weapons) + Rest;
      return A;
   end Even_Split;

   procedure Set_Bucket
     (A      : in out Allocation;
      B      : Bucket;
      Amount : Economy.Credits;
      Budget : Economy.Credits;
      Ok     : out Boolean)
   is
      Trial : Allocation := A;
   begin
      Trial (B) := Amount;
      if Is_Valid (Trial, Budget) then
         A  := Trial;
         Ok := True;
      else
         Ok := False;
      end if;
   end Set_Bucket;

end Research_Alloc;
