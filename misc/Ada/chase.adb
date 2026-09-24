--  chase.adb
--  Implementation of the Chase algorithm and its variants

with Ada.Text_IO; use Ada.Text_IO;

package body Chase is

   -- Helper function to trim spaces from both ends of a string
   function Trim_Both (S : String) return String is
      First : Integer := S'First;
      Last : Integer := S'Last;
   begin
      -- Skip leading spaces
      while First <= Last and then S(First) = ' ' loop
         First := First + 1;
      end loop;
      -- Skip trailing spaces
      while Last >= First and then S(Last) = ' ' loop
         Last := Last - 1;
      end loop;
      if First > Last then
         return "";
      else
         return S(First..Last);
      end if;
   end Trim_Both;

   -- ===================================================================
   -- HELPER FUNCTIONS
   -- ===================================================================

   function Create_Literal (Text : String) return Value is
      V : Value;
      Actual_Length : Integer := Text'Length;
   begin
      if Actual_Length > 10 then
         raise Invalid_FD with "Value text too long";
      end if;
      V.Text := (others => ' ');
      V.Text(1..Actual_Length) := Text;
      V.V_Kind := Literal_Value;
      V.Subscript := 0;
      return V;
   end Create_Literal;

   function Create_Variable (Text : String; Subscript : Integer) return Value is
      V : Value;
      Actual_Length : Integer := Text'Length;
   begin
      if Actual_Length > 10 then
         raise Invalid_FD with "Value text too long";
      end if;
      V.Text := (others => ' ');
      V.Text(1..Actual_Length) := Text;
      V.V_Kind := Variable_Value;
      V.Subscript := Subscript;
      return V;
   end Create_Variable;

   function Values_Equal (Left, Right : Value) return Boolean is
   begin
      if Left.V_Kind = Literal_Value and Right.V_Kind = Literal_Value then
         return Trim_Both(Left.Text) = Trim_Both(Right.Text);
      elsif Left.V_Kind = Variable_Value and Right.V_Kind = Variable_Value then
         return Left.Subscript = Right.Subscript;
      else
         return False;
      end if;
   end Values_Equal;

   function Find_Attribute_Index (
      Attributes : Attribute_List;
      Attr_Length : Integer;
      Attr : Attribute)
   return Integer is
   begin
      for I in 1..Attr_Length loop
         if Attributes(I) = Attr then
            return I;
         end if;
      end loop;
      return -1;
   end Find_Attribute_Index;

   function Attribute_In_Schema (
      Attributes : Attribute_List;
      Attr_Length : Integer;
      Attr : Attribute)
   return Boolean is
   begin
      return Find_Attribute_Index(Attributes, Attr_Length, Attr) /= -1;
   end Attribute_In_Schema;

   -- Helper function to convert Character to Attribute
   function Char_To_Attribute (C : Character) return Attribute is
   begin
      case C is
         when 'A' | 'a' => return Attribute'Val(1);
         when 'B' | 'b' => return Attribute'Val(2);
         when 'C' | 'c' => return Attribute'Val(3);
         when 'D' | 'd' => return Attribute'Val(4);
         when 'E' | 'e' => return Attribute'Val(5);
         when 'F' | 'f' => return Attribute'Val(6);
         when 'G' | 'g' => return Attribute'Val(7);
         when 'H' | 'h' => return Attribute'Val(8);
         when others => return Nul;
      end case;
   end Char_To_Attribute;

   -- ===================================================================
   -- TABLEAU OPERATIONS
   -- ===================================================================

   procedure Create_Initial_Tableau (
      Original_Tuple : Tuple;
      Decomp : Decomposition;
      Decomp_Length : Integer;
      Tuple_Length : Integer;
      Result : out Tableau;
      Result_Length : out Integer) is
   begin
      Result_Length := Decomp_Length;
      for Schema_Idx in 1..Decomp_Length loop
         for Attr_Idx in 1..Tuple_Length loop
            if Attribute_In_Schema(Decomp(Schema_Idx), Max_Attributes, Char_To_Attribute(Original_Tuple(Attr_Idx).Text(1))) then
               Result(Schema_Idx)(Attr_Idx) := Original_Tuple(Attr_Idx);
            else
               Result(Schema_Idx)(Attr_Idx) := Create_Variable(Original_Tuple(Attr_Idx).Text, Schema_Idx);
            end if;
         end loop;
      end loop;
   end Create_Initial_Tableau;

   procedure Apply_FD (
      T : in out Tableau;
      T_Length : Integer;
      FD : Functional_Dependency;
      Tuple_Length : Integer;
      Changed : out Boolean) is

      function Get_Position (Attr : Attribute) return Integer is
      begin
         case Attr is
            when A => return 1;
            when B => return 2;
            when C => return 3;
            when D => return 4;
            when E => return 5;
            when F => return 6;
            when G => return 7;
            when H => return 8;
            when others => return -1;
         end case;
      end Get_Position;

      Right_Pos : Integer;
   begin
      Changed := False;
      Right_Pos := Get_Position(FD.Right);
      if Right_Pos = -1 then
         raise Invalid_FD with "Right-hand attribute not found";
      end if;

      for Row1 in 1..T_Length loop
         for Row2 in Row1+1..T_Length loop
            declare
               Left_Match : Boolean := True;
               Has_Literal : Boolean := False;
            begin
               for I in 1..FD.Left_Length loop
                  declare
                     Pos : Integer := Get_Position(FD.Left(I));
                  begin
                     if Pos = -1 then
                        Left_Match := False;
                        exit;
                     end if;
                     if not Values_Equal(T(Row1)(Pos), T(Row2)(Pos)) then
                        Left_Match := False;
                        exit;
                     end if;
                  end;
               end loop;

               if Left_Match and not Values_Equal(T(Row1)(Right_Pos), T(Row2)(Right_Pos)) then
                  if T(Row1)(Right_Pos).V_Kind = Literal_Value then
                     T(Row2)(Right_Pos) := T(Row1)(Right_Pos);
                     Changed := True;
                  elsif T(Row2)(Right_Pos).V_Kind = Literal_Value then
                     T(Row1)(Right_Pos) := T(Row2)(Right_Pos);
                     Changed := True;
                  else
                     if T(Row1)(Right_Pos).Subscript < T(Row2)(Right_Pos).Subscript then
                        T(Row2)(Right_Pos) := T(Row1)(Right_Pos);
                     else
                        T(Row1)(Right_Pos) := T(Row2)(Right_Pos);
                     end if;
                     Changed := True;
                  end if;
               end if;
            end;
         end loop;
      end loop;
   end Apply_FD;

   function Contains_Original_Tuple (
      T : Tableau;
      T_Length : Integer;
      Original_Tuple : Tuple;
      Tuple_Length : Integer)
   return Boolean is
   begin
      for Row in 1..T_Length loop
         declare
            Match : Boolean := True;
         begin
            for I in 1..Tuple_Length loop
               if T(Row)(I).V_Kind /= Literal_Value or else not Values_Equal(T(Row)(I), Original_Tuple(I)) then
                  Match := False;
                  exit;
               end if;
            end loop;
            if Match then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Contains_Original_Tuple;

   -- ===================================================================
   -- MAIN CHASE ALGORITHMS
   -- ===================================================================

   function Standard_Chase (
      Original_Tuple : Tuple;
      FDs : FD_List;
      FDs_Length : Integer;
      Decomp : Decomposition;
      Decomp_Length : Integer;
      Tuple_Length : Integer)
   return Boolean is

      T : Tableau := (others => (others => Create_Literal("")));
      T_Length : Integer;
      Changed : Boolean;
   begin
      Create_Initial_Tableau(Original_Tuple, Decomp, Decomp_Length, Tuple_Length, T, T_Length);

      for Iteration in 1..100 loop
         Changed := False;
         for I in 1..FDs_Length loop
            Apply_FD(T, T_Length, FDs(I), Tuple_Length, Changed);
         end loop;
         exit when not Changed;
         if Contains_Original_Tuple(T, T_Length, Original_Tuple, Tuple_Length) then
            return True;
         end if;
      end loop;

      return Contains_Original_Tuple(T, T_Length, Original_Tuple, Tuple_Length);
   end Standard_Chase;

   function Oblivious_Chase (
      Original_Tuple : Tuple;
      FDs : FD_List;
      FDs_Length : Integer;
      Decomp : Decomposition;
      Decomp_Length : Integer;
      Tuple_Length : Integer)
   return Boolean is

      T : Tableau := (others => (others => Create_Literal("")));
      T_Length : Integer;
      Changed : Boolean;
   begin
      Create_Initial_Tableau(Original_Tuple, Decomp, Decomp_Length, Tuple_Length, T, T_Length);

      for Iteration in 1..100 loop
         Changed := False;
         for I in 1..FDs_Length loop
            for J in 1..2 loop
               Apply_FD(T, T_Length, FDs(I), Tuple_Length, Changed);
            end loop;
         end loop;
         exit when not Changed;
         if Contains_Original_Tuple(T, T_Length, Original_Tuple, Tuple_Length) then
            return True;
         end if;
      end loop;

      return Contains_Original_Tuple(T, T_Length, Original_Tuple, Tuple_Length);
   end Oblivious_Chase;

   function Core_Chase (
      Original_Tuple : Tuple;
      FDs : FD_List;
      FDs_Length : Integer;
      Decomp : Decomposition;
      Decomp_Length : Integer;
      Tuple_Length : Integer)
   return Boolean is

      T : Tableau := (others => (others => Create_Literal("")));
      T_Length : Integer;
      Changed : Boolean;
   begin
      Create_Initial_Tableau(Original_Tuple, Decomp, Decomp_Length, Tuple_Length, T, T_Length);

      for Iteration in 1..100 loop
         Changed := False;
         for I in 1..FDs_Length loop
            Apply_FD(T, T_Length, FDs(I), Tuple_Length, Changed);
         end loop;
         exit when not Changed;
         if Contains_Original_Tuple(T, T_Length, Original_Tuple, Tuple_Length) then
            return True;
         end if;
      end loop;

      return Contains_Original_Tuple(T, T_Length, Original_Tuple, Tuple_Length);
   end Core_Chase;

   function Restricted_Chase_TGD (
      Original_Tuple : Tuple;
      TGDs : FD_List;
      TGDs_Length : Integer;
      Decomp : Decomposition;
      Decomp_Length : Integer;
      Tuple_Length : Integer)
   return Boolean is

      T : Tableau := (others => (others => Create_Literal("")));
      T_Length : Integer;
      Changed : Boolean;
   begin
      Create_Initial_Tableau(Original_Tuple, Decomp, Decomp_Length, Tuple_Length, T, T_Length);

      for Iteration in 1..100 loop
         Changed := False;
         for I in 1..TGDs_Length loop
            Apply_FD(T, T_Length, TGDs(I), Tuple_Length, Changed);
         end loop;
         exit when not Changed;
         if Contains_Original_Tuple(T, T_Length, Original_Tuple, Tuple_Length) then
            return True;
         end if;
      end loop;

      return Contains_Original_Tuple(T, T_Length, Original_Tuple, Tuple_Length);
   end Restricted_Chase_TGD;

   -- ===================================================================
   -- VALIDATION FUNCTIONS
   -- ===================================================================

   function Validate_FDs (FDs : FD_List; FDs_Length : Integer) return Boolean is
   begin
      for I in 1..FDs_Length loop
         if FDs(I).Left_Length = 0 then
            return False;
         end if;
      end loop;
      return True;
   end Validate_FDs;

   function Validate_Decomposition (
      Decomp : Decomposition;
      Decomp_Length : Integer;
      All_Attrs : Attribute_List;
      All_Attrs_Length : Integer)
   return Boolean is
   begin
      for I in 1..All_Attrs_Length loop
         declare
            Found : Boolean := False;
         begin
            for J in 1..Decomp_Length loop
               if Attribute_In_Schema(Decomp(J), Max_Attributes, All_Attrs(I)) then
                  Found := True;
                  exit;
               end if;
            end loop;
            if not Found then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Validate_Decomposition;

end Chase;
