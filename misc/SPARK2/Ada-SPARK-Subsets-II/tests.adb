pragma Ada_2022;
with Ada.Text_IO;
with Subsets_II; use Subsets_II;

procedure Tests is
   function Img (A : Count_List) return String is
     (if A'Length = 0 then "" else A (A'First)'Image & Img (A (A'First + 1 .. A'Last)));

   procedure Step (C : in out Choice; Want : Count_List; Want_Found : Boolean) is
      Found : Boolean;
   begin
      Next_Choice (C, Found);
      if C.Take /= Want or else Found /= Want_Found then
         raise Program_Error with "Next_Choice: got" & Img (C.Take) & " " & Found'Image & ", expected" & Img (Want);
      end if;
   end Step;

   procedure Expect (Got, Want : Item_List; Label : String) is
   begin
      if Got'Length /= Want'Length or else (Got'Length > 0 and then (Got'First /= 1 or else Got /= Want)) then
         raise Program_Error with Label;
      end if;
   end Expect;

   function Ones (N : Length) return Choice is (N => N, Copies => [others => 1], Take => [others => 0]);

   Old : constant array (0 .. 12) of Positive :=
     [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1_024, 2_048, 4_096];
   --  1 1 2 as values 1, 2 with copies 2, 1: the six distinct subsets {},
   --  {1}, {1 1}, {2}, {1 2}, {1 1 2}, with the copies of value 1 as the
   --  lowest digit.
   type Six is array (1 .. 6) of Count_List (1 .. 2);
   Order : constant Six := [[0, 0], [1, 0], [2, 0], [0, 1], [1, 1], [2, 1]];
   C12 : Choice := (N => 2, Copies => [2, 1], Take => [0, 0]);
   C0  : Choice := Ones (0);
   C3  : Choice := (N => 3, Copies => [3, 2, 1], Take => [3, 2, 0]);
   V   : constant Item_List := [1, 2];
   Found : Boolean;
begin
   --  The old table: N distinct values give 2 ** N subsets.
   for N in Old'Range loop
      if Count (Ones (N)) /= Old (N) then
         raise Program_Error with "Count, distinct" & N'Image;
      end if;
   end loop;
   --  (2 + 1) (1 + 1) = 6; (3 + 1) (2 + 1) (1 + 1) = 24; 30 copies of one
   --  value: 31; 15 + 15 copies: 16 * 16 = 256; 30 distinct: 2 ** 30.
   if Count (C12) /= 6 or else Count (C3) /= 24
     or else Count ((N => 1, Copies => [30], Take => [0])) /= 31
     or else Count ((N => 2, Copies => [15, 15], Take => [0, 0])) /= 256
     or else Count (Ones (30)) /= 1_073_741_824
   then
      raise Program_Error with "Count with copies";
   end if;

   for K in 2 .. 6 loop
      Step (C12, Order (K), True);
   end loop;
   Step (C12, Order (1), False);   --  wraps to the empty subset

   --  3 2 0 -> the first two digits are full, so the third goes up: 0 0 1.
   Step (C3, [0, 0, 1], True);

   Next_Choice (C0, Found);
   if Found then
      raise Program_Error with "no values: one subset";
   end if;

   Expect (Subset (V, (N => 2, Copies => [2, 1], Take => [2, 1])), [1, 1, 2], "Subset 2 1");
   Expect (Subset (V, (N => 2, Copies => [2, 1], Take => [0, 1])), [2], "Subset 0 1");
   Expect (Subset (V, (N => 2, Copies => [2, 1], Take => [1, 0])), [1], "Subset 1 0");
   Expect (Subset (V, (N => 2, Copies => [2, 1], Take => [0, 0])), [], "Subset 0 0");
   Expect (Subset ([7, -3, 5], (N => 3, Copies => [1, 3, 2], Take => [1, 3, 2])), [7, -3, -3, -3, 5, 5], "Subset all");

   Ada.Text_IO.Put_Line ("subsets II tests passed");
end Tests;
