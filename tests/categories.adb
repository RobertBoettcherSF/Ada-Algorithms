pragma Ada_2022;

package body Categories is

   function Pad (S : String; Width : Positive) return String is
      R : String (1 .. Width) := (others => ' ');
   begin
      if S'Length > Width then
         R := S (S'First .. S'First + Width - 1);
      else
         R (1 .. S'Length) := S;
      end if;
      return R;
   end Pad;

   function Make
     (Name     : String;
      Category : Category_Id;
      Test_Bin : String) return Algo_Entry
   is
      E : Algo_Entry;
   begin
      E.Name     := Pad (Name, E.Name'Length);
      E.Name_Len := Name'Length;
      E.Category := Category;
      E.Test_Bin := Pad (Test_Bin, E.Test_Bin'Length);
      E.Bin_Len  := Test_Bin'Length;
      return E;
   end Make;

   Registry : constant array (Algo_Index range 1 .. 4) of Algo_Entry :=
     [1 => Make ("quicksort",     Sorting,   "test_quicksort"),
      2 => Make ("heapsort",      Sorting,   "test_heapsort"),
      3 => Make ("binary_search", Searching, "test_binary_search"),
      4 => Make ("modular_arithmetic", Numerical, "test_modular_arithmetic")];

   function Category_Label (C : Category_Id) return String is
   begin
      case C is
         when Sorting   => return "sorting";
         when Searching => return "searching";
         when Numerical => return "numerical";
      end case;
   end Category_Label;

   function To_Lower (C : Character) return Character is
   begin
      if C in 'A' .. 'Z' then
         return Character'Val
           (Character'Pos (C) - Character'Pos ('A') + Character'Pos ('a'));
      else
         return C;
      end if;
   end To_Lower;

   function Lower (S : String) return String is
      R : String (S'Range);
   begin
      for I in S'Range loop
         R (I) := To_Lower (S (I));
      end loop;
      return R;
   end Lower;

   function Parse_Category (S : String) return Category_Id is
      L : constant String := Lower (S);
   begin
      if L = "sorting" then
         return Sorting;
      elsif L = "searching" then
         return Searching;
      elsif L = "numerical" then
         return Numerical;
      else
         raise Constraint_Error with "unknown category: " & S;
      end if;
   end Parse_Category;

   function Registry_Length return Natural is
   begin
      return Registry'Length;
   end Registry_Length;

   function Get (I : Algo_Index) return Algo_Entry is
   begin
      return Registry (I);
   end Get;

   function Name_Of (E : Algo_Entry) return String is
   begin
      return E.Name (1 .. E.Name_Len);
   end Name_Of;

   function Bin_Of (E : Algo_Entry) return String is
   begin
      return E.Test_Bin (1 .. E.Bin_Len);
   end Bin_Of;

end Categories;
