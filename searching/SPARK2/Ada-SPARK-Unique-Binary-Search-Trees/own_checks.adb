pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Unique_Binary_Search_Trees; use Unique_Binary_Search_Trees;
--  Own checks (H116): the count must be computed for every N up to 19
--  (Catalan (19) = 1,767,263,190 is the largest that fits Integer) and agree
--  with two independent references: enumeration of BST shapes (N <= 8) and
--  the closed form binomial (2N, N) / (N + 1).
procedure Own_Checks is
   Fails : Natural := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      if not Cond then
         Fails := Fails + 1;
         Put_Line ("FAIL " & Name);
      end if;
   end Check;

   --  Reference 1 (enumeration, N <= 8): build the BST of every insertion
   --  order of 1 .. N, encode each tree's shape, and count distinct shapes.
   function Enumerate (N : Natural) return Long_Long_Integer is
      Max : constant := 8;
      type Perm is array (1 .. Max) of Natural;
      Shape_Max : constant := 2 * Max + 1;
      subtype Shape is String (1 .. Shape_Max);
      Seen  : array (1 .. 2000) of Shape;
      Found : Natural := 0;
      P     : Perm := [others => 0];
      Used  : array (1 .. Max) of Boolean := [others => False];

      function Encode return Shape is
         Left, Right : array (1 .. Max) of Natural := [others => 0];
         Root : constant Natural := P (1);
         S    : Shape := [others => ' '];
         Pos  : Natural := 0;
         procedure Walk (Node : Natural) is
         begin
            Pos := Pos + 1;
            if Node = 0 then
               S (Pos) := '.';
            else
               S (Pos) := '(';
               Walk (Left (Node));
               Walk (Right (Node));
            end if;
         end Walk;
      begin
         for K in 2 .. N loop
            declare
               Cur : Natural := Root;
            begin
               loop
                  if P (K) < Cur then
                     exit when Left (Cur) = 0;
                     Cur := Left (Cur);
                  else
                     exit when Right (Cur) = 0;
                     Cur := Right (Cur);
                  end if;
               end loop;
               if P (K) < Cur then
                  Left (Cur) := P (K);
               else
                  Right (Cur) := P (K);
               end if;
            end;
         end loop;
         Walk (Root);
         return S;
      end Encode;

      procedure Place (K : Positive) is
      begin
         if K > N then
            declare
               S : constant Shape := Encode;
            begin
               for F in 1 .. Found loop
                  if Seen (F) = S then
                     return;
                  end if;
               end loop;
               Found := Found + 1;
               Seen (Found) := S;
            end;
            return;
         end if;
         for V in 1 .. N loop
            if not Used (V) then
               Used (V) := True;
               P (K) := V;
               Place (K + 1);
               Used (V) := False;
            end if;
         end loop;
      end Place;
   begin
      if N = 0 then
         return 1;
      end if;
      Place (1);
      return Long_Long_Integer (Found);
   end Enumerate;

   --  Reference 2 (closed form, every N): binomial (2N, N) / (N + 1),
   --  binomial built as a product of exact divisions.
   function Closed_Form (N : Natural) return Long_Long_Integer is
      B : Long_Long_Integer := 1;
   begin
      for K in 1 .. N loop
         B := B * Long_Long_Integer (N + K) / Long_Long_Integer (K);
      end loop;
      return B / Long_Long_Integer (N + 1);
   end Closed_Form;
   function Count_Of (N : Natural) return Long_Long_Integer is
   begin
      return Long_Long_Integer (Number_Of_Trees (N));
   exception
      when Constraint_Error =>
         return -1;   --  N rejected: not a count
   end Count_Of;
begin
   Check (Count_Of (19) = 1_767_263_190, "19");
   for N in 0 .. 8 loop
      Check (Count_Of (N) = Enumerate (N), "enumeration N =" & N'Image);
   end loop;
   for N in 0 .. 19 loop
      Check (Count_Of (N) = Closed_Form (N), "closed form N =" & N'Image);
   end loop;
   if Fails = 0 then
      Put_Line ("PASS Unique_Binary_Search_Trees own checks");
   else
      Put_Line ("FAILED" & Fails'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Own_Checks;
