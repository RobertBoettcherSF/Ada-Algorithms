pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Unique_BSTs_Stub; use Unique_BSTs_Stub;
procedure Tests is
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
begin
   Check (Number_Of_Trees (0) = 1, "0");
   Check (Number_Of_Trees (3) = 5, "3");
   Check (Number_Of_Trees (19) = 1_767_263_190, "19");
   for N in 0 .. 8 loop
      Check (Number_Of_Trees (N) = Enumerate (N), "enumeration N =" & N'Image);
   end loop;
   for N in Node_Count loop
      Check (Number_Of_Trees (N) = Closed_Form (N), "closed form N =" & N'Image);
   end loop;
   if Fails = 0 then
      Put_Line ("PASS Unique_BSTs_Stub");
   else
      Put_Line ("FAILED" & Fails'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
